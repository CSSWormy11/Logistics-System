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
// GLOBAL STRING FORMATTER: BANISHES SCIENTIFIC NOTATION PERMANENTLY
// =========================================================================
logi_fnc_formatPoints = {
    params ["_num"];
    if (_num == -1) exitWith { "UNLIMITED" };
    
    private _integer = floor _num;
    private _str = str _integer;
    
    if ((_str find "e") != -1) then {
        private _parts = _str splitString "e+";
        private _base = _parts # 0;
        private _exponent = parseNumber (_parts # 1);
        private _cleanBase = (_base splitString ".") joinString "";
        while {count _cleanBase <= _exponent} do { _cleanBase = _cleanBase + "0"; };
        _str = _cleanBase;
    };
    
    private _arr = _str splitString "";
    private _res = "";
    private _cnt = 0;
    for "_i" from (count _arr - 1) to 0 step -1 do {
        if (_cnt > 0 && _cnt % 3 == 0) then { _res = "," + _res; };
        _res = (_arr # _i) + _res;
        _cnt = _cnt + 1;
    };
    _res
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

    private _sortedMSRs = _allMSRs apply { [(vehicle player) distance2D (["Pickup", _x, _x] call logi_fnc_getMarkerPosSafe), _x] };
    _sortedMSRs sort true;
    private _primaryMSR = if (count _sortedMSRs > 0) then { (_sortedMSRs # 0) # 1 } else { "MSR" };

    private _sortedSBs = _allSBs apply { [(vehicle player) distance2D (["Pickup", _x, _x] call logi_fnc_getMarkerPosSafe), _x] };
    _sortedSBs sort true;
    private _primarySB  = if (count _sortedSBs > 0) then { (_sortedSBs # 0) # 1 } else { "SB" };

    if ("STRATEGIC" in _rolesUpper && count _allSBs > 0) then {
        if !(["Logi_Strategic_Task"] call BIS_fnc_taskExists) then {
            private _msrPickupPos = ["Pickup", _primaryMSR, "Pickup_MSR"] call logi_fnc_getMarkerPosSafe;
            [player, "Logi_Strategic_Task", ["Strategic Run: Transport bulk logistics assets from the MSR Hub down to the Staging Base storage yards.", "Strategic Route", ""], _msrPickupPos, "CREATED", 1, false, "container", false] call BIS_fnc_taskCreate;
        };
    } else {
        if (["Logi_Strategic_Task"] call BIS_fnc_taskExists) then { ["Logi_Strategic_Task"] call BIS_fnc_deleteTask; };
    };

    if ("TACTICAL" in _rolesUpper && count _allFOBs > 0) then {
        if !(["Logi_Tactical_Task"] call BIS_fnc_taskExists) then {
            private _sbPickupPos = ["Pickup", _primarySB, "Pickup_SB"] call logi_fnc_getMarkerPosSafe;
            [player, "Logi_Tactical_Task", ["Tactical Run: Sort rear-line reserves at the Staging Base and distribute them to front-line FOB vectors.", "Tactical Route", ""], _sbPickupPos, "CREATED", 1, false, "infantry", false] call BIS_fnc_taskCreate;
        };
    } else {
        if (["Logi_Tactical_Task"] call BIS_fnc_taskExists) then { ["Logi_Tactical_Task"] call BIS_fnc_deleteTask; };
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
            "" call BIS_fnc_taskSetCurrent;
            ["Logi_Strategic_Task"] call BIS_fnc_deleteTask;
            ["Logi_Tactical_Task"] call BIS_fnc_deleteTask;
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
            "" call BIS_fnc_taskSetCurrent;
            ["Logi_Strategic_Task"] call BIS_fnc_deleteTask;
            ["Logi_Tactical_Task"] call BIS_fnc_deleteTask;
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
                [_vehicleRoles] call createClientLogiTasks;
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
                // Delivery completed (loaded -> unloaded): reset to vehicle's default priority task for next run
                _stickyTaskID = "";
                _lockedAssignment = false;
            };
            if (!_wasLoaded && _isLoaded) then {
                // Pickup completed (unloaded -> loaded): keep current task, unlock destination once to point to dropoff
                _lockedAssignment = false;
            };
            _wasLoaded = _isLoaded;

            // Respect manual task switching if the player explicitly clicked "Assign" on another task in the native Map UI
            // Note: The native Map UI updates `currentTask player` (the engine TASK handle), NOT `BIS_fnc_taskCurrent`!
            private _realCurrentTask = currentTask player;
            private _engineCurrentTask = "";
            if (!isNull _realCurrentTask) then {
                {
                    if ([_x] call BIS_fnc_taskExists && { _realCurrentTask isEqualTo ([_x, player] call BIS_fnc_taskReal) }) exitWith {
                        _engineCurrentTask = _x;
                    };
                } forEach ["Logi_Strategic_Task", "Logi_Tactical_Task", "Logi_CLT_Task"];
            };

            if (_engineCurrentTask != "" && _engineCurrentTask != _stickyTaskID) then {
                if (_stickyTaskID != "") then {
                    // Synchronize BIS_fnc_setTask internal state so subsequent destination updates never revert the player's choice
                    if ([_stickyTaskID] call BIS_fnc_taskExists) then {
                        [_stickyTaskID, "CREATED", false] call BIS_fnc_taskSetState;
                    };
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

                    // Sort candidate SBs by distance so ties pick the nearest Supply Base
                    private _orderedSBs = (_candidateSBs apply { [_vehicle distance2D (["Dropoff", _x, _x] call logi_fnc_getMarkerPosSafe), _x] });
                    _orderedSBs sort true;
                    _candidateSBs = _orderedSBs apply { _x # 1 };

                    private _targetSB = _candidateSBs param [0, _primarySB];
                    private _lowestCategory = _allowedVehicleCategories param [0, "Cargo"];
                    private _lowestScore = 999999999;
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

                    _vehicle setVariable ["logistics_intended_fob", _targetSB, true];
                    if (!_isLoaded) then {
                        private _pickupPos = ["Pickup", _primaryMSR, "Pickup_MSR"] call logi_fnc_getMarkerPosSafe;
                        ["Logi_Strategic_Task", _pickupPos] call BIS_fnc_taskSetDestination;
                        player setVariable ["logistics_current_assigned_category", _lowestCategory, true];
                    } else {
                        private _dropoffPos = ["Dropoff", _targetSB, "Dropoff_SB"] call logi_fnc_getMarkerPosSafe;
                        ["Logi_Strategic_Task", _dropoffPos] call BIS_fnc_taskSetDestination;
                    };
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

                    // Sort candidate FOBs by distance so ties pick the nearest FOB
                    private _orderedFOBs = (_candidateFOBs apply { [_vehicle distance2D (["Dropoff", _x, _x] call logi_fnc_getMarkerPosSafe), _x] });
                    _orderedFOBs sort true;
                    _candidateFOBs = _orderedFOBs apply { _x # 1 };

                    private _targetFOB = _candidateFOBs # 0;
                    private _targetCategory = _allowedVehicleCategories param [0, "Cargo"];
                    private _lowestScore = 999999999;

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

                    _vehicle setVariable ["logistics_intended_fob", _targetFOB, true];
                    if (!_isLoaded) then {
                        private _pickupPos = ["Pickup", _primarySB, "Pickup_SB"] call logi_fnc_getMarkerPosSafe;
                        ["Logi_Tactical_Task", _pickupPos] call BIS_fnc_taskSetDestination;
                        player setVariable ["logistics_current_assigned_category", _targetCategory, true];
                    } else {
                        private _dropoffPos = ["Dropoff", _targetFOB, ""] call logi_fnc_getMarkerPosSafe;
                        ["Logi_Tactical_Task", _dropoffPos] call BIS_fnc_taskSetDestination;
                    };
                    _lockedAssignment = true;
                };
            };
        };
        sleep 1;
    };
};