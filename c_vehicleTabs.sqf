// ============================================================================
// LOGISTICS SYSTEM: VEHICLE TAB CONTENT POPULATOR (PART 2)
// File: c_vehicleTabs.sqf
// Description: Sorts blueprints dynamically into 7 precise tabs using native
//              Arma 3 isKindOf engine inheritance logic.
//              Actively filters out blueprints that belong to hostile factions,
//              exceed the facility's base restriction tag, or lack a valid
//              deployment pad at the current facility.
// Called By: qm_quartermasterUI.hpp (Button Actions from Motorpool Menu)
// ============================================================================

private _tabIndex = param [0, 0, [0]];
disableSerialization;

private _display = findDisplay 8888; 
if (isNull _display) then { _display = uiNamespace getVariable ["QM_Vehicle_Display", displayNull]; };
if (isNull _display) exitWith {};

private _listBox = _display displayCtrl 1600;
lbClear _listBox;

_display setVariable ["QM_Vehicle_Active_Tab", _tabIndex];

private _baseKey = player getVariable ["QM_Current_Terminal_Base", ""];
private _isSB = (["SB", _baseKey] call BIS_fnc_inString);
private _playerFaction = str (side group player);

// --- PRE-SCAN ALL AVAILABLE INFRASTRUCTURE AT THIS BASE (Markers AND Objects) ---
private _allGarageMarkers = [];
private _searchStr = toUpper format ["%1_Garage", _baseKey];

{ if ((toUpper _x) find _searchStr == 0) then { _allGarageMarkers pushBackUnique _x; }; } forEach allMapMarkers;

{
    if ((toUpper _x) find _searchStr == 0) then {
        private _val = missionNamespace getVariable [_x, objNull];
        if (_val isEqualType objNull && { !isNull _val }) then { _allGarageMarkers pushBackUnique _x; };
    };
} forEach (allVariables missionNamespace);

private _hasUniversal = (_allGarageMarkers findIf { !(["BOAT", _x] call BIS_fnc_inString) && !(["PLANE", _x] call BIS_fnc_inString) && !(["HELICOPTER", _x] call BIS_fnc_inString) && !(["AIR", _x] call BIS_fnc_inString) }) != -1;
private _hasBoat  = _hasUniversal || (_allGarageMarkers findIf { ["BOAT", _x] call BIS_fnc_inString }) != -1;
private _hasPlane = _hasUniversal || (_allGarageMarkers findIf { ["PLANE", _x] call BIS_fnc_inString }) != -1 || (_allGarageMarkers findIf { ["AIR", _x] call BIS_fnc_inString }) != -1;
private _hasHeli  = _hasUniversal || (_allGarageMarkers findIf { ["HELICOPTER", _x] call BIS_fnc_inString }) != -1 || (_allGarageMarkers findIf { ["AIR", _x] call BIS_fnc_inString }) != -1;
private _hasGround = count _allGarageMarkers > 0;

{
    _x params ["_displayName", "_classname", "_massCost", ["_restrictionType", "ALL"], ["_faction", "ALL"], ["_vehSize", "M"]];
    
    if (_faction == "ALL" || _faction == _playerFaction) then {
        if (_restrictionType == "ALL" || (_restrictionType == "SB" && _isSB)) then {
            
            // --- ENGINE-NATIVE INHERITANCE CHECKS (STRICT OOP) ---
            // Natively flags both UGVs and UAVs
            private _isDrone = getNumber (configFile >> "CfgVehicles" >> _classname >> "isUav") == 1;
            
            private _isBoat    = _classname isKindOf "Ship";
            private _isPlane   = _classname isKindOf "Plane";
            private _isHeli    = _classname isKindOf "Helicopter";
            private _isTracked = _classname isKindOf "Tank";
            private _isWheeled = _classname isKindOf "Car" || _classname isKindOf "Motorcycle"; // Catches ATVs
            
            // Supply catch-all: If it's not a drone, and not a standard vehicle, it's a static supply object
            private _isSupply  = !(_isBoat || _isPlane || _isHeli || _isTracked || _isWheeled || _isDrone);

            // Requirement matching for physical pads
            private _reqPad = "GROUND";
            if (_isBoat) then { _reqPad = "BOAT"; }
            else { if (_isPlane) then { _reqPad = "PLANE"; }
            else { if (_isHeli) then { _reqPad = "HELICOPTER"; }; }; };

            private _padExists = switch (_reqPad) do {
                case "BOAT": { _hasBoat };
                case "PLANE": { _hasPlane };
                case "HELICOPTER": { _hasHeli };
                default { _hasGround };
            };

            // Map UI Tab Index to Vehicle Category
            private _tabValid = false;
            switch (_tabIndex) do {
                case 0: { _tabValid = _isWheeled && !_isDrone; };  // 0: Wheeled
                case 1: { _tabValid = _isTracked && !_isDrone; };  // 1: Tracked
                case 2: { _tabValid = _isHeli && !_isDrone; };     // 2: Helicopter
                case 3: { _tabValid = _isPlane && !_isDrone; };    // 3: Plane
                case 4: { _tabValid = _isBoat && !_isDrone; };     // 4: Boat
                case 5: { _tabValid = _isDrone; };                 // 5: Drone
                case 6: { _tabValid = _isSupply && !_isDrone; };   // 6: Supplies
            };

            if (_tabValid && _padExists) then {
                
                // --- MULTI-RESOURCE UI FORMATTER ---
                private _costStringArray = [];
                {
                    _x params ["_poolName", "_poolVal"];
                    // Ignore anything 0, or astronomically high (like the 1,000,000,000 internal tank caps)
                    if (_poolVal > 0 && _poolVal < 10000000) then { 
                        private _shortName = switch (_poolName) do {
                            case "Vehicle": { "Veh" };
                            case "Cargo": { "Crg" };
                            case "Ammo": { "Ammo" };
                            case "Fuel": { "Fuel" };
                            case "Medical": { "Med" };
                            case "Repair": { "Rep" };
                            case "Troops": { "Trp" };
                            default { _poolName };
                        };
                        _costStringArray pushBack format ["%1 %2", round _poolVal, _shortName];
                    };
                } forEach _massCost;
                
                private _costStr = _costStringArray joinString " | ";
                if (_costStr == "") then { _costStr = "Free"; };

                private _label = format ["[%2] - %1", _displayName, _costStr];
                private _idx = _listBox lbAdd _label;
                _listBox lbSetValue [_idx, _forEachIndex];
            };
        };
    };
} forEach G_Procureable_Vehicles;

if (lbSize _listBox > 0) then { _listBox lbSetCurSel 0; };