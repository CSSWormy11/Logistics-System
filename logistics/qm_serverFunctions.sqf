// ============================================================================
// LOGISTICS SYSTEM: SERVER FUNCTIONS LIBRARY
// File: qm_serverFunctions.sqf
// Description: Centralized server functions for QM spawning, ledger deductions,
//              and framework operations. Called dynamically by init.sqf.
// ============================================================================

if (!isServer) exitWith {};

// -----------------------------------------------------------------------
// --- Server Utility Functions ---
// -----------------------------------------------------------------------

QM_fnc_deductRespawnTroop = {
    params ["_baseKey"];
    private _v = format ["LogiScore_%1_Troops", _baseKey];
    private _c = missionNamespace getVariable [_v, 0];
    if (_c != -1) then { missionNamespace setVariable [_v, (_c - 1) max 0, true]; };
};

QM_fnc_processInventoryTransaction = {
    params ["_baseKey", "_massDelta", "_playerUnit", "_loadoutBackup"];
    if (isNull _playerUnit) exitWith {};
    private _cargoVar = format ["LogiScore_%1_Cargo", _baseKey];
    private _currentPool = missionNamespace getVariable [_cargoVar, 0];
    if (_massDelta > 0 && _currentPool != -1) then {
        if (_currentPool >= _massDelta) then {
            missionNamespace setVariable [_cargoVar, (_currentPool - _massDelta) max 0, true];
            [format ["QUARTERMASTER: Transaction approved. Deducted %1 Cargo Points.", _massDelta]] remoteExec ["systemChat", _playerUnit];
        } else {
            ["QUARTERMASTER DENIED: Base capacity limits reached! Restoring gear."] remoteExec ["systemChat", _playerUnit];
            _playerUnit setUnitLoadout _loadoutBackup;
        };
    };
    if (_massDelta < 0 && _currentPool != -1) then {
        private _refund = abs _massDelta;
        missionNamespace setVariable [_cargoVar, _currentPool + _refund, true];
        [format ["QUARTERMASTER: Surplus materials processed. Credited +%1 Cargo Points.", _refund]] remoteExec ["systemChat", _playerUnit];
    };
};

QM_fnc_normalizePoolName = {
    params [["_poolName", "", [""]]];
    if (toUpper _poolName in ["VEHICLE", "VEHICLES"]) exitWith { "Vehicle" };
    if (toUpper _poolName in ["TROOP", "TROOPS"]) exitWith { "Troops" };
    _poolName
};

