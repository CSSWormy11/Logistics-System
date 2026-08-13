// ============================================================================
// TACTICAL COMMAND CENTER: GLOBAL INTELLIGENCE NETWORK (GIN) - CORE
// File: tsk_serverGIN.sqf
// Description: Server-side ledger for tracking dynamic battlefield intel.
//              Handles tag-based sorting (CAS, CAP, INF, CLT, SEAD, INT) and 
//              physical escalation (e.g., Tank Disabled -> Infantry Sweep).
//              Does NOT handle tasking. Serves as a database for task modules.
// ============================================================================

if (!isServer) exitWith {};

diag_log "TACTICAL COMMAND CENTER: Initializing Global Intelligence Network Ledger...";

// The Master Ledger (HashMap)
// Key: Unique Intel String ID (e.g., "GIN_INTEL_84729")
// Value: [TargetObject, Position, TagsArray, ReportCategory, MarkerID, DropoffPos]
TSK_GIN_Ledger = createHashMap;

// ============================================================================
// FUNCTION: GET AIRCRAFT CAPABILITIES
// Purpose: Dynamically scans the live ordnance loaded on an aircraft and 
//          returns an array of combat roles it is capable of executing.
// Returns: Array of strings (e.g., ["RECON", "CAS", "SEAD"])
// ============================================================================
TSK_fnc_getAircraftCapabilities = {
    params ["_vehicle"];
    if (isNull _vehicle || !(_vehicle isKindOf "Air")) exitWith { [] };
    
    private _capabilities = ["RECON"]; // Every aircraft can visually scout
    private _hasAA = false; private _hasAG = false; private _hasSEAD = false;

    // Scan every single missile, bomb, and bullet loaded in the aircraft
    {
        private _magClass = _x select 0;
        private _magUpper = toUpper _magClass;
        private _ammoClass = getText (configFile >> "CfgMagazines" >> _magClass >> "ammo");
        private _airLock = getNumber (configFile >> "CfgAmmo" >> _ammoClass >> "airLock");

        // 1. Explicit Check for Anti-Radiation Missiles
        if ("HARM" in _magUpper || "KH58" in _magUpper) then { _hasSEAD = true; };

        // 2. Engine check for Air-to-Air vs Air-to-Ground
        if (_airLock == 1 || _airLock == 2) then { _hasAA = true; }; 
        if (_airLock == 0 || _airLock == 2) then { _hasAG = true; }; 
    } forEach (magazinesAllTurrets _vehicle);

    if (_hasSEAD) then { _capabilities pushBackUnique "SEAD"; };
    if (_hasAG) then { _capabilities pushBackUnique "CAS"; };
    if (_hasAA) then { _capabilities pushBackUnique "CAP"; _capabilities pushBackUnique "INT"; };
    
    _capabilities 
};

