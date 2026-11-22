// ============================================================================
// SYSTEM BOOTLOADER: MASTER UNIFIED INITIALIZATION (MASTER CLEAN)
// File: init.sqf
// Version: Modular Architecture Migration (Traffic Controller)
// Purpose: Initialize logistics templates, base ledgers, server daemons,
//          client UI hooks, and shared R4C/crew/garage systems.
// Notes:   Optional modules are loaded via fileExists guards to allow
//          modular mission builds and backwards compatibility.
// ============================================================================

// ---------------------------------------------------------------------------
// 1. TEMPLATES & CONFIGURATIONS
// Templates and optional includes
// ---------------------------------------------------------------------------
// These files define mission-specific templates and lookup tables.
// Each include is guarded so the mission can run without optional modules.
// - templates\tp_cargoTemplates.sqf       : vehicle cargo templates and spawn lists
// - templates\tp_supplyScores.sqf         : per-item scoring used to compute default pool values
// - templates\tp_baseDefaults.sqf         : default ledger values for non-SB base types
// - templates\tp_vehicleRoles.sqf         : role-to-class mappings used by spawn/garage logic
// - templates\tp_vehicleCaps.sqf          : vehicle cap family matrix (QM_CAP_ConfigMatrix)
// ---------------------------------------------------------------------------
if (fileExists "templates\tp_cargoTemplates.sqf") then { call compile preprocessFileLineNumbers "templates\tp_cargoTemplates.sqf";
} else {
    //Fallback minimal template so code using allowedLogisticsVehicles still works.
    logisticsCargoTemplates = [["B_Truck_01_cargo_F", [["Cargo",[]],["Ammo",[]],["Fuel",[]],["Medical",[]],["Repair",[]],["Vehicle",[]],["Troops",[]]]]];
};

if (fileExists "templates\tp_supplyScores.sqf") then { call compile preprocessFileLineNumbers "templates\tp_supplyScores.sqf"; };
if (fileExists "templates\tp_baseDefaults.sqf") then { call compile preprocessFileLineNumbers "templates\tp_baseDefaults.sqf"; };
if (fileExists "templates\tp_virtualArsenal.sqf") then { call compile preprocessFileLineNumbers "templates\tp_virtualArsenal.sqf"; };
if (fileExists "templates\tp_spawnableInfantry.sqf") then { call compile preprocessFileLineNumbers "templates\tp_spawnableInfantry.sqf"; };
if (fileExists "templates\tp_spawnableVehicles.sqf") then { call compile preprocessFileLineNumbers "templates\tp_spawnableVehicles.sqf"; };
if (fileExists "templates\tp_vehicleCaps.sqf") then { call compile preprocessFileLineNumbers "templates\tp_vehicleCaps.sqf"; } else { QM_CAP_ConfigMatrix = []; };
if (fileExists "templates\tp_vehicleRoles.sqf") then { call compile preprocessFileLineNumbers "templates\tp_vehicleRoles.sqf"; }; // LOAD THE Vehicle Role TEMPLATE
if (fileExists "templates\tp_fieldLoadingTemplate.sqf") then { call compile preprocessFileLineNumbers "templates\tp_fieldLoadingTemplate.sqf"; } else { logisticsFieldLoadingTemplate = []; };

// ---------------------------------------------------------------------------
// Global derived lists
// ---------------------------------------------------------------------------
if (isNil "QM_AutoCloseMotorpool") then { QM_AutoCloseMotorpool = 1; };
publicVariable "QM_AutoCloseMotorpool";

if (isNil "QM_Respawn_FOBCooldown") then { QM_Respawn_FOBCooldown = 120; }; // Default 120s cooldown for FOBs (SBs have 0 cooldown)
publicVariable "QM_Respawn_FOBCooldown";

allowedLogisticsVehicles = logisticsCargoTemplates apply {_x select 0};
publicVariable "allowedLogisticsVehicles";


// ---------------------------------------------------------------------------
// 2. UNIVERSAL HELPER FUNCTIONS (MUST LOAD BEFORE MODULES)
// ---------------------------------------------------------------------------

// V8 TERRAIN BIOME EVALUATOR
// Purpose: Dynamically maps the current loaded world to its respective climate biome
//          for Quartermaster UI and Arsenal template filtering.
fn_G_getTerrain = {
    private _world = toLowerANSI worldName;
    private _biome = "Woodland"; // Default Fallback
    
    if (_world in ["altis", "stratis", "malden"]) then { _biome = "Mediterranean"; };
    if (_world in ["takistan", "zargabad", "lythium", "sefrouramal"]) then { _biome = "Desert"; };
    if (_world in ["tanoa", "cam_lao_nam", "lingor"]) then { _biome = "Jungle"; };
    if (_world in ["chernarus", "chernarus_summer", "enoch", "livonia"]) then { _biome = "Woodland"; };
    
    _biome
};

