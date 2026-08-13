// ============================================================================
// LOGISTICS SYSTEM: SERVER INFRASTRUCTURE MANAGER (PART 2)
// File: qm_serverGarrisonManager.sqf
// Description: Collects mission-maker placed base objects OR markers. If a marker
//              is used, it generates the appropriate physical infrastructure.
//              *FIX*: Handled stringent Type Checks to prevent string mapping crashes
//              *FIX*: Stopped Cargo Houses from auto-spawning on markers.
//              *FIX*: Abandoned V_Garage processing to reduce map clutter.
//              *NEW*: Evaluates and logs structure bounding boxes at mission start.
// Called By: init.sqf (Executed during server initialization)
// ============================================================================

if (!isServer) exitWith {};
waitUntil { !isNil "logisticsBases" };

diag_log "QUARTERMASTER: Server Infrastructure Builder booted.";

private _terminalClasses = ["VirtualReammoBox_camonet_F"];
private _spawnClasses = ["Land_Cargo_House_V1_F", "Land_Cargo_House_V3_F"];

private _structuralPads = [
    "Land_Hangar_F", "Land_TentHangar_V1_F", "Land_ServiceHangar_01_L_F", "Land_ServiceHangar_01_R_F", "Land_Airport_01_hangar_F",
    "Land_HelipadCircle_F", "Land_HelipadSquare_F", "Land_HelipadCivil_F", "Land_HelipadEmpty_F",
    "Land_Destroyer_01_Boat_Rack_01_F", "Land_Boat_Rack_01_F", "Land_BoatRack_01_F"
];

// --- MISSION STARTUP: STRUCTURAL BOUNDING BOX LOGGER ---
private _fnc_logStructureData = {
    params ["_markerName", "_pos", "_obj"];
    if (_markerName == "") exitWith {};
    
    diag_log format ["--- STARTUP EVALUATION: MARKER '%1' ---", _markerName];
    diag_log format ["Marker Position (AGL): %1", _pos];
    
    // Ignore logging dimensions for things we just spawned dynamically (like empty helipads or small boxes)
    if (!isNull _obj && {!(typeOf _obj in _terminalClasses) && !(typeOf _obj in _spawnClasses) && typeOf _obj != "Land_HelipadEmpty_F"}) then {
        diag_log format ["Tied to Structure: True (%1)", typeOf _obj];
        private _bbr = boundingBoxReal _obj;
        private _p1 = _bbr select 0;
        private _p2 = _bbr select 1;
        private _maxWidth = abs ((_p2 select 0) - (_p1 select 0));
        private _maxLength = abs ((_p2 select 1) - (_p1 select 1));
        private _maxHeight = abs ((_p2 select 2) - (_p1 select 2));
        
        diag_log format ["Structure Dimensions (WxLxH): %1m x %2m x %3m", _maxWidth, _maxLength, _maxHeight];
        diag_log format ["Front-Left Corner (Local): %1", _p1];
        diag_log format ["Back-Right Corner (Local): %1", _p2];
        diag_log format ["Safest Calculated Center (ASL): %1", getPosASL _obj];
    } else {
        diag_log "Tied to Structure: False (No pre-existing structures detected. Utilizing raw marker coordinates).";
    };
    diag_log "--------------------------------------------------";
};

