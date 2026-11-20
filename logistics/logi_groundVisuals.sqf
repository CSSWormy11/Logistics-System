// ============================================================================
// LOGISTICS SYSTEM: DYNAMIC GROUND VISUAL MARKERS (SECTION 6.9)
// File: logi_groundVisuals.sqf
// Description: Automated day/night visual cue manager for logistics triggers.
//              - Day: Clean, low-density centerline smoke (active SmokeShell plumes).
//                Refreshed continuously every 50 seconds to maintain unbroken columns.
//              - Night: Multi-tier lighting:
//                * Tier 1 (Corners & Flanks): Runway edge lights (2,000m+ draw).
//                * Tier 2 (Centerline): Helipad lights (400m-600m glide slope).
//                * Tier 3 (Centerline): Chemlights (soft deck touchdown reference).
//              - Standard Color Scheme:
//                * Service Areas: Yellow (Universal maintenance).
//                * Dropoff Zones: Green (BLUFOR tactical delivery LZ / drop marker).
//                * Pickup Zones:  Purple (Distinct loading / staging pad).
//              - State Machine: Evaluates sunOrMoon every 10s to swap day/night.
//              - Override: missionNamespace getVariable ["Logi_GroundVisuals_ForceMode", -1]
//                (-1 = Auto sunOrMoon, 0 = Force Night, 1 = Force Day)
// Called By: init.sqf (Server only)
// ============================================================================

if (!isServer) exitWith {};

// Wait for logistics bases and triggers to initialize
waitUntil { !isNil "logisticsBases" && { count logisticsBases > 0 } };
waitUntil { time > 0 };
sleep 2; // Allow logi_initTasks.sqf to complete initial trigger passes

diag_log "[LOGISTICS GROUND VISUALS]: Initializing dynamic visual cues manager (Section 6.9)...";

// -----------------------------------------------------------------------------
// HELPER: CLASSNAME SELECTOR WITH FALLBACK & MOD AUTO-DETECTION
// -----------------------------------------------------------------------------
private _hasConstantHelipadLight = isClass (configFile >> "CfgVehicles" >> "PortableHelipadLight_01_green_constant");

private _fnc_safeClass = {
    params ["_preferred", "_fallback"];
    if (isClass (configFile >> "CfgVehicles" >> _preferred)) then { _preferred } else { _fallback }
};

// 1. SERVICE AREAS (YELLOW)
private _serviceSmokeClass    = "SmokeShellYellow";
private _serviceChemClass     = "Chemlight_yellow";
private _serviceHelipadClass  = if (_hasConstantHelipadLight) then { "PortableHelipadLight_01_yellow_constant" } else { "PortableHelipadLight_01_yellow_F" };
private _serviceRunwayClass   = ["Land_runway_edgelight_yellow_F", "Land_runway_edgelight"] call _fnc_safeClass;

// 2. DROPOFF ZONES (GREEN)
private _dropoffSmokeClass    = "SmokeShellGreen";
private _dropoffChemClass     = "Chemlight_green";
private _dropoffHelipadClass  = if (_hasConstantHelipadLight) then { "PortableHelipadLight_01_green_constant" } else { "PortableHelipadLight_01_green_F" };
private _dropoffRunwayClass   = ["Land_Flush_Light_green_F", "Land_runway_edgelight"] call _fnc_safeClass;

// 3. PICKUP ZONES (PURPLE)
private _pickupSmokeClass     = "SmokeShellPurple";
private _pickupChemClass      = "Chemlight_blue";
private _pickupHelipadClass   = if (_hasConstantHelipadLight) then { "PortableHelipadLight_01_blue_constant" } else { "PortableHelipadLight_01_blue_F" };
private _pickupRunwayClass    = ["Land_runway_edgelight_blue_F", "Land_runway_edgelight"] call _fnc_safeClass;