// LOGISTICS BASE TYPE & ROLE RESOLVERS
// Purpose: Dynamically resolves base types (e.g. "SB", "CVN", "DDG", "FOB", "CON")
//          and their operational logistics role ("STRATEGIC", "TACTICAL", "MSR")
//          from logisticsBaseDefaults without hardcoding.
logi_fnc_getBaseType = {
    params ["_baseKey"];
    private _parts = (toUpper _baseKey) splitString "_";
    if (count _parts == 0) exitWith { "FOB" };
    private _prefix = _parts select 0;
    if (_prefix == "CONTESTED") exitWith { "CON" };
    if (_prefix == "FG") exitWith { "FFG" };
    _prefix
};

logi_fnc_getBaseRole = {
    params ["_baseKey"];
    private _bType = [_baseKey] call logi_fnc_getBaseType;
    private _typeIdx = logisticsBaseDefaults findIf { toUpper (_x select 0) == _bType };
    if (_typeIdx != -1) then {
        private _props = (logisticsBaseDefaults select _typeIdx) select 1;
        private _roleIdx = _props findIf { (_x select 0) == "Role" };
        if (_roleIdx != -1) exitWith { (_props select _roleIdx) select 1 };
    };
    if (_bType in ["MSR", "CS", "AOR"]) exitWith { "MSR" };
    if (_bType in ["SB", "CVN", "LHA", "LST", "LPD"]) exitWith { "STRATEGIC" };
    if (_bType in ["CON"]) exitWith { "CLT" };
    "TACTICAL"
};

// QM_fnc_getSyncedObjects
// Purpose: Multiplayer-safe wrapper around synchronizedObjects.
//          Note: Arma 3 engine only returns synchronizedObjects on Game Logics,
//          Modules, Triggers, or AI Units (static props like Flagpoles return []).
//          Server caches & broadcasts the list to QM_SyncedObjects so remote MP clients can read it.
QM_fnc_getSyncedObjects = {
    params [["_obj", objNull, [objNull]]];
    if (isNull _obj) exitWith { [] };
    private _cached = _obj getVariable ["QM_SyncedObjects", []];
    if (count _cached > 0) exitWith { _cached };
    synchronizedObjects _obj
};

