/*
    ============================================================================
    LOGISTICS SYSTEM: VEHICLE CONSUMPTION ENGINE
    File: qm_supplyPhysicalController.sqf
    Module: Part 3B - Physical Infrastructure Dependency System
    Execution: Server-Side Background Watchdog Loop
    Description:
        Dynamically scans for editor-placed objects using <BaseKey>_<type> naming.
        Uses a "Hybrid Tracker": Instead of checking native cargo capacities (which 
        break down on 1-Trillion capacity Huron objects due to SQF floating point limits),
        this script dynamically monitors vehicles parked near the active containers 
        and bills the base when the vehicles are successfully serviced.
    ============================================================================
*/

if (!isServer) exitWith {};
waitUntil { !isNil "logisticsBases" };
diag_log "PART 3B: Initializing Hybrid Vehicle-Tracker Watchdog...";

private _infrastructureBlueprints = createHashMap;

// --- STEP 1: PARSE THE MISSION ENVIRONMENT ---
{
    private _base = _x;
    private _padTrigger = missionNamespace getVariable [format ["%1_service", _base], objNull];
    
    // Only map physical objects if there is NO virtual trigger pad at this base
    if (isNull _padTrigger) then {
        private _searchObjects = vehicles + allMissionObjects "ReammoBox_F" + allMissionObjects "ThingX" + allMissionObjects "Building";
        
        {
            private _objName = vehicleVarName _x;
            if (_objName != "" && { _objName select [0, count _base] == _base }) then {
                
                private _supplyLane = "";
                if ("_fuel" in _objName) then { _supplyLane = "Fuel"; };
                if ("_ammo" in _objName) then { _supplyLane = "Ammo"; };
                if ("_repair" in _objName) then { _supplyLane = "Repair"; };
                
                if (_supplyLane != "") then {
                    _infrastructureBlueprints set [_objName, [_x, _supplyLane, _base]];
                    
                    _x enableVehicleCargo false;
                    _x enableRopeAttach false;
                    
                    private _poolVar = format ["LogiScore_%1_%2", _base, _supplyLane];
                    private _currentPoolVal = missionNamespace getVariable [_poolVar, 0];
                    
                    // Force the object to be capable of providing native service if base has points
                    private _startState = if (_currentPoolVal > 0) then { 1.0 } else { 0.0 };
                    switch (_supplyLane) do {
                        case "Fuel": { _x setFuelCargo _startState; };
                        case "Ammo": { _x setAmmoCargo _startState; };
                        case "Repair": { _x setRepairCargo _startState; };
                    };
                    
                    diag_log format ["[PART 3B REGISTRY INITIAL SCAN]: Mapped Hybrid Object '%1' -> Lane: %2", _objName, _supplyLane];
                };
            };
        } forEach _searchObjects;
    };
} forEach logisticsBases;

if (count _infrastructureBlueprints == 0) exitWith { diag_log "PART 3B: No active physical infrastructure assets detected."; };

// --- STEP 2: HYBRID VEHICLE-STATE TRACKING LOOP ---
private _trackedVehicles = createHashMap;

while {true} do {
    uiSleep 2.0; // 2-second tick for precise vehicle tracking
    
    private _activeVehiclesThisTick = [];

    {
        private _objName = _x;
        private _blueprint = _infrastructureBlueprints get _objName;
        _blueprint params ["_obj", "_lane", "_baseKey"];
        
        if (alive _obj) then {
            private _poolVar = format ["LogiScore_%1_%2", _baseKey, _lane];
            private _currentMasterPool = missionNamespace getVariable [_poolVar, 0];
            
            // Turn container off/on based on base funds
            if (_currentMasterPool <= 0) then {
                switch (_lane) do { case "Fuel": { _obj setFuelCargo 0; }; case "Ammo": { _obj setAmmoCargo 0; }; case "Repair": { _obj setRepairCargo 0; }; };
            } else {
                switch (_lane) do { case "Fuel": { _obj setFuelCargo 1; }; case "Ammo": { _obj setAmmoCargo 1; }; case "Repair": { _obj setRepairCargo 1; }; };
                
                // Track vehicles within 20m of the active container
                private _nearVehs = _obj nearEntities [["LandVehicle", "Air"], 20];
                {
                    private _v = _x;
                    // Only track vehicles that are stationary (getting serviced)
                    if (alive _v && speed _v < 2) then {
                        private _vid = netId _v;
                        _activeVehiclesThisTick pushBackUnique _vid;
                        
                        // Load or create the vehicle's memory state
                        private _vState = _trackedVehicles getOrDefault [_vid, createHashMap];
                        
                        if (_lane == "Repair") then {
                            private _cDam = damage _v;
                            private _lDam = _vState getOrDefault ["dam", _cDam];
                            
                            if (_cDam < _lDam) then { // Vehicle health went UP natively
                                private _cost = ceil ((_lDam - _cDam) * 2000); // 2000 pts per 100% repair
                                if (_cost > 0) then {
                                    _currentMasterPool = (_currentMasterPool - _cost) max 0;
                                    missionNamespace setVariable [_poolVar, _currentMasterPool, true];
                                    diag_log format ["QM HYBRID SYNC: Base %1 billed %2 pts for %3 Repair.", _baseKey, _cost, typeOf _v];
                                };
                            };
                            _vState set ["dam", _cDam];
                        };
                        
                        if (_lane == "Fuel") then {
                            private _cFuel = fuel _v;
                            private _lFuel = _vState getOrDefault ["fuel", _cFuel];
                            
                            if (_cFuel > _lFuel) then { // Vehicle fuel went UP natively
                                private _cost = ceil ((_cFuel - _lFuel) * 100); // 100 pts per 100% fuel
                                if (_cost > 0) then {
                                    _currentMasterPool = (_currentMasterPool - _cost) max 0;
                                    missionNamespace setVariable [_poolVar, _currentMasterPool, true];
                                    diag_log format ["QM HYBRID SYNC: Base %1 billed %2 pts for %3 Refuel.", _baseKey, _cost, typeOf _v];
                                };
                            };
                            _vState set ["fuel", _cFuel];
                        };
                        
                        if (_lane == "Ammo") then {
                            private _cAmmo = 0;
                            { _cAmmo = _cAmmo + (_x # 2); } forEach (magazinesAllTurrets _v);
                            private _lAmmo = _vState getOrDefault ["ammo", _cAmmo];
                            
                            if (_cAmmo > _lAmmo) then { // Vehicle received new bullets natively
                                private _cost = 5; // Flat fee per magazine insertion tick
                                _currentMasterPool = (_currentMasterPool - _cost) max 0;
                                missionNamespace setVariable [_poolVar, _currentMasterPool, true];
                                diag_log format ["QM HYBRID SYNC: Base %1 billed %2 pts for %3 Rearm.", _baseKey, _cost, typeOf _v];
                            };
                            _vState set ["ammo", _cAmmo];
                        };
                        
                        _trackedVehicles set [_vid, _vState];
                    };
                } forEach _nearVehs;
            };
        };
    } forEach (keys _infrastructureBlueprints);
    
    // Clean up memory for vehicles that drove away
    private _trackedIds = keys _trackedVehicles;
    {
        if !(_x in _activeVehiclesThisTick) then { _trackedVehicles deleteAt _x; };
    } forEach _trackedIds;
};