QM_fnc_serverVehicleSale = {
    params [["_baseKey", "", [""]], ["_vehicle", objNull, [objNull]], ["_playerUnit", objNull, [objNull]]];
    if (_baseKey == "" || isNull _vehicle) exitWith {};

    private _class = typeOf _vehicle;
    private _displayName = getText (configFile >> "CfgVehicles" >> _class >> "displayName");
    if (_displayName == "") then { _displayName = _class; };
    private _cleanBase = _baseKey splitString "_" joinString " ";
    private _costArray = _vehicle getVariable ["QM_Spawn_CostArray", []];

    // If vehicle lacks runtime spawn cost tracking, fall back to supplyScores or template costs (excluding Troops/Cargo for empty drivable vehicles)
    if (count _costArray == 0) then {
        private _lowerClass = toLowerANSI _class;
        private _scoreIndex = supplyScores findIf { toLowerANSI (_x # 0) == _lowerClass };
        if (_scoreIndex != -1) then {
            _costArray = (supplyScores # _scoreIndex) # 1;
        } else {
            private _blueprintIdx = G_Procureable_Vehicles findIf { ((_x select 1) select 0) == _class };
            if (_blueprintIdx != -1) then {
                private _rawCost = (G_Procureable_Vehicles select _blueprintIdx) select 2;
                private _isSupply = !(_class isKindOf "Ship" || _class isKindOf "Plane" || _class isKindOf "Helicopter" || _class isKindOf "LandVehicle" || _class isKindOf "Air");
                private _isDrone = getNumber(configFile >> "CfgVehicles" >> _class >> "isUav") == 1;

                {
                    _x params ["_rawPoolName", "_poolCost"];
                    private _poolName = [_rawPoolName] call QM_fnc_normalizePoolName;
                    private _eff = _poolCost;
                    if (!_isSupply && !_isDrone) then {
                        if (_poolName in ["Troops", "Cargo"]) then { _eff = 0; };
                    };
                    if (_eff > 0 && _eff < 1000000) then { _costArray pushBack [_poolName, _eff]; };
                } forEach _rawCost;
            };
        };
    };

    if (count _costArray > 0) then {
        {
            _x params ["_rawPoolName", "_poolCost"];
            private _poolName = [_rawPoolName] call QM_fnc_normalizePoolName;
            if (_poolCost > 0 && _poolCost < 1000000) then {
                private _vehVar = format ["LogiScore_%1_%2", _baseKey, _poolName];
                private _currentPool = missionNamespace getVariable [_vehVar, 0];
                if (_currentPool != -1) then {
                    missionNamespace setVariable [_vehVar, _currentPool + _poolCost, true];
                };
            };
        } forEach _costArray;
        
        private _receiptMsg = format ["LOGISTICS RECEIPT: %1 recycled. 100%% of resources returned to %2 ledger.", _displayName, _cleanBase];
        if (!isNull _playerUnit) then {
            [_receiptMsg] remoteExec ["systemChat", _playerUnit];
        } else {
            [_receiptMsg] remoteExec ["systemChat", 0];
        };
    } else {
        private _vehVar = format ["LogiScore_%1_Vehicle", _baseKey];
        private _currentPool = missionNamespace getVariable [_vehVar, 0];
        if (_currentPool != -1) then { missionNamespace setVariable [_vehVar, _currentPool + 2000, true]; };
        private _receiptMsg = format ["LOGISTICS RECEIPT: %1 recycled into %2 stores (2000 Vehicle Material credited).", _displayName, _cleanBase];
        if (!isNull _playerUnit) then {
            [_receiptMsg] remoteExec ["systemChat", _playerUnit];
        } else {
            [_receiptMsg] remoteExec ["systemChat", 0];
        };
    };

    if (!isNil "QM_CAP_fnc_unregisterVehicleAsset") then { [_vehicle] call QM_CAP_fnc_unregisterVehicleAsset; };
    { _vehicle deleteVehicleCrew _x; } forEach (crew _vehicle);
    deleteVehicle _vehicle;
};

QM_fnc_serverCreateLocalUnit = {
    params ["_baseKey", "_classname", "_playerUnit", "_costArray", "_name"];
    if (!isServer) exitWith {};

    private _canAfford = true;
    private _missingPool = "";
    {
        _x params ["_rawPoolName", "_poolCost"];
        private _poolName = [_rawPoolName] call QM_fnc_normalizePoolName;
        if (_poolCost > 0) then {
            private _poolVar = format ["LogiScore_%1_%2", _baseKey, _poolName];
            private _currentPool = missionNamespace getVariable [_poolVar, 0];
            if (_currentPool != -1 && _currentPool < _poolCost) exitWith {
                _canAfford = false;
                _missingPool = _poolName;
            };
        };
    } forEach _costArray;

    if (!_canAfford) exitWith {
        [format ["RECRUITER: Mobilization halted. Base '%1' resources depleted.", _missingPool]] remoteExec ["systemChat", _playerUnit];
    };

    private _locations = [_baseKey, "Spawn"] call QM_fnc_getLocationsByPrefix;
    if (count _locations == 0) exitWith {
        [format ["RECRUITER: Mobilization halted. No '%1_Spawn' 3D objects found at this base.", _baseKey]] remoteExec ["systemChat", _playerUnit];
    };

    {
        _x params ["_rawPoolName", "_poolCost"];
        private _poolName = [_rawPoolName] call QM_fnc_normalizePoolName;
        if (_poolCost > 0) then {
            private _poolVar = format ["LogiScore_%1_%2", _baseKey, _poolName];
            private _currentPool = missionNamespace getVariable [_poolVar, 0];
            if (_currentPool != -1) then { missionNamespace setVariable [_poolVar, (_currentPool - _poolCost) max 0, true]; };
        };
    } forEach _costArray;

    private _sortedLocations = _locations apply { [(_x select 0) distance2D _playerUnit, _x] };
    _sortedLocations sort true;
    private _bestLoc = (_sortedLocations select 0) select 1;
    private _padObj = _bestLoc select 0;
    private _spawnPosASL = getPosASL _padObj;
    private _spawnDir = getDir _padObj;

    private _group = group _playerUnit;
    private _newUnit = _group createUnit [_classname, ASLToAGL _spawnPosASL, [], 0, "CAN_COLLIDE"];
    _newUnit setDir _spawnDir;
    _newUnit setPosASL _spawnPosASL;
    
    [format ["BARRACKS: %1 authenticated. Drafted into your immediate squad.", _name]] remoteExec ["systemChat", _playerUnit];
};

QM_fnc_serverCreateLocalGroup = {
    params ["_baseKey", "_unitArray", "_playerUnit", "_costArray", "_name"];
    if (!isServer) exitWith {};

    private _canAfford = true;
    private _missingPool = "";
    {
        _x params ["_rawPoolName", "_poolCost"];
        private _poolName = [_rawPoolName] call QM_fnc_normalizePoolName;
        if (_poolCost > 0) then {
            private _poolVar = format ["LogiScore_%1_%2", _baseKey, _poolName];
            private _currentPool = missionNamespace getVariable [_poolVar, 0];
            if (_currentPool != -1 && _currentPool < _poolCost) exitWith {
                _canAfford = false;
                _missingPool = _poolName;
            };
        };
    } forEach _costArray;

    if (!_canAfford) exitWith {
        [format ["RECRUITER: Deployment halted. Insufficient base '%1' assets.", _missingPool]] remoteExec ["systemChat", _playerUnit];
    };

    private _locations = [_baseKey, "Spawn"] call QM_fnc_getLocationsByPrefix;
    if (count _locations == 0) exitWith {
        [format ["RECRUITER: Deployment halted. No '%1_Spawn' 3D objects found at this base.", _baseKey]] remoteExec ["systemChat", _playerUnit];
    };

    {
        _x params ["_rawPoolName", "_poolCost"];
        private _poolName = [_rawPoolName] call QM_fnc_normalizePoolName;
        if (_poolCost > 0) then {
            private _poolVar = format ["LogiScore_%1_%2", _baseKey, _poolName];
            private _currentPool = missionNamespace getVariable [_poolVar, 0];
            if (_currentPool != -1) then { missionNamespace setVariable [_poolVar, (_currentPool - _poolCost) max 0, true]; };
        };
    } forEach _costArray;

    private _sortedLocations = _locations apply { [(_x select 0) distance2D _playerUnit, _x] };
    _sortedLocations sort true;
    private _bestLoc = (_sortedLocations select 0) select 1;
    private _padObj = _bestLoc select 0;
    private _spawnPosASL = getPosASL _padObj;
    private _spawnDir = getDir _padObj;

    private _spawnedUnits = [];
    private _group = group _playerUnit;
    {
        private _newUnit = _group createUnit [_x, ASLToAGL _spawnPosASL, [], 0, "CAN_COLLIDE"];
        _newUnit setDir _spawnDir;
        _newUnit setPosASL _spawnPosASL;
        _spawnedUnits pushBack _newUnit;
    } forEach _unitArray;

    [format ["BARRACKS: Template %1 attached successfully to your squad link.", _name]] remoteExec ["systemChat", _playerUnit];
};

// -----------------------------------------------------------------------
// --- Vehicle Cap System (QM_CAP) ---
// -----------------------------------------------------------------------
QM_CAP_ActiveRegistry = [];
{
    private _family = _x select 0;
    if ((QM_CAP_ActiveRegistry findIf { (_x select 0) == _family }) == -1) then {
        QM_CAP_ActiveRegistry pushBack [_family, []];
    };
} forEach QM_CAP_ConfigMatrix;

QM_CAP_fnc_checkCurrentActiveCount = {
    params ["_classname"];
    private _canSpawn = true;
    private _activeCount = 0;
    private _maxAllowed = -1;
    private _limitingFamily = "";

    {
        _x params ["_family", "_limit"];
        if (_limit >= 0 && { _classname isKindOf _family }) then {
            private _idx = QM_CAP_ActiveRegistry findIf { (_x select 0) == _family };
            if (_idx != -1) then {
                private _list = ((QM_CAP_ActiveRegistry select _idx) select 1) select { !isNull _x && alive _x };
                (QM_CAP_ActiveRegistry select _idx) set [1, _list];

                private _curCount = count _list;
                _activeCount = _curCount;
                _maxAllowed = _limit;
                _limitingFamily = _family;

                if (_curCount >= _limit) exitWith {
                    _canSpawn = false;
                };
            };
        };
        if (!_canSpawn) exitWith {};
    } forEach QM_CAP_ConfigMatrix;

    [_canSpawn, _activeCount, _maxAllowed, _limitingFamily]
};

QM_CAP_fnc_registerNewVehicle = {
    params ["_obj", "_class"];
    if (isNull _obj || _class == "") exitWith {};

    private _matchedFamilies = [];
    {
        private _family = _x select 0;
        if (_class isKindOf _family) then {
            private _list = (_x select 1) select { !isNull _x && alive _x };
            _list pushBackUnique _obj;
            _x set [1, _list];
            _matchedFamilies pushBackUnique _family;
        };
    } forEach QM_CAP_ActiveRegistry;

    if (count _matchedFamilies == 0) exitWith {};

    _obj setVariable ["QM_CAP_MyParentFamilies", _matchedFamilies];
    _obj setVariable ["QM_CAP_MyParentFamily", _matchedFamilies select (count _matchedFamilies - 1)];

    if !(_obj getVariable ["QM_CAP_HasHandlers", false]) then {
        _obj setVariable ["QM_CAP_HasHandlers", true];
        _obj addEventHandler ["Killed", { [_this select 0] call QM_CAP_fnc_unregisterVehicleAsset; }];
        _obj addEventHandler ["Deleted", { [_this select 0] call QM_CAP_fnc_unregisterVehicleAsset; }];
    };
};

QM_CAP_fnc_unregisterVehicleAsset = {
    params ["_obj"];
    if (isNull _obj) exitWith {};

    private _families = _obj getVariable ["QM_CAP_MyParentFamilies", []];
    private _singleFamily = _obj getVariable ["QM_CAP_MyParentFamily", ""];
    if (count _families == 0 && _singleFamily != "") then {
        _families = [_singleFamily];
    };

    if (count _families > 0) then {
        {
            private _family = _x;
            private _idx = QM_CAP_ActiveRegistry findIf { (_x select 0) == _family };
            if (_idx != -1) then {
                (QM_CAP_ActiveRegistry select _idx) set [1, ((QM_CAP_ActiveRegistry select _idx) select 1) - [_obj, objNull]];
            };
        } forEach _families;
    } else {
        {
            _x set [1, (_x select 1) - [_obj, objNull]];
        } forEach QM_CAP_ActiveRegistry;
    };
};

// -----------------------------------------------------------------------
// --- Garage Routing Engine ---
// -----------------------------------------------------------------------
QM_fnc_processGarageSpawn = {
    params ["_baseKey", "_classname", "_clientPlayer", ["_costArray", [], [[]]], ["_vehSize", "", [""]]];
    
    if (_vehSize == "") then {
        private _isDrone = getNumber(configFile >> "CfgVehicles" >> _classname >> "isUav") == 1;
        if (_classname isKindOf "Helicopter" || _classname isKindOf "VTOL_Base_F" || _isDrone) then {
            _vehSize = "OPEN";
        } else {
            if (_classname isKindOf "Plane") then {
                _vehSize = "L";
            } else {
                if (_classname isKindOf "Quadbike_01_base_F" || _classname isKindOf "Motorcycle") then {
                    _vehSize = "S";
                } else {
                    _vehSize = "M"; // Standard ground vehicle fallback
                };
            };
        };
    };

    if (_classname == "" || { !isClass (configFile >> "CfgVehicles" >> _classname) }) exitWith {
        [format ["MECHANIC: Vehicle blueprint '%1' is not available in current configuration.", _classname]] remoteExec ["systemChat", _clientPlayer];
    };

    private _capData = [_classname] call QM_CAP_fnc_checkCurrentActiveCount;
    if !(_capData select 0) exitWith { [format ["PROCURMENT DENIED: Cap limit reached [%1/%2].", _capData select 1, _capData select 2]] remoteExec ["hint", _clientPlayer]; };

    // Determine asset profile (supply container vs drone vs drivable vehicle)
    private _isSupply = !(_classname isKindOf "Ship" || _classname isKindOf "Plane" || _classname isKindOf "Helicopter" || _classname isKindOf "LandVehicle" || _classname isKindOf "Air");
    private _isDrone = getNumber (configFile >> "CfgVehicles" >> _classname >> "isUav") == 1;

    // Filter effective cost array: empty drivable vehicles do not deduct Troops or unspawned Cargo
    private _effectiveCostArray = [];
    {
        _x params ["_rawPoolName", "_poolCost"];
        private _poolName = [_rawPoolName] call QM_fnc_normalizePoolName;
        private _effectiveCost = _poolCost;

        if (!_isSupply && !_isDrone) then {
            if (_poolName in ["Troops", "Cargo"]) then { _effectiveCost = 0; };
        };

        if (_effectiveCost > 0 && _effectiveCost < 1000000) then {
            _effectiveCostArray pushBack [_poolName, _effectiveCost];
        };
    } forEach _costArray;

    private _canAfford = true;
    private _missingPool = "";
    {
        _x params ["_poolName", "_poolCost"];
        if (_poolCost > 0 && _poolCost < 1000000) then {
            private _poolVar = format ["LogiScore_%1_%2", _baseKey, _poolName];
            private _currentPool = missionNamespace getVariable [_poolVar, 0];
            if (_currentPool != -1 && _currentPool < _poolCost) exitWith {
                _canAfford = false;
                _missingPool = _poolName;
            };
        };
    } forEach _effectiveCostArray;

    if (!_canAfford) exitWith { [format ["MANAGEMENT: Insufficient %1 supply points.", _missingPool]] remoteExec ["systemChat", _clientPlayer]; };

    // Determine vehicle classification
    private _isBoat = _classname isKindOf "Ship";
    private _isPlane = _classname isKindOf "Plane";
    private _isHeli = _classname isKindOf "Helicopter";
    private _isGround = (!_isBoat && !_isPlane && !_isHeli);

    private _typeSuffix = if (_isBoat) then { "BOAT" } else {
        if (_isPlane) then { "PLANE" } else {
            if (_isHeli) then { "HELICOPTER" } else { "GROUND" }
        }
    };

    // Determine vehicle requested minimum pad size rank (0 = XXS ... 6 = OPEN)
    private _reqSize = switch (toUpper _vehSize) do {
        case "XXS":  { 0 };
        case "XS":   { 1 };
        case "S":    { 2 };
        case "M":    { 3 };
        case "L":    { 4 };
        case "XL":   { 5 };
        case "OPEN": { 6 };
        default      { 0 };
    };

    private _locations = [];
    private _allBaseGarages = [];
    private _searchStr = toUpper format ["%1_Garage", _baseKey];
    private _prefixLen = count _searchStr;

    {
        if ((toUpper _x) find _searchStr == 0) then {
            private _val = missionNamespace getVariable [_x, objNull];
            if (_val isEqualType objNull && { !isNull _val }) then { _allBaseGarages pushBackUnique _x; };
        };
    } forEach (allVariables missionNamespace);

    // Also include garage pads synced in Eden Editor to the master base anchor/flagpole
    private _baseObj = missionNamespace getVariable [_baseKey, objNull];
    if (!isNull _baseObj) then {
        {
            if !(_x isKindOf "EmptyDetector") then {
                private _cName = vehicleVarName _x;
                private _cUpper = toUpper _cName;
                if (_cUpper find "GARAGE" >= 0 || _cUpper find "BOAT" >= 0 || _cUpper find "GROUND" >= 0 || _cUpper find "AIR" >= 0 || _cUpper find "HELI" >= 0 || _cUpper find "PLANE" >= 0 || _cUpper find "PAD" >= 0) then {
                    _allBaseGarages pushBackUnique _cName;
                };
            };
        } forEach ([_baseObj] call QM_fnc_getSyncedObjects);
    };

    {
        private _mName = _x;
        private _mUpper = toUpper _mName;

        // Slice off base prefix and "GARAGE" token so base name (e.g. "SB_MAIN") never pollutes category or size tokens
        private _remainder = if (_mUpper find _searchStr == 0) then {
            _mUpper select [_prefixLen]
        } else {
            private _gIdx = _mUpper find "GARAGE";
            if (_gIdx >= 0) then { _mUpper select [_gIdx + 6] } else { _mUpper };
        };

        // Multi-Category & Granular Per-Category Size Parser
        private _tokens = _remainder splitString "_";
        private _padGroundSize = -1;
        private _padHeliSize = -1;
        private _padPlaneSize = -1;
        private _padBoatSize = -1;
        private _hasGround = false;
        private _hasHeli = false;
        private _hasPlane = false;
        private _hasBoat = false;
        private _defaultPadSize = 6;
        private _lastCat = "";

        {
            private _t = _x;
            if (_t in ["GROUND", "CAR", "TANK"]) then { _hasGround = true; _lastCat = "GROUND"; };
            if (_t in ["HELI", "HELICOPTER"]) then { _hasHeli = true; _lastCat = "HELI"; };
            if (_t in ["PLANE"]) then { _hasPlane = true; _lastCat = "PLANE"; };
            if (_t in ["BOAT"]) then { _hasBoat = true; _lastCat = "BOAT"; };
            if (_t in ["AIR"]) then { _hasHeli = true; _hasPlane = true; _lastCat = "AIR"; };

            private _szVal = -1;
            switch (_t) do {
                case "XXS":  { _szVal = 0; };
                case "XS":   { _szVal = 1; };
                case "S":    { _szVal = 2; };
                case "M":    { _szVal = 3; };
                case "L":    { _szVal = 4; };
                case "XL":   { _szVal = 5; };
                case "OPEN": { _szVal = 6; };
            };

            if (_szVal != -1) then {
                switch (_lastCat) do {
                    case "GROUND": { _padGroundSize = _szVal; };
                    case "HELI":   { _padHeliSize = _szVal; };
                    case "PLANE":  { _padPlaneSize = _szVal; };
                    case "BOAT":   { _padBoatSize = _szVal; };
                    case "AIR":    { _padHeliSize = _szVal; _padPlaneSize = _szVal; };
                    default        { _defaultPadSize = _szVal; };
                };
            };
        } forEach _tokens;

        private _isUniversalPad = (!_hasGround && !_hasHeli && !_hasPlane && !_hasBoat);

        // Strict Type & Size Compatibility Gate
        private _typeValid = false;
        private _padSize = -1;

        if (_isGround && (_hasGround || _isUniversalPad)) then {
            _typeValid = true;
            _padSize = if (_padGroundSize != -1) then { _padGroundSize } else { _defaultPadSize };
        };
        if (_isBoat && (_hasBoat || _isUniversalPad)) then {
            _typeValid = true;
            _padSize = if (_padBoatSize != -1) then { _padBoatSize } else { _defaultPadSize };
        };
        if (_isHeli && (_hasHeli || _isUniversalPad)) then {
            _typeValid = true;
            _padSize = if (_padHeliSize != -1) then { _padHeliSize } else { _defaultPadSize };
        };
        if (_isPlane && (_hasPlane || _isUniversalPad)) then {
            _typeValid = true;
            _padSize = if (_padPlaneSize != -1) then { _padPlaneSize } else { _defaultPadSize };
        };

        if (_typeValid && (_padSize >= _reqSize)) then {
            private _rawVar = missionNamespace getVariable [_mName, objNull];
            private _padObj = if (_rawVar isEqualType objNull) then { _rawVar } else { objNull };
            if (!isNull _padObj) then {
                private _posASL = getPosASL _padObj;
                private _dir = getDir _padObj;
                _locations pushBack [_padObj, _posASL, _dir, "OBJECT", _mName];
            };
        };
    } forEach _allBaseGarages;

    if (count _locations == 0) exitWith {
        [format ["MECHANIC: Deployment failed. No suitable %1 or Universal 3D assembly pads detected.", _typeSuffix]] remoteExec ["systemChat", _clientPlayer];
    };

    private _sortedLocations = _locations apply { [(_x select 0) distance2D _clientPlayer, _x] };
    _sortedLocations sort true;
    _locations = _sortedLocations apply { _x select 1 }; 

    // --- SUPPLY DEPLETION PRE-VALIDATION GATING ---
    private _canAfford = true;
    private _missingPool = "";
    {
        _x params ["_poolName", "_poolCost"];
        if (_poolCost > 0 && _poolCost < 1000000) then {
            private _poolVar = format ["LogiScore_%1_%2", _baseKey, _poolName];
            private _currentPool = missionNamespace getVariable [_poolVar, 0];
            if (_currentPool != -1 && { _currentPool < _poolCost }) exitWith {
                _canAfford = false;
                _missingPool = format ["%1 (Required: %2, Available: %3)", _poolName, _poolCost, _currentPool];
            };
        };
    } forEach _effectiveCostArray;

    if (!_canAfford) exitWith {
        [format ["MECHANIC: Deployment rejected. Insufficient base resources: %1.", _missingPool]] remoteExec ["systemChat", _clientPlayer];
    };

    {
        _x params ["_poolName", "_poolCost"];
        if (_poolCost > 0 && _poolCost < 1000000) then {
            private _poolVar = format ["LogiScore_%1_%2", _baseKey, _poolName];
            private _currentPool = missionNamespace getVariable [_poolVar, 0];
            if (_currentPool != -1) then { missionNamespace setVariable [_poolVar, (_currentPool - _poolCost) max 0, true]; };
        };
    } forEach _effectiveCostArray;

    [_locations, _classname, _clientPlayer, _baseKey, _effectiveCostArray, _typeSuffix] spawn {
        params ["_locations", "_class", "_player", "_bKey", "_costArray", "_typeSuffix"];
    
        private _spawned = false;
        private _attempts = 0;
        private _maxAttempts = 60; 

        private _spawnVehRadius = (sizeOf _class) * 0.5; 

        while {!_spawned && _attempts < _maxAttempts} do {
            private _selectedLocation = [];
            
            {
                private _padObj = _x select 0;
                private _padPosAGL = ASLToAGL (_x select 1);
                
                // If this pad is itself a Boat Rack with cargo already loaded, treat as occupied
                if (count (getVehicleCargo _padObj) > 0) then { continue };

                private _blockingEntities = nearestObjects [_padPosAGL, ["LandVehicle", "Air", "Ship"], 30];
                
                private _aliveBlockers = _blockingEntities select { 
                    alive _x && 
                    {_x != _player} && 
                    {_x != _padObj} &&
                    {(_x distance _padObj) < (((sizeOf typeOf _x) * 0.5) + _spawnVehRadius + 1)}
                };
                
                if (count _aliveBlockers == 0) exitWith { _selectedLocation = _x; };
            } forEach _locations;

            if (count _selectedLocation > 0) then {
                _spawned = true;
                private _padObj = _selectedLocation select 0;
                private _baseSpawnPosASL = _selectedLocation select 1;
                private _dir = _selectedLocation select 2;
                private _veh = objNull;

                if (_typeSuffix == "BOAT") then {
                    _veh = createVehicle [_class, [0,0,200], [], 0, "NONE"];
                    _veh setVariable ["QM_SystemLoaded", true, true];
                    private _loadedIntoRack = false;

                    // 1. Check if the pad object itself can carry the boat (e.g. Boat Rack named <Base>_Garage_Boat_...)
                    if (((_padObj canVehicleCargo _veh) select 0) && { count (getVehicleCargo _padObj) == 0 }) then {
                        _padObj setVariable ["QM_SystemLoading", true];
                        _loadedIntoRack = _padObj setVehicleCargo _veh;
                        _padObj setVariable ["QM_SystemLoading", false];
                    };

                    // 2. Otherwise check for an adjacent Boat Rack within 20m of the pad object
                    if (!_loadedIntoRack) then {
                        private _racks = nearestObjects [ASLToAGL _baseSpawnPosASL, ["Land_Destroyer_01_Boat_Rack_01_F", "Land_Boat_Rack_01_F", "Land_BoatRack_01_F"], 20];
                        private _validRack = objNull;
                        { if (count (getVehicleCargo _x) == 0 && { (_x canVehicleCargo _veh) select 0 }) exitWith { _validRack = _x; }; } forEach _racks;
                        if (!isNull _validRack) then {
                            _validRack setVariable ["QM_SystemLoading", true];
                            _loadedIntoRack = _validRack setVehicleCargo _veh;
                            _validRack setVariable ["QM_SystemLoading", false];
                        };
                    };

                    if (_loadedIntoRack) then {
                        ["MECHANIC: Boat loaded into active deployment rack."] remoteExec ["systemChat", _player];
                    } else {
                        _veh setDir _dir;
                        _veh setPosASL _baseSpawnPosASL;
                    };
                } else {
                    _veh = createVehicle [_class, [0,0,500], [], 0, "NONE"]; 
                    _veh setDir _dir;
                    
                    if (_veh isKindOf "Air") then {
                        private _foldAnims = ["wing_fold_l", "wing_fold_r", "wing_fold_l_cover", "wing_fold_r_cover", "fold_wing_l", "fold_wing_r", "mainRotor_folded", "tailRotor_folded", "rotors_fold"];
                        { _veh animateSource [_x, 1, true]; } forEach _foldAnims;
                    };

                    _veh setPosASL _baseSpawnPosASL;
                };
                
                private _isUAV = getNumber (configFile >> "CfgVehicles" >> _class >> "isUav") == 1;
                if (_isUAV) then {
                    createVehicleCrew _veh;
                    ["MECHANIC: Autonomous drone control link established."] remoteExec ["systemChat", _player];
                };

                _veh setVariable ["QM_Spawn_CostArray", _costArray];
                _veh setVariable ["QM_Spawn_BaseKey", _bKey];
                _veh setVariable ["QM_Spawn_Time", diag_tickTime];
                
                _veh addEventHandler ["Killed", {
                    params ["_unit", "_killer", "_instigator", "_useEffects"];
                    private _timeAlive = diag_tickTime - (_unit getVariable ["QM_Spawn_Time", 0]);
                    
                    if (_timeAlive <= 1.5) then {
                        private _cArr = _unit getVariable ["QM_Spawn_CostArray", []];
                        private _bKey = _unit getVariable ["QM_Spawn_BaseKey", ""];
                        
                        {
                            _x params ["_rawPoolName", "_poolCost"];
                            private _poolName = [_rawPoolName] call QM_fnc_normalizePoolName;
                            if (_poolCost > 0 && _poolCost < 1000000) then {
                                private _v = format ["LogiScore_%1_%2", _bKey, _poolName];
                                private _pool = missionNamespace getVariable [_v, 0];
                                if (_pool != -1) then { missionNamespace setVariable [_v, _pool + _poolCost, true]; };
                            };
                        } forEach _cArr;
                    };
                }];

                [_veh, _class] call QM_CAP_fnc_registerNewVehicle;
                if (!isNil "QM_fnc_initVehicleCargoRules") then {
                    [_veh] remoteExec ["QM_fnc_initVehicleCargoRules", 0, true];
                };
                ["MANAGEMENT: Allocation authorized. Vehicle deployed successfully."] remoteExec ["systemChat", _player];
            } else {
                if (_attempts == 0) then {
                    ["MECHANIC: All garage pads are currently occupied. Queuing your order..."] remoteExec ["systemChat", _player];
                };
                _attempts = _attempts + 1;
                uiSleep 2;
            };
        };

        if (!_spawned) then {
            ["MECHANIC: Garage pads were blocked for too long. Order cancelled and points refunded."] remoteExec ["systemChat", _player];
            {
                _x params ["_rawPoolName", "_poolCost"];
                private _poolName = [_rawPoolName] call QM_fnc_normalizePoolName;
                if (_poolCost > 0 && _poolCost < 1000000) then {
                    private _v = format ["LogiScore_%1_%2", _bKey, _poolName];
                    private _pool = missionNamespace getVariable [_v, 0];
                    if (_pool != -1) then { missionNamespace setVariable [_v, _pool + _poolCost, true]; };
                };
            } forEach _costArray;
        };
    };
};

// -----------------------------------------------------------------------
// --- R4C Processing ---
// -----------------------------------------------------------------------
QM_fnc_serverProcessR4C = {
    params ["_baseKey", "_vehicle", "_playerUnit", "_serviceType", "_calculatedCost"];
    if (_baseKey == "" || (toUpper _baseKey) find "MSR" >= 0 || isNull _vehicle || isNull _playerUnit || _serviceType == "") exitWith { false };

    private _poolSuffix = switch (_serviceType) do {
        case "REPAIR": { "Repair" };
        case "REFUEL": { "Fuel" };
        case "REARM":  { "Ammo" };
        default        { "" };
    };
    if (_poolSuffix == "") exitWith { false };

    private _poolVar = format ["LogiScore_%1_%2", _baseKey, _poolSuffix];
    private _currentPool = missionNamespace getVariable [_poolVar, 0];

    if (_currentPool != -1 && _currentPool < _calculatedCost) exitWith {
        [format ["R4-C DENIED: Insufficient %1 pool at %2. Needs %3, has %4.", _poolSuffix, _baseKey, _calculatedCost, _currentPool]] remoteExec ["systemChat", _playerUnit];
        false
    };

    private _newPoolValue = 0;
    if (_currentPool != -1) then {
        _newPoolValue = (_currentPool - _calculatedCost) max 0;
        missionNamespace setVariable [_poolVar, _newPoolValue, true];
    };

    switch (_serviceType) do {
        case "REPAIR": { _vehicle setDamage 0; };
        case "REFUEL": { _vehicle setFuel 1; };
        case "REARM":  { _vehicle setVehicleAmmoDef 1; };
    };

    true
};

QM_fnc_serverR4CCreateVehicleCrew = {
    params ["_baseKey", "_vehicle", "_playerUnit", "_missingSeatCount", "_totalCost"];
    if (!isServer || (toUpper _baseKey) find "MSR" >= 0) exitWith {};

    private _troopVar = format ["LogiScore_%1_Troops", _baseKey];
    private _currentPool = missionNamespace getVariable [_troopVar, 0];

    if (_currentPool != -1 && _currentPool < _missingSeatCount) exitWith {
        [format ["R4-C CREW DENIED: Needs %1 troops.", _missingSeatCount]] remoteExec ["systemChat", _playerUnit];
    };

    private _newTroopValue = 0;
    if (_currentPool != -1) then {
        _newTroopValue = (_currentPool - _missingSeatCount) max 0;
        missionNamespace setVariable [_troopVar, _newTroopValue, true];
    };

    private _existingCrew = crew _vehicle;
    createVehicleCrew _vehicle;
    private _newCrew = (crew _vehicle) - _existingCrew;
    if (!isNull _playerUnit && count _newCrew > 0) then {
        _newCrew joinSilent (group _playerUnit);
    };
    [format ["R4-C CREW: %1 personnel deployed.", _missingSeatCount]] remoteExec ["systemChat", _playerUnit];
};

// =========================================================================
// TROOP CARGO DELIVERY HANDLER
// Credits disembarked reinforcement troops to the base ledger and removes them
// =========================================================================
QM_fnc_serverProcessTroopDelivery = {
    params [["_baseKey", "", [""]], ["_count", 0, [0]], ["_units", [], [[]]]];
    if (!isServer || _baseKey == "" || _count <= 0) exitWith {};

    private _troopVar = format ["LogiScore_%1_Troops", _baseKey];
    private _currentPool = missionNamespace getVariable [_troopVar, 0];
    if (_currentPool != -1) then {
        missionNamespace setVariable [_troopVar, _currentPool + _count, true];
    };

    diag_log format ["[LOGISTICS TROOPS]: %1 reinforcement troops delivered and garrisoned at %2.", _count, _baseKey];

    // Safely delete units after disembark animation
    [_units] spawn {
        params ["_uList"];
        sleep 6;
        {
            if (alive _x) then { deleteVehicle _x; };
        } forEach _uList;
    };
};