// --- ROBUST SPAWN HELPER (Prevents Water Death & Snaps to Carrier Decks) ---
private _fnc_spawnSafely = {
    params ["_class", "_pos", "_dir"];
    private _obj = createVehicle [_class, [_pos#0, _pos#1, 500], [], 0, "CAN_COLLIDE"];
    _obj setDir _dir;
    
    if (surfaceIsWater _pos) then {
        private _intersects = lineIntersectsSurfaces [AGLToASL [_pos#0, _pos#1, 100], AGLToASL [_pos#0, _pos#1, -20], objNull, objNull, true, 1, "GEOM", "NONE"];
        if (count _intersects > 0) then {
            _obj setPosASL ((_intersects # 0) # 0);
        } else {
            _obj setPosASL (AGLToASL _pos);
        };
    } else {
        _obj setPosATL [_pos#0, _pos#1, 0];
    };
    
    _obj setVectorUp [0,0,1];
    _obj
};

while {true} do {
    {
        private _baseKey = _x;
        
        // ====================================================================
        // 1. TERMINALS & ARSENALS (Ammo Caches)
        // ====================================================================
        private _terminals = ([_baseKey, "Arsenal"] call QM_fnc_getLocationsByPrefix) + ([_baseKey, "Terminal"] call QM_fnc_getLocationsByPrefix);
        
        if (count _terminals == 0) then { 
            _terminals = [[objNull, getMarkerPos _baseKey, markerDir _baseKey, "MARKER", format ["%1_Terminal_Fallback", _baseKey]]]; 
            diag_log format ["QUARTERMASTER WARNING: No explicit _Arsenal or _Terminal objects/markers found for %1.", _baseKey];
        };

        {
            _x params ["_entity", "_pos", "_dir", "_type", "_identityName"];
            
            // Protect against string type-mapping crashes
            private _varVal = missionNamespace getVariable [_identityName, objNull];
            private _activeHub = if (_varVal isEqualType objNull) then { _varVal } else { objNull };
            
            // --- STEP A: ESTABLISH THE PHYSICAL HUB ---
            if (_type == "MARKER" && (isNull _activeHub || {!alive _activeHub})) then {
                private _existing = nearestObjects [_pos, _terminalClasses, 10];
                if (count _existing > 0) then {
                    _activeHub = _existing select 0;
                } else {
                    _activeHub = [selectRandom _terminalClasses, _pos, _dir] call _fnc_spawnSafely;
                };
                missionNamespace setVariable [_identityName, _activeHub, true]; 
            };
            
            if (_type == "OBJECT") then { _activeHub = _entity; };
            
            // LOG EVALUATION
            [_identityName, _pos, _activeHub] call _fnc_logStructureData;

            // --- STEP B: INITIALIZE THE HUB ---
            if (!isNull _activeHub && alive _activeHub) then {
                if ((_activeHub getVariable ["QM_Crate_OwningBase", ""]) == "") then {
                    _activeHub setVariable ["QM_Crate_OwningBase", _baseKey, true];
                    _activeHub addEventHandler ["ContainerOpened", { _this call QM_fnc_traderOnContainerOpened; }];
                    _activeHub addEventHandler ["ContainerClosed", { _this call QM_fnc_traderOnContainerClosed; }];

                    clearWeaponCargoGlobal _activeHub; clearMagazineCargoGlobal _activeHub; clearItemCargoGlobal _activeHub; clearBackpackCargoGlobal _activeHub;
                    
                    if (!isNil "G_Allowed_Weapons") then {
                        { _activeHub addWeaponCargoGlobal [_x select 0, _x select 1]; } forEach G_Allowed_Weapons;
                        { _activeHub addMagazineCargoGlobal [_x select 0, _x select 1]; } forEach G_Allowed_Magazines;
                        { _activeHub addItemCargoGlobal [_x select 0, _x select 1]; } forEach G_Allowed_Items;
                        { _activeHub addBackpackCargoGlobal [_x select 0, _x select 1]; } forEach G_Allowed_Backpacks;
                    };
                };

                // --- STEP C: JIP SAFE PIPELINE ---
                if (!(_activeHub getVariable ["QM_TerminalUnifiedActionsActive", false])) then {
                    _activeHub setVariable ["QM_TerminalUnifiedActionsActive", true, true];
                    private _globalHubs = missionNamespace getVariable ["QM_Global_Terminals", []];
                    _globalHubs pushBackUnique _activeHub;
                    missionNamespace setVariable ["QM_Global_Terminals", _globalHubs, true];
                };
            };
        } forEach _terminals;

        // ====================================================================
        // 2. INFANTRY SPAWNS (Cargo Houses - Hook Only, No Spawn)
        // ====================================================================
        private _spawns = [_baseKey, "Spawn"] call QM_fnc_getLocationsByPrefix;
        {
            _x params ["_entity", "_pos", "_dir", "_type", "_identityName"];
            private _linkedStructure = objNull;

            if (_type == "MARKER") then {
                private _existing = nearestObjects [_pos, _spawnClasses, 15];
                if (count _existing > 0) then { 
                    _linkedStructure = _existing select 0;
                    missionNamespace setVariable [_identityName, _linkedStructure, true]; 
                };
            };

            // LOG EVALUATION
            [_identityName, _pos, _linkedStructure] call _fnc_logStructureData;

        } forEach _spawns;

        // ====================================================================
        // 3. PHYSICAL GARAGES & BOAT RACKS
        // ====================================================================
        private _allGarages = allMapMarkers select { _x find format ["%1_Garage", _baseKey] == 0 };
        {
            private _markerName = _x;
            private _pos = getMarkerPos _markerName;
            private _dir = markerDir _markerName;
            private _mUpper = toUpper _markerName;
            
            private _padClass = "Land_HelipadEmpty_F";
            if ("BOAT" in _mUpper) then { _padClass = "Land_Destroyer_01_Boat_Rack_01_F"; };
            
            private _existing = nearestObjects [_pos, _structuralPads, 30];
            private _pad = objNull;
            
            if (count _existing > 0) then {
                _pad = _existing select 0;
            } else {
                _pad = [_padClass, _pos, _dir] call _fnc_spawnSafely;
            };
            
            missionNamespace setVariable [_markerName, _pad, true];

            // LOG EVALUATION
            [_markerName, _pos, _pad] call _fnc_logStructureData;

        } forEach _allGarages;

    } forEach logisticsBases;
    uiSleep 8; 
};