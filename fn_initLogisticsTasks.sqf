// ============================================================================
// LOGISTICS SYSTEM: TRANSPORT TASK INITIALIZATION (PART 1)
// File: fn_initLogisticsTasks.sqf
// Description: Startup setup script. Scans editor triggers and bases, 
//              normalizes legacy trigger onActivation script references while
//              preserving mission-maker trigger conditions, combines multi-trigger
//              pickup zones under a unified countdown HUD, and creates map markers
//              (including exact trigger bounding-box area overlays).
// Called By: init.sqf
// ============================================================================

LOGI_fnc_handlePickupTrigger = {
    params [
        ["_vehicle", objNull, [objNull]],
        ["_parentBase", "", [""]],
        ["_sourceTrigger", objNull, [objNull]]
    ];

    if (isNull _vehicle || _parentBase == "") exitWith {};

    // Normalize base key in case a numbered trigger passed "<Base>_pickup"
    private _pLower = toLowerANSI _parentBase;
    private _pIdx = _pLower find "_pickup";
    if (_pIdx != -1) then { _parentBase = _parentBase select [0, _pIdx]; };

    // Do not start a duplicate load if already loaded
    if (_vehicle getVariable ["logistics_is_loaded", false]) exitWith {};

    // Read timeout configured on THIS specific trigger (allowing air triggers to have a timer while ground/ship triggers are instant or shorter)
    private _timeoutCfg = if (!isNull _sourceTrigger) then {
        _sourceTrigger getVariable ["LogiTriggerTimeout", [0, 0, 0, false]]
    } else {
        missionNamespace getVariable [format ["LogiPickupTimeout_%1", _parentBase], [0, 0, 0, false]]
    };
    _timeoutCfg params [["_tMin", 0], ["_tMid", 0], ["_tMax", 0], ["_tInterrupt", true]];

    private _duration = 0;
    if (_tMax > 0 || _tMid > 0 || _tMin > 0) then {
        _duration = round (random [_tMin, _tMid, _tMax]);
    };

    // If vehicle is already in a timed countdown from an adjacent trigger (e.g. flew into MSR_pickup_1 then landed in instant MSR_pickup_3):
    if (_vehicle getVariable ["logistics_is_loading", false]) exitWith {
        if (_duration <= 0) then {
            _vehicle setVariable ["logistics_skip_timer", true, true];
        };
    };

    // Instant pickup if this trigger has no countdown configured
    if (_duration <= 0) exitWith {
        [_vehicle, _parentBase] execVM "fn_spawnLoadSupply.sqf";
    };

    private _baseTriggers = missionNamespace getVariable [format ["LogiPickupTriggers_%1", _parentBase], []];
    if (!isNull _sourceTrigger) then { _baseTriggers pushBackUnique _sourceTrigger; };

    private _triggerCond = if (!isNull _sourceTrigger) then {
        toLowerANSI (_sourceTrigger getVariable ["LogiTriggerCond", ""])
    } else { "" };

    private _maxAllowedSpeed = -1; // -1 = no speed limit (e.g. flying Planes in MSR_pickup_1/2)
    if ("speed _x == 0" in _triggerCond || "speed _x < 1" in _triggerCond) then {
        _maxAllowedSpeed = 1.5;
    } else {
        if ("speed _x < 10" in _triggerCond) then {
            _maxAllowedSpeed = 10;
        };
    };

    // Unified countdown across all pickup triggers belonging to this base
    [_vehicle, _parentBase, _baseTriggers, _duration, _tInterrupt, _maxAllowedSpeed] spawn {
        params ["_veh", "_baseKey", "_trigList", "_totalSec", "_interruptable", "_speedLimit"];

        _veh setVariable ["logistics_is_loading", true, true];
        _veh setVariable ["logistics_skip_timer", false, true];
        private _displayName = (_baseKey splitString "_") joinString " ";
        private _cancelled = false;

        private _instructionText = if (_speedLimit < 0) then {
            "Stay inside the marked zone"
        } else {
            if (_speedLimit <= 1.5) then {
                "Remain stopped inside zone"
            } else {
                format ["Hold speed < %1 km/h in zone", round _speedLimit]
            }
        };

        for "_rem" from _totalSec to 1 step -1 do {
            if (!alive _veh || (_veh getVariable ["logistics_is_loaded", false])) exitWith {
                _cancelled = true;
            };

            // If player landed/stopped inside an instant pickup trigger of the same base, complete immediately
            if (_veh getVariable ["logistics_skip_timer", false]) exitWith {};

            // Check if vehicle is inside ANY of this base's pickup triggers and within the trigger's speed requirement
            private _inAnyZone = ({ _veh inArea _x } count _trigList) > 0;
            private _speedOk = (_speedLimit < 0) || { (abs (speed _veh)) <= _speedLimit };

            if ((!_inAnyZone || !_speedOk) && _interruptable) exitWith {
                _cancelled = true;
                private _drv = driver _veh;
                if (!isNull _drv && isPlayer _drv) then {
                    private _reason = if (!_inAnyZone) then { "Left loading area" } else { "Moved too fast" };
                    [format ["[%1 LOADING ZONE]\n%2 — supply loading cancelled!", _displayName, _reason]] remoteExec ["hintSilent", _drv];
                    [format ["LOGISTICS COMMAND: %1 at %2 before loading completed. Timer reset.", _reason, _displayName]] remoteExec ["systemChat", _drv];
                };
            };

            private _drv = driver _veh;
            if (!isNull _drv && isPlayer _drv) then {
                [format ["[%1 LOADING ZONE]\nLoading supplies...\n%2: %3s remaining", _displayName, _instructionText, _rem]] remoteExec ["hintSilent", _drv];
            };

            sleep 1;
        };

        _veh setVariable ["logistics_is_loading", false, true];
        _veh setVariable ["logistics_skip_timer", false, true];

        if (!_cancelled && alive _veh && !(_veh getVariable ["logistics_is_loaded", false])) then {
            private _drv = driver _veh;
            if (!isNull _drv && isPlayer _drv) then {
                [format ["[%1 LOADING ZONE]\nSupply loading complete!", _displayName]] remoteExec ["hintSilent", _drv];
            };
            [_veh, _baseKey] execVM "fn_spawnLoadSupply.sqf";
        };
    };
};

