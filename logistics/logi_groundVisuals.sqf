// ============================================================================
// LOGISTICS SYSTEM: DYNAMIC GROUND VISUAL MARKERS (SECTION 6.9)
// File: logi_groundVisuals.sqf
// Description: Automated day/night visual cue manager for logistics triggers.
//
//              - Edge Lights (PERMANENT AIRFIELD FIXTURES):
//                * Service Areas: Yellow (Land_runway_edgelight_yellow_F)
//                * Pickup & Dropoff Zones: Blue (Land_runway_edgelight_blue_F)
//                * Spawned ONCE at mission startup and remain permanently on the map.
//                * Engine automatically illuminates them at dusk and turns them off at dawn ("AUTO").
//
//              - Centerline Visual Cues (DAY / NIGHT ADAPTIVE):
//                * Day: Eden Smoke Modules (ModuleSmoke*_F) spawned once and activated
//                  via BIS_fnc_moduleEffectsSmoke. Billow continuous smoke all day without loops.
//                * Night: Centerline Helipad Lights + Chemlights for approach and touchdown.
//                * Centerline objects cleanly swap only when day transitions to night (or vice versa).
//
//              - Standard Color Scheme:
//                * Service Areas: Yellow
//                * Dropoff Zones: Green (BLUFOR friendly LZ / delivery target)
//                * Pickup Zones:  Purple (Loading & staging pad)
//
//              - Manual Testing Override:
//                missionNamespace getVariable ["Logi_GroundVisuals_ForceMode", -1]
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

// 1. PERMANENT RUNWAY EDGE LIGHTS
// Service: Yellow | Pickup & Dropoff: Blue
private _serviceRunwayClass = ["Land_runway_edgelight_yellow_F", "Land_runway_edgelight"] call _fnc_safeClass;
private _edgeRunwayClass    = ["Land_runway_edgelight_blue_F", "Land_runway_edgelight"] call _fnc_safeClass;

// 2. CENTERLINE DAYTIME SMOKE MODULES
private _serviceSmokeClass  = "ModuleSmokeYellow_F";
private _dropoffSmokeClass  = "ModuleSmokeGreen_F";
private _pickupSmokeClass   = "ModuleSmokePurple_F";

// 3. CENTERLINE NIGHTTIME HELIPAD LIGHTS & CHEMLIGHTS
private _serviceHelipadClass  = if (_hasConstantHelipadLight) then { "PortableHelipadLight_01_yellow_constant" } else { "PortableHelipadLight_01_yellow_F" };
private _serviceChemClass     = "Chemlight_yellow";

private _dropoffHelipadClass  = if (_hasConstantHelipadLight) then { "PortableHelipadLight_01_green_constant" } else { "PortableHelipadLight_01_green_F" };
private _dropoffChemClass     = "Chemlight_green";

private _pickupHelipadClass   = if (_hasConstantHelipadLight) then { "PortableHelipadLight_01_blue_constant" } else { "PortableHelipadLight_01_blue_F" };
private _pickupChemClass      = "Chemlight_blue";

// 4. VEHICLE SPAWN PADS / FACTORY HELIPADS (BLUE SAFETY WARNING)
private _spawnSmokeClass      = "ModuleSmokeBlue_F";
private _spawnAmmoClass       = "SmokeShellBlue";
private _spawnHelipadClass    = if (_hasConstantHelipadLight) then { "PortableHelipadLight_01_blue_constant" } else { "PortableHelipadLight_01_blue_F" };
private _spawnChemClass       = "Chemlight_blue";

// Logic group for Eden effect modules
private _logicGrp = missionNamespace getVariable ["Logi_GroundVisuals_LogicGrp", grpNull];
if (isNull _logicGrp) then {
    _logicGrp = createGroup [sideLogic, true];
    missionNamespace setVariable ["Logi_GroundVisuals_LogicGrp", _logicGrp];
};