// QM_fnc_getLocationsByPrefix
// Purpose: Scans for mission-maker placed 3D objects matching:
//          1. <BaseKey>_<typeSuffix> (un-numbered or numbered 1..100)
//          2. Objects synced in Eden to a master base object/flagpole named <BaseKey>
//             with short suffix names (e.g. _Arsenal, _Garage_Air, _Spawn_1).
// Returns: Array of arrays -> [[Object, PositionASL, Direction, "OBJECT", OriginalName], ...]
QM_fnc_getLocationsByPrefix = {
    params ["_baseKey", "_typeSuffix"];
    private _found = [];
    
    private _checkAndAdd = {
        params ["_name"];
        private _obj = missionNamespace getVariable [_name, objNull];
        // Protect against string type-mapping crashes
        private _safeObj = if (_obj isEqualType objNull) then { _obj } else { objNull };
        
        if (!isNull _safeObj) then {
            if !(_safeObj in (_found apply { _x # 0 })) then {
                _found pushBack [_safeObj, getPosASL _safeObj, getDir _safeObj, "OBJECT", _name];
            };
        };
    };

    // 1. Direct match: <BaseKey>_<typeSuffix> (e.g. SB_Main_Arsenal, SB_Main_Garage_Air)
    [format ["%1_%2", _baseKey, _typeSuffix]] call _checkAndAdd;

    // 2. Numbered match: <BaseKey>_<typeSuffix>_1 .. 100
    for "_i" from 1 to 100 do {
        [format ["%1_%2_%3", _baseKey, _typeSuffix, _i]] call _checkAndAdd;
    };

    // 3. Synchronized Match: Objects synced in Eden Editor to master base anchor/flagpole
    private _baseObj = missionNamespace getVariable [_baseKey, objNull];
    if (!isNull _baseObj) then {
        private _suffixUpper = toUpper _typeSuffix;
        {
            private _child = _x;
            if (!isNull _child && { !(_child isKindOf "EmptyDetector") }) then {
                private _childName = vehicleVarName _child;
                private _childUpper = toUpper _childName;
                if (_childUpper find _suffixUpper != -1 || { (_child getVariable ["QM_TypeSuffix", ""]) == _suffixUpper }) then {
                    if !(_child in (_found apply { _x # 0 })) then {
                        _found pushBack [_child, getPosASL _child, getDir _child, "OBJECT", _childName];
                    };
                };
            };
        } forEach ([_baseObj] call QM_fnc_getSyncedObjects);
    };
    
    _found
};


// ---------------------------------------------------------------------------
// 3. OPTIONAL MODULES (Executed safely after functions load)
// ---------------------------------------------------------------------------
if (fileExists "logistics\logi_initTasks.sqf") then { [] execVM "logistics\logi_initTasks.sqf"; };
if (fileExists "logistics\logi_manageMissions.sqf") then { [] execVM "logistics\logi_manageMissions.sqf"; };
if (fileExists "logistics\logi_standaloneLoading.sqf") then { [] execVM "logistics\logi_standaloneLoading.sqf"; };
if (fileExists "logistics\logi_markerDiagnostics.sqf") then { [] execVM "logistics\logi_markerDiagnostics.sqf"; };


// ---------------------------------------------------------------------------
// 4. SERVER-SIDE INITIALIZATION
// ---------------------------------------------------------------------------
if (isServer) then {

    // --- COMPILE SERVER FUNCTIONS LIBRARY ---
    if (fileExists "logistics\qm_serverFunctions.sqf") then { call compile preprocessFileLineNumbers "logistics\qm_serverFunctions.sqf"; };

    // Auto-hide Garage map markers so mission makers don't have to do it manually
    {
        if (["_GARAGE", _x] call BIS_fnc_inString) then { _x setMarkerAlpha 0; };
    } forEach allMapMarkers;

    // -----------------------------------------------------------------------
    // DEFINE BASES
    // Method 1: Discover bases from 2D Map Markers
    // Method 2: Discover bases from 3D Master Anchor Objects / Flagpoles
    // -----------------------------------------------------------------------
    private _knownBaseTypes = logisticsBaseDefaults apply { toUpper (_x select 0) };
    if !("CONTESTED" in _knownBaseTypes) then { _knownBaseTypes pushBack "CONTESTED"; };

    private _discoveredBases = [];

    // Method 1: Scan 2D Map Markers
    {
        private _markerNameUpper = toUpper _x;
        private _parts = _markerNameUpper splitString "_";
        if (count _parts > 0) then {
            private _prefix = _parts select 0;
            if (_prefix in _knownBaseTypes && { ["SPAWN", "GARAGE", "TERMINAL", "ARSENAL", "SERVICE", "PICKUP", "DROPOFF", "MEDICAL", "FUEL", "AMMO", "REPAIR"] findIf { _markerNameUpper find _x >= 0 } == -1 }) then {
                _discoveredBases pushBackUnique _x;
                if (markerText _x == "") then {
                    private _nameParts = _x splitString "_";
                    if (count _nameParts > 1) then { _nameParts deleteAt 0; };
                    _x setMarkerText (_nameParts joinString " ");
                };
            };
        };
    } forEach allMapMarkers;

    // Method 2: Scan 3D World Objects (Flag Poles, Game Logics, Master Anchors)
    {
        private _objVar = vehicleVarName _x;
        if (_objVar != "") then {
            private _objVarUpper = toUpper _objVar;
            private _parts = _objVarUpper splitString "_";
            if (count _parts > 0) then {
                private _prefix = _parts select 0;
                if (_prefix in _knownBaseTypes && { ["SPAWN", "GARAGE", "TERMINAL", "ARSENAL", "SERVICE", "PICKUP", "DROPOFF", "MEDICAL", "FUEL", "AMMO", "REPAIR"] findIf { _objVarUpper find _x >= 0 } == -1 }) then {
                    _discoveredBases pushBackUnique _objVar;
                    // Auto-synthesize a 2D map marker if no marker exists for this base object
                    if (getMarkerPos _objVar isEqualTo [0,0,0]) then {
                        private _m = createMarker [_objVar, getPos _x];
                        _m setMarkerType "b_installation";
                        
                        private _customName = _x getVariable ["QM_BaseName", _x getVariable ["QM_BaseDisplayName", ""]];
                        if (_customName == "" && { _x isKindOf "EmptyDetector" }) then {
                            _customName = triggerText _x;
                        };
                        // Also check any trigger synced to this base logic for mission-maker assigned trigger text
                        if (_customName == "") then {
                            private _syncedTrig = ([_x] call QM_fnc_getSyncedObjects) select { _x isKindOf "EmptyDetector" && { triggerText _x != "" } } param [0, objNull];
                            if (!isNull _syncedTrig) then {
                                _customName = triggerText _syncedTrig;
                            };
                        };
                        private _displayName = if (_customName != "") then {
                            _customName
                        } else {
                            private _nameParts = _objVar splitString "_";
                            if (count _nameParts > 1) then { _nameParts deleteAt 0; };
                            _nameParts joinString " "
                        };

                        _m setMarkerText _displayName;
                        _m setMarkerColor "ColorWEST";
                        _m setMarkerDir 0;
                    };
                };
            };
        };
    } forEach (allMissionObjects "All" + allMissionObjects "EmptyDetector");

    // Ensure "MSR" base key is always present in logisticsBases for infinite supply pool accounting
    if !("MSR" in _discoveredBases) then {
        _discoveredBases pushBackUnique "MSR";
    };

    logisticsBases = _discoveredBases;
    publicVariable "logisticsBases"; 

    // --- Initialize Base Ledger Economy ---
    private _sbCount = { ([_x] call logi_fnc_getBaseRole) == "STRATEGIC" } count logisticsBases;
    private _sbMultiplier = if (_sbCount <= 1) then { 2 } else { 1 };

    {
        private _baseName = _x; 
        if (getMarkerColor _baseName != "") then {
            _baseName setMarkerDir 0;   // Section 6.3: Normalize master base marker orientation to True North
            _baseName setMarkerAlpha 1; // Master base marker remains visible on map
        };
        
        private _baseType = [_baseName] call logi_fnc_getBaseType;

        // Read directly from tp_baseDefaults.sqf (supports per-base override or base-type defaults)
        private _bNameUpper = toUpper _baseName;
        private _typeIndex = logisticsBaseDefaults findIf { toUpper (_x select 0) == _bNameUpper };
        if (_typeIndex == -1) then {
            _typeIndex = logisticsBaseDefaults findIf { toUpper (_x select 0) == _baseType };
        };
        if (_typeIndex != -1) then {
            { 
                private _cat = _x select 0;
                private _val = _x select 1;
                if (_cat != "Role") then {
                    private _bRole = [_baseName] call logi_fnc_getBaseRole;
                    if (_val != -1 && _bRole == "STRATEGIC") then {
                        _val = _val * _sbMultiplier;
                    };
                    missionNamespace setVariable [format ["LogiScore_%1_%2", _baseName, _cat], _val, true]; 
                };
            } forEach ((logisticsBaseDefaults select _typeIndex) select 1);
        };
    } forEach logisticsBases;

    // Broadcast synchronizedObjects from server-owned Game Logics / Triggers to all clients (MP locality safety)
    [] spawn {
        waitUntil { time > 0 };
        {
            private _baseObj = missionNamespace getVariable [_x, objNull];
            if (!isNull _baseObj) then {
                private _synced = synchronizedObjects _baseObj;
                if (count _synced > 0) then {
                    _baseObj setVariable ["QM_SyncedObjects", _synced, true];
                };
            };
        } forEach logisticsBases;
    };

    // Start server-side daemons if present
    if (fileExists "logistics\qm_supplyPhysicalController.sqf") then { [] execVM "logistics\qm_supplyPhysicalController.sqf"; };
    if (fileExists "logistics\qm_serverGarrisonManager.sqf") then { [] execVM "logistics\qm_serverGarrisonManager.sqf"; };
    if (fileExists "logistics\qm_serverRespawnManager.sqf") then { [] execVM "logistics\qm_serverRespawnManager.sqf"; };
    if (fileExists "logistics\logi_groundVisuals.sqf") then { [] execVM "logistics\logi_groundVisuals.sqf"; };
    if (fileExists "tsk_serverGIN.sqf") then { [] execVM "tsk_serverGIN.sqf"; };
};


// ---------------------------------------------------------------------------
// 5. CLIENT-SIDE INITIALIZATION
// ---------------------------------------------------------------------------
if (hasInterface) then {

    waitUntil { !isNil "logisticsBases" };

    // --- COMPILE CLIENT FUNCTIONS LIBRARY & DAEMONS ---
    if (fileExists "logistics\qm_clientFunctions.sqf") then { call compile preprocessFileLineNumbers "logistics\qm_clientFunctions.sqf"; };

    // Compile legacy client UI helpers if present
    if (fileExists "logistics\qm_pylonManager.sqf") then { QM_fnc_pylonManager = compile preprocessFileLineNumbers "logistics\qm_pylonManager.sqf"; };
    if (fileExists "logistics\qm_clientActionCompiler.sqf") then { call compile preprocessFileLineNumbers "logistics\qm_clientActionCompiler.sqf"; };
    if (fileExists "logistics\qm_equipmentTrader.sqf") then { [] execVM "logistics\qm_equipmentTrader.sqf"; };
    if (fileExists "logistics\qm_clientRespawnManager.sqf") then { [] execVM "logistics\qm_clientRespawnManager.sqf"; };

    // --- TACTICAL COMMAND CENTER CLIENT DAEMONS ---
    if (fileExists "tsk_clientMapIntel.sqf") then { [] execVM "tsk_clientMapIntel.sqf"; };
    if (fileExists "tsk_clientTaskMaster.sqf") then { [] execVM "tsk_clientTaskMaster.sqf"; };
};