// ============================================================================
// LOGISTICS SYSTEM: STARTUP MARKER & STRUCTURE DIAGNOSTICS
// File: fn_startupMarkerDiagnostics.sqf
// Description: Evaluates markers at mission start, detects tied structures,
//              calculates bounding box corners, center, and compares to marker.
//              Used for mission-maker validation and safety checks.
// Execution: Server-side only (via init.sqf)
// ============================================================================

if (!isServer) exitWith {};

diag_log "======================================================================";
diag_log "QUARTERMASTER: INITIATING STARTUP MARKER & STRUCTURE DIAGNOSTICS";
diag_log "======================================================================";

// The classes we consider "infrastructure" to tie markers to
private _searchClasses = [
    "Land_Hangar_F", "Land_TentHangar_V1_F", "Land_ServiceHangar_01_L_F", "Land_ServiceHangar_01_R_F", 
    "Land_Airport_01_hangar_F", "Land_HelipadCircle_F", "Land_HelipadSquare_F", "Land_HelipadCivil_F", 
    "Land_HelipadEmpty_F", "Land_Destroyer_01_Boat_Rack_01_F", "Land_Boat_Rack_01_F", "Land_BoatRack_01_F", 
    "Land_Cargo_House_V1_F", "Land_Cargo_House_V3_F", "VirtualReammoBox_camonet_F"
];

// Ensure bases array has populated
if (isNil "logisticsBases") exitWith { diag_log "DIAGNOSTICS ERROR: logisticsBases is not defined."; };

{
    private _baseKey = _x;
    // Find every single marker associated with this base (e.g. SB_Garage_1, SB_Spawn_2)
    private _allBaseMarkers = allMapMarkers select { _x find _baseKey == 0 };

    {
        private _markerName = _x;
        private _markerPos = getMarkerPos _markerName;
        
        diag_log format ["--- EVALUATING MARKER: %1 ---", _markerName];
        diag_log format ["Marker Position (2D): [%1, %2]", _markerPos select 0, _markerPos select 1];
        
        // Check for tied structure (30m radius)
        private _nearbyStructures = nearestObjects [_markerPos, _searchClasses, 30];
        
        if (count _nearbyStructures > 0) then {
            private _structure = _nearbyStructures select 0;
            diag_log format ["Tied to Structure: YES | Class: %1", typeOf _structure];
            
            // Extract native engine bounding box
            private _bbr = boundingBoxReal _structure;
            private _p1 = _bbr select 0; // [minX, minY, minZ] -> Back-Left-Bottom
            private _p2 = _bbr select 1; // [maxX, maxY, maxZ] -> Front-Right-Top
            
            // Calculate local corners
            private _localFrontLeft = [_p1 select 0, _p2 select 1, _p1 select 2];
            private _localFrontRight = [_p2 select 0, _p2 select 1, _p1 select 2];
            private _localBackLeft = [_p1 select 0, _p1 select 1, _p1 select 2];
            private _localBackRight = [_p2 select 0, _p1 select 1, _p1 select 2];
            
            // Convert to World Pos
            private _worldFrontLeft = _structure modelToWorld _localFrontLeft;
            private _worldFrontRight = _structure modelToWorld _localFrontRight;
            private _worldBackLeft = _structure modelToWorld _localBackLeft;
            private _worldBackRight = _structure modelToWorld _localBackRight;
            
            // Calculate true center of bounding box volume
            private _localCenter = [((_p1 select 0) + (_p2 select 0)) / 2, ((_p1 select 1) + (_p2 select 1)) / 2, ((_p1 select 2) + (_p2 select 2)) / 2];
            private _worldCenter = _structure modelToWorld _localCenter;
            
            // Compare structure center to where the user manually placed the marker
            private _diffX = (_markerPos select 0) - (_worldCenter select 0);
            private _diffY = (_markerPos select 1) - (_worldCenter select 1);
            
            diag_log "STRUCTURE CORNERS (World Position):";
            diag_log format ["  Front-Left:  %1", _worldFrontLeft];
            diag_log format ["  Front-Right: %1", _worldFrontRight];
            diag_log format ["  Back-Left:   %1", _worldBackLeft];
            diag_log format ["  Back-Right:  %1", _worldBackRight];
            
            diag_log "POSITION COMPARISON:";
            diag_log format ["  Calculated Structure Center (World): [%1, %2]", _worldCenter select 0, _worldCenter select 1];
            diag_log format ["  Marker Placed At (World):            [%1, %2]", _markerPos select 0, _markerPos select 1];
            diag_log format ["  Offset (Marker from Center):         X: %1m | Y: %2m", _diffX, _diffY];
            diag_log format ["  Safest Spawn Pos (Center ASL):       %1", getPosASL _structure];
        } else {
            diag_log "Tied to Structure: NO (No compatible structures found within 30m).";
        };
        diag_log "----------------------------------------------------------------------";
    } forEach _allBaseMarkers;
} forEach logisticsBases;

diag_log "======================================================================";
diag_log "QUARTERMASTER: STARTUP MARKER DIAGNOSTICS COMPLETE";
diag_log "======================================================================";