// -----------------------------------------------------------------------------
// HELPER: MODULE ACTIVATOR
// Activates dynamically spawned Eden Effect Modules across all clients.
// Follows Bohemia module execution convention: ["init", [_logic, _units, _isCuratorPlaced], _isActivated]
// -----------------------------------------------------------------------------
logi_fnc_activateModule = {
    params ["_mod"];
    if (isNull _mod) exitWith {};
    
    // Read the registered function from CfgVehicles
    private _fncName = getText (configFile >> "CfgVehicles" >> typeOf _mod >> "function");
    if (_fncName == "") then { _fncName = "BIS_fnc_moduleGrenade"; };

    // Broadcast standard module init parameters: ["init", [_logic, _units, _isCuratorPlaced], _isActivated]
    ["init", [_mod, [], false], true] remoteExec [_fncName, 0, true];
};

// Helper: Safely spawn and initialize a continuous smoke module
logi_fnc_createSmokeModule = {
    params ["_class", "_pos", "_colorName", "_ammoClass", "_logicGroup"];
    
    private _mod = _logicGroup createUnit [_class, _pos, [], 0, "CAN_COLLIDE"];
    if (isNull _mod) then {
        // Fallback to base ModuleSmoke_F with color attribute
        _mod = _logicGroup createUnit ["ModuleSmoke_F", _pos, [], 0, "CAN_COLLIDE"];
    };
    
    // Set attributes read by BIS_fnc_moduleGrenade / ModuleSmoke
    _mod setVariable ["Type", _ammoClass, true];
    _mod setVariable ["type", _ammoClass, true];
    _mod setVariable ["Color", _colorName, true];
    _mod setVariable ["color", _colorName, true];
    _mod setVariable ["Repeat", 1, true];
    _mod setVariable ["repeat", 1, true];
    _mod setVariable ["Timeout", 0, true];
    _mod setVariable ["timeout", 0, true];
    
    if (surfaceIsWater _pos) then {
        _mod setPosASL _pos;
    } else {
        _mod setPosATL _pos;
    };

    [_mod] call logi_fnc_activateModule;
    _mod
};

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
        // Day:   1 single center smoke module
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

        // Perimeter Flanks: 4 corners always marked
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

    // Height snapping (Surface-aware: ATL for terrain, ASL 0.05m for ocean/water)
    private _snapPos = {
        params ["_p"];
        if (surfaceIsWater _p) then {
            [_p select 0, _p select 1, 0.05]
        } else {
            [_p select 0, _p select 1, 0]
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
        private _smokeClass = switch (_padType) do {
            case "DROPOFF": { _dropoffSmokeClass };
            case "PICKUP":  { _pickupSmokeClass };
            default         { _serviceSmokeClass };
        };
        private _colorName = switch (_padType) do {
            case "DROPOFF": { "Green" };
            case "PICKUP":  { "Purple" };
            default         { "Yellow" };
        };
        private _ammoClass = switch (_padType) do {
            case "DROPOFF": { "SmokeShellGreen" };
            case "PICKUP":  { "SmokeShellPurple" };
            default         { "SmokeShellYellow" };
        };
        private _helipadClass = switch (_padType) do {
            case "DROPOFF": { _dropoffHelipadClass };
            case "PICKUP":  { _pickupHelipadClass };
            default         { _serviceHelipadClass };
        };
        private _chemClass = switch (_padType) do {
            case "DROPOFF": { _dropoffChemClass };
            case "PICKUP":  { _pickupChemClass };
            default         { _serviceChemClass };
        };

        _zoneData pushBack [
            vehicleVarName _trigger,
            _padType,
            _smokeClass,
            _colorName,
            _ammoClass,
            _helipadClass,
            _chemClass,
            _smokePositions,
            _centerLightPositions,
            _perimeterLightPositions,
            _dirLen
        ];
    };
} forEach _registeredTriggers;

diag_log format ["[LOGISTICS GROUND VISUALS]: Configured %1 logistics visual zones.", count _zoneData];