// -----------------------------------------------------------------------------
// HELPER: GEOMETRIC LAYOUT & SPACING ENGINE
// Analyzes triggerArea and computes exact 3D coordinates for Centerline and Flanks.
// -----------------------------------------------------------------------------
logi_fnc_calculatePadGeometry = {
    params ["_trigger"];
    private _trgPos = getPosATL _trigger;
    (triggerArea _trigger) params [["_sizeA", 20], ["_sizeB", 20], ["_angle", 0], ["_isRect", true]];

    if (_sizeA <= 0) then { _sizeA = 20; };
    if (_sizeB <= 0) then { _sizeB = 20; };

    // Determine Major Axis (Length) vs Minor Axis (Width)
    private _isLengthB = (_sizeB >= _sizeA);
    private _halfLen = if (_isLengthB) then { _sizeB } else { _sizeA };
    private _halfWid = if (_isLengthB) then { _sizeA } else { _sizeB };
    private _dirLen  = if (_isLengthB) then { _angle } else { (_angle + 90) % 360 };
    private _dirWid  = (_dirLen + 90) % 360;

    // Unit direction vectors on horizontal plane
    private _vLen = [sin _dirLen, cos _dirLen, 0];
    private _vWid = [sin _dirWid, cos _dirWid, 0];

    // 4 Perimeter Corners
    private _c1 = _trgPos vectorAdd (_vLen vectorMultiply _halfLen) vectorAdd (_vWid vectorMultiply _halfWid);
    private _c2 = _trgPos vectorAdd (_vLen vectorMultiply _halfLen) vectorAdd (_vWid vectorMultiply (-_halfWid));
    private _c3 = _trgPos vectorAdd (_vLen vectorMultiply (-_halfLen)) vectorAdd (_vWid vectorMultiply _halfWid);
    private _c4 = _trgPos vectorAdd (_vLen vectorMultiply (-_halfLen)) vectorAdd (_vWid vectorMultiply (-_halfWid));

    private _totalLen = _halfLen * 2;
    private _totalWid = _halfWid * 2;
    private _isLarge = (_totalLen > 100 || _totalWid > 100);

    private _centerSmokePositions = [];
    private _centerLightPositions = [];
    private _perimeterLightPositions = [];

    if (!_isLarge) then {
        // ---------------------------------------------------------------------
        // SMALL PAD (<= 100m):
        // Day:   1 single center smoke
        // Night: 1 center helipad light + 1 center chemlight; 4 corner runway lights
        // ---------------------------------------------------------------------
        _centerSmokePositions pushBack _trgPos;
        _centerLightPositions pushBack _trgPos;
        _perimeterLightPositions append [_c1, _c2, _c3, _c4];
    } else {
        // ---------------------------------------------------------------------
        // LARGE PAD / AIRFIELD CORRIDOR (> 100m):
        // Centerline: Originates from center, steps outward symmetrically.
        // Buffer: stops 35m short of the trigger end (within 25m-50m buffer requirement).
        // ---------------------------------------------------------------------
        private _maxCenterDist = (_halfLen - 35) max 0;

        // Center point
        _centerSmokePositions pushBack _trgPos;
        _centerLightPositions pushBack _trgPos;

        // Daytime Smoke: every 200m along major axis
        private _smokeStep = 200;
        for "_d" from _smokeStep to _maxCenterDist step _smokeStep do {
            _centerSmokePositions pushBack (_trgPos vectorAdd (_vLen vectorMultiply _d));
            _centerSmokePositions pushBack (_trgPos vectorAdd (_vLen vectorMultiply (-_d)));
        };

        // Nighttime Centerline Lights: every 100m along major axis
        private _lightStep = 100;
        for "_d" from _lightStep to _maxCenterDist step _lightStep do {
            _centerLightPositions pushBack (_trgPos vectorAdd (_vLen vectorMultiply _d));
            _centerLightPositions pushBack (_trgPos vectorAdd (_vLen vectorMultiply (-_d)));
        };

        // Perimeter Flanks (Night only):
        // 4 corners always marked
        _perimeterLightPositions append [_c1, _c2, _c3, _c4];

        // Step inward from corners along the flanks every 100m
        for "_d" from _lightStep to (_halfLen - 50) step _lightStep do {
            // Right flank (+halfWid)
            _perimeterLightPositions pushBack (_trgPos vectorAdd (_vWid vectorMultiply _halfWid) vectorAdd (_vLen vectorMultiply _d));
            _perimeterLightPositions pushBack (_trgPos vectorAdd (_vWid vectorMultiply _halfWid) vectorAdd (_vLen vectorMultiply (-_d)));
            // Left flank (-halfWid)
            _perimeterLightPositions pushBack (_trgPos vectorAdd (_vWid vectorMultiply (-_halfWid)) vectorAdd (_vLen vectorMultiply _d));
            _perimeterLightPositions pushBack (_trgPos vectorAdd (_vWid vectorMultiply (-_halfWid)) vectorAdd (_vLen vectorMultiply (-_d)));
        };
    };

    // Height snapping (Surface-aware: ATL for terrain, ASL 0.1m for ocean/water)
    private _snapPos = {
        params ["_p"];
        if (surfaceIsWater _p) then {
            [_p select 0, _p select 1, 0.1]
        } else {
            [_p select 0, _p select 1, 0.05]
        };
    };

    _centerSmokePositions = _centerSmokePositions apply { [_x] call _snapPos };
    _centerLightPositions = _centerLightPositions apply { [_x] call _snapPos };
    _perimeterLightPositions = _perimeterLightPositions apply { [_x] call _snapPos };

    [_isLarge, _centerSmokePositions, _centerLightPositions, _perimeterLightPositions, _dirLen]
};

