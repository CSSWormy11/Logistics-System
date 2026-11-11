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
    if (_baseKey == "" || isNull _vehicle || isNull _playerUnit) exitWith {};

    private _class = typeOf _vehicle;
    private _blueprintIdx = G_Procureable_Vehicles findIf { ((_x select 1) select 0) == _class };

    if (_blueprintIdx != -1) then {
        private _costArray = (G_Procureable_Vehicles select _blueprintIdx) select 2;
        
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
        [format ["SALVAGEMAN: Asset recycled. 100%% of resources returned to %1 ledger.", _baseKey]] remoteExec ["systemChat", _playerUnit];
    } else {
        private _vehVar = format ["LogiScore_%1_Vehicle", _baseKey];
        private _currentPool = missionNamespace getVariable [_vehVar, 0];
        if (_currentPool != -1) then { missionNamespace setVariable [_vehVar, _currentPool + 2000, true]; };
        ["SALVAGEMAN: Unregistered vehicle recycled. 2000 Vehicle Material credited."] remoteExec ["systemChat", _playerUnit];
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

    if (_classname == "") exitWith { ["MECHANIC: Factory canceled."] remoteExec ["systemChat", _clientPlayer]; };

    private _capData = [_classname] call QM_CAP_fnc_checkCurrentActiveCount;
    if !(_capData select 0) exitWith { [format ["PROCURMENT DENIED: Cap limit reached [%1/%2].", _capData select 1, _capData select 2]] remoteExec ["hint", _clientPlayer]; };

    private _canAfford = true;
    private _missingPool = "";
    {
        _x params ["_rawPoolName", "_poolCost"];
        private _poolName = [_rawPoolName] call QM_fnc_normalizePoolName;
        if (_poolCost > 0 && _poolCost < 1000000) then {
            private _poolVar = format ["LogiScore_%1_%2", _baseKey, _poolName];
            private _currentPool = missionNamespace getVariable [_poolVar, 0];
            if (_currentPool != -1 && _currentPool < _poolCost) exitWith {
                _canAfford = false;
                _missingPool = _poolName;
            };
        };
    } forEach _costArray;

    if (!_canAfford) exitWith { [format ["MANAGEMENT: Insufficient %1 supply points.", _missingPool]] remoteExec ["systemChat", _clientPlayer]; };

    private _typeSuffix = "GROUND";
    if (_classname isKindOf "Ship") then { _typeSuffix = "BOAT"; }
    else { if (_classname isKindOf "Plane") then { _typeSuffix = "PLANE"; }
    else { if (_classname isKindOf "Helicopter") then { _typeSuffix = "HELICOPTER"; }; }; };

    private _validSizes = [];
    switch (toUpper _vehSize) do {
        case "XXS":  { _validSizes = ["XXS", "XS", "S", "M", "L", "XL", "OPEN"]; };
        case "XS":   { _validSizes = ["XS", "S", "M", "L", "XL", "OPEN"]; };
        case "S":    { _validSizes = ["S", "M", "L", "XL", "OPEN"]; };
        case "M":    { _validSizes = ["M", "L", "XL", "OPEN"]; };
        case "L":    { _validSizes = ["L", "XL", "OPEN"]; };
        case "XL":   { _validSizes = ["XL", "OPEN"]; };
        case "OPEN": { _validSizes = ["OPEN"]; };
        default      { _validSizes = [_vehSize]; };
    };

    private _allowedSuffixes = [];
    {
        _allowedSuffixes pushBack format ["Garage_%1_%2", _typeSuffix, _x];
        if (_typeSuffix == "HELICOPTER") then { _allowedSuffixes pushBack format ["Garage_HELI_%1", _x]; };
        if (_typeSuffix in ["PLANE", "HELICOPTER"]) then { _allowedSuffixes pushBack format ["Garage_AIR_%1", _x]; };
        _allowedSuffixes pushBack format ["Garage_%1", _x]; 
    } forEach _validSizes;
    
    _allowedSuffixes pushBack format ["Garage_%1", _typeSuffix]; 
    if (_typeSuffix == "HELICOPTER") then { _allowedSuffixes pushBack "Garage_HELI"; };
    if (_typeSuffix in ["PLANE", "HELICOPTER"]) then { _allowedSuffixes pushBack "Garage_AIR"; };
    _allowedSuffixes pushBack "Garage"; 

    private _locations = [];
    private _allBaseGarages = [];
    private _searchStr = toUpper format ["%1_Garage", _baseKey];

    {
        if ((toUpper _x) find _searchStr == 0) then {
            private _val = missionNamespace getVariable [_x, objNull];
            if (_val isEqualType objNull && { !isNull _val }) then { _allBaseGarages pushBackUnique _x; };
        };
    } forEach (allVariables missionNamespace);

    {
        private _mName = _x;
        private _mUpper = toUpper _mName;
        private _isValid = false;
        
        {
            private _suffixUpper = toUpper format ["%1_%2", _baseKey, _x];
            if (_mUpper == _suffixUpper) exitWith { _isValid = true; };
            
            for "_i" from 1 to 100 do {
                if (_mUpper == toUpper format ["%1_%2_%3", _baseKey, _x, _i]) exitWith { _isValid = true; };
            };
            if (_isValid) exitWith {};
        } forEach _allowedSuffixes;

        if (_isValid) then {
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

    {
        _x params ["_rawPoolName", "_poolCost"];
        private _poolName = [_rawPoolName] call QM_fnc_normalizePoolName;
        if (_poolCost > 0 && _poolCost < 1000000) then {
            private _poolVar = format ["LogiScore_%1_%2", _baseKey, _poolName];
            private _currentPool = missionNamespace getVariable [_poolVar, 0];
            if (_currentPool != -1) then { missionNamespace setVariable [_poolVar, (_currentPool - _poolCost) max 0, true]; };
        };
    } forEach _costArray;

    [_locations, _classname, _clientPlayer, _baseKey, _costArray, _typeSuffix] spawn {
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
                    private _loadedIntoRack = false;

                    // 1. Check if the pad object itself can carry the boat (e.g. Boat Rack named <Base>_Garage_Boat_...)
                    if (((_padObj canVehicleCargo _veh) select 0) && { count (getVehicleCargo _padObj) == 0 }) then {
                        _loadedIntoRack = _padObj setVehicleCargo _veh;
                    };

                    // 2. Otherwise check for an adjacent Boat Rack within 20m of the pad object
                    if (!_loadedIntoRack) then {
                        private _racks = nearestObjects [ASLToAGL _baseSpawnPosASL, ["Land_Destroyer_01_Boat_Rack_01_F", "Land_Boat_Rack_01_F", "Land_BoatRack_01_F"], 20];
                        private _validRack = objNull;
                        { if (count (getVehicleCargo _x) == 0 && { (_x canVehicleCargo _veh) select 0 }) exitWith { _validRack = _x; }; } forEach _racks;
                        if (!isNull _validRack) then {
                            _loadedIntoRack = _validRack setVehicleCargo _veh;
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
    if (_baseKey == "" || isNull _vehicle || isNull _playerUnit || _serviceType == "") exitWith { false };

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
    if (!isServer) exitWith {};

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