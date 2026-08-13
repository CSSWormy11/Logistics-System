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
// CLIENT-SIDE TASK GENERATION (SIMPLIFIED TO SINGLE CONTINUOUS WAYPOINTS)
// =========================================================================
createClientLogiTasks = {
    [player, "Logi_Strategic_Task", ["Strategic Run: Transport bulk logistics assets from the MSR Hub down to the Staging Base storage yards.", "Strategic Route", ""], getMarkerPos "Pickup_MSR", "CREATED", 1, false, "container", false] call BIS_fnc_taskCreate;
    [player, "Logi_Tactical_Task", ["Tactical Run: Sort rear-line reserves at the Staging Base and distribute them to front-line FOB vectors.", "Tactical Route", ""], getMarkerPos "Pickup_SB", "CREATED", 1, false, "infantry", false] call BIS_fnc_taskCreate;
};

// =========================================================================
// 1. LIVE RESOURCE HUD MANIFEST DIARY THREAD
// =========================================================================
[] spawn {
    while { true } do {
        if (["Logi_Strategic_Task"] call BIS_fnc_taskExists) then {
            // FIX: Removed invalid <font size> attributes that caused DiaryParser RPT errors
            private _sbDesc = "<br/><font color='#ffffff'>Stockpile Manifest for Staging Base:</font><br/>";
            {
                private _points = missionNamespace getVariable [format ["LogiScore_SB_%1", _x], 0];
                private _displayStr = [_points] call logi_fnc_formatPoints;
                _sbDesc = _sbDesc + format ["<br/> - <font color='#ff8800'>%1:</font> %2 points", _x, _displayStr];
            } forEach ["Cargo", "Ammo", "Fuel", "Medical", "Repair", "Vehicle", "Troops"];
            ["Logi_Strategic_Task", [_sbDesc, "Strategic Route", ""]] call BIS_fnc_taskSetDescription;
        };

        if (["Logi_Tactical_Task"] call BIS_fnc_taskExists) then {
            private _fobMasterDesc = "<br/><font color='#ffffff'>Front-line Regional Stockpiles:</font><br/>";
            private _allFOBs = logisticsBases select { "FOB" in _x };
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
            ["Logi_Tactical_Task", [_fobMasterDesc, "Tactical Route", ""]] call BIS_fnc_taskSetDescription;
        };
        
        sleep 5;
    };
};

// =========================================================================
// 2. STICKY TASK CONTROLLER & DYNAMIC ASSIGNMENT ENGINE
// =========================================================================
[] spawn {
    private _wasLogisticsDriver = false;

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
            player setVariable ["logistics_current_assigned_category", "", true];
            systemChat "LOGISTICS ALERT: Asset link severed due to vehicle destruction. Manifest purged.";
        };

        // CRITICAL FIX: Exclude Helicopters, Planes, and Light Vehicles from math-driven UI spam.
        // They will exclusively rely on the GIN [CLT] Combat Tasking systems instead.
        private _isLogisticsDriver = (_vehicle != player && {typeOf _vehicle in allowedLogisticsVehicles && driver _vehicle == player && alive _vehicle && !(_vehicle isKindOf "Air") && getMass _vehicle > 4000});

        if (_isLogisticsDriver && !_wasLogisticsDriver) then {
            call createClientLogiTasks;
            _wasLogisticsDriver = true;
            systemChat "LOGISTICS ENGINE: Routing assets mapped to navigation system.";
        };

        if (!_isLogisticsDriver && _wasLogisticsDriver) then {
            "" call BIS_fnc_taskSetCurrent;
            ["Logi_Strategic_Task"] call BIS_fnc_deleteTask;
            ["Logi_Tactical_Task"] call BIS_fnc_deleteTask;
            _wasLogisticsDriver = false;
            systemChat "LOGISTICS ENGINE: Logistics tasks cleared from HUD.";
        };

        if (_isLogisticsDriver) then {
            private _vehType = typeOf _vehicle;
            private _templateIndex = allowedLogisticsVehicles find _vehType;
            private _cargoListConfig = (logisticsCargoTemplates # _templateIndex) # 1;
            
            private _allowedVehicleCategories = [];
            {
                private _catName = _x # 0;
                if (_catName != "Mixed") then { _allowedVehicleCategories pushBack _catName; };
            } forEach _cargoListConfig;

            private _assignedRoleOverride = "Tactical"; 
            private _roleIdx = logisticsVehicleRoles findIf { _x # 0 == _vehType };
            if (_roleIdx != -1) then { _assignedRoleOverride = (logisticsVehicleRoles # _roleIdx) # 1; };

            private _isInternalLoaded = _vehicle getVariable ["logistics_is_loaded", false];
            private _hasSlingLoadAttached = !isNull (getSlingLoad _vehicle);
            private _isLoaded = (_isInternalLoaded || _hasSlingLoadAttached);

            // --- ROUTING ENGINE ---
            if (_assignedRoleOverride == "Strategic") then {
                if ((player call BIS_fnc_taskCurrent) != "Logi_Strategic_Task") then { ["Logi_Strategic_Task", true] call BIS_fnc_taskSetCurrent; };
                
                if (!_isLoaded) then {
                    private _lowestCategory = _allowedVehicleCategories # 0;
                    private _lowestScore = 999999999;
                    {
                        private _score = missionNamespace getVariable [format ["LogiScore_SB_%1", _x], 0];
                        if (_score != -1 && _score < _lowestScore) then { _lowestScore = _score; _lowestCategory = _x; };
                    } forEach _allowedVehicleCategories;

                    ["Logi_Strategic_Task", getMarkerPos "Pickup_MSR"] call BIS_fnc_taskSetDestination;
                    player setVariable ["logistics_current_assigned_category", _lowestCategory, true];
                } else {
                    ["Logi_Strategic_Task", getMarkerPos "Dropoff_SB"] call BIS_fnc_taskSetDestination;
                };
            } else {
                if ((player call BIS_fnc_taskCurrent) != "Logi_Tactical_Task") then { ["Logi_Tactical_Task", true] call BIS_fnc_taskSetCurrent; };

                if (!_isLoaded) then {
                    private _allFOBs = logisticsBases select { "FOB" in _x };
                    if (count _allFOBs > 0) then {
                        private _targetFOB = _allFOBs # 0;
                        private _targetCategory = _allowedVehicleCategories # 0;
                        private _lowestScore = 999999999;

                        {
                            private _fob = _x;
                            {
                                private _category = _x;
                                private _score = missionNamespace getVariable [format ["LogiScore_%1_%2", _fob, _category], 0];
                                if (_score < _lowestScore) then { _lowestScore = _score; _targetFOB = _fob; _targetCategory = _category; };
                            } forEach _allowedVehicleCategories;
                        } forEach _allFOBs;

                        ["Logi_Tactical_Task", getMarkerPos "Pickup_SB"] call BIS_fnc_taskSetDestination;
                        _vehicle setVariable ["logistics_intended_fob", _targetFOB, true];
                        player setVariable ["logistics_current_assigned_category", _targetCategory, true];
                    };
                } else {
                    private _targetFOB = _vehicle getVariable ["logistics_intended_fob", "FOB_Hill105"];
                    ["Logi_Tactical_Task", getMarkerPos (format ["Dropoff_%1", _targetFOB])] call BIS_fnc_taskSetDestination;
                };
            };
        };
        sleep 1;
    };
};