private _allMissionTriggers = allMissionObjects "EmptyDetector";

{
    private _trigger = _x;
    private _triggerName = vehicleVarName _trigger; 
    
    if (_triggerName != "") then {
        private _tLower = toLowerANSI _triggerName;
        private _pickupIdx = _tLower find "_pickup";
        private _dropoffIdx = _tLower find "_dropoff";
        private _serviceIdx = _tLower find "_service";
        private _isPickup = (_pickupIdx != -1);
        private _isDropoff = (_dropoffIdx != -1);
        private _isService = (_serviceIdx != -1);
        
        if (_isPickup || _isDropoff || _isService) then {
            private _cutIdx = if (_isPickup) then { _pickupIdx } else { if (_isDropoff) then { _dropoffIdx } else { _serviceIdx } };
            private _parentBase = _triggerName select [0, _cutIdx];
            private _displayName = (_parentBase splitString "_") joinString " ";

            // One-time startup hook: preserve mission-maker trigger Condition, but update legacy script names in OnActivation
            private _stmts = triggerStatements _trigger;
            _stmts params [["_cond", "this"], ["_act", ""], ["_deact", ""]];

            if (_isPickup) then {
                // Register this trigger into the parent base's unified pickup trigger group
                private _trigListVar = format ["LogiPickupTriggers_%1", _parentBase];
                private _trigList = missionNamespace getVariable [_trigListVar, []];
                _trigList pushBackUnique _trigger;
                missionNamespace setVariable [_trigListVar, _trigList];

                // Capture mission-maker trigger timeout and condition per trigger for the unified countdown HUD, then zero engine timeout
                private _tTimeout = triggerTimeout _trigger;
                _tTimeout params [["_tMin", 0], ["_tMid", 0], ["_tMax", 0], ["_tInt", false]];
                _trigger setVariable ["LogiTriggerTimeout", [_tMin, _tMid, _tMax, _tInt]];
                _trigger setVariable ["LogiTriggerCond", _cond];
                if (_tMax > 0 || _tMid > 0 || _tMin > 0) then {
                    missionNamespace setVariable [format ["LogiPickupTimeout_%1", _parentBase], [_tMin, _tMid, _tMax, _tInt]];
                    _trigger setTriggerTimeout [0, 0, 0, false];
                };

                if (_act == "" || { "SpawnLoadSupply" in _act } || { "fn_spawnLoadSupply" in _act } || { "LOGI_fnc_handlePickupTrigger" in _act }) then {
                    _act = format [
                        "private _veh = (thisList select {typeOf _x in allowedLogisticsVehicles}) param [0, objNull]; if (!isNull _veh) then { [_veh, %1, thisTrigger] call LOGI_fnc_handlePickupTrigger; };",
                        str _parentBase
                    ];
                    _trigger setTriggerStatements [_cond, _act, _deact];
                };
            };

            if (_isDropoff) then {
                if (_act == "" || { "CargoDelivery" in _act } || { "fn_cargoDelivery" in _act }) then {
                    _act = format ["[thisTrigger, %1] execVM 'fn_cargoDelivery.sqf';", str _parentBase];
                    if (_deact == "") then { _deact = "thisTrigger setVariable ['isProcessingLogistics', false];"; };
                    _trigger setTriggerStatements [_cond, _act, _deact];
                };
            };

            if (_isService) then {
                // Allow LandVehicle, Air, and Ship driven by the local player to trigger R4-C Service Pads and pass vehicle player reliably
                _cond = "(local player) && { private _v = vehicle player; (_v in thisList) && (_v isKindOf 'LandVehicle' || _v isKindOf 'Air' || _v isKindOf 'Ship') && (abs (speed _v) < 1) && (player == driver _v) }";
                _act  = "[thisTrigger, vehicle player, 3] execVM 'fn_executeR4CService.sqf';";
                _trigger setTriggerStatements [_cond, _act, _deact];
            };

            // Server-only: Standardized map marker generation (Icon + Exact Trigger Area Bounding Box)
            if (isServer) then {
                private _prefix = if (_isPickup) then {"Pickup_"} else { if (_isDropoff) then {"Dropoff_"} else {"Service_"} };
                private _expectedMarkerID = format ["%1%2", _prefix, _parentBase]; 
                
                if (getMarkerColor _expectedMarkerID == "") then {
                    createMarker [_expectedMarkerID, getPos _trigger];
                    _expectedMarkerID setMarkerColor (if (_isPickup) then {"ColorBLUFOR"} else { if (_isDropoff) then {"ColorGreen"} else {"ColorYellow"} });
                    _expectedMarkerID setMarkerType (if (_isPickup) then {"mil_pickup"} else { if (_isDropoff) then {"mil_end"} else {"b_maint"} });
                    _expectedMarkerID setMarkerText (if (_isPickup) then {format ["%1 - Loading Zone", _displayName]} else { if (_isDropoff) then {format ["%1 - Delivery Zone", _displayName]} else {format ["%1 - R4-C Service Pad", _displayName]} });
                };

                // Draw the exact trigger area bounding box on the map so players can see the zone boundaries
                private _areaMarkerID = format ["Area_%1", _triggerName];
                if (getMarkerColor _areaMarkerID == "") then {
                    (triggerArea _trigger) params ["_sizeA", "_sizeB", "_angle", "_isRect"];
                    if (_sizeA > 0 && _sizeB > 0) then {
                        createMarker [_areaMarkerID, getPos _trigger];
                        _areaMarkerID setMarkerShape (if (_isRect) then {"RECTANGLE"} else {"ELLIPSE"});
                        _areaMarkerID setMarkerSize [_sizeA, _sizeB];
                        _areaMarkerID setMarkerDir _angle;
                        _areaMarkerID setMarkerBrush "SolidBorder";
                        _areaMarkerID setMarkerColor (if (_isPickup) then {"ColorBLUFOR"} else { if (_isDropoff) then {"ColorGreen"} else {"ColorYellow"} });
                        _areaMarkerID setMarkerAlpha 0.25;
                    };
                };
            };
        };
    };
} forEach _allMissionTriggers;