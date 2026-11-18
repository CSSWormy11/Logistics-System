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

waitUntil { !isNil "logisticsBases" && { count logisticsBases > 0 } };
waitUntil { time > 0 };

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
        [_vehicle, _parentBase] execVM "logistics\logi_spawnLoadSupply.sqf";
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
            [_veh, _baseKey] execVM "logistics\logi_spawnLoadSupply.sqf";
        };
    };
};

private _allMissionTriggers = allMissionObjects "EmptyDetector";

{
    private _trigger = _x;
    private _triggerName = vehicleVarName _trigger; 
    
    if (_triggerName != "") then {
        private _tLower = toLowerANSI _triggerName;
        private _pickupIdx = _tLower find "pickup";
        private _dropoffIdx = _tLower find "dropoff";
        private _serviceIdx = _tLower find "service";
        private _isPickup = (_pickupIdx != -1);
        private _isDropoff = (_dropoffIdx != -1);
        private _isService = (_serviceIdx != -1);
        
        if (_isPickup || _isDropoff || _isService) then {
            private _cutIdx = if (_isPickup) then { _pickupIdx } else { if (_isDropoff) then { _dropoffIdx } else { _serviceIdx } };
            private _parentBase = _triggerName select [0, _cutIdx];
            if (count _parentBase > 0 && { _parentBase select [count _parentBase - 1, 1] == "_" }) then {
                _parentBase = _parentBase select [0, count _parentBase - 1];
            };

            // If trigger uses a short name (e.g. "Pickup_1", "Dropoff_1", "Service_1") or parentBase not found in logisticsBases:
            if (_parentBase == "" || !(_parentBase in (missionNamespace getVariable ["logisticsBases", []]))) then {
                private _syncedBaseObj = (synchronizedObjects _trigger) select { 
                    private _bKey = vehicleVarName _x; 
                    _bKey != "" && { _bKey in (missionNamespace getVariable ["logisticsBases", []]) } 
                } param [0, objNull];
                if (!isNull _syncedBaseObj) then {
                    _parentBase = vehicleVarName _syncedBaseObj;
                };
            };
            if (_parentBase == "" || !(_parentBase in (missionNamespace getVariable ["logisticsBases", []]))) exitWith {};

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

                private _allPickups = missionNamespace getVariable ["Logi_AllPickupTriggers", []];
                _allPickups pushBackUnique _trigger;
                missionNamespace setVariable ["Logi_AllPickupTriggers", _allPickups];

                // Capture mission-maker trigger timeout and condition per trigger for the unified countdown HUD, then zero engine timeout
                private _tTimeout = triggerTimeout _trigger;
                _tTimeout params [["_tMin", 0], ["_tMid", 0], ["_tMax", 0], ["_tInt", false]];
                _trigger setVariable ["LogiTriggerTimeout", [_tMin, _tMid, _tMax, _tInt]];
                _trigger setVariable ["LogiTriggerCond", _cond];
                if (_tMax > 0 || _tMid > 0 || _tMin > 0) then {
                    missionNamespace setVariable [format ["LogiPickupTimeout_%1", _parentBase], [_tMin, _tMid, _tMax, _tInt]];
                    _trigger setTriggerTimeout [0, 0, 0, false];
                };

                if (_act == "" || { "SpawnLoadSupply" in _act } || { "fn_spawnLoadSupply" in _act } || { "logi_spawnLoadSupply" in _act } || { "LOGI_fnc_handlePickupTrigger" in _act }) then {
                    _act = format [
                        "private _veh = (thisList select {typeOf _x in allowedLogisticsVehicles}) param [0, objNull]; if (!isNull _veh) then { [_veh, %1, thisTrigger] call LOGI_fnc_handlePickupTrigger; };",
                        str _parentBase
                    ];
                    _trigger setTriggerStatements [_cond, _act, _deact];
                };
            };

            if (_isDropoff) then {
                // Register this trigger into the parent base's dropoff trigger group
                private _dropListVar = format ["LogiDropoffTriggers_%1", _parentBase];
                private _dropList = missionNamespace getVariable [_dropListVar, []];
                _dropList pushBackUnique _trigger;
                missionNamespace setVariable [_dropListVar, _dropList];
                _trigger setVariable ["LogiTriggerCond", _cond];

                // Universal Dropoff: Allow any vehicle, aircraft, boat, or player on foot to trigger dropoff processing
                _cond = "this";
                _act = format ["[thisTrigger, %1] execVM 'logistics\logi_cargoDelivery.sqf';", str _parentBase];
                if (_deact == "") then { _deact = "thisTrigger setVariable ['isProcessingLogistics', false];"; };
                _trigger setTriggerStatements [_cond, _act, _deact];
            };

            if (_isService) then {
                // Allow LandVehicle, Air, and Ship driven by the local player to trigger R4-C Service Pads and pass vehicle player reliably
                _cond = "(local player) && { private _v = vehicle player; (_v in thisList) && (_v isKindOf 'LandVehicle' || _v isKindOf 'Air' || _v isKindOf 'Ship') && (abs (speed _v) < 1) && (player == driver _v) }";
                _act  = "[thisTrigger, vehicle player, 3] execVM 'logistics\qm_executeR4CService.sqf';";
                _trigger setTriggerStatements [_cond, _act, _deact];
            };

            // Server-only: Standardized map marker generation (Clean Icon without text + Exact Trigger Area Bounding Box)
            if (isServer) then {
                private _prefix = if (_isPickup) then {"Pickup_"} else { if (_isDropoff) then {"Dropoff_"} else {"Service_"} };
                private _expectedMarkerID = format ["%1%2", _prefix, _parentBase]; 
                private _triggerMarkerID = format ["%1%2", _prefix, _triggerName];
                
                // Color coding: Pickup = Blue (BLUFOR), Dropoff = Green, Service = Yellow
                private _markerColor = if (_isPickup) then {"ColorBLUFOR"} else { if (_isDropoff) then {"ColorGreen"} else {"ColorYellow"} };
                private _markerType = if (_isPickup) then {"mil_pickup"} else { if (_isDropoff) then {"mil_end"} else {"b_maint"} };

                // Primary base-level marker (used by spawning & routing scripts)
                if (getMarkerColor _expectedMarkerID == "") then {
                    createMarker [_expectedMarkerID, getPos _trigger];
                    _expectedMarkerID setMarkerColor _markerColor;
                    _expectedMarkerID setMarkerType _markerType;
                    _expectedMarkerID setMarkerText ""; // Text removed: master base marker handles name
                    _expectedMarkerID setMarkerAlpha 0; // Default global alpha 0 (Spotlight hierarchy controls local visibility)
                } else {
                    // Secondary / subsequent pads of the same category at this base (prevents duplicate icon overlap on pad 1)
                    if (getMarkerColor _triggerMarkerID == "") then {
                        createMarker [_triggerMarkerID, getPos _trigger];
                        _triggerMarkerID setMarkerColor _markerColor;
                        _triggerMarkerID setMarkerType _markerType;
                        _triggerMarkerID setMarkerText ""; // Text removed: clean icon only
                        _triggerMarkerID setMarkerAlpha 0; // Default global alpha 0 (Spotlight hierarchy controls local visibility)
                    };
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
                        _areaMarkerID setMarkerAlpha 0; // Default global alpha 0 (Spotlight hierarchy controls local visibility)
                    };
                };
            };
        };
    };
} forEach _allMissionTriggers;

// =========================================================================
// HELPER: CONTEXTUAL SPOTLIGHT MAP MARKER HIERARCHY (OPTION 3)
// Dynamic local alpha manager for pickup, dropoff, service, and area pads.
//
// 1. INFANTRY ON FOOT (vehicle player == player):
//    - All Pickup, Dropoff, Service, and Area markers: Alpha 0 (Clean map, 0 clutter).
//
// 2. ANY PLAYER IN A VEHICLE (Combat aircraft, Tanks, APCs, Boats, Cars, Transports):
//    - Service Markers (Service_* & Area_*_service*):
//      * Nominal Status: Alpha 0.50 (Area: 0.20) for global base repair/refuel awareness.
//      * Distress / Damaged (>25% dmg, <50% fuel, or low ammo): Spotlighted at Alpha 1.0 (Area: 0.45).
//    - Pickup & Dropoff Markers:
//      * Non-logistics vehicles (Wipeout, Slammer, etc.): Alpha 0 (No cargo clutter).
//
// 3. LOGISTICS DRIVERS (Authorized Logistics Transport):
//    - Overview Mode (no active route locked):
//      * Pad Icons: Alpha 1.0, Area triggers: Alpha 0.25.
//    - Active Route Mode (Route locked with origin & destination):
//      * Active Assigned Route Pads (Origin Pickup & Dest Dropoff): Alpha 1.0 (Area: 0.45).
//      * Secondary Alternative Pads (All other bases): Alpha 0.25 (Area: 0.10).
//      * Service Pads: Alpha 1.0 on active bases, Alpha 0.50 on secondary bases (or 1.0 if damaged).
//
// 4. MASTER BASE MARKERS (SB_Main, FOB_*, MSR):
//    - Always visible to all players at Alpha 1.0 with human-readable labels.
// =========================================================================
logi_fnc_updateMarkerSpotlight = {
    params [
        ["_isLogiDriver", false],
        ["_activeFromBase", ""],
        ["_activeTargetBase", ""],
        ["_inAnyVehicleOverride", nil],
        ["_needsServiceOverride", nil]
    ];

    if (!hasInterface) exitWith {};

    private _localVeh = vehicle player;
    private _inAnyVehicle = if (!isNil "_inAnyVehicleOverride") then {
        _inAnyVehicleOverride
    } else {
        (_localVeh != player && alive _localVeh)
    };

    private _needsService = if (!isNil "_needsServiceOverride") then {
        _needsServiceOverride
    } else {
        if (!_inAnyVehicle) then {
            false
        } else {
            private _req = (damage _localVeh > 0.25) || (fuel _localVeh < 0.50);
            if (!_req) then {
                private _hitDmg = getAllHitPointsDamage _localVeh param [2, []];
                if (_hitDmg findIf { _x > 0.25 } != -1) then { _req = true; };
            };
            if (!_req) then {
                private _mags = magazinesAmmo _localVeh;
                if (count _mags > 0) then {
                    private _initMags = _localVeh getVariable ["QM_InitialMagTotal", -1];
                    private _currentAmmoSum = 0;
                    { _currentAmmoSum = _currentAmmoSum + (_x # 1); } forEach _mags;
                    if (_initMags == -1) then {
                        _localVeh setVariable ["QM_InitialMagTotal", _currentAmmoSum];
                    } else {
                        if (_initMags > 0 && { _currentAmmoSum <= (_initMags * 0.50) }) then {
                            _req = true;
                        };
                    };
                };
            };
            _req
        }
    };

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
            private _isServiceArea = (_isArea && { "_service" in _m });
            private _isServiceRelated = (_isService || _isServiceArea);

            if (_isServiceRelated) then {
                // =============================================================
                // SERVICE PAD VISIBILITY RULES
                // =============================================================
                if (!_inAnyVehicle) then {
                    // Infantry on foot: hidden
                    _x setMarkerAlphaLocal 0;
                } else {
                    // In any vehicle (Combat plane, tank, boat, or logistics truck)
                    if (_needsService) then {
                        // Vehicle damaged >25%, fuel <50%, or low ammo: Spotlight at 100%
                        if (_isServiceArea) then {
                            _x setMarkerAlphaLocal 0.45;
                        } else {
                            _x setMarkerAlphaLocal 1.0;
                        };
                    } else {
                        // Vehicle in nominal condition: Check if active logistics base
                        private _basePart = if (_isArea) then { _m select [5] } else { _m select [8] };
                        private _isActiveLogiBase = false;
                        if (_hasActiveRoute) then {
                            if (_fromBaseLower != "" && { (_basePart find _fromBaseLower) == 0 }) then {
                                private _len = count _fromBaseLower;
                                private _next = _basePart select [_len, 1];
                                if (_next == "" || _next == "_") then { _isActiveLogiBase = true; };
                            };
                            if (_targetBaseLower != "" && { (_basePart find _targetBaseLower) == 0 }) then {
                                private _len = count _targetBaseLower;
                                private _next = _basePart select [_len, 1];
                                if (_next == "" || _next == "_") then { _isActiveLogiBase = true; };
                            };
                        };

                        if (_isActiveLogiBase) then {
                            if (_isServiceArea) then { _x setMarkerAlphaLocal 0.45; } else { _x setMarkerAlphaLocal 1.0; };
                        } else {
                            // Baseline vehicle visibility (50% icon, 20% area boundary)
                            if (_isServiceArea) then { _x setMarkerAlphaLocal 0.20; } else { _x setMarkerAlphaLocal 0.50; };
                        };
                    };
                };
            } else {
                // =============================================================
                // CARGO PICKUP & DROPOFF VISIBILITY RULES (Logistics Only)
                // =============================================================
                if (!_isLogiDriver) then {
                    // Non-logistics players & combat vehicles: hidden
                    _x setMarkerAlphaLocal 0;
                } else {
                    if (!_hasActiveRoute) then {
                        // Logistics overview mode (all pads visible)
                        if (_isArea) then {
                            _x setMarkerAlphaLocal 0.25;
                        } else {
                            _x setMarkerAlphaLocal 1.0;
                        };
                    } else {
                        // Active route mode: Identify if marker belongs to active pickup or dropoff base
                        private _basePart = if (_isArea) then {
                            _m select [5] // strip "area_"
                        } else {
                            if (_isPickup) then { _m select [7] } else { _m select [8] }
                        };

                        private _matchesFrom = false;
                        if (_fromBaseLower != "") then {
                            private _len = count _fromBaseLower;
                            if ((_basePart find _fromBaseLower) == 0) then {
                                private _nextChar = _basePart select [_len, 1];
                                if (_nextChar == "" || _nextChar == "_") then { _matchesFrom = true; };
                            };
                        };

                        private _matchesTarget = false;
                        if (_targetBaseLower != "") then {
                            private _len = count _targetBaseLower;
                            if ((_basePart find _targetBaseLower) == 0) then {
                                private _nextChar = _basePart select [_len, 1];
                                if (_nextChar == "" || _nextChar == "_") then { _matchesTarget = true; };
                            };
                        };

                        private _isActivePad = false;
                        if (_isArea) then {
                            if (_matchesFrom && ("_pickup" in _m)) then { _isActivePad = true; };
                            if (_matchesTarget && ("_dropoff" in _m)) then { _isActivePad = true; };
                        } else {
                            if (_matchesFrom && _isPickup) then { _isActivePad = true; };
                            if (_matchesTarget && _isDropoff) then { _isActivePad = true; };
                        };

                        if (_isActivePad) then {
                            if (_isArea) then {
                                _x setMarkerAlphaLocal 0.45;
                            } else {
                                _x setMarkerAlphaLocal 1.0;
                            };
                        } else {
                            if (_isArea) then {
                                _x setMarkerAlphaLocal 0.10;
                            } else {
                                _x setMarkerAlphaLocal 0.25;
                            };
                        };
                    };
                };
            };
        };
    } forEach allMapMarkers;
};

// Initial pass on client startup: keep combat maps clean
if (hasInterface) then {
    [false] call logi_fnc_updateMarkerSpotlight;
};
