// ============================================================================
// SYSTEM BOOTLOADER: MASTER UNIFIED INITIALIZATION (MASTER CLEAN)
// File: init.sqf
// Version: Consolidated Part1→Part3 (annotated)
// Purpose: Initialize logistics templates, base ledgers, server daemons,
//          client UI hooks, and shared R4C/crew/garage systems.
// Notes:   Optional modules are loaded via fileExists guards to allow
//          modular mission builds and backwards compatibility.
// ============================================================================

diag_log "LOGISTICS/QUARTERMASTER ENGINE: Booting master initialization...";

// ---------------------------------------------------------------------------
// 1. TEMPLATES & CONFIGURATIONS
// Templates and optional includes
// ---------------------------------------------------------------------------
// These files define mission-specific templates and lookup tables.
// Each include is guarded so the mission can run without optional modules.
// - logisticsCargoTemplates.sqf : vehicle cargo templates and spawn lists
// - SupplyScores.sqf            : per-item scoring used to compute default pool values
// - logisticsBaseDefaults.sqf  : default ledger values for non-SB base types
// - logisticsVehicleRoles.sqf  : role-to-class mappings used by spawn/garage logic
// - qm_vehicleCapsTemplate.sqf : vehicle cap family matrix (QM_CAP_ConfigMatrix)
// ---------------------------------------------------------------------------
if (fileExists "logisticsCargoTemplates.sqf") then {
    call compile preprocessFileLineNumbers "logisticsCargoTemplates.sqf";
} else {
    // Fallback minimal template so code using allowedLogisticsVehicles still works.
    logisticsCargoTemplates = [["B_Truck_01_cargo_F", [["Cargo",[]],["Ammo",[]],["Fuel",[]],["Medical",[]],["Repair",[]],["Vehicle",[]],["Troops",[]]]]];
};

if (fileExists "SupplyScores.sqf") then { call compile preprocessFileLineNumbers "SupplyScores.sqf"; };
if (fileExists "logisticsBaseDefaults.sqf") then { call compile preprocessFileLineNumbers "logisticsBaseDefaults.sqf"; };
if (fileExists "virtualArsenalTemplate.sqf") then { call compile preprocessFileLineNumbers "virtualArsenalTemplate.sqf"; };
if (fileExists "spawnableVehicleTemplate.sqf") then { call compile preprocessFileLineNumbers "spawnableVehicleTemplate.sqf"; };
if (fileExists "qm_vehicleCapsTemplate.sqf") then { call compile preprocessFileLineNumbers "qm_vehicleCapsTemplate.sqf"; } else { QM_CAP_ConfigMatrix = []; };
if (fileExists "logisticsVehicleRoles.sqf") then { call compile preprocessFileLineNumbers "logisticsVehicleRoles.sqf"; }; // LOAD THE Vehicle Role TEMPLATE

// Additional optional client/server helpers (safe guarded)
if (fileExists "fn_initLogisticsTasks.sqf") then { [] execVM "fn_initLogisticsTasks.sqf"; };
if (fileExists "fn_manageLogisticsMissions.sqf") then { [] execVM "fn_manageLogisticsMissions.sqf"; };
if (fileExists "fn_startupMarkerDiagnostics.sqf") then { [] execVM "fn_startupMarkerDiagnostics.sqf"; };

// ---------------------------------------------------------------------------
// Global derived lists
// ---------------------------------------------------------------------------
// **allowedLogisticsVehicles**
// - **Type:** array of classname strings
// - **Purpose:** quick lookup of vehicle classes that can be used for logistics
// - **Source:** derived from logisticsCargoTemplates (first element of each entry)
// ---------------------------------------------------------------------------
// GLOBAL SETTINGS (MISSION MAKER CONFIGURATION)
// ---------------------------------------------------------------------------
// 1 = Motorpool menu kicks player out after spawning a vehicle. 0 = Menu stays open.
if (isNil "QM_AutoCloseMotorpool") then { QM_AutoCloseMotorpool = 1; };
publicVariable "QM_AutoCloseMotorpool";

allowedLogisticsVehicles = logisticsCargoTemplates apply {_x select 0};


// ---------------------------------------------------------------------------
// 2. UNIVERSAL HELPER FUNCTIONS
// Global Helper Functions (Available to Client & Server)
// ---------------------------------------------------------------------------
// QM_fnc_getLocationsByPrefix
// Purpose: Scans for mission-maker placed objects (by variable name) OR map markers.
//          Checks for un-numbered (e.g. SB_Garage) and numbered up to 20 (e.g. SB_Garage_1).
// Returns: Array of arrays -> [[Entity/Name, Position, Direction, "OBJECT"|"MARKER", OriginalName], ...]
QM_fnc_getLocationsByPrefix = {
    params ["_baseKey", "_typeSuffix"];
    private _found = [];
    
    private _checkAndAdd = {
        params ["_name"];
        private _obj = missionNamespace getVariable [_name, objNull];
        // Protect against string type-mapping crashes
        private _safeObj = if (_obj isEqualType objNull) then { _obj } else { objNull };
        
        if (!isNull _safeObj) then {
            _found pushBack [_safeObj, getPosATL _safeObj, getDir _safeObj, "OBJECT", _name];
        } else {
            if (getMarkerColor _name != "") then {
                _found pushBack [_name, getMarkerPos _name, markerDir _name, "MARKER", _name];
            };
        };
    };

    // Check base suffix without numbers (e.g. SB_Garage)
    [format ["%1_%2", _baseKey, _typeSuffix]] call _checkAndAdd;

    // Check numbered suffixes 1 through 100 (e.g. SB_Garage_1, SB_Garage_2)
    for "_i" from 1 to 100 do {
        [format ["%1_%2_%3", _baseKey, _typeSuffix, _i]] call _checkAndAdd;
    };
    
    _found
};

