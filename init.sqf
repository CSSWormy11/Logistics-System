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
// - logisticsCargoTemplates.sqf : vehicle cargo templates and spawn lists
// - SupplyScores.sqf            : per-item scoring used to compute default pool values
// - logisticsBaseDefaults.sqf  : default ledger values for non-SB base types
// - logisticsVehicleRoles.sqf  : role-to-class mappings used by spawn/garage logic
// - qm_vehicleCapsTemplate.sqf : vehicle cap family matrix (QM_CAP_ConfigMatrix)
// ---------------------------------------------------------------------------
if (fileExists "logisticsCargoTemplates.sqf") then { call compile preprocessFileLineNumbers "logisticsCargoTemplates.sqf";
} else {
    //Fallback minimal template so code using allowedLogisticsVehicles still works.
    logisticsCargoTemplates = [["B_Truck_01_cargo_F", [["Cargo",[]],["Ammo",[]],["Fuel",[]],["Medical",[]],["Repair",[]],["Vehicle",[]],["Troops",[]]]]];
};

if (fileExists "SupplyScores.sqf") then { call compile preprocessFileLineNumbers "SupplyScores.sqf"; };
if (fileExists "logisticsBaseDefaults.sqf") then { call compile preprocessFileLineNumbers "logisticsBaseDefaults.sqf"; };
if (fileExists "virtualArsenalTemplate.sqf") then { call compile preprocessFileLineNumbers "virtualArsenalTemplate.sqf"; };
if (fileExists "spawnableInfantryTemplate.sqf") then { call compile preprocessFileLineNumbers "spawnableInfantryTemplate.sqf"; };
if (fileExists "spawnableVehicleTemplate.sqf") then { call compile preprocessFileLineNumbers "spawnableVehicleTemplate.sqf"; };
if (fileExists "qm_vehicleCapsTemplate.sqf") then { call compile preprocessFileLineNumbers "qm_vehicleCapsTemplate.sqf"; } else { QM_CAP_ConfigMatrix = []; };
if (fileExists "logisticsVehicleRoles.sqf") then { call compile preprocessFileLineNumbers "logisticsVehicleRoles.sqf"; }; // LOAD THE Vehicle Role TEMPLATE

// ---------------------------------------------------------------------------
// Global derived lists
// ---------------------------------------------------------------------------
if (isNil "QM_AutoCloseMotorpool") then { QM_AutoCloseMotorpool = 1; };
publicVariable "QM_AutoCloseMotorpool";

allowedLogisticsVehicles = logisticsCargoTemplates apply {_x select 0};


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
// 3. OPTIONAL MODULES (Executed safely after functions load)
// ---------------------------------------------------------------------------
if (fileExists "fn_initLogisticsTasks.sqf") then { [] execVM "fn_initLogisticsTasks.sqf"; };
if (fileExists "fn_manageLogisticsMissions.sqf") then { [] execVM "fn_manageLogisticsMissions.sqf"; };
if (fileExists "fn_startupMarkerDiagnostics.sqf") then { [] execVM "fn_startupMarkerDiagnostics.sqf"; };


// ---------------------------------------------------------------------------
// 4. SERVER-SIDE INITIALIZATION
// ---------------------------------------------------------------------------
if (isServer) then {

    // --- COMPILE SERVER FUNCTIONS LIBRARY ---
    if (fileExists "qm_serverFunctions.sqf") then { call compile preprocessFileLineNumbers "qm_serverFunctions.sqf"; };

    // Auto-hide Garage map markers so mission makers don't have to do it manually
    {
        if (["_GARAGE", _x] call BIS_fnc_inString) then { _x setMarkerAlpha 0; };
    } forEach allMapMarkers;

    // -----------------------------------------------------------------------
    // DEFINE BASES FIRST
    // Discover supply bases on the map
    // -----------------------------------------------------------------------
    logisticsBases = allMapMarkers select {
        private _m = toLowerANSI _x;
        ((_m find "fob" >= 0) || (_m find "sb" >= 0) || (_m find "msr" >= 0)) &&
        { ["spawn", "garage", "terminal", "arsenal", "service", "pickup", "dropoff"] findIf { _m find _x >= 0 } == -1 }
    };
    publicVariable "logisticsBases"; 

    // Broadcast to clients
    {
        if ("_GARAGE" in toUpper _x) then { _x setMarkerAlpha 0; };
    } forEach allMapMarkers;

    // --- Initialize Base Ledger Economy ---
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

    // Start server-side daemons if present
    if (fileExists "qm_supplyPhysicalController.sqf") then { [] execVM "qm_supplyPhysicalController.sqf"; };
    if (fileExists "qm_serverGarrisonManager.sqf") then { [] execVM "qm_serverGarrisonManager.sqf"; };
    if (fileExists "qm_serverRespawnManager.sqf") then { [] execVM "qm_serverRespawnManager.sqf"; };
    if (fileExists "tsk_serverGIN.sqf") then { [] execVM "tsk_serverGIN.sqf"; };
};


// ---------------------------------------------------------------------------
// 5. CLIENT-SIDE INITIALIZATION
// ---------------------------------------------------------------------------
if (hasInterface) then {

    waitUntil { !isNil "logisticsBases" };

    // --- COMPILE CLIENT FUNCTIONS LIBRARY & DAEMONS ---
    if (fileExists "qm_clientFunctions.sqf") then { call compile preprocessFileLineNumbers "qm_clientFunctions.sqf"; };

    // Compile legacy client UI helpers if present
    if (fileExists "fn_pylonManager.sqf") then { QM_fnc_pylonManager = compile preprocessFileLineNumbers "fn_pylonManager.sqf"; };
    if (fileExists "qm_clientActionCompiler.sqf") then { call compile preprocessFileLineNumbers "qm_clientActionCompiler.sqf"; };
    if (fileExists "fn_equipmentTrader.sqf") then { [] execVM "fn_equipmentTrader.sqf"; };

    // --- TACTICAL COMMAND CENTER CLIENT DAEMONS ---
    if (fileExists "tsk_clientMapIntel.sqf") then { [] execVM "tsk_clientMapIntel.sqf"; };
    if (fileExists "tsk_clientTaskMaster.sqf") then { [] execVM "tsk_clientTaskMaster.sqf"; };
};