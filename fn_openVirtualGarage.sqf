// ============================================================================
// LOGISTICS SYSTEM: VIRTUAL GARAGE DISPLAY OVERRIDE (PART 2)
// File: fn_openVirtualGarage.sqf
// Description: Closes the active dialog and safely launches the native
//              Arma 3 Virtual Garage interface. 
//              *FIX*: Abandoned V_Garage markers. Now automatically scans all
//              Garage pads and anchors to the largest size capacity marker.
// Called By: qm_clientActionCompiler.sqf (Terminal Hub Action Menu)
// ============================================================================

private _targetBox = player getVariable ["QM_Current_Terminal_Box", objNull];
private _baseKey = player getVariable ["QM_Current_Terminal_Base", ""];

// Force kill interface window parameters clear before launching visual engine grid
closeDialog 0;

// Grab all standard garage infrastructure (Markers AND Objects) for this base
private _allGarages = [];
private _searchStr = toUpper format ["%1_Garage", _baseKey];

{ if ((toUpper _x) find _searchStr == 0) then { _allGarages pushBackUnique _x; }; } forEach allMapMarkers;

{
    if ((toUpper _x) find _searchStr == 0) then {
        private _val = missionNamespace getVariable [_x, objNull];
        if (_val isEqualType objNull && { !isNull _val }) then { _allGarages pushBackUnique _x; };
    };
} forEach (allVariables missionNamespace);

private _bestMarker = "";

if (count _allGarages > 0) then {
    // Priority list to find the biggest physical clearance pad so the preview UI doesn't clip
    private _sizePriority = ["_XL", "_L", "_PLANE", "_HELICOPTER", "_M", "_S", "_XS", "_XXS"];
    
    {
        private _suffix = _x;
        private _found = _allGarages findIf { (toUpper _x) find _suffix != -1 };
        if (_found != -1) exitWith { _bestMarker = _allGarages select _found; };
    } forEach _sizePriority;
    
    // If no size tags exist, just grab the first one
    if (_bestMarker == "") then { _bestMarker = _allGarages select 0; };
};

if (_bestMarker != "") then {
    // Fetch the bound invisible Helipad object created by the server
    private _targetObject = missionNamespace getVariable [_bestMarker, objNull];
    
    if (!isNull _targetObject) then {
        ["Open", [true, _targetObject]] call BIS_fnc_garage;
    } else {
        // Extreme failsafe
        ["Open", [true, _targetBox]] call BIS_fnc_garage;
    };
} else {
    // Fallback to the terminal box only if the mission maker forgot to place ANY garage markers
    systemChat "QM WARNING: No _Garage markers found at this base. Anchoring simulation to terminal.";
    ["Open", [true, _targetBox]] call BIS_fnc_garage;
};