// ---------------------------------------------------------------------------
// 3. SERVER-SIDE INITIALIZATION
// Server-only initialization
// ---------------------------------------------------------------------------
if (isServer) then {

    // Auto-hide Garage map markers so mission makers don't have to do it manually
    {
        if (["_GARAGE", _x] call BIS_fnc_inString) then { _x setMarkerAlpha 0; };
    } forEach allMapMarkers;


    // -----------------------------------------------------------------------
    // DEFINE BASES FIRST
    // Discover supply bases on the map
    // **logisticsBases**
    // - **Type:** array of marker names (strings)
    // - **Purpose:** list of map markers considered supply bases (FOB, SB, MSR)
    // - **Filter:** excludes markers that contain "_spawn" to avoid spawn markers
    // -----------------------------------------------------------------------
    logisticsBases = allMapMarkers select {
        private _m = toLowerANSI _x;
        (("fob" in _m) || ("sb" in _m) || ("msr" in _m)) &&
        { ["_spawn", "_garage", "_terminal", "_arsenal", "_service", "_pickup", "_dropoff"] findIf { _x in _m } == -1 }
    };
    publicVariable "logisticsBases"; 

    // Broadcast to clients
    // Auto-hide Garage map markers so mission makers don't have to do it manually
    {
        if ("_GARAGE" in toUpper _x) then { _x setMarkerAlpha 0; };
    } forEach allMapMarkers;


    // -----------------------------------------------------------------------
    // --- Initialize Base Ledger Economy ---
    // --- Dynamic Balancing Calculator ---
    //  (HEMTT Ceiling Engine)
    // -----------------------------------------------------------------------
    {
        private _baseName = _x; 
        _baseName setMarkerAlpha 0;
        
        private _baseType = "FOB";
        if (["MSR", _baseName] call BIS_fnc_inString) then { _baseType = "MSR"; };
        if (["SB", _baseName] call BIS_fnc_inString) then { _baseType = "SB"; };

        // Read directly from logisticsBaseDefaults.sqf
        private _typeIndex = logisticsBaseDefaults findIf {_x # 0 == _baseType};
        if (_typeIndex != -1) then {
            { 
                missionNamespace setVariable [format ["LogiScore_%1_%2", _baseName, _x # 0], _x # 1, true]; 
            } forEach ((logisticsBaseDefaults # _typeIndex) # 1);
        };
    } forEach logisticsBases;

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

    QM_fnc_serverVehicleSale = {
        params [["_baseKey", "", [""]], ["_vehicle", objNull, [objNull]], ["_playerUnit", objNull, [objNull]]];
        if (_baseKey == "" || isNull _vehicle || isNull _playerUnit) exitWith {};

        private _class = typeOf _vehicle;
        private _blueprintIdx = G_Procureable_Vehicles findIf { (_x select 1) == _class };

        if (_blueprintIdx != -1) then {
            private _costArray = (G_Procureable_Vehicles select _blueprintIdx) select 2;
            
            // Refund 100% of ALL points back to the correct pools dynamically (Strict 1-for-1 Exchange)
            {
                _x params ["_poolName", "_poolCost"];
                if (_poolCost > 0 && _poolCost < 10000000) then {
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
        deleteVehicle _vehicle;
    };

    QM_fnc_serverCreateLocalUnit = {
        params ["_baseKey", "_classname", "_playerUnit", "_cost", "_name"];
        if (!isServer) exitWith {};

        private _troopVar = format ["LogiScore_%1_Troops", _baseKey];
        private _currentPool = missionNamespace getVariable [_troopVar, 0];

        if (_currentPool != -1 && _currentPool < _cost) exitWith {
            ["RECRUITER: Mobilization halted. Base manpower resources depleted."] remoteExec ["systemChat", _playerUnit];
        };
        if (_currentPool != -1) then { missionNamespace setVariable [_troopVar, (_currentPool - _cost) max 0, true]; };

        private _locations = [_baseKey, "Spawn"] call QM_fnc_getLocationsByPrefix;
        private _spawnPos = [];
    
        if (count _locations > 0) then {
            private _sortedLocations = _locations apply { [(_x select 1) distance2D _playerUnit, _x] };
            _sortedLocations sort true;
            private _bestLoc = (_sortedLocations select 0) select 1;
            _bestLoc params ["_entity", "_sPos", "_dir", "_type", "_identityName"];
            _spawnPos = _sPos;
        } else {
            _spawnPos = (getPosATL _playerUnit) vectorAdd [sin (getDir _playerUnit - 180) * 5, cos (getDir _playerUnit - 180) * 5, 0.2];
        };

        // --- CARRIER DECK FIX FOR AI SPAWNS ---
        // Raycast to find the solid deck so AI don't spawn in the ship hull
        private _startPos = [_spawnPos select 0, _spawnPos select 1, 150];
        private _endPos = [_spawnPos select 0, _spawnPos select 1, -10];
        private _intersects = lineIntersectsSurfaces [_startPos, _endPos, objNull, objNull, true, 1, "GEOM", "NONE"];
        if (count _intersects > 0) then {
            // createUnit requires AGL positioning. Convert the physical ASL intersection to AGL.
            _spawnPos = ASLToAGL ((_intersects select 0) select 0);
        };

        private _group = group _playerUnit;
        private _newUnit = _group createUnit [_classname, _spawnPos, [], 2, "FORM"];
        
        [format ["BARRACKS: %1 authenticated. Drafted into your immediate squad.", _name]] remoteExec ["systemChat", _playerUnit];
        diag_log format ["[LOGISTICS INFANTRY]: Spawned client-local individual %1 (%2) for Player %3.", _name, _classname, name _playerUnit];
    };

    QM_fnc_serverCreateLocalGroup = {
        params ["_baseKey", "_unitArray", "_playerUnit", "_cost", "_name"];
        if (!isServer) exitWith {};

        private _troopVar = format ["LogiScore_%1_Troops", _baseKey];
        private _currentPool = missionNamespace getVariable [_troopVar, 0];

        if (_currentPool != -1 && _currentPool < _cost) exitWith {
            ["RECRUITER: Deployment halted. Insufficient base troop assets."] remoteExec ["systemChat", _playerUnit];
        };
        if (_currentPool != -1) then { missionNamespace setVariable [_troopVar, (_currentPool - _cost) max 0, true]; };

        private _locations = [_baseKey, "Spawn"] call QM_fnc_getLocationsByPrefix;
        private _spawnPos = [];
    
        if (count _locations > 0) then {
            private _sortedLocations = _locations apply { [(_x select 1) distance2D _playerUnit, _x] };
            _sortedLocations sort true;
            private _bestLoc = (_sortedLocations select 0) select 1;
            _bestLoc params ["_entity", "_sPos", "_dir", "_type", "_identityName"];
            _spawnPos = _sPos;
        } else {
            _spawnPos = (getPosATL _playerUnit) vectorAdd [sin (getDir _playerUnit - 180) * 6, cos (getDir _playerUnit - 180) * 6, 0.2];
        };

        // --- CARRIER DECK FIX FOR AI SPAWNS ---
        private _startPos = [_spawnPos select 0, _spawnPos select 1, 150];
        private _endPos = [_spawnPos select 0, _spawnPos select 1, -10];
        private _intersects = lineIntersectsSurfaces [_startPos, _endPos, objNull, objNull, true, 1, "GEOM", "NONE"];
        if (count _intersects > 0) then {
            _spawnPos = ASLToAGL ((_intersects select 0) select 0);
        };

        private _spawnedUnits = [];
        private _group = group _playerUnit;
        {
            private _newUnit = _group createUnit [_x, _spawnPos, [], 3, "NONE"];
            _spawnedUnits pushBack _newUnit;
        } forEach _unitArray;

        [format ["BARRACKS: Template %1 attached successfully to your squad link.", _name]] remoteExec ["systemChat", _playerUnit];
        diag_log format ["[LOGISTICS INFANTRY]: Spawned client-local template group %1 for Player %2.", _name, name _playerUnit];
    };

    // -----------------------------------------------------------------------
    // --- Vehicle Cap System (QM_CAP) ---
    // -----------------------------------------------------------------------
    QM_CAP_ActiveRegistry = []; { QM_CAP_ActiveRegistry pushBack [_x select 0, []]; } forEach QM_CAP_ConfigMatrix;

    QM_CAP_fnc_checkCurrentActiveCount = {
        params ["_classname"]; private _p = ""; private _m = -1;
        { if (_classname isKindOf (_x select 0)) exitWith { _p = _x select 0; _m = _x select 1; }; } forEach QM_CAP_ConfigMatrix;
        if (_p == "") exitWith { [true, 0, -1] };
        private _idx = QM_CAP_ActiveRegistry findIf {(_x select 0) == _p};
        private _list = ((QM_CAP_ActiveRegistry select _idx) select 1) select {!isNull _x && alive _x};
        QM_CAP_ActiveRegistry select _idx set [1, _list];
        [((count _list) < _m), count _list, _m]
    };

    QM_CAP_fnc_registerNewVehicle = {
        params ["_obj", "_class"]; private _p = ""; { if (_class isKindOf (_x select 0)) exitWith { _p = _x select 0; }; } forEach QM_CAP_ConfigMatrix;
        if (_p == "") exitWith {}; private _idx = QM_CAP_ActiveRegistry findIf {(_x select 0) == _p};
        private _list = (QM_CAP_ActiveRegistry select _idx) select 1; _list pushBack _obj; QM_CAP_ActiveRegistry select _idx set [1, _list];
        _obj setVariable ["QM_CAP_MyParentFamily", _p];
        _obj addEventHandler ["Killed", { [_this select 0] call QM_CAP_fnc_unregisterVehicleAsset; }];
        _obj addEventHandler ["Deleted", { [_this select 0] call QM_CAP_fnc_unregisterVehicleAsset; }];
    };

    QM_CAP_fnc_unregisterVehicleAsset = {
        params ["_obj"]; if (isNull _obj) exitWith {}; private _p = _obj getVariable ["QM_CAP_MyParentFamily", ""]; if (_p == "") exitWith {};
        private _idx = QM_CAP_ActiveRegistry findIf {(_x select 0) == _p};
        if (_idx != -1) then { QM_CAP_ActiveRegistry select _idx set [1, ((QM_CAP_ActiveRegistry select _idx) select 1) - [_obj]]; };
    };

    // -----------------------------------------------------------------------
    // --- Garage Routing Engine ---
    // Garage spawn (procurement)
    // -----------------------------------------------------------------------
    QM_fnc_processGarageSpawn = {
        params ["_baseKey", "_classname", "_clientPlayer", ["_costArray", [], [[]]], ["_vehSize", "M", [""]]];
        if (_classname == "") exitWith { ["MECHANIC: Factory canceled."] remoteExec ["systemChat", _clientPlayer]; };

        private _capData = [_classname] call QM_CAP_fnc_checkCurrentActiveCount;
        if !(_capData select 0) exitWith { [format ["PROCURMENT DENIED: Cap limit reached [%1/%2].", _capData select 1, _capData select 2]] remoteExec ["hint", _clientPlayer]; };

        // 1. VERIFY ALL POOLS HAVE SUFFICIENT FUNDS BEFORE DOING ANYTHING
        private _canAfford = true;
        private _missingPool = "";
        {
            _x params ["_poolName", "_poolCost"];
            if (_poolCost > 0 && _poolCost < 10000000) then {
                private _poolVar = format ["LogiScore_%1_%2", _baseKey, _poolName];
                private _currentPool = missionNamespace getVariable [_poolVar, 0];
                if (_currentPool != -1 && _currentPool < _poolCost) exitWith {
                    _canAfford = false;
                    _missingPool = _poolName;
                };
            };
        } forEach _costArray;

        if (!_canAfford) exitWith { [format ["MANAGEMENT: Insufficient %1 supply points.", _missingPool]] remoteExec ["systemChat", _clientPlayer]; };

        // FIX: Added 'HELICOPTER' native parsing to support precise marker names
        private _typeSuffix = "GROUND";
        if (_classname isKindOf "Ship") then { _typeSuffix = "BOAT"; }
        else { if (_classname isKindOf "Plane") then { _typeSuffix = "PLANE"; }
        else { if (_classname isKindOf "Helicopter") then { _typeSuffix = "HELICOPTER"; }; }; };

        // Dynamic Size Cascade: Smaller vehicles can safely utilize larger capacity pads
        private _validSizes = [];
        switch (_vehSize) do {
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
            if (_typeSuffix in ["PLANE", "HELICOPTER"]) then { _allowedSuffixes pushBack format ["Garage_AIR_%1", _x]; };
            _allowedSuffixes pushBack format ["Garage_%1", _x]; 
        } forEach _validSizes;
        
        _allowedSuffixes pushBack format ["Garage_%1", _typeSuffix]; 
        if (_typeSuffix in ["PLANE", "HELICOPTER"]) then { _allowedSuffixes pushBack "Garage_AIR"; };
        _allowedSuffixes pushBack "Garage"; 

        diag_log "======================================================================";
        diag_log format ["[GARAGE EVALUATION] Player %1 requested %2 (Type: %3, Size: %4).", name _clientPlayer, _classname, _typeSuffix, _vehSize];
        diag_log format ["[GARAGE EVALUATION] Target Base Key: '%1'", _baseKey];

        // 1. Gather ALL valid matching locations using case-insensitive mapping against real markers
        private _locations = [];
        private _allBaseGarages = [];
        private _searchStr = toUpper format ["%1_Garage", _baseKey];
        
        // Grab strictly 2D Markers (Bypassing objects to prevent duplicate collision errors)
        { if ((toUpper _x) find _searchStr == 0) then { _allBaseGarages pushBackUnique _x; }; } forEach allMapMarkers;

        {
            private _mName = _x;
            private _mUpper = toUpper _mName;
            private _isValid = false;
            
            {
                private _suffixUpper = toUpper format ["%1_%2", _baseKey, _x];
                
                // Exact match (e.g., SB_Garage_Air)
                if (_mUpper == _suffixUpper) exitWith { _isValid = true; };
                
                // Numbered match (e.g., SB_Garage_Air_1 to 100)
                for "_i" from 1 to 100 do {
                    if (_mUpper == format ["%1_%2_%3", _baseKey, _x, _i]) exitWith { _isValid = true; };
                };
                if (_isValid) exitWith {};
            } forEach _allowedSuffixes;

            if (_isValid) then {
                private _padObj = missionNamespace getVariable [_mName, objNull];
                private _pos = if (!isNull _padObj) then { getPosATL _padObj } else { getMarkerPos _mName };
                private _dir = if (!isNull _padObj) then { getDir _padObj } else { markerDir _mName };
                private _type = if (!isNull _padObj) then { "OBJECT" } else { "MARKER" };
                
                _locations pushBack [_padObj, _pos, _dir, _type, _mName];
            };
        } forEach _allBaseGarages;

        if (count _locations == 0) exitWith {
            diag_log format ["[GARAGE ERROR]: Deployment failed. No suitable %1 pads detected for size tier %2 at base '%3'.", _typeSuffix, _vehSize, _baseKey];
            diag_log "======================================================================";
            [format ["MECHANIC: Deployment failed. No suitable %1 or Universal assembly pads detected.", _typeSuffix]] remoteExec ["systemChat", _clientPlayer];
        };

        // 2. Sort dynamically based on distance to requesting player
        private _sortedLocations = _locations apply { [(_x select 1) distance2D _clientPlayer, _x] };
        _sortedLocations sort true;
        _locations = _sortedLocations apply { _x select 1 }; 

        diag_log "[GARAGE EVALUATION] Valid markers sorted by distance to player (Execution Order):";
        {
            private _markerName = _x select 4;
            private _dist = (_x select 1) distance2D _clientPlayer;
            diag_log format ["  >> Priority #%1: '%2' (Distance: %3m)", _forEachIndex + 1, _markerName, _dist];
        } forEach _locations;

        // DEDUCT ALL POINTS UP FRONT FROM ALL REQUIRED POOLS
        {
            _x params ["_poolName", "_poolCost"];
            if (_poolCost > 0 && _poolCost < 10000000) then {
                private _poolVar = format ["LogiScore_%1_%2", _baseKey, _poolName];
                private _currentPool = missionNamespace getVariable [_poolVar, 0];
                if (_currentPool != -1) then { missionNamespace setVariable [_poolVar, (_currentPool - _poolCost) max 0, true]; };
            };
        } forEach _costArray;
    
        // --- THE QUEUEING ENGINE ---
        [_locations, _classname, _clientPlayer, _baseKey, _costArray, _typeSuffix] spawn {
            params ["_locations", "_class", "_player", "_bKey", "_costArray", "_typeSuffix"];
        
            private _spawned = false;
            private _attempts = 0;
            private _maxAttempts = 60; 

            // --- SPATIAL BOUNDING-SPHERE COLLISION MATH ---
            private _spawnVehRadius = (sizeOf _class) * 0.5; 

            while {!_spawned && _attempts < _maxAttempts} do {
                private _selectedLocation = [];
                
                {
                    private _name = _x select 4;
                    private _mPos = _x select 1;
                    
                    // Elevated check position to accurately capture objects sitting on a carrier deck
                    private _checkPos = [_mPos select 0, _mPos select 1, 10]; 
                    
                    // Grab everything within a massive 30m radius to catch large off-center vehicles
                    private _blockingEntities = nearestObjects [_checkPos, ["LandVehicle", "Air", "Ship"], 30];
                    
                    // Dynamically calculate if the parked vehicle's bounding sphere intersects with the spawning vehicle's radius
                    private _aliveBlockers = _blockingEntities select { 
                        alive _x && { (_x distance _checkPos) < (((sizeOf typeOf _x) * 0.5) + _spawnVehRadius + 1) } 
                    };
                    
                    diag_log format ["  >> Checking Pad Obstructions: '%1' | Found %2 alive vehicles blocking.", _name, count _aliveBlockers];
                    
                    if (count _aliveBlockers == 0) exitWith { _selectedLocation = _x; };
                } forEach _locations;

                if (count _selectedLocation > 0) then {
                    _spawned = true;
                    private _baseSpawnPos = _selectedLocation select 1;
                    private _dir = _selectedLocation select 2;
                    private _padObj = missionNamespace getVariable [(_selectedLocation select 4), objNull];
                    private _veh = objNull;

                    if (_typeSuffix == "BOAT") then {
                        private _racks = nearestObjects [_baseSpawnPos, ["Land_Destroyer_01_Boat_Rack_01_F", "Land_Boat_Rack_01_F", "Land_BoatRack_01_F"], 20];
                        private _validRack = objNull;
                        { if (count (getVehicleCargo _x) == 0) exitWith { _validRack = _x; }; } forEach _racks;

                        if (!isNull _validRack) then {
                            _veh = createVehicle [_class, [0,0,200], [], 0, "NONE"];
                            _validRack setVehicleCargo _veh;
                            systemChat "MECHANIC: Boat loaded into active deployment rack.";
                        } else {
                            _veh = createVehicle [_class, [0,0,500], [], 0, "NONE"]; 
                            _veh setDir _dir;
                            
                            // --- CARRIER DECK FIX ---
                            if (!isNull _padObj) then { 
                                _veh setPosASL (getPosASL _padObj); 
                            } else { 
                                private _startPos = [_baseSpawnPos select 0, _baseSpawnPos select 1, 150];
                                private _endPos = [_baseSpawnPos select 0, _baseSpawnPos select 1, -10];
                                private _intersects = lineIntersectsSurfaces [_startPos, _endPos, objNull, objNull, true, 1, "GEOM", "NONE"];
                                if (count _intersects > 0) then {
                                    _veh setPosASL ((_intersects select 0) select 0);
                                } else {
                                    _veh setPosATL [_baseSpawnPos select 0, _baseSpawnPos select 1, 0.5]; 
                                };
                            };
                        };
                    } else {
                        // Always safely spawn high in the air before snapping to avoid water destruction
                        _veh = createVehicle [_class, [0,0,500], [], 0, "NONE"]; 
                        _veh setDir _dir;
                        
                        // --- FOLD WINGS & ROTORS INSTANTLY IN THE SKY ---
                        if (_veh isKindOf "Air") then {
                            private _foldAnims = ["wing_fold_l", "wing_fold_r", "wing_fold_l_cover", "wing_fold_r_cover", "fold_wing_l", "fold_wing_r", "mainRotor_folded", "tailRotor_folded", "rotors_fold"];
                            { _veh animateSource [_x, 1, true]; } forEach _foldAnims;
                        };

                        // --- CARRIER DECK FIX ---
                        if (!isNull _padObj) then { 
                            _veh setPosASL (getPosASL _padObj); 
                        } else { 
                            private _startPos = [_baseSpawnPos select 0, _baseSpawnPos select 1, 150];
                            private _endPos = [_baseSpawnPos select 0, _baseSpawnPos select 1, -10];
                            private _intersects = lineIntersectsSurfaces [_startPos, _endPos, objNull, objNull, true, 1, "GEOM", "NONE"];
                            if (count _intersects > 0) then {
                                _veh setPosASL ((_intersects select 0) select 0);
                            } else {
                                _veh setPosATL [_baseSpawnPos select 0, _baseSpawnPos select 1, 0.2]; 
                            };
                        };
                    };
                    
                    diag_log format ["[GARAGE SPAWN] %1 Successfully materialized at ASL: %2.", _class, getPosASL _veh];
                    
                    // Native A3 UAVs do not need manual group assignment. Let Engine assign side logic.
                    private _isUAV = getNumber (configFile >> "CfgVehicles" >> _class >> "isUav") == 1;
                    if (_isUAV) then {
                        createVehicleCrew _veh;
                        systemChat "MECHANIC: Autonomous drone control link established.";
                    };

                    // --- 1.5 SECOND PHYSICS DESTRUCTION FAILSAFE 100% MULTI-REFUND ---
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
                                _x params ["_poolName", "_poolCost"];
                                if (_poolCost > 0 && _poolCost < 10000000) then {
                                    private _v = format ["LogiScore_%1_%2", _bKey, _poolName];
                                    private _pool = missionNamespace getVariable [_v, 0];
                                    if (_pool != -1) then { missionNamespace setVariable [_v, _pool + _poolCost, true]; };
                                };
                            } forEach _cArr;
                            
                            diag_log "======================================================";
                            diag_log format ["[GARAGE CRITICAL]: Vehicle %1 instantly destroyed by physics!", typeOf _unit];
                            diag_log format ["- Time Alive: %1 seconds", _timeAlive];
                            diag_log format ["- Exact Position of Failure (ASL): %1", getPosASL _unit];
                            diag_log "======================================================";
                        };
                    }];

                    [_veh, _class] call QM_CAP_fnc_registerNewVehicle;
                    ["MANAGEMENT: Allocation authorized. Vehicle deployed successfully."] remoteExec ["systemChat", _player];
                    diag_log "======================================================================";
                } else {
                    if (_attempts == 0) then {
                        ["MECHANIC: All garage pads are currently occupied. Queuing your order..."] remoteExec ["systemChat", _player];
                        diag_log format ["[GARAGE QUEUE]: All valid pads blocked for %1. Entering 120-second queue loop...", _class];
                    };
                    _attempts = _attempts + 1;
                    uiSleep 2;
                };
            };

            if (!_spawned) then {
                ["MECHANIC: Garage pads were blocked for too long. Order cancelled and points refunded."] remoteExec ["systemChat", _player];
                // Refund 100% of ALL specific arrays on timeout
                {
                    _x params ["_poolName", "_poolCost"];
                    if (_poolCost > 0 && _poolCost < 10000000) then {
                        private _v = format ["LogiScore_%1_%2", _bKey, _poolName];
                        private _pool = missionNamespace getVariable [_v, 0];
                        if (_pool != -1) then { missionNamespace setVariable [_v, _pool + _poolCost, true]; };
                    };
                } forEach _costArray;
                
                diag_log format ["[GARAGE QUEUE]: Queue timed out for %1. Points refunded.", _class];
                diag_log "======================================================================";
            };
        };
    };

    // -----------------------------------------------------------------------
    // --- R4C Processing ---
    // Part 3 shared core: R4C processing (repair/refuel/rearm)
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

        diag_log format ["[PART 3 SHARED CORE REARM/REPAIR/REFUEL INITIATED] --- Base: %1 | Track: %2", _baseKey, _serviceType];
        diag_log format ["    >> BEFORE SERVICE Base Ledger Balance: %1 Points", _currentPool];

        if (_currentPool != -1 && _currentPool < _calculatedCost) exitWith {
            [format ["R4-C DENIED: Insufficient %1 pool at %2. Needs %3, has %4.", _poolSuffix, _baseKey, _calculatedCost, _currentPool]] remoteExec ["systemChat", _playerUnit];
            diag_log format ["    >> TRANSACTION TERMINATED: Insufficient ledger funds! Required: %1.", _calculatedCost];
            diag_log "----------------------------------------------------------------------------";
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

        diag_log format ["    >> AFTER SERVICE  Base Ledger Balance: %1 Points (Deducted: %2 Points)", _newPoolValue, _calculatedCost];
        diag_log "----------------------------------------------------------------------------";
        true
    };

    QM_fnc_serverR4CCreateVehicleCrew = {
        params ["_baseKey", "_vehicle", "_playerUnit", "_missingSeatCount", "_totalCost"];
        if (!isServer) exitWith {};

        private _troopVar = format ["LogiScore_%1_Troops", _baseKey];
        private _currentPool = missionNamespace getVariable [_troopVar, 0];

        diag_log format ["[PART 3 SHARED CORE CREW SERVICE INITIATED] --- Base: %1", _baseKey];
        diag_log format ["    >> BEFORE RECREW Manpower Balance: %1 Troops", _currentPool];

        if (_currentPool != -1 && _currentPool < _missingSeatCount) exitWith {
            [format ["R4-C CREW DENIED: Needs %1 troops, has %2.", _missingSeatCount, _currentPool]] remoteExec ["systemChat", _playerUnit];
            diag_log format ["    >> RECREW TRANSACTION REJECTED: Insufficient manpower! Needs %1.", _missingSeatCount];
            diag_log "----------------------------------------------------------------------------";
        };

        private _newTroopValue = 0;
        if (_currentPool != -1) then {
            _newTroopValue = (_currentPool - _missingSeatCount) max 0;
            missionNamespace setVariable [_troopVar, _newTroopValue, true];
        };

        (group _playerUnit) createVehicleCrew _vehicle;
        [format ["R4-C CREW: %1 personnel deployed.", _missingSeatCount]] remoteExec ["systemChat", _playerUnit];

        diag_log format ["    >> AFTER RECREW  Manpower Balance: %1 Troops (Deducted: %2 Troops)", _newTroopValue, _missingSeatCount];
        diag_log "----------------------------------------------------------------------------";
    };

    QM_fnc_LogisticsDebugger = {
        {
            private _base = _x;
            diag_log format ["--- CORE MASTER LEDGER AUDIT: Base %1 ---", _base];
            {
                private _val = missionNamespace getVariable [format ["LogiScore_%1_%2", _base, _x], 0];
                diag_log format ["    [%1 Pool Balance]: %2", _x, _val];
            } forEach ["Cargo","Ammo","Fuel","Medical","Repair","Vehicle","Troops"];
        } forEach logisticsBases;
    };

    // Start server-side daemons if present
    if (fileExists "qm_supplyPhysicalController.sqf") then { [] execVM "qm_supplyPhysicalController.sqf"; };
    if (fileExists "qm_serverGarrisonManager.sqf") then { [] execVM "qm_serverGarrisonManager.sqf"; };
    if (fileExists "qm_serverRespawnManager.sqf") then { [] execVM "qm_serverRespawnManager.sqf"; };
    if (fileExists "tsk_serverGIN.sqf") then { [] execVM "tsk_serverGIN.sqf"; };
};

// ---------------------------------------------------------------------------
// 4. CLIENT-SIDE INITIALIZATION
// Client-side initialization
// ---------------------------------------------------------------------------
if (hasInterface) then {

    waitUntil { !isNil "logisticsBases" };

    // Compile client UI helpers if present
    if (fileExists "fn_pylonManager.sqf") then { QM_fnc_pylonManager = compile preprocessFileLineNumbers "fn_pylonManager.sqf"; };
    if (fileExists "qm_clientActionCompiler.sqf") then { call compile preprocessFileLineNumbers "qm_clientActionCompiler.sqf"; };
    if (fileExists "fn_equipmentTrader.sqf") then { [] execVM "fn_equipmentTrader.sqf"; };

    // --- TACTICAL COMMAND CENTER CLIENT DAEMONS ---
    if (fileExists "tsk_clientMapIntel.sqf") then { [] execVM "tsk_clientMapIntel.sqf"; };
    if (fileExists "tsk_clientTaskMaster.sqf") then { [] execVM "tsk_clientTaskMaster.sqf"; };

    // --- JIP SAFE PIPELINE FOR ACTION MENUS ---
    // Instead of trusting the server to blindly broadcast the actions before you load in,
    // this watchdog safely adds the actions to terminals once they exist locally.
    [] spawn {
        private _processedHubs = [];
        while {true} do {
            private _globalHubs = missionNamespace getVariable ["QM_Global_Terminals", []];
            {
                private _hub = _x;
                if (!isNull _hub && !(_hub in _processedHubs)) then {
                    private _baseKey = _hub getVariable ["QM_Crate_OwningBase", ""];
                    if (_baseKey != "") then {
                        if (!isNil "QM_fnc_clientRegisterTraderActions") then { [_hub, _baseKey] call QM_fnc_clientRegisterTraderActions; };
                        if (!isNil "QM_fnc_clientRegisterFlagActions") then { [_hub, _baseKey] call QM_fnc_clientRegisterFlagActions; };
                        if (!isNil "QM_fnc_clientRegisterBarracksActions") then { [_hub, _baseKey] call QM_fnc_clientRegisterBarracksActions; };
                        _processedHubs pushBack _hub;
                    };
                };
            } forEach _globalHubs;
            uiSleep 3;
        };
    };

    player createDiarySubject ["BasesManifestTab", "Base Supply Manifest"];

    // QM_fnc_getNearbyAmmoSource
    QM_fnc_getNearbyAmmoSource = {
        params ["_veh"];
        if (isNull _veh) exitWith {""};
        private _foundBase = "";

        private _triggers = allMissionObjects "EmptyDetector";
        {
            private _tName = vehicleVarName _x;
            if (["_service", _tName] call BIS_fnc_inString) then {
                if (_veh inArea _x || _veh distance2D _x < 40) then {
                    private _idx = _tName find "_service";
                    private _potBase = _tName select [0, _idx];
                    if (["SB", _potBase] call BIS_fnc_inString) then { _foundBase = _potBase; };
                };
            };
            if (_foundBase != "") exitWith {};
        } forEach _triggers;

        if (_foundBase != "") exitWith { _foundBase };

        private _nearEnts = nearestObjects [_veh, ["AllVehicles","ReammoBox_F","ThingX","Building"], 40];
        {
            private _varName = vehicleVarName _x;
            if (["_ammo", _varName] call BIS_fnc_inString) then {
                private _idx = _varName find "_ammo";
                private _potBase = _varName select [0, _idx];
                if (["SB", _potBase] call BIS_fnc_inString) then { _foundBase = _potBase; };
            };
            if (_foundBase != "") exitWith {};
        } forEach _nearEnts;

        _foundBase
    };

    // QM_fnc_canOpenPylonMenu
    QM_fnc_canOpenPylonMenu = {
        params ["_unit"];
        private _veh = if (vehicle _unit != _unit) then { vehicle _unit } else { cursorTarget };
        if (isNull _veh || {!(_veh isKindOf "Air")} || {speed _veh > 1} || {(_unit distance _veh > 12)}) exitWith {false};
        private _base = [_veh] call QM_fnc_getNearbyAmmoSource;
        if (_base == "") exitWith {false};
        (missionNamespace getVariable [format["LogiScore_%1_Ammo", _base], 0] > 0)
    };

    // Add action to player for pylon manager
    [] spawn {
        waitUntil { !isNull player };
        QM_fnc_addPylonAction = {
            params ["_unit"];
            _unit addAction [
                "<t color='#00FFFF'>[ Open Aircraft Pylon Manager ]</t>",
                {
                    params ["_target","_caller","_actionId","_arguments"];
                    private _veh = if (vehicle _caller != _caller) then { vehicle _caller } else { cursorTarget };
                    private _baseKey = [_veh] call QM_fnc_getNearbyAmmoSource;
                    [_veh, _baseKey] spawn QM_fnc_pylonManager;
                },
                nil, 1.5, false, true, "",
                "[_this] call QM_fnc_canOpenPylonMenu"
            ];
        };
        [player] call QM_fnc_addPylonAction;
        player addEventHandler ["Respawn", { [(_this select 0)] call QM_fnc_addPylonAction; }];
    };

    // Client-side ledger refresher (diary UI)
    [] spawn {
        private _diaryHandlesMap = createHashMap;
        {
            private _recordHandle = player createDiaryRecord ["BasesManifestTab", [_x, "Synchronizing UI layers..."]];
            _diaryHandlesMap set [_x, _recordHandle];
        } forEach logisticsBases;

        while {true} do {
            {
                private _base = _x;
                private _cPoints = missionNamespace getVariable [format["LogiScore_%1_Cargo", _base], 0];
                private _aPoints = missionNamespace getVariable [format["LogiScore_%1_Ammo", _base], 0];
                private _fPoints = missionNamespace getVariable [format["LogiScore_%1_Fuel", _base], 0];
                private _mPoints = missionNamespace getVariable [format["LogiScore_%1_Medical", _base], 0];
                private _rPoints = missionNamespace getVariable [format["LogiScore_%1_Repair", _base], 0];
                private _vPoints = missionNamespace getVariable [format["LogiScore_%1_Vehicle", _base], 0];
                private _tPoints = missionNamespace getVariable [format["LogiScore_%1_Troops", _base], 0];

                // CRITICAL FIX: Changed <t> tag to <font> and size '1.2' to '16' to prevent Arma 3 DiaryParser Map UI Lockup
                private _reportText = format ["<br/><font color='#00FFFF' size='16'>%1 Supply Manifest Ledger</font><br/><br/>  [Cargo Pool]: <font color='#FFFF00'>%2</font> Points<br/>  [Ammo Pool]: <font color='#FFFF00'>%3</font> Resources<br/>  [Fuel Pool]: <font color='#FFFF00'>%4</font> Liters<br/>  [Medical Pool]: <font color='#FFFF00'>%5</font> Supplies<br/>  [Repair Pool]: <font color='#FFFF00'>%6</font> Kits<br/>  [Vehicle Pool]: <font color='#FFFF00'>%7</font> Material<br/>  [Troops Pool]: <font color='#FFFF00'>%8</font> Personnel<br/>", _base, _cPoints, _aPoints, _fPoints, _mPoints, _rPoints, _vPoints, _tPoints];

                private _activeHandle = _diaryHandlesMap get _base;
                if (!isNil "_activeHandle") then {
                    player setDiaryRecordText [["BasesManifestTab", _activeHandle], [_base, _reportText]];
                };
            } forEach logisticsBases;
            uiSleep 4;
        };
    };

    diag_log "QUARTERMASTER: Local player interaction space initialized.";
};