// -----------------------------------------------------------------------------
// DISCOVER VEHICLE SPAWN PADS & HELIPADS
// Warns players with Blue Smoke (Day) and Blue Lights (Night) to keep spawn pads clear.
// -----------------------------------------------------------------------------
private _helipadClasses = [
    "Land_HelipadEmpty_F",
    "Land_HelipadCircle_F",
    "Land_HelipadSquare_F",
    "Land_HelipadCivil_F",
    "Land_HelipadRescue_F",
    "Land_Destroyer_01_Boat_Rack_01_F",
    "Land_Boat_Rack_01_F",
    "Land_BoatRack_01_F"
];

private _spawnPadPositions = [];
{
    private _type = typeOf _x;
    private _name = toLowerANSI (vehicleVarName _x);
    if (!isNull _x && !(_x isKindOf "EmptyDetector")) then {
        if (_type in _helipadClasses || { _name find "garage" != -1 || _name find "spawn" != -1 }) then {
            private _pos = getPosATL _x;
            if (surfaceIsWater _pos) then {
                _spawnPadPositions pushBackUnique [getPosASL _x, true];
            } else {
                _spawnPadPositions pushBackUnique [_pos, false];
            };
        };
    };
} forEach (allMissionObjects "All");

diag_log format ["[LOGISTICS GROUND VISUALS]: Configured %1 vehicle spawn pads for safety visual warnings.", count _spawnPadPositions];

// -----------------------------------------------------------------------------
// SPAWN PERMANENT RUNWAY EDGE LIGHTS ONCE AT STARTUP
// Yellow for Service areas, Blue for Pickup & Dropoff zones.
// These remain permanently on the map; the engine cycles their bulbs ("AUTO").
// -----------------------------------------------------------------------------
private _permanentEdgeLights = [];
{
    _x params [
        "_trgName", "_padType", "_smokeClass", "_colorName", "_ammoClass",
        "_helipadClass", "_chemClass", "_smokePositions",
        "_centerLightPositions", "_perimeterLightPositions", "_dirLen"
    ];

    private _edgeClass = if (_padType == "SERVICE") then { _serviceRunwayClass } else { _edgeRunwayClass };

    {
        private _rLight = createVehicle [_edgeClass, _x, [], 0, "CAN_COLLIDE"];
        _rLight setDir _dirLen;
        if (surfaceIsWater _x) then {
            _rLight setPosASL _x;
        } else {
            _rLight setPosATL _x;
        };
        _rLight switchLight "AUTO";
        _permanentEdgeLights pushBack _rLight;
    } forEach _perimeterLightPositions;
} forEach _zoneData;

diag_log format ["[LOGISTICS GROUND VISUALS]: Spawned %1 permanent runway edge lights across all zones.", count _permanentEdgeLights];