// -----------------------------------------------------------------------------
// DISCOVER LOGISTICS TRIGGERS & PRECOMPUTE GEOMETRY
// -----------------------------------------------------------------------------
private _registeredTriggers = missionNamespace getVariable ["Logi_AllVisualTriggers", []];

// If not pre-registered by logi_initTasks, scan all mission triggers directly
if (count _registeredTriggers == 0) then {
    {
        private _tName = toLowerANSI (vehicleVarName _x);
        if (_tName != "") then {
            if (_tName find "pickup" != -1) then {
                _registeredTriggers pushBack [_x, "PICKUP"];
            } else {
                if (_tName find "dropoff" != -1) then {
                    _registeredTriggers pushBack [_x, "DROPOFF"];
                } else {
                    if (_tName find "service" != -1) then {
                        _registeredTriggers pushBack [_x, "SERVICE"];
                    };
                };
            };
        };
    } forEach (allMissionObjects "EmptyDetector");
};

// Precompute zone records so geometry calculations run only once on startup
private _zoneData = [];
{
    _x params ["_trigger", "_padType"];
    if (!isNull _trigger) then {
        private _geom = [_trigger] call logi_fnc_calculatePadGeometry;
        _geom params ["_isLarge", "_smokePositions", "_centerLightPositions", "_perimeterLightPositions", "_dirLen"];

        // Select classes based on pad role
        private _classes = switch (_padType) do {
            case "DROPOFF": { [_dropoffSmokeClass, _dropoffChemClass, _dropoffHelipadClass, _dropoffRunwayClass] };
            case "PICKUP":  { [_pickupSmokeClass, _pickupChemClass, _pickupHelipadClass, _pickupRunwayClass] };
            default         { [_serviceSmokeClass, _serviceChemClass, _serviceHelipadClass, _serviceRunwayClass] };
        };

        _zoneData pushBack [
            vehicleVarName _trigger,
            _padType,
            _classes,
            _smokePositions,
            _centerLightPositions,
            _perimeterLightPositions,
            _dirLen
        ];
    };
} forEach _registeredTriggers;

diag_log format ["[LOGISTICS GROUND VISUALS]: Configured %1 logistics visual zones.", count _zoneData];

// -----------------------------------------------------------------------------
// DAY / NIGHT STATE MACHINE DAEMON
// - Checks illumination (sunOrMoon > 0.25 = Day, <= 0.25 = Night)
// - Supports manual override: Logi_GroundVisuals_ForceMode (0 = Night, 1 = Day, -1 = Auto)
// - Maintains unbroken daytime smoke plumes by refreshing active shells every 50s
// -----------------------------------------------------------------------------
private _currentVisualMode = -1; // -1 = uninitialized, 0 = Night, 1 = Day
private _activeEntities = [];
private _lastSmokeRefresh = 0;

