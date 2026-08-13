// ============================================================================
// TACTICAL COMMAND CENTER: CLIENT MAP INTEL HOOK
// File: tsk_clientMapIntel.sqf
// Description: Handles all client-side intel reporting mechanisms.
//              1. Intercepts custom map markers and uploads them.
//              2. Monitors the "T" (Tactical Ping) keybind for visual spotting.
//              3. Radio triggers for automated LZ Pickup requests.
// Called By: init.sqf (Executed on Clients)
// ============================================================================

if (!hasInterface) exitWith {};
waitUntil { !isNull player };

diag_log "TACTICAL COMMAND CENTER: Initializing Map Intel UI Hook...";

// ============================================================================
// 1. BUILD THE GIN FIELD MANUAL (JOURNAL ENTRY)
// ============================================================================
// CRITICAL FIX: Removed exact bracket `<12` notation from Diary text. 
// Replaced with '(Under 12,000kg)' to prevent Arma 3 DiaryParser Map UI Lockup!
player createDiarySubject ["TacticalNet", "GIN"];
player createDiaryRecord ["TacticalNet", ["Intel Reporting Guide", "
<font size='16' color='#FF8C00'>Global Intelligence Network (GIN)</font><br/><br/>
As a field operative, you are responsible for reporting hostile contacts to the Tactical Operations Center. You can report intel via your Map or your optical sensors.<br/><br/>
<font color='#00FFFF'>1. Manual Map Markers:</font><br/>
Place a marker over the suspected target and type one of the following tags anywhere in the text field. The system will automatically overwrite your text with the standardized operational description.<br/>
  • <font color='#FF0000'>[CAS]</font> - Request Close Air Support (Ground Targets)<br/>
  • <font color='#FF0000'>[CAP]</font> - Request Combat Air Patrol (Air Targets)<br/>
  • <font color='#FF0000'>[INF]</font> - Request Infantry Assault/Sweep<br/>
  • <font color='#FF0000'>[ARM]</font> - Request Anti-Armor Support<br/>
  • <font color='#00FF00'>[CLT]</font> - Request Combat Logistics Transport<br/><br/>
<font color='#00FFFF'>2. Combat Logistics (CLT) Extraction:</font><br/>
Infantry or Light Vehicles (Under 12,000kg) can request airlift via two methods:<br/>
  • <font color='#FFFF00'>Map Markers:</font> Double-click the map and place a 'Pickup' marker named 'LZ' (Helicopter) or 'TAXI' (Ground). Place an 'End' marker with the same name for dropoff. The task will generate automatically.<br/>
  • <font color='#FFFF00'>Radio Call:</font> Open your Comms menu and dial <font color='#00FF00'>Radio Alpha (0-0-1)</font>. A pickup will be requested at the nearest suitable flat clearing.<br/><br/>
<font color='#00FFFF'>3. Visual Spotting (Keybind):</font><br/>
Aim your weapon, binoculars, or drone camera at a hostile vehicle and press your <font color='#FFFF00'>Tactical Ping key (Default: T)</font>. The vehicle's class will be automatically identified and uploaded to the GIN ledger.
"]];

// ============================================================================
// 2. RADIO TRIGGER FOR QUICK PICKUP (Method 1)
// ============================================================================
// FIX: Separated execution code into function block so // comments don't break string triggers
TSK_fnc_requestRadioAirlift = {
    private _veh = vehicle player;
    private _canSling = (_veh == player) || {(_veh isKindOf "LandVehicle" || _veh isKindOf "Ship") && getMass _veh <= 12000};
    if (!_canSling) exitWith { systemChat "TACTICAL NET: Vehicle too heavy for airlift. Request Denied."; };
    
    // Find the nearest flat space suitable for a heavy helicopter landing
    private _lzPos = (getPos player) findEmptyPosition [10, 150, "B_Heli_Transport_01_F"];
    if (count _lzPos == 0) then { _lzPos = getPos player; }; 
    
    [player, "TRANSPORT_REQ", ["CLT_AIR"], _lzPos] remoteExec ["TSK_fnc_GIN_ReportIntel", 2];
    systemChat "TACTICAL NET: Quick Pickup Request submitted. Dispatching marker to nearest flat zone.";
};

private _trg = createTrigger ["EmptyDetector", [0,0,0], false];
_trg setTriggerActivation ["ALPHA", "PRESENT", true];
_trg setTriggerText "Request Logistics Pickup (LZ)";
_trg setTriggerStatements ["this", "call TSK_fnc_requestRadioAirlift;", ""];

// ============================================================================
// 3. MANUAL MAP MARKER INTERCEPTOR (Method 2)
// ============================================================================
addMissionEventHandler ["MarkerCreated", {
    params ["_marker", "_channel", "_owner"];
    
    // Engine-safe check: Player-placed map markers always contain "_USER_DEFINED"
    if (!("_USER_DEFINED" in _marker)) exitWith {};
    if (_owner != player) exitWith {};

    private _markerText = markerText _marker;
    private _textUpper = toUpper _markerText;
    private _markerType = markerType _marker;
    
    // --- SPECIAL INTERCEPT: TWO-PART LZ EXTRACTION ---
    private _isPickupIcon = (_markerType in ["mil_pickup", "hd_pickup"]);
    private _isDropoffIcon = (_markerType in ["mil_end", "hd_end"]);

    if ((_isPickupIcon || _isDropoffIcon) && (_textUpper == "LZ" || _textUpper == "TAXI")) exitWith {
        private _veh = vehicle player;
        private _canSling = (_veh == player) || {(_veh isKindOf "LandVehicle" || _veh isKindOf "Ship") && getMass _veh <= 12000};
        
        if (!_canSling) exitWith { 
            systemChat "TACTICAL NET: Vehicle too heavy for transport. Request denied."; 
            deleteMarker _marker;
        };

        private _varPrefix = if (_textUpper == "LZ") then { "TSK_LZ" } else { "TSK_TAXI" };
        private _transportTag = if (_textUpper == "LZ") then { "CLT_AIR" } else { "CLT_GROUND" };

        if (_isPickupIcon) then {
            player setVariable [format["%1_PU", _varPrefix], getMarkerPos _marker];
            systemChat format ["TACTICAL NET: %1 Pickup Registered. Place '%1' End marker for Dropoff.", _textUpper];
        } else {
            player setVariable [format["%1_DO", _varPrefix], getMarkerPos _marker];
            systemChat format ["TACTICAL NET: %1 Dropoff Registered. Place '%1' Pickup marker.", _textUpper];
        };
        deleteMarker _marker;

        private _pu = player getVariable [format["%1_PU", _varPrefix], []];
        private _do = player getVariable [format["%1_DO", _varPrefix], []];
        
        if (count _pu > 0 && count _do > 0) then {
            // Both points verified! Ship to GIN with dropoff payload.
            [player, "TRANSPORT_REQ", [_transportTag], _pu, _do] remoteExec ["TSK_fnc_GIN_ReportIntel", 2];
            systemChat format ["TACTICAL NET: %1 Transport Request verified and dispatched to GIN.", _textUpper];
            player setVariable [format["%1_PU", _varPrefix], nil];
            player setVariable [format["%1_DO", _varPrefix], nil];
        };
    };

    // --- STANDARD BRACKET INTEL ---
    if ("[" in _markerText && "]" in _markerText) then {
        private _startIndex = _markerText find "[";
        private _endIndex = _markerText find "]";
        private _tagString = _markerText select [_startIndex + 1, (_endIndex - _startIndex) - 1];
        
        private _rawTags = _tagString splitString ", ";
        private _tags = _rawTags apply { toUpper _x };

        private _category = "UNKNOWN";
        if ("ARM" in _tags || "CAS" in _tags || "MECH" in _tags) then { _category = "ARMOR"; };
        if ("CAP" in _tags) then { _category = "AIR"; };
        // Map old basic [CLT] tags to hit all logi trucks and aircraft
        if ("CLT" in _tags) then { _category = "TRANSPORT_REQ"; _tags pushBack "CLT_AIR"; _tags pushBack "CLT_GROUND"; };
        if ("INF" in _tags || "RECCE" in _tags) then { _category = "INFANTRY"; };

        private _pos = getMarkerPos _marker;
        deleteMarker _marker;

        [objNull, _category, _tags, _pos] remoteExec ["TSK_fnc_GIN_ReportIntel", 2];
        systemChat format ["TACTICAL NET: Intel accepted. Broadcasting %1 coordinates to relevant task systems.", _tags];
    };
}];

// ============================================================================
// 4. VISUAL SPOTTING INTERCEPTOR (THE 'T' KEY)
// ============================================================================
[] spawn {
    waitUntil {!isNull (findDisplay 46)};
    (findDisplay 46) displayAddEventHandler ["KeyDown", {
        params ["_displayorcontrol", "_key", "_shift", "_ctrl", "_alt"];
        private _handled = false;
        
        if (_key in (actionKeys "TacticalPing") || _key in (actionKeys "LockTarget")) then {
            private _target = cursorTarget;
            
            if (!isNull _target && {side _target != playerSide} && {alive _target}) then {
                private _category = "UNKNOWN";
                private _tags = [];
                
                if (_target isKindOf "Air") then { 
                    _category = "AIR"; _tags = ["INT"]; 
                } else {
                    if (isVehicleRadarOn _target) then {
                        _category = "RADAR"; _tags = ["SEAD"];
                    } else {
                        if (_target isKindOf "Tank" || _target isKindOf "Car") then { 
                            _category = "ARMOR"; _tags = ["CAS", "ARM"]; 
                        };
                    };
                };
                if (_target isKindOf "Man") then { _category = "INFANTRY"; _tags = ["RECCE"]; };

                if (_category != "UNKNOWN") then {
                    [_target, _category, _tags, getPos _target] remoteExec ["TSK_fnc_GIN_ReportIntel", 2];
                    systemChat format ["TACTICAL NET: Visual contact uploaded. System Class: %1", _category];
                };
            };
        };
        _handled
    }];
};