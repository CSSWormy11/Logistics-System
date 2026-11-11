// ============================================================================
// LOGISTICS SYSTEM: MOTORPOOL SALVAGEMAN (PART 2)
// File: fn_usedCarSalesman.sqf
// Description: Scans the base's garage pads, service zones, boat racks, and
//              terminal area for the nearest unoccupied vehicle and sends a
//              remote execution request to the server to scrap it for points.
// Called By: qm_clientActionCompiler.sqf (Terminal Hub Action Menu)
// ============================================================================

private _baseKey = player getVariable ["QM_Current_Terminal_Base", ""];
if (_baseKey == "") exitWith { hint "SALVAGEMAN ERROR: Missing active base identifier."; };

private _terminalBox = player getVariable ["QM_Current_Terminal_Box", objNull];
private _searchCenters = [getPosATL player];
if (!isNull _terminalBox) then { _searchCenters pushBack (getPosATL _terminalBox); };
if (getMarkerColor _baseKey != "") then { _searchCenters pushBack (getMarkerPos _baseKey); };

// Collect all Garage, Service, and Boat 3D object positions for this base
private _prefixUpper = toUpper _baseKey;
{
    if ((toUpper _x) find _prefixUpper == 0) then {
        private _vUpper = toUpper _x;
        if ("_GARAGE" in _vUpper || "_SERVICE" in _vUpper || "_BOAT" in _vUpper) then {
            private _val = missionNamespace getVariable [_x, objNull];
            if (_val isEqualType objNull && { !isNull _val }) then {
                _searchCenters pushBack (getPosATL _val);
            };
        };
    };
} forEach (allVariables missionNamespace);

private _globalTerminals = missionNamespace getVariable ["QM_Global_Terminals", []];
private _candidates = [];

{
    private _center = _x;
    // Use 2D search radius around each pad/terminal and check both ground/deck and water/air
    private _near = (_center nearEntities [["LandVehicle", "Air", "Ship"], 40]) + (nearestObjects [_center, ["LandVehicle", "Air", "Ship"], 40]);
    {
        if (
            alive _x &&
            { !(_x in _globalTerminals) } &&
            { (_x distance2D _center) <= 30 } &&
            { ({ isPlayer _x } count (crew _x)) == 0 }
        ) then {
            _candidates pushBackUnique _x;
        };
    } forEach _near;

    // Also check boat racks for loaded boats via Vehicle-in-Vehicle cargo
    private _racks = nearestObjects [_center, ["Land_Destroyer_01_Boat_Rack_01_F", "Land_Boat_Rack_01_F", "Land_BoatRack_01_F"], 40];
    {
        {
            if (alive _x && { ({ isPlayer _x } count (crew _x)) == 0 }) then {
                _candidates pushBackUnique _x;
            };
        } forEach (getVehicleCargo _x);
    } forEach _racks;
} forEach _searchCenters;

if (count _candidates == 0) exitWith {
    hint "SALVAGEMAN: No unoccupied vehicle detected on the base garage pads or terminal zone.";
};

// Pick the candidate vehicle closest to the player
private _sorted = _candidates apply { [_x distance player, _x] };
_sorted sort true;
private _targetScrapVehicle = (_sorted select 0) select 1;

[_baseKey, _targetScrapVehicle, player] remoteExec ["QM_fnc_serverVehicleSale", 2];