// ============================================================================
// LOGISTICS SYSTEM: CLIENT TASK MANAGER (PART 1)
// File: fn_manageLogisticsMissions.sqf
// Description: Client-side autonomous loop. Tracks player state, vehicle type,
//              and cargo. Updates task descriptions and UI markers dynamically.
//              Handles live resource HUD and strategic/tactical routing.
// Called By: init.sqf (Executed by Client via hasInterface)
// ============================================================================

if (!hasInterface) exitWith {};

// =========================================================================
// GLOBAL STRING FORMATTER: FULL LENGTH VALUES, COMMAS & SCALE NOTATION
// Handles numbers from 0 up to 100+ Trillion without scientific notation
// =========================================================================
logi_fnc_formatPoints = {
    private _num = 0;
    private _includeScale = true;
    if (_this isEqualType []) then {
        _num = _this param [0, 0];
        _includeScale = _this param [1, true];
    } else {
        _num = _this;
    };

    if (_num isEqualType "") then {
        if (_num == "-1" || _num == "UNLIMITED") exitWith { "UNLIMITED" };
        _num = parseNumber _num;
    };

    if (_num == -1) exitWith { "UNLIMITED" };
    if (_num == 0) exitWith { "0" };

    private _isNeg = (_num < 0);
    private _integer = floor (abs _num);
    private _str = str _integer;

    // Expand scientific notation if present (e.g. "1.6e+006", "1.6e+06", "1e+014")
    private _eIdx = _str find "e";
    if (_eIdx == -1) then { _eIdx = _str find "E"; };

    if (_eIdx != -1) then {
        private _sig = _str select [0, _eIdx];
        private _expStr = _str select [_eIdx + 1];
        private _exp = parseNumber _expStr;

        private _dotIdx = _sig find ".";
        if (_dotIdx == -1) then {
            for "_i" from 1 to _exp do { _sig = _sig + "0"; };
            _str = _sig;
        } else {
            private _intPart = _sig select [0, _dotIdx];
            private _decPart = _sig select [_dotIdx + 1];
            private _decLen = count _decPart;

            if (_exp >= _decLen) then {
                private _zeroCount = _exp - _decLen;
                private _combined = _intPart + _decPart;
                for "_i" from 1 to _zeroCount do { _combined = _combined + "0"; };
                _str = _combined;
            } else {
                private _shiftedInt = _intPart + (_decPart select [0, _exp]);
                _str = _shiftedInt;
            };
        };
    };

    // Strip any trailing decimal residue if present
    private _finalDot = _str find ".";
    if (_finalDot != -1) then {
        _str = _str select [0, _finalDot];
    };

    // Determine value range scale descriptor
    private _digitCount = count _str;
    private _scaleTag = "";
    if (_includeScale) then {
        if (_digitCount >= 19) then {
            _scaleTag = " (Quintillions)";
        } else {
            if (_digitCount >= 16) then {
                _scaleTag = " (Quadrillions)";
            } else {
                if (_digitCount >= 13) then {
                    _scaleTag = " (Trillions)";
                } else {
                    if (_digitCount >= 10) then {
                        _scaleTag = " (Billions)";
                    } else {
                        if (_digitCount >= 7) then {
                            _scaleTag = " (Millions)";
                        } else {
                            if (_digitCount >= 4) then {
                                _scaleTag = " (Thousands)";
                            };
                        };
                    };
                };
            };
        };
    };

    // Insert thousands commas from right to left
    private _arr = _str splitString "";
    private _res = "";
    private _cnt = 0;
    for "_i" from (_digitCount - 1) to 0 step -1 do {
        if (_cnt > 0 && (_cnt % 3 == 0)) then { _res = "," + _res; };
        _res = (_arr # _i) + _res;
        _cnt = _cnt + 1;
    };

    if (_isNeg) then { _res = "-" + _res; };
    _res + _scaleTag
};

// =========================================================================
// HELPER: RESOLVE BASE & PICKUP/DROPOFF MARKER POSITIONS SAFELY
// =========================================================================
logi_fnc_getMarkerPosSafe = {
    params ["_prefix", "_baseKey", ["_fallbackMarker", ""]];
    private _candidate1 = format ["%1_%2", _prefix, _baseKey];
    if (getMarkerColor _candidate1 != "") exitWith { getMarkerPos _candidate1 };

    if (_fallbackMarker != "" && { getMarkerColor _fallbackMarker != "" }) exitWith { getMarkerPos _fallbackMarker };

    if (getMarkerColor _baseKey != "") exitWith { getMarkerPos _baseKey };
    [0, 0, 0]
};

// =========================================================================
// HELPER: GET COMPATIBLE PICKUP TRIGGER BY MISSION-MAKER CONDITION
// =========================================================================
logi_fnc_getCompatiblePickupTrigger = {
    params ["_vehicle", "_baseKey"];
    private _trigs = missionNamespace getVariable [format ["LogiPickupTriggers_%1", _baseKey], []];
    if (count _trigs == 0) exitWith {
        private _pos = ["Pickup", _baseKey, ""] call logi_fnc_getMarkerPosSafe;
        [objNull, _pos, mapGridPosition _pos, "Come to a complete stop inside zone"]
    };

    private _isPlane = _vehicle isKindOf "Plane";
    private _isHeli  = _vehicle isKindOf "Helicopter";
    private _isBoat  = _vehicle isKindOf "Ship";
    private _isLand  = !_isPlane && !_isHeli && !_isBoat;

    private _compatible = [];
    {
        private _trig = _x;
        private _cond = toLowerANSI (_trig getVariable ["LogiTriggerCond", ""]);
        private _condFiltersPlane = ("_x iskindof ""plane""" in _cond || "_x iskindof 'plane'" in _cond);
        private _condFiltersHeli  = ("_x iskindof ""helicopter""" in _cond || "_x iskindof 'helicopter'" in _cond);

        private _match = false;
        if (_isPlane) then {
            // Planes can use plane corridors or open triggers that don't restrict to helicopters
            _match = !_condFiltersHeli;
        } else {
            if (_isHeli) then {
                // Helicopters use heli zones or open triggers that don't restrict to planes
                _match = !_condFiltersPlane;
            } else {
                // Ground vehicles and boats use open triggers that don't filter for aircraft
                _match = !_condFiltersPlane && !_condFiltersHeli;
            };
        };

        if (_match) then {
            _compatible pushBack _trig;
        };
    } forEach _trigs;

    if (count _compatible == 0) then { _compatible = _trigs; };

    // Select nearest compatible trigger to the vehicle
    private _sorted = _compatible apply { [_vehicle distance2D _x, _x] };
    _sorted sort true;
    private _bestTrig = (_sorted # 0) # 1;
    private _centerPos = getPos _bestTrig;
    private _gridStr = mapGridPosition _bestTrig;

    private _condStr = toLowerANSI (_bestTrig getVariable ["LogiTriggerCond", ""]);
    private _speedRule = "Come to a complete stop inside zone";
    if ("speed _x == 0" in _condStr || "speed _x < 1" in _condStr) then {
        _speedRule = "Come to a complete stop inside zone";
    } else {
        if ("speed _x < 10" in _condStr) then {
            _speedRule = "Maintain slow speed (< 10 km/h) in zone";
        } else {
            if (_isPlane) then {
                _speedRule = "Fly through marked corridor at mission airspeed";
            } else {
                _speedRule = "Drive/fly through marked corridor";
            };
        };
    };

    [_bestTrig, _centerPos, _gridStr, _speedRule]
};

// =========================================================================
// HELPER: GET DROPOFF TRIGGER LOCATION & GRID
// =========================================================================
logi_fnc_getDropoffLocation = {
    params ["_vehicle", "_baseKey"];
    private _trigs = missionNamespace getVariable [format ["LogiDropoffTriggers_%1", _baseKey], []];
    if (count _trigs > 0) then {
        private _sorted = _trigs apply { [_vehicle distance2D _x, _x] };
        _sorted sort true;
        private _bestTrig = (_sorted # 0) # 1;
        [_bestTrig, getPos _bestTrig, mapGridPosition _bestTrig]
    } else {
        private _pos = ["Dropoff", _baseKey, ""] call logi_fnc_getMarkerPosSafe;
        [objNull, _pos, mapGridPosition _pos]
    };
};

// =========================================================================
// HELPER: CALCULATE TRAVEL DISTANCE (ROAD DRIVING VS AIR FLIGHT)
// =========================================================================
logi_fnc_getRouteDistance = {
    params ["_fromBase", "_toBase", "_isGroundVehicle"];
    
    private _p1 = ["Dropoff", _fromBase, _fromBase] call logi_fnc_getMarkerPosSafe;
    private _p2 = ["Dropoff", _toBase, _toBase] call logi_fnc_getMarkerPosSafe;
    private _straightLineDist = _p1 distance2D _p2;

    if (!_isGroundVehicle) exitWith { _straightLineDist };

    // Ground vehicle: Check road network driving distance table
    private _pairKey = format ["%1_%2", _fromBase, _toBase];
    private _revKey  = format ["%1_%2", _toBase, _fromBase];

    private _roadTable = missionNamespace getVariable ["Logi_RoadDistanceTable", createHashMap];
    if (count _roadTable == 0) then {
        _roadTable = createHashMapFromArray [
            // Stratis SB_Main to Land FOBs (actual road driving distance in meters)
            ["SB_Main_FOB_AgiaMarinaBase", 1050],
            ["SB_Main_FOB_CampRogain", 3200],
            ["SB_Main_FOB_CampMaxwell", 4100],
            ["SB_Main_FOB_Mike26", 4600],
            ["SB_Main_FOB_Kamino", 5300],
            ["SB_Main_FOB_CampTempest", 7200],

            // Reverse lookups
            ["FOB_AgiaMarinaBase_SB_Main", 1050],
            ["FOB_CampRogain_SB_Main", 3200],
            ["FOB_CampMaxwell_SB_Main", 4100],
            ["FOB_Mike26_SB_Main", 4600],
            ["FOB_Kamino_SB_Main", 5300],
            ["FOB_CampTempest_SB_Main", 7200]
        ];
        missionNamespace setVariable ["Logi_RoadDistanceTable", _roadTable];
    };

    if (_pairKey in _roadTable) exitWith { _roadTable get _pairKey };
    if (_revKey in _roadTable) exitWith { _roadTable get _revKey };

    // Dynamic fallback for unmapped base pairs or custom maps:
    // Scale straight-line distance by terrain/road winding factor (1.4x)
    _straightLineDist * 1.4
};

// =========================================================================
// HELPER: CONTEXTUAL SPOTLIGHT MAP MARKER HIERARCHY (OPTION 3)
// Dynamic local alpha manager for pickup, dropoff, service, and area pads.
// Non-logistics players: Alpha 0 (Clean tactical map, 0 clutter).
// Logistics overview (no active route): Alpha 1.0 icons, 0.25 area triggers.
// Logistics active route:
//   - Active Pickup & Dropoff Pads (+ Service on active bases): Alpha 1.0 (Area: 0.45).
//   - Secondary Alternative Pads (All other bases): Alpha 0.25 (Area: 0.10).
// Master Base Markers (SB_Main, FOB_*, MSR) remain permanently visible at 1.0.
// =========================================================================
logi_fnc_updateMarkerSpotlight = {
    params [
        ["_isLogiDriver", false],
        ["_activeFromBase", ""],
        ["_activeTargetBase", ""]
    ];

    if (!hasInterface) exitWith {};

    private _hasActiveRoute = (_isLogiDriver && _activeFromBase != "" && _activeTargetBase != "");
    private _fromBaseLower = toLowerANSI _activeFromBase;
    private _targetBaseLower = toLowerANSI _activeTargetBase;

    {
        private _m = toLowerANSI _x;
        private _isArea = (_m find "area_" == 0);
        private _isPickup = (_m find "pickup_" == 0);
        private _isDropoff = (_m find "dropoff_" == 0);
        private _isService = (_m find "service_" == 0);

        if (_isArea || _isPickup || _isDropoff || _isService) then {
            if (!_isLogiDriver) then {
                // Non-logistics players: completely hidden locally
                _x setMarkerAlphaLocal 0;
            } else {
                if (!_hasActiveRoute) then {
                    // Logistics driver without assigned route (overview mode)
                    if (_isArea) then {
                        _x setMarkerAlphaLocal 0.25;
                    } else {
                        _x setMarkerAlphaLocal 1.0;
                    };
                } else {
                    // Active route mode: Identify if marker belongs to active pickup or dropoff base
                    private _basePart = "";
                    if (_isArea) then {
                        _basePart = _m select [5]; // strip "area_"
                    } else {
                        if (_isPickup) then {
                            _basePart = _m select [7]; // strip "pickup_"
                        } else {
                            if (_isDropoff) then {
                                _basePart = _m select [8]; // strip "dropoff_"
                            } else {
                                _basePart = _m select [8]; // strip "service_"
                            };
                        };
                    };

                    // Check prefix matching against active base keys
                    private _matchesFrom = false;
                    if (_fromBaseLower != "") then {
                        private _len = count _fromBaseLower;
                        if ((_basePart find _fromBaseLower) == 0) then {
                            private _nextChar = _basePart select [_len, 1];
                            if (_nextChar == "" || _nextChar == "_") then {
                                _matchesFrom = true;
                            };
                        };
                    };

                    private _matchesTarget = false;
                    if (_targetBaseLower != "") then {
                        private _len = count _targetBaseLower;
                        if ((_basePart find _targetBaseLower) == 0) then {
                            private _nextChar = _basePart select [_len, 1];
                            if (_nextChar == "" || _nextChar == "_") then {
                                _matchesTarget = true;
                            };
                        };
                    };

                    // Contextual role check:
                    // Origin base: Pickup pads and Service pads are spotlighted
                    // Destination base: Dropoff pads and Service pads are spotlighted
                    private _isActivePad = false;
                    if (_isArea) then {
                        if (_matchesFrom && ("_pickup" in _m || "_service" in _m)) then { _isActivePad = true; };
                        if (_matchesTarget && ("_dropoff" in _m || "_service" in _m)) then { _isActivePad = true; };
                    } else {
                        if (_matchesFrom && (_isPickup || _isService)) then { _isActivePad = true; };
                        if (_matchesTarget && (_isDropoff || _isService)) then { _isActivePad = true; };
                    };

                    if (_isActivePad) then {
                        // SPOTLIGHT: Full prominence for primary route operations
                        if (_isArea) then {
                            _x setMarkerAlphaLocal 0.45;
                        } else {
                            _x setMarkerAlphaLocal 1.0;
                        };
                    } else {
                        // SECONDARY: Dimmed to 25% for alternate/emergency dropoff awareness
                        if (_isArea) then {
                            _x setMarkerAlphaLocal 0.10;
                        } else {
                            _x setMarkerAlphaLocal 0.25;
                        };
                    };
                };
            };
        };
    } forEach allMapMarkers;
};

// =========================================================================
// HELPER: DELETE SUB-TASKS UNDER A PARENT ROUTE TASK
// =========================================================================
logi_fnc_deleteRouteSubTasks = {
    params ["_parentTaskID"];
    {
        private _sId = format ["%1_%2", _parentTaskID, _x];
        if ([_sId] call BIS_fnc_taskExists) then { [_sId] call BIS_fnc_deleteTask; };
    } forEach ["Pickup", "Manifest", "Delivery"];
};

// =========================================================================
// HELPER: FULL LOGISTICS TASK CLEANUP (PLAYER-LOCAL)
// =========================================================================
logi_fnc_clearAllLogiTasks = {
    "" call BIS_fnc_taskSetCurrent;
    {
        private _pId = _x;
        [_pId] call logi_fnc_deleteRouteSubTasks;
        if ([_pId] call BIS_fnc_taskExists) then { [_pId] call BIS_fnc_deleteTask; };
    } forEach ["Logi_Strategic_Task", "Logi_Tactical_Task", "Logi_CLT_Task"];
};

// =========================================================================
// HELPER: UPDATE 3-TIER SUB-TASK HIERARCHY FOR ACTIVE ROUTE
// =========================================================================
logi_fnc_updateRouteTasks = {
    params [
        "_parentTaskID",
        "_pickupBaseKey",
        "_destBaseKey",
        "_category",
        "_isLoaded",
        "_vehicle"
    ];

    ([_vehicle, _pickupBaseKey] call logi_fnc_getCompatiblePickupTrigger) params ["_pickupTrig", "_pickupPos", "_pickupGrid", "_speedRule"];
    ([_vehicle, _destBaseKey] call logi_fnc_getDropoffLocation) params ["_dropoffTrig", "_dropoffPos", "_dropoffGrid"];

    // Update contextual marker spotlight hierarchy for active route leg
    [true, _pickupBaseKey, _destBaseKey] call logi_fnc_updateMarkerSpotlight;


    private _pickupClean = (_pickupBaseKey splitString "_") joinString " ";
    private _destClean   = (_destBaseKey splitString "_") joinString " ";

    private _subPickup   = _parentTaskID + "_Pickup";
    private _subManifest = _parentTaskID + "_Manifest";
    private _subDelivery = _parentTaskID + "_Delivery";

    // 1. Pickup Sub-Task
    private _pickupTitle = format ["1. Pickup Supplies: %1 (Grid %2)", _pickupClean, _pickupGrid];
    private _pickupDesc  = format ["Proceed to %1 loading zone at Grid %2.<br/>Procedure: %3.", _pickupClean, _pickupGrid, _speedRule];
    private _pickupState = if (_isLoaded) then { "SUCCEEDED" } else { "ASSIGNED" };

    if !([_subPickup] call BIS_fnc_taskExists) then {
        [player, [_subPickup, _parentTaskID], [_pickupDesc, _pickupTitle, ""], _pickupPos, _pickupState, 2, false, "load", false] call BIS_fnc_taskCreate;
    } else {
        [_subPickup, [_pickupDesc, _pickupTitle, ""]] call BIS_fnc_taskSetDescription;
        [_subPickup, _pickupPos] call BIS_fnc_taskSetDestination;
        if ((_subPickup call BIS_fnc_taskState) != _pickupState) then {
            [_subPickup, _pickupState, true] call BIS_fnc_taskSetState;
        };
    };

    // 2. Manifest Sub-Task
    private _manifestCategory = if (_isLoaded) then {
        _vehicle getVariable ["logistics_loaded_type", _category]
    } else {
        _category
    };
    private _manifestStatus = if (_isLoaded) then { "LOADED" } else { "AWAITING PICKUP" };
    private _manifestTitle = format ["2. Manifest: %1 [%2]", _manifestCategory, _manifestStatus];
    private _manifestDesc  = if (_isLoaded) then {
        format ["Secured Cargo: %1.<br/>Status: Loaded and secured in transport.<br/>Destination: %2 (Grid %3).", _manifestCategory, _destClean, _dropoffGrid]
    } else {
        format ["Assigned Cargo: %1.<br/>Status: Awaiting pickup at %2 (Grid %3).", _manifestCategory, _pickupClean, _pickupGrid]
    };
    private _manifestState = if (_isLoaded) then { "SUCCEEDED" } else { "CREATED" };

    if !([_subManifest] call BIS_fnc_taskExists) then {
        [player, [_subManifest, _parentTaskID], [_manifestDesc, _manifestTitle, ""], [0,0,0], _manifestState, 1, false, "box", false] call BIS_fnc_taskCreate;
    } else {
        [_subManifest, [_manifestDesc, _manifestTitle, ""]] call BIS_fnc_taskSetDescription;
        if ((_subManifest call BIS_fnc_taskState) != _manifestState) then {
            [_subManifest, _manifestState, true] call BIS_fnc_taskSetState;
        };
    };

    // 3. Delivery Sub-Task
    private _deliveryTitle = format ["3. Deliver Supplies: %1 (Grid %2)", _destClean, _dropoffGrid];
    private _deliveryDesc  = format ["Deliver supplies to %1 dropoff zone at Grid %2.", _destClean, _dropoffGrid];
    private _deliveryState = if (_isLoaded) then { "ASSIGNED" } else { "CREATED" };

    if !([_subDelivery] call BIS_fnc_taskExists) then {
        [player, [_subDelivery, _parentTaskID], [_deliveryDesc, _deliveryTitle, ""], _dropoffPos, _deliveryState, 2, false, "land", false] call BIS_fnc_taskCreate;
    } else {
        [_subDelivery, [_deliveryDesc, _deliveryTitle, ""]] call BIS_fnc_taskSetDescription;
        [_subDelivery, _dropoffPos] call BIS_fnc_taskSetDestination;
        if ((_subDelivery call BIS_fnc_taskState) != _deliveryState) then {
            [_subDelivery, _deliveryState, true] call BIS_fnc_taskSetState;
        };
    };

    // Ensure parent task is ASSIGNED if sticky
    if (([_parentTaskID] call BIS_fnc_taskExists) && { (_parentTaskID call BIS_fnc_taskState) != "ASSIGNED" }) then {
        [_parentTaskID, "ASSIGNED", false] call BIS_fnc_taskSetState;
    };

    // Lock active 3D HUD waypoint onto the current leg sub-task
    private _activeSub = if (_isLoaded) then { _subDelivery } else { _subPickup };
    [_activeSub, true] call BIS_fnc_taskSetCurrent;
    private _realActive = [_activeSub, player] call BIS_fnc_taskReal;
    if (!isNull _realActive) then {
        player setCurrentTask _realActive;
    };
};

logi_fnc_getVehicleRoles = {
    params ["_vehType"];
    private _roles = ["Tactical", "Strategic", "CLT"];
    private _roleIdx = logisticsVehicleRoles findIf { (_x # 0) == _vehType };
    if (_roleIdx != -1) then {
        private _roleConfig = (logisticsVehicleRoles # _roleIdx) # 1;
        if (_roleConfig isEqualType []) then {
            if (count _roleConfig > 0) then { _roles = _roleConfig; };
        } else {
            if (_roleConfig isEqualType "") then { _roles = [_roleConfig]; };
        };
    };
    _roles
};

// =========================================================================
// CLIENT-SIDE TASK GENERATION (FILTERED BY VEHICLE ALLOWED ROLES)
// =========================================================================
createClientLogiTasks = {
    params [["_allowedRoles", ["Strategic", "Tactical", "CLT"]]];
    private _rolesUpper = _allowedRoles apply { toUpper _x };

    private _allMSRs = (missionNamespace getVariable ["logisticsBases", []]) select { "MSR" in toUpper _x };
    private _allSBs  = (missionNamespace getVariable ["logisticsBases", []]) select { "SB" in toUpper _x };
    private _allFOBs = (missionNamespace getVariable ["logisticsBases", []]) select { "FOB" in toUpper _x };

    if ("STRATEGIC" in _rolesUpper && count _allSBs > 0) then {
        if !(["Logi_Strategic_Task"] call BIS_fnc_taskExists) then {
            [player, "Logi_Strategic_Task", ["Strategic Run: Transport bulk logistics assets from the MSR Hub down to the Staging Base storage yards.", "Strategic Route", ""], [0,0,0], "CREATED", 1, false, "container", false] call BIS_fnc_taskCreate;
        };
    } else {
        {
            if ([_x] call BIS_fnc_taskExists) then { [_x] call BIS_fnc_deleteTask; };
        } forEach ["Logi_Strategic_Pickup", "Logi_Strategic_Manifest", "Logi_Strategic_Delivery", "Logi_Strategic_Task"];
    };

    if ("TACTICAL" in _rolesUpper && count _allFOBs > 0) then {
        if !(["Logi_Tactical_Task"] call BIS_fnc_taskExists) then {
            [player, "Logi_Tactical_Task", ["Tactical Run: Sort rear-line reserves at the Staging Base and distribute them to front-line FOB vectors.", "Tactical Route", ""], [0,0,0], "CREATED", 1, false, "infantry", false] call BIS_fnc_taskCreate;
        };
    } else {
        {
            if ([_x] call BIS_fnc_taskExists) then { [_x] call BIS_fnc_deleteTask; };
        } forEach ["Logi_Tactical_Pickup", "Logi_Tactical_Manifest", "Logi_Tactical_Delivery", "Logi_Tactical_Task"];
    };
};

// =========================================================================
// 1. LIVE RESOURCE HUD MANIFEST DIARY THREAD
// =========================================================================
[] spawn {
    waitUntil { !isNil "logisticsBases" };
    private _lastSbDesc = "";
    private _lastFobDesc = "";
    while { true } do {
        if (["Logi_Strategic_Task"] call BIS_fnc_taskExists) then {
            private _sbDesc = "<br/><font color='#ffffff'>Stockpile Manifest for Staging Base(s):</font><br/>";
            private _allSBs = logisticsBases select { "SB" in toUpper _x };
            {
                private _sbBase = _x;
                private _cleanName = (_sbBase splitString "_") joinString " ";
                _sbDesc = _sbDesc + format ["<br/><font color='#00aaff'>■ %1:</font>", _cleanName];
                {
                    private _points = missionNamespace getVariable [format ["LogiScore_%1_%2", _sbBase, _x], 0];
                    private _displayStr = [_points] call logi_fnc_formatPoints;
                    _sbDesc = _sbDesc + format ["<br/> - <font color='#ff8800'>%1:</font> %2 points", _x, _displayStr];
                } forEach ["Cargo", "Ammo", "Fuel", "Medical", "Repair", "Vehicle", "Troops"];
                _sbDesc = _sbDesc + "<br/>----------------------------------------<br/>";
            } forEach _allSBs;

            if (_sbDesc != _lastSbDesc) then {
                private _realStratTask = ["Logi_Strategic_Task", player] call BIS_fnc_taskReal;
                if (!isNull _realStratTask) then {
                    _realStratTask setSimpleTaskDescription [_sbDesc, "Strategic Route", ""];
                };
                _lastSbDesc = _sbDesc;
            };
        } else {
            _lastSbDesc = "";
        };

        if (["Logi_Tactical_Task"] call BIS_fnc_taskExists) then {
            private _fobMasterDesc = "<br/><font color='#ffffff'>Front-line Regional Stockpiles:</font><br/>";
            private _allFOBs = logisticsBases select { "FOB" in toUpper _x };
            {
                private _fobBase = _x;
                private _cleanName = _fobBase splitString "_";
                _fobMasterDesc = _fobMasterDesc + format ["<br/><font color='#00aaff'>■ %1:</font>", _cleanName joinString " "];
                {
                    private _points = missionNamespace getVariable [format ["LogiScore_%1_%2", _fobBase, _x], 0];
                    private _displayStr = [_points] call logi_fnc_formatPoints;
                    _fobMasterDesc = _fobMasterDesc + format ["<br/>  • %1: %2", _x, _displayStr];
                } forEach ["Cargo", "Ammo", "Fuel", "Medical", "Repair", "Vehicle", "Troops"];
                _fobMasterDesc = _fobMasterDesc + "<br/>----------------------------------------<br/>";
            } forEach _allFOBs;

            if (_fobMasterDesc != _lastFobDesc) then {
                private _realTactTask = ["Logi_Tactical_Task", player] call BIS_fnc_taskReal;
                if (!isNull _realTactTask) then {
                    _realTactTask setSimpleTaskDescription [_fobMasterDesc, "Tactical Route", ""];
                };
                _lastFobDesc = _fobMasterDesc;
            };
        } else {
            _lastFobDesc = "";
        };
        
        sleep 5;
    };
};

// =========================================================================
// 2. STICKY TASK CONTROLLER & PRIORITY-ORDERED ASSIGNMENT ENGINE
// =========================================================================
[] spawn {
    waitUntil { !isNil "logisticsBases" };
    // Initialize map marker visibility for client (combat units start with clean map)
    [false] call logi_fnc_updateMarkerSpotlight;
    private _wasLogisticsDriver = false;
    private _lastVehicle = objNull;
    private _wasLoaded = false;
    private _stickyTaskID = "";
    private _lockedAssignment = false;

    while { true } do {
        private _vehicle = vehicle player;
        
        // =====================================================================
        // CATASTROPHIC LOSS SAFETY NET
        // If the logistics transport is blown up or vanishes, force a total
        // state purge immediately so the driver loop unfreezes.
        // =====================================================================
        if (_wasLogisticsDriver && (!alive _vehicle || isNull _vehicle)) then {
            call logi_fnc_clearAllLogiTasks;
            [false] call logi_fnc_updateMarkerSpotlight;
            _wasLogisticsDriver = false;
            _lastVehicle = objNull;
            _wasLoaded = false;
            _stickyTaskID = "";
            _lockedAssignment = false;
            player setVariable ["logistics_current_assigned_category", "", true];
            systemChat "LOGISTICS ALERT: Asset link severed due to vehicle destruction. Manifest purged.";
        };

        private _isLogisticsDriver = (_vehicle != player && { typeOf _vehicle in allowedLogisticsVehicles && driver _vehicle == player && alive _vehicle });

        if (!_isLogisticsDriver && _wasLogisticsDriver) then {
            call logi_fnc_clearAllLogiTasks;
            [false] call logi_fnc_updateMarkerSpotlight;
            _wasLogisticsDriver = false;
            _lastVehicle = objNull;
            _wasLoaded = false;
            _stickyTaskID = "";
            _lockedAssignment = false;
            systemChat "LOGISTICS ENGINE: Logistics tasks cleared from HUD.";
        };

        if (_isLogisticsDriver) then {
            private _vehType = typeOf _vehicle;
            private _vehicleRoles = [_vehType] call logi_fnc_getVehicleRoles;

            if (!_wasLogisticsDriver || _vehicle != _lastVehicle) then {
                call logi_fnc_clearAllLogiTasks;
                [_vehicleRoles] call createClientLogiTasks;
                [true] call logi_fnc_updateMarkerSpotlight;
                _wasLogisticsDriver = true;
                _lastVehicle = _vehicle;
                _wasLoaded = false;
                _stickyTaskID = "";
                _lockedAssignment = false;
                systemChat "LOGISTICS ENGINE: Routing assets mapped to navigation system.";
            };

            private _templateIndex = allowedLogisticsVehicles find _vehType;
            private _entry = logisticsCargoTemplates # _templateIndex;
            private _cargoListConfig = if (count _entry > 2 && { (_entry # 2) isEqualType [] }) then { _entry # 2 } else { _entry # 1 };
            
            private _allowedVehicleCategories = [];
            {
                private _catName = _x # 0;
                if (_catName != "Mixed") then { _allowedVehicleCategories pushBack _catName; };
            } forEach _cargoListConfig;

            private _isInternalLoaded = _vehicle getVariable ["logistics_is_loaded", false];
            private _hasSlingLoadAttached = !isNull (getSlingLoad _vehicle);
            private _isLoaded = (_isInternalLoaded || _hasSlingLoadAttached);

            // Detect load state transitions
            if (_wasLoaded && !_isLoaded) then {
                private _targetBase = _vehicle getVariable ["logistics_intended_fob", ""];
                private _dropoffPos = [0,0,0];
                if (_targetBase != "") then {
                    ([_vehicle, _targetBase] call logi_fnc_getDropoffLocation) params ["", "_pos"];
                    _dropoffPos = _pos;
                };

                private _isNearDropoff = (_dropoffPos distance2D [0,0,0] > 10) && { (_vehicle distance2D _dropoffPos) <= 150 };

                // Alternate-Base Delivery Recognition: Check if unloaded at intended dropoff OR any other friendly base dropoff pad
                private _deliveredBase = "";
                if (_isNearDropoff) then {
                    _deliveredBase = _targetBase;
                } else {
                    {
                        private _baseName = _x;
                        ([_vehicle, _baseName] call logi_fnc_getDropoffLocation) params ["", "_bPos"];
                        if (_bPos distance2D [0,0,0] > 10 && { (_vehicle distance2D _bPos) <= 150 }) exitWith {
                            _deliveredBase = _baseName;
                        };
                    } forEach (missionNamespace getVariable ["logisticsBases", []]);
                };

                if (_deliveredBase != "" && _stickyTaskID != "") then {
                    // Successful delivery! Mark Delivery sub-task and Parent task SUCCEEDED
                    private _subDelivery = _stickyTaskID + "_Delivery";
                    if ([_subDelivery] call BIS_fnc_taskExists) then {
                        [_subDelivery, "SUCCEEDED", true] call BIS_fnc_taskSetState;
                    };
                    if ([_stickyTaskID] call BIS_fnc_taskExists) then {
                        [_stickyTaskID, "SUCCEEDED", true] call BIS_fnc_taskSetState;
                    };
                    
                    private _routeDisplayName = if (_stickyTaskID == "Logi_Strategic_Task") then {"Strategic Route"} else {"Tactical Route"};
                    if (_deliveredBase == _targetBase) then {
                        systemChat format ["LOGISTICS ENGINE: %1 completed successfully! Cycling next assignment...", _routeDisplayName];
                    } else {
                        systemChat format ["LOGISTICS ENGINE: %1 rerouted to %2 and completed successfully! Cycling next assignment...", _routeDisplayName, _deliveredBase splitString "_" joinString " "];
                    };

                    // Reset sub-tasks and reset parent task state for the next run
                    [_stickyTaskID] call logi_fnc_deleteRouteSubTasks;
                    if ([_stickyTaskID] call BIS_fnc_taskExists) then {
                        [_stickyTaskID, "CREATED", false] call BIS_fnc_taskSetState;
                    };
                    _stickyTaskID = "";
                    _lockedAssignment = false;
                    _vehicle setVariable ["logistics_intended_fob", "", true];
                    player setVariable ["logistics_current_assigned_category", "", true];
                    [true] call logi_fnc_updateMarkerSpotlight;
                } else {
                    if (_stickyTaskID != "") then {
                        // Unloaded prematurely outside delivery zone!
                        systemChat "LOGISTICS ALERT: Cargo detached or unloaded outside designated delivery zone!";
                        private _subManifest = _stickyTaskID + "_Manifest";
                        private _subPickup   = _stickyTaskID + "_Pickup";
                        private _subDelivery = _stickyTaskID + "_Delivery";

                        if ([_subManifest] call BIS_fnc_taskExists) then {
                            [_subManifest, [format ["Cargo was dropped or detached before reaching delivery zone.<br/>Return to %1 to reload cargo.", _targetBase splitString "_" joinString " "], "2. Manifest: [DETACHED / LOST]", ""]] call BIS_fnc_taskSetDescription;
                            [_subManifest, "CREATED", false] call BIS_fnc_taskSetState;
                        };
                        if ([_subDelivery] call BIS_fnc_taskExists) then {
                            [_subDelivery, "CREATED", false] call BIS_fnc_taskSetState;
                        };
                        if ([_subPickup] call BIS_fnc_taskExists) then {
                            [_subPickup, "ASSIGNED", true] call BIS_fnc_taskSetState;
                            [_subPickup, true] call BIS_fnc_taskSetCurrent;
                            private _realSubPickup = [_subPickup, player] call BIS_fnc_taskReal;
                            if (!isNull _realSubPickup) then { player setCurrentTask _realSubPickup; };
                        };
                        _lockedAssignment = false;
                    };
                };
            };
            if (!_wasLoaded && _isLoaded) then {
                // Pickup completed (unloaded -> loaded): unlock destination once to transition to dropoff leg
                _lockedAssignment = false;
            };
            _wasLoaded = _isLoaded;

            // Respect manual task switching if the player explicitly clicked "Assign" on another task in the native Map UI
            private _realCurrentTask = currentTask player;
            private _engineCurrentTask = "";
            if (!isNull _realCurrentTask) then {
                {
                    private _baseTask = _x;
                    if ([_baseTask] call BIS_fnc_taskExists && { _realCurrentTask isEqualTo ([_baseTask, player] call BIS_fnc_taskReal) }) exitWith {
                        _engineCurrentTask = _baseTask;
                    };
                    // Also check if player clicked on one of the sub-tasks!
                    {
                        private _sId = format ["%1_%2", _baseTask, _x];
                        if ([_sId] call BIS_fnc_taskExists && { _realCurrentTask isEqualTo ([_sId, player] call BIS_fnc_taskReal) }) exitWith {
                            _engineCurrentTask = _baseTask;
                        };
                    } forEach ["Pickup", "Manifest", "Delivery"];
                } forEach ["Logi_Strategic_Task", "Logi_Tactical_Task", "Logi_CLT_Task"];
            };

            if (_engineCurrentTask != "" && _engineCurrentTask != _stickyTaskID) then {
                if (_stickyTaskID != "") then {
                    // Reset old task and remove its active sub-tasks
                    if ([_stickyTaskID] call BIS_fnc_taskExists) then {
                        [_stickyTaskID, "CREATED", false] call BIS_fnc_taskSetState;
                    };
                    [_stickyTaskID] call logi_fnc_deleteRouteSubTasks;
                    _stickyTaskID = _engineCurrentTask;
                    [_stickyTaskID, "ASSIGNED", false] call BIS_fnc_taskSetState;
                    _lockedAssignment = false;
                    systemChat format ["LOGISTICS ENGINE: Route manually switched to [%1].", _stickyTaskID];
                };
            };

            // Auto-select next available task according to vehicle's role priority order ONLY when no sticky task is active
            if (_stickyTaskID == "" || !([_stickyTaskID] call BIS_fnc_taskExists)) then {
                {
                    private _roleUpper = toUpper _x;
                    if (_roleUpper == "CLT" && { ["Logi_CLT_Task"] call BIS_fnc_taskExists }) exitWith {
                        _stickyTaskID = "Logi_CLT_Task";
                    };
                    if (_roleUpper == "STRATEGIC" && { ["Logi_Strategic_Task"] call BIS_fnc_taskExists }) exitWith {
                        _stickyTaskID = "Logi_Strategic_Task";
                    };
                    if (_roleUpper == "TACTICAL" && { ["Logi_Tactical_Task"] call BIS_fnc_taskExists }) exitWith {
                        _stickyTaskID = "Logi_Tactical_Task";
                    };
                } forEach _vehicleRoles;

                if (_stickyTaskID != "") then {
                    {
                        if (_x != _stickyTaskID && { [_x] call BIS_fnc_taskExists }) then {
                            [_x, "CREATED", false] call BIS_fnc_taskSetState;
                            [_x] call logi_fnc_deleteRouteSubTasks;
                        };
                    } forEach ["Logi_Strategic_Task", "Logi_Tactical_Task", "Logi_CLT_Task"];
                    [_stickyTaskID, "ASSIGNED", true] call BIS_fnc_taskSetState;
                    _lockedAssignment = false;
                };
            };

            private _allMSRs = logisticsBases select { "MSR" in toUpper _x };
            private _allSBs  = logisticsBases select { "SB" in toUpper _x };
            private _allFOBs = logisticsBases select { "FOB" in toUpper _x };

            private _isGroundVehicle = !(_vehicle isKindOf "Air") && !(_vehicle isKindOf "Ship");
            private _isNavalVehicle  = _vehicle isKindOf "Ship";

            // Filter pickup candidates by terrain type (land vs. water) before selecting nearest MSR and SB
            private _pickupMSRs = _allMSRs;
            if (_isGroundVehicle) then {
                private _landMSRs = _allMSRs select { !surfaceIsWater (["Pickup", _x, _x] call logi_fnc_getMarkerPosSafe) };
                if (count _landMSRs > 0) then { _pickupMSRs = _landMSRs; };
            };
            if (_isNavalVehicle) then {
                private _waterMSRs = _allMSRs select { surfaceIsWater (["Pickup", _x, _x] call logi_fnc_getMarkerPosSafe) };
                if (count _waterMSRs > 0) then { _pickupMSRs = _waterMSRs; };
            };
            private _sortedMSRs = _pickupMSRs apply { [_vehicle distance2D (["Pickup", _x, _x] call logi_fnc_getMarkerPosSafe), _x] };
            _sortedMSRs sort true;
            private _primaryMSR = if (count _sortedMSRs > 0) then { (_sortedMSRs # 0) # 1 } else { "MSR" };

            private _pickupSBs = _allSBs;
            if (_isGroundVehicle) then {
                private _landPickupSBs = _allSBs select { !surfaceIsWater (["Pickup", _x, _x] call logi_fnc_getMarkerPosSafe) };
                if (count _landPickupSBs > 0) then { _pickupSBs = _landPickupSBs; };
            };
            if (_isNavalVehicle) then {
                private _waterPickupSBs = _allSBs select { surfaceIsWater (["Pickup", _x, _x] call logi_fnc_getMarkerPosSafe) };
                if (count _waterPickupSBs > 0) then { _pickupSBs = _waterPickupSBs; };
            };
            private _sortedSBs = _pickupSBs apply { [_vehicle distance2D (["Pickup", _x, _x] call logi_fnc_getMarkerPosSafe), _x] };
            _sortedSBs sort true;
            private _primarySB = if (count _sortedSBs > 0) then { (_sortedSBs # 0) # 1 } else { "SB" };

            // --- ROUTING ENGINE (STICKY UNTIL CURRENT TASK COMPLETES) ---
            if (_stickyTaskID == "Logi_Strategic_Task") then {
                if (!_lockedAssignment) then {
                    // Ground vehicles cannot drive to ocean-based SBs; naval vessels cannot sail to inland SBs
                    private _candidateSBs = _allSBs;
                    if (_isGroundVehicle) then {
                        private _landSBs = _allSBs select { !surfaceIsWater (["Dropoff", _x, _x] call logi_fnc_getMarkerPosSafe) };
                        if (count _landSBs > 0) then { _candidateSBs = _landSBs; };
                    };
                    if (_isNavalVehicle) then {
                        private _waterSBs = _allSBs select { surfaceIsWater (["Dropoff", _x, _x] call logi_fnc_getMarkerPosSafe) };
                        if (count _waterSBs > 0) then { _candidateSBs = _waterSBs; };
                    };

                    // Sort candidate SBs by route distance from origin MSR (road distance for land, flight for air)
                    private _orderedSBs = (_candidateSBs apply { 
                        private _dist = [_primaryMSR, _x, _isGroundVehicle] call logi_fnc_getRouteDistance;
                        [_dist, _x] 
                    });
                    _orderedSBs sort true;
                    _candidateSBs = _orderedSBs apply { _x # 1 };

                    // Preserve existing intended SB if vehicle is already loaded
                    private _savedSB = _vehicle getVariable ["logistics_intended_fob", ""];
                    private _targetSB = if (_isLoaded && _savedSB != "" && _savedSB in _candidateSBs) then {
                        _savedSB
                    } else {
                        _candidateSBs param [0, _primarySB]
                    };

                    private _lowestCategory = _allowedVehicleCategories param [0, "Cargo"];
                    private _lowestScore = 999999999;

                    if (!_isLoaded || _savedSB == "") then {
                        {
                            private _sb = _x;
                            {
                                private _score = missionNamespace getVariable [format ["LogiScore_%1_%2", _sb, _x], 0];
                                if (_score != -1 && _score < _lowestScore) then {
                                    _lowestScore = _score;
                                    _targetSB = _sb;
                                    _lowestCategory = _x;
                                };
                            } forEach _allowedVehicleCategories;
                        } forEach _candidateSBs;
                    } else {
                        _lowestCategory = player getVariable ["logistics_current_assigned_category", _allowedVehicleCategories param [0, "Cargo"]];
                    };

                    _vehicle setVariable ["logistics_intended_fob", _targetSB, true];
                    player setVariable ["logistics_current_assigned_category", _lowestCategory, true];

                    // Deploy / update the 3-tier sub-task hierarchy for this leg
                    ["Logi_Strategic_Task", _primaryMSR, _targetSB, _lowestCategory, _isLoaded, _vehicle] call logi_fnc_updateRouteTasks;

                    _lockedAssignment = true;
                };
            };

            if (_stickyTaskID == "Logi_Tactical_Task") then {
                if (!_lockedAssignment && count _allFOBs > 0) then {
                    // Ground vehicles cannot drive to ocean-based FOBs (e.g. Destroyers); naval vessels cannot sail to inland FOBs
                    private _candidateFOBs = _allFOBs;
                    if (_isGroundVehicle) then {
                        private _landFOBs = _allFOBs select { !surfaceIsWater (["Dropoff", _x, _x] call logi_fnc_getMarkerPosSafe) };
                        if (count _landFOBs > 0) then { _candidateFOBs = _landFOBs; };
                    };
                    if (_isNavalVehicle) then {
                        private _waterFOBs = _allFOBs select { surfaceIsWater (["Dropoff", _x, _x] call logi_fnc_getMarkerPosSafe) };
                        if (count _waterFOBs > 0) then { _candidateFOBs = _waterFOBs; };
                    };

                    // Sort candidate FOBs by route travel distance from origin SB (road distance for land, flight for air)
                    private _orderedFOBs = (_candidateFOBs apply { 
                        private _dist = [_primarySB, _x, _isGroundVehicle] call logi_fnc_getRouteDistance;
                        [_dist, _x] 
                    });
                    _orderedFOBs sort true;
                    _candidateFOBs = _orderedFOBs apply { _x # 1 };

                    // Preserve existing intended FOB if vehicle is already loaded
                    private _savedFOB = _vehicle getVariable ["logistics_intended_fob", ""];
                    private _targetFOB = if (_isLoaded && _savedFOB != "" && _savedFOB in _candidateFOBs) then {
                        _savedFOB
                    } else {
                        _candidateFOBs # 0
                    };

                    private _targetCategory = _allowedVehicleCategories param [0, "Cargo"];
                    private _lowestScore = 999999999;

                    if (!_isLoaded || _savedFOB == "") then {
                        {
                            private _fob = _x;
                            {
                                private _category = _x;
                                private _score = missionNamespace getVariable [format ["LogiScore_%1_%2", _fob, _category], 0];
                                if (_score != -1 && _score < _lowestScore) then {
                                    _lowestScore = _score;
                                    _targetFOB = _fob;
                                    _targetCategory = _category;
                                };
                            } forEach _allowedVehicleCategories;
                        } forEach _candidateFOBs;
                    } else {
                        _targetCategory = player getVariable ["logistics_current_assigned_category", _allowedVehicleCategories param [0, "Cargo"]];
                    };

                    _vehicle setVariable ["logistics_intended_fob", _targetFOB, true];
                    player setVariable ["logistics_current_assigned_category", _targetCategory, true];

                    // Deploy / update the 3-tier sub-task hierarchy for this leg
                    ["Logi_Tactical_Task", _primarySB, _targetFOB, _targetCategory, _isLoaded, _vehicle] call logi_fnc_updateRouteTasks;

                    _lockedAssignment = true;
                };
            };
        };
        sleep 1;
    };
};