// -----------------------------------------------------------------------------
// DAY / NIGHT STATE MACHINE DAEMON (CENTERLINE ONLY)
// - Checks illumination (sunOrMoon > 0.25 = Day, <= 0.25 = Night)
// - Manual override: Logi_GroundVisuals_ForceMode (0 = Night, 1 = Day, -1 = Auto)
// - Cleanly swaps centerline smoke modules (day) and centerline lights (night)
//   ONLY when day transitions to night (or vice versa).
// -----------------------------------------------------------------------------
private _currentVisualMode = -1; // -1 = uninitialized, 0 = Night, 1 = Day
private _activeCenterlineEntities = [];

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
        // 1. Cleanly delete all previous centerline visual cue objects
        {
            if (!isNull _x) then {
                private _emitter = _x getVariable ["effectEmitter", objNull];
                if (!isNull _emitter) then { deleteVehicle _emitter; };
                deleteVehicle _x;
            };
        } forEach _activeCenterlineEntities;
        _activeCenterlineEntities = [];

        if (_newMode == 1) then {
            // -----------------------------------------------------------------
            // DAYTIME MODE: Continuous Centerline Smoke Modules
            // Spawned once, activated via BIS_fnc_moduleGrenade / ModuleSmoke.
            // -----------------------------------------------------------------
            diag_log "[LOGISTICS GROUND VISUALS]: Transitioning to DAYTIME (Activating centerline smoke modules)...";

            {
                _x params [
                    "_trgName", "_padType", "_smokeClass", "_colorName", "_ammoClass",
                    "_helipadClass", "_chemClass", "_smokePositions",
                    "_centerLightPositions", "_perimeterLightPositions", "_dirLen"
                ];

                {
                    private _smokeMod = [_smokeClass, _x, _colorName, _ammoClass, _logicGrp] call logi_fnc_createSmokeModule;
                    _activeCenterlineEntities pushBack _smokeMod;
                } forEach _smokePositions;
            } forEach _zoneData;

            // Deploy Blue Smoke Warning on all Vehicle Spawn Pads / Helipads
            {
                _x params ["_pos", "_isWater"];
                private _smokeMod = [_spawnSmokeClass, _pos, "Blue", _spawnAmmoClass, _logicGrp] call logi_fnc_createSmokeModule;
                _activeCenterlineEntities pushBack _smokeMod;
            } forEach _spawnPadPositions;

            diag_log format ["[LOGISTICS GROUND VISUALS]: Activated %1 daytime smoke modules (zones + spawn pads).", count _activeCenterlineEntities];

        } else {
            // -----------------------------------------------------------------
            // NIGHTTIME MODE: Centerline Helipad Lights + Chemlights
            // -----------------------------------------------------------------
            diag_log "[LOGISTICS GROUND VISUALS]: Transitioning to NIGHTTIME (Activating centerline helipad & chemlights)...";

            {
                _x params [
                    "_trgName", "_padType", "_smokeClass", "_colorName", "_ammoClass",
                    "_helipadClass", "_chemClass", "_smokePositions",
                    "_centerLightPositions", "_perimeterLightPositions", "_dirLen"
                ];

                {
                    // Centerline Helipad Light (400m-600m glide slope alignment)
                    private _hLight = createVehicle [_helipadClass, _x, [], 0, "CAN_COLLIDE"];
                    _hLight setDir _dirLen;
                    if (surfaceIsWater _x) then {
                        _hLight setPosASL _x;
                    } else {
                        _hLight setPosATL _x;
                    };
                    _activeCenterlineEntities pushBack _hLight;

                    // Centerline Chemlight (Soft deck touchdown illumination)
                    private _chemObj = createVehicle [_chemClass, _x, [], 0, "CAN_COLLIDE"];
                    if (surfaceIsWater _x) then {
                        _chemObj setPosASL _x;
                    } else {
                        _chemObj setPosATL _x;
                    };
                    _activeCenterlineEntities pushBack _chemObj;
                } forEach _centerLightPositions;

            } forEach _zoneData;

            // Deploy Blue Helipad Light & Chemlight Warning on all Vehicle Spawn Pads / Helipads
            {
                _x params ["_pos", "_isWater"];
                private _hLight = createVehicle [_spawnHelipadClass, _pos, [], 0, "CAN_COLLIDE"];
                if (_isWater) then { _hLight setPosASL _pos; } else { _hLight setPosATL _pos; };
                _activeCenterlineEntities pushBack _hLight;

                private _chemObj = createVehicle [_spawnChemClass, _pos, [], 0, "CAN_COLLIDE"];
                if (_isWater) then { _chemObj setPosASL _pos; } else { _chemObj setPosATL _pos; };
                _activeCenterlineEntities pushBack _chemObj;
            } forEach _spawnPadPositions;

            diag_log format ["[LOGISTICS GROUND VISUALS]: Activated %1 nighttime lighting entities (zones + spawn pads).", count _activeCenterlineEntities];
        };

        _currentVisualMode = _newMode;
    };

    sleep 10;
};