while { true } do {
    private _forceMode = missionNamespace getVariable ["Logi_GroundVisuals_ForceMode", -1];
    private _isDay = if (_forceMode != -1) then {
        (_forceMode == 1)
    } else {
        (sunOrMoon > 0.25)
    };
    private _newMode = if (_isDay) then { 1 } else { 0 };

    // Mode Transition (Day -> Night or Night -> Day)
    if (_newMode != _currentVisualMode) then {
        // 1. Cleanly delete all previous visual cue objects
        {
            if (!isNull _x) then { deleteVehicle _x; };
        } forEach _activeEntities;
        _activeEntities = [];

        if (_newMode == 1) then {
            // -----------------------------------------------------------------
            // DAYTIME MODE: Active SmokeShell Plumes on Centerline
            // -----------------------------------------------------------------
            diag_log "[LOGISTICS GROUND VISUALS]: Transitioning to DAYTIME (Deploying centerline SmokeShells)...";

            {
                _x params ["_trgName", "_padType", "_classes", "_smokePositions", "_centerLightPositions", "_perimeterLightPositions", "_dirLen"];
                _classes params ["_smokeClass", "_chemClass", "_helipadClass", "_runwayClass"];

                {
                    private _smokeObj = createVehicle [_smokeClass, _x, [], 0, "CAN_COLLIDE"];
                    _smokeObj setVelocity [0, 0, 0];
                    if (surfaceIsWater _x) then {
                        _smokeObj setPosASL _x;
                    } else {
                        _smokeObj setPosATL _x;
                    };
                    _activeEntities pushBack _smokeObj;
                } forEach _smokePositions;
            } forEach _zoneData;

            _lastSmokeRefresh = time;
            diag_log format ["[LOGISTICS GROUND VISUALS]: Deployed %1 daytime smoke emitters.", count _activeEntities];

        } else {
            // -----------------------------------------------------------------
            // NIGHTTIME MODE: Perimeter Runway Lights + Centerline Helipad/Chems
            // -----------------------------------------------------------------
            diag_log "[LOGISTICS GROUND VISUALS]: Transitioning to NIGHTTIME (Activating runway, helipad & chemlights)...";

            {
                _x params ["_trgName", "_padType", "_classes", "_smokePositions", "_centerLightPositions", "_perimeterLightPositions", "_dirLen"];
                _classes params ["_smokeClass", "_chemClass", "_helipadClass", "_runwayClass"];

                // Tier 1: Outer Perimeter & Corners (Runway Edge Lights - 2,000m+ draw)
                {
                    private _rLight = createVehicle [_runwayClass, _x, [], 0, "CAN_COLLIDE"];
                    _rLight setDir _dirLen;
                    if (surfaceIsWater _x) then {
                        _rLight setPosASL _x;
                    } else {
                        _rLight setPosATL _x;
                    };
                    _activeEntities pushBack _rLight;
                } forEach _perimeterLightPositions;

                // Tier 2 & 3: Centerline Approach & Touchdown (Helipad Lights + Chemlights)
                {
                    // Center Helipad Light (400m-600m glide slope alignment)
                    private _hLight = createVehicle [_helipadClass, _x, [], 0, "CAN_COLLIDE"];
                    _hLight setDir _dirLen;
                    if (surfaceIsWater _x) then {
                        _hLight setPosASL _x;
                    } else {
                        _hLight setPosATL _x;
                    };
                    _activeEntities pushBack _hLight;

                    // Center Chemlight (Soft deck touchdown illumination)
                    private _chemObj = createVehicle [_chemClass, _x, [], 0, "CAN_COLLIDE"];
                    if (surfaceIsWater _x) then {
                        _chemObj setPosASL _x;
                    } else {
                        _chemObj setPosATL _x;
                    };
                    _activeEntities pushBack _chemObj;
                } forEach _centerLightPositions;

            } forEach _zoneData;

            diag_log format ["[LOGISTICS GROUND VISUALS]: Activated %1 nighttime lighting props.", count _activeEntities];
        };

        _currentVisualMode = _newMode;
    } else {
        // ---------------------------------------------------------------------
        // PERIODIC SMOKE REFRESH (DAYTIME ONLY)
        // Vanilla SmokeShell canisters burn out after ~60-70 seconds.
        // Refresh every 50 seconds to keep plumes continuous and unbroken.
        // ---------------------------------------------------------------------
        if (_currentVisualMode == 1 && { (time - _lastSmokeRefresh) >= 50 }) then {
            // Delete expired smoke cans
            {
                if (!isNull _x) then { deleteVehicle _x; };
            } forEach _activeEntities;
            _activeEntities = [];

            // Spawn fresh smoke canisters
            {
                _x params ["_trgName", "_padType", "_classes", "_smokePositions", "_centerLightPositions", "_perimeterLightPositions", "_dirLen"];
                _classes params ["_smokeClass", "_chemClass", "_helipadClass", "_runwayClass"];

                {
                    private _smokeObj = createVehicle [_smokeClass, _x, [], 0, "CAN_COLLIDE"];
                    _smokeObj setVelocity [0, 0, 0];
                    if (surfaceIsWater _x) then {
                        _smokeObj setPosASL _x;
                    } else {
                        _smokeObj setPosATL _x;
                    };
                    _activeEntities pushBack _smokeObj;
                } forEach _smokePositions;
            } forEach _zoneData;

            _lastSmokeRefresh = time;
        };
    };

    sleep 10;
};
