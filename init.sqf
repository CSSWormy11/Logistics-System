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
    _prefix
};

logi_fnc_getBaseRole = {
    params ["_baseKey"];
    private _bType = [_baseKey] call logi_fnc_getBaseType;
    private _typeIdx = logisticsBaseDefaults findIf { toUpper (_x select 0) == _bType };
    if (_typeIdx == -1) exitWith { "TACTICAL" };
    private _props = (logisticsBaseDefaults select _typeIdx) select 1;
    private _roleIdx = _props findIf { (_x select 0) == "Role" };
    if (_roleIdx != -1) then { (_props select _roleIdx) select 1 } else {
        if (_bType in ["MSR", "CS"]) exitWith { "MSR" };
        if (_bType in ["SB", "CVN", "LHA"]) exitWith { "STRATEGIC" };
        "TACTICAL"
    }
};

// QM_fnc_getLocationsByPrefix
// Purpose: Scans strictly for mission-maker placed 3D objects (by variable name)
//          matching <BaseKey>_<typeSuffix> (un-numbered or numbered 1..100).
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
            _found pushBack [_safeObj, getPosASL _safeObj, getDir _safeObj, "OBJECT", _name];
        };
    };

    // Check base suffix without numbers (e.g. SB_Arsenal)
    [format ["%1_%2", _baseKey, _typeSuffix]] call _checkAndAdd;

    // Check numbered suffixes 1 through 100 (e.g. SB_Arsenal_1, SB_Spawn_2)
    for "_i" from 1 to 100 do {
        [format ["%1_%2_%3", _baseKey, _typeSuffix, _i]] call _checkAndAdd;
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
    // DEFINE BASES FIRST
    // Discover supply bases dynamically from tp_baseDefaults.sqf
    // -----------------------------------------------------------------------
    private _knownBaseTypes = logisticsBaseDefaults apply { toUpper (_x select 0) };
    if !("CONTESTED" in _knownBaseTypes) then { _knownBaseTypes pushBack "CONTESTED"; };

    logisticsBases = allMapMarkers select {
        private _parts = (toUpper _x) splitString "_";
        if (count _parts == 0) exitWith { false };
        private _prefix = _parts select 0;
        (_prefix in _knownBaseTypes) &&
        { ["SPAWN", "GARAGE", "TERMINAL", "ARSENAL", "SERVICE", "PICKUP", "DROPOFF", "MEDICAL"] findIf { (toUpper _x) find _x >= 0 } == -1 }
    };
    
    // Ensure "MSR" base key is always present in logisticsBases for infinite supply pool accounting
    if !("MSR" in logisticsBases) then {
        logisticsBases pushBackUnique "MSR";
    };
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

        // Read directly from tp_baseDefaults.sqf
        private _typeIndex = logisticsBaseDefaults findIf { toUpper (_x select 0) == _baseType };
        if (_typeIndex != -1) then {
            { 
                private _cat = _x select 0;
                private _val = _x select 1;
                if (_cat != "Role") then {
                    if (_val != -1 && (_baseType in ["SB", "CVN", "LHA"])) then {
                        _val = _val * _sbMultiplier;
                    };
                    missionNamespace setVariable [format ["LogiScore_%1_%2", _baseName, _cat], _val, true]; 
                };
            } forEach ((logisticsBaseDefaults select _typeIndex) select 1);
        };
    } forEach logisticsBases;

    // Start server-side daemons if present
    if (fileExists "logistics\qm_supplyPhysicalController.sqf") then { [] execVM "logistics\qm_supplyPhysicalController.sqf"; };
    if (fileExists "logistics\qm_serverGarrisonManager.sqf") then { [] execVM "logistics\qm_serverGarrisonManager.sqf"; };
    if (fileExists "logistics\qm_serverRespawnManager.sqf") then { [] execVM "logistics\qm_serverRespawnManager.sqf"; };
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