// ============================================================================
// FUNCTION: REPORT INTEL
// Purpose: Injects a new target into the GIN and creates a map marker.
// Usage: [targetObj, "ARMOR", ["CAS", "ARM"], getPos targetObj] call TSK_fnc_GIN_ReportIntel;
// Added optional 5th parameter for LZ Dropoff locations
// ============================================================================
TSK_fnc_GIN_ReportIntel = {
    params ["_object", "_reportCategory", "_tagsArray", "_pos", ["_dropoffPos", []]];
    
    // Check if object is already tracked to prevent duplicates
    private _alreadyTracked = false;
    { if (!isNull _object && (_y select 0) == _object) exitWith { _alreadyTracked = true; }; } forEach TSK_GIN_Ledger;
    if (_alreadyTracked) exitWith { diag_log "TACTICAL COMMAND CENTER: Intel rejected (Target already actively tracked)."; };

    private _intelID = format ["GIN_INTEL_%1", floor(random 999999)];
    private _markerID = format ["GIN_MARKER_%1", _intelID];

    // --- DYNAMIC FACTION COLOR & ICON GENERATION ---
    private _targetSide = if (!isNull _object) then { side _object } else { east };
    private _sidePrefix = "o"; // Default OPFOR
    private _markerColor = "ColorOPFOR";
    
    switch (_targetSide) do {
        case west: { _sidePrefix = "b"; _markerColor = "ColorBLUFOR"; };
        case independent: { _sidePrefix = "n"; _markerColor = "ColorGUER"; };
        case civilian: { _sidePrefix = "c"; _markerColor = "ColorCIV"; };
    };

    // Create the visual map marker based on the primary tag
    createMarker [_markerID, _pos];
    
    // Assign specific shape strings based on dynamic side variables
    switch (_reportCategory) do {
        case "ARMOR": { _markerID setMarkerType format["%1_armor", _sidePrefix]; _markerID setMarkerColor _markerColor; _markerID setMarkerText " [CAS] Hostile Armor"; };
        case "RADAR": { _markerID setMarkerType format["%1_antiair", _sidePrefix]; _markerID setMarkerColor _markerColor; _markerID setMarkerText " [SEAD] Active Radar"; };
        case "AIR": { _markerID setMarkerType format["%1_air", _sidePrefix]; _markerID setMarkerColor _markerColor; _markerID setMarkerText " [INT] Hostile Air Asset"; };
        case "INFANTRY": { _markerID setMarkerType format["%1_inf", _sidePrefix]; _markerID setMarkerColor _markerColor; _markerID setMarkerText " [RECCE] Hostile Infantry"; };
        case "CRASH_SITE": { _markerID setMarkerType "loc_Ruin"; _markerID setMarkerColor "ColorOrange"; _markerID setMarkerText " [CSAR] Downed Aircraft"; };
        case "TRANSPORT_REQ": { _markerID setMarkerType "mil_pickup"; _markerID setMarkerColor "ColorBLUFOR"; _markerID setMarkerText " [CLT] Requesting Airlift"; };
        default { _markerID setMarkerType "o_unknown"; _markerID setMarkerColor "ColorRed"; _markerID setMarkerText " [UNKNOWN] Unidentified Contact"; };
    };

    // Store the dropoff coordinates in index slot 5
    TSK_GIN_Ledger set [_intelID, [_object, _pos, _tagsArray, _reportCategory, _markerID, _dropoffPos]];
    diag_log format ["TACTICAL COMMAND CENTER: New Intel Logged [%1] - Tags: %2", _reportCategory, _tagsArray];
};

// ============================================================================
// FUNCTION: REMOVE INTEL
// Purpose: Purges intel from the database and removes the marker.
// ============================================================================
TSK_fnc_GIN_RemoveIntel = {
    params ["_intelID"];
    private _data = TSK_GIN_Ledger get _intelID;
    if (!isNil "_data") then {
        deleteMarker (_data select 4); 
        TSK_GIN_Ledger deleteAt _intelID;
    };
};

// ============================================================================
// THE GIN ESCALATION WATCHDOG
// Purpose: Background loop that constantly monitors the physical state of 
//          tracked objects and escalates tags (e.g., CAS -> RECCE).
// ============================================================================
[] spawn {
    while {true} do {
        private _keys = keys TSK_GIN_Ledger;
        
        {
            private _intelID = _x;
            private _data = TSK_GIN_Ledger get _intelID;
            _data params ["_obj", "_pos", "_tags", "_category", "_marker"];

            // Update marker position dynamically if the object is moving
            if (!isNull _obj && alive _obj) then { _marker setMarkerPos (getPos _obj); };

            // --- RESOLUTION CONDITION: OBJECT DESTROYED ---
            if (!isNull _obj && !alive _obj) then {
                // If it's a transport request, we don't delete on death, but for enemies we do
                if (_category != "TRANSPORT_REQ") then {
                    [_intelID] call TSK_fnc_GIN_RemoveIntel;
                    diag_log format ["TACTICAL COMMAND CENTER: Intel %1 Resolved (Target Destroyed).", _intelID];
                };
            } else {

                // --- ESCALATION PATH A: ARMOR DISABLED & ABANDONED ---
                if (_category == "ARMOR" && {"CAS" in _tags}) then {
                    // Check if vehicle can't move and the crew has bailed out
                    if (!canMove _obj && {({alive _x} count crew _obj) == 0}) then {

                        // Update the tags: Remove CAS, Add RECCE (Infantry Sweep)
                        _data set [2, ["RECCE", "INF"]];

                        // Update Ledger
                        _data set [3, "INFANTRY"]; 
                        TSK_GIN_Ledger set [_intelID, _data];

                        // Update Marker UI
                        _marker setMarkerType "mil_warning";
                        _marker setMarkerColor "ColorOrange";
                        _marker setMarkerText " [RECCE] Disabled Armor (Infantry Sweep)";
                        
                        diag_log format ["TACTICAL COMMAND CENTER: Escalation Triggered on %1! Shifted to RECCE Sweep.", _intelID];
                    };
                };

                // --- ESCALATION PATH B: RADAR ACTIVE BUT NO SEAD AVAILABLE ---
                if (_category == "RADAR") then {
                    private _seadAvailable = false;
                    
                    // Scan the skies for any active player pilot carrying HARM/Anti-Radiation missiles
                    {
                        private _playerVeh = vehicle _x;
                        if (_playerVeh != _x && _playerVeh isKindOf "Air") then {
                            private _activeCaps = [_playerVeh] call TSK_fnc_getAircraftCapabilities;
                            if ("SEAD" in _activeCaps) then { _seadAvailable = true; };
                        };
                    } forEach allPlayers;

                    if (!_seadAvailable && !("CAS" in _tags)) then {
                        // Nobody brought SEAD weapons. Escalate target to standard CAS.
                        _data set [2, ["CAS", "SEAD"]]; 
                        TSK_GIN_Ledger set [_intelID, _data];
                        _marker setMarkerColor "ColorRed";
                        _marker setMarkerText " [CAS] Air Defense (No SEAD Available)";
                        
                        diag_log format ["TACTICAL COMMAND CENTER: Escalation Triggered on %1! SEAD unavailable, shifted to CAS.", _intelID];
                    } else {
                        if (_seadAvailable && ("CAS" in _tags)) then {
                            // A pilot just took off with SEAD weapons! Remove the CAS fallback.
                            _data set [2, ["SEAD"]]; 
                            TSK_GIN_Ledger set [_intelID, _data];
                            
                            // Revert to correct side color dynamically
                            private _tgtSide = if (!isNull _obj) then { side _obj } else { east };
                            private _revertColor = "ColorOPFOR";
                            switch (_tgtSide) do {
                                case west: { _revertColor = "ColorBLUFOR"; };
                                case independent: { _revertColor = "ColorGUER"; };
                                case civilian: { _revertColor = "ColorCIV"; };
                            };
                            
                            _marker setMarkerColor _revertColor;
                            _marker setMarkerText " [SEAD] Active Air Defense/Radar";
                            
                            diag_log format ["TACTICAL COMMAND CENTER: De-escalation on %1! SEAD asset online, removed CAS fallback.", _intelID];
                        };
                    };
                };
            };
        } forEach _keys;
        
        // --- BROADCAST PUBLIC LEDGER TO ALL CLIENTS FOR TASKING ---
        // Broadcast to clients including the new DO Dropoff Coordinate
        private _publicArray = [];
        {
            private _data = TSK_GIN_Ledger get _x;
            _publicArray pushBack [_x, _data select 0, _data select 1, _data select 2, _data select 3, _data select 5]; 
        } forEach (keys TSK_GIN_Ledger);
        missionNamespace setVariable ["TSK_GIN_Public_Ledger", _publicArray, true];
        
        uiSleep 5; // Watchdog ticks every 5 seconds
    };
};

// ============================================================================
// THE GIN AI AUTO-DETECTION SYSTEM
// Purpose: Allows BLUFOR AI units to organically feed spotted OPFOR targets
//          into the intel network based on native "knowsAbout" mechanics.
// ============================================================================
[] spawn {
    while {true} do {
        // Broadened to search for any hostiles to BLUFOR
        private _opforTargets = vehicles select { alive _x && [west, side _x] call BIS_fnc_sideIsEnemy && (_x isKindOf "LandVehicle" || _x isKindOf "Air") };
        {
            private _enemy = _x;
            // If the BLUFOR side has a high knowledge (spotted) of this enemy
            if (west knowsAbout _enemy > 2) then {
                
                // Silencer: Check if already tracked to prevent log spam
                private _alreadyTracked = false;
                { if (!isNull _enemy && (_y select 0) == _enemy) exitWith { _alreadyTracked = true; }; } forEach TSK_GIN_Ledger;
                
                if (!_alreadyTracked) then {
                    private _category = "UNKNOWN";
                    private _tags = [];
                    
                    // Identify Target Types
                    if (_enemy isKindOf "Air") then { 
                        _category = "AIR"; _tags = ["INT"]; 
                    } else {
                        // SEAD Check: True if the ground vehicle's active radar panel is turned ON
                        if (isVehicleRadarOn _enemy) then {
                            _category = "RADAR"; _tags = ["SEAD"];
                        } else {
                            if (_enemy isKindOf "Tank" || _enemy isKindOf "Car") then { 
                                _category = "ARMOR"; _tags = ["CAS", "ARM"]; 
                            };
                        };
                    };
                    if (_category != "UNKNOWN") then { [_enemy, _category, _tags, getPos _enemy] call TSK_fnc_GIN_ReportIntel; };
                };
            };
        } forEach _opforTargets;
        uiSleep 15; // Slow tick to save server performance
    };
};