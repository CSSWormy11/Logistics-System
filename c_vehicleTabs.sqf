// ============================================================================
// LOGISTICS SYSTEM: MOTORPOOL UI TAB POPULATOR
// File: c_vehicleTabs.sqf
// Description: Populates the vehicle list based on selected UI tabs.
//              Dynamically parses base markers by string length subtraction
//              to precisely filter vehicles by type and size capabilities.
// ============================================================================

private _tabIndex = param [0, 0, [0]];
disableSerialization;

private _display = findDisplay 8888; 
if (isNull _display) then { _display = uiNamespace getVariable ["QM_Vehicle_Display", displayNull]; };
if (isNull _display) exitWith {};

private _listBox = _display displayCtrl 1600;
lbClear _listBox;

// Track the clicked tab into the display
_display setVariable ["QM_Vehicle_Active_Tab", _tabIndex];

private _baseKey = player getVariable ["QM_Current_Terminal_Base", ""];
private _bkUpper = toUpper _baseKey;

// Base Type Booleans (Strict string matching via native find)
private _isSB = (_bkUpper find "SB" >= 0);
private _isFOB = (_bkUpper find "FOB" >= 0);

private _playerFaction = toUpper (str playerSide);
private _currentTerrain = toUpper (call fn_G_getTerrain);

// ------------------------------------------------------------------------
// DYNAMIC BASE INFRASTRUCTURE SCANNER
// Parses the marker name by excluding the known base and garage prefix.
// Converts the remaining sizes to an index (0-6) to easily track the largest pad.
// ------------------------------------------------------------------------
private _maxGroundSize = -1;
private _maxHeliSize = -1;
private _maxPlaneSize = -1;
private _maxBoatSize = -1;

private _prefixUpper = toUpper format ["%1_Garage", _baseKey];
private _prefixLen = count _prefixUpper;

private _allGarages = [];
{ if ((toUpper _x) find _prefixUpper == 0) then { _allGarages pushBackUnique _x; }; } forEach allMapMarkers;

{
    if ((toUpper _x) find _prefixUpper == 0) then {
        private _val = missionNamespace getVariable [_x, objNull];
        if (_val isEqualType objNull && { !isNull _val }) then { _allGarages pushBackUnique _x; };
    };
} forEach (allVariables missionNamespace);

{
    private _mUpper = toUpper _x;
    
    // Slice off the known prefix length (e.g., "SB_CARRIER_GARAGE_AIR_L_1" -> "_AIR_L_1")
    private _remainder = _mUpper select [_prefixLen]; 
    
    // 1. Determine size limit index (0 = XXS ... 6 = OPEN)
    private _sz = 6; 
    if (_remainder find "_XXS" >= 0) then { _sz = 0; }
    else { if (_remainder find "_XS" >= 0) then { _sz = 1; }
    else { if (_remainder find "_S" >= 0) then { _sz = 2; }
    else { if (_remainder find "_M" >= 0) then { _sz = 3; }
    else { if (_remainder find "_L" >= 0) then { _sz = 4; }
    else { if (_remainder find "_XL" >= 0) then { _sz = 5; }; }; }; }; }; };
    
    // 2. Identify Pad Engine Type exclusively from the remaining string modifiers
    private _isPadBoat = (_remainder find "_BOAT" >= 0);
    private _isPadHeli = (_remainder find "_HELI" >= 0);
    private _isPadPlane = (_remainder find "_PLANE" >= 0);
    private _isPadAir = (_remainder find "_AIR" >= 0);
    private _isPadGround = (_remainder find "_GROUND" >= 0) || (_remainder find "_CAR" >= 0) || (_remainder find "_TANK" >= 0);
    
    // _AIR acts as a catch-all for both planes (hangars) and helicopters (open pads)
    if (_isPadAir) then { _isPadHeli = true; _isPadPlane = true; };
    
    // Universal pad fallback: If no specific type was appended, it handles everything
    if (!_isPadBoat && !_isPadHeli && !_isPadPlane && !_isPadGround) then {
        _maxGroundSize = _maxGroundSize max _sz;
        _maxHeliSize = _maxHeliSize max _sz;
        _maxPlaneSize = _maxPlaneSize max _sz;
        _maxBoatSize = _maxBoatSize max _sz;
    } else {
        if (_isPadBoat) then { _maxBoatSize = _maxBoatSize max _sz; };
        if (_isPadHeli) then { _maxHeliSize = _maxHeliSize max _sz; };
        if (_isPadPlane) then { _maxPlaneSize = _maxPlaneSize max _sz; };
        if (_isPadGround) then { _maxGroundSize = _maxGroundSize max _sz; };
    };
} forEach _allGarages;

// ------------------------------------------------------------------------
// UI LIST POPULATOR
// ------------------------------------------------------------------------
{
    _x params [
        "_displayName", 
        "_classArray", 
        "_costArray", 
        ["_restrictionType", "ALL"], 
        ["_faction", "ALL"], 
        ["_terrainArray", ["ALL"]], 
        ["_systemsArray", ["Quartermaster"]],
        ["_vehSize", ""]
    ];

    // Safely parse the classname to prevent 'Undefined Variable' execution crashes
    private _classname = "";
    if (_classArray isEqualType []) then {
        if (count _classArray > 0) then { _classname = _classArray select 0; };
    } else {
        if (_classArray isEqualType "") then { _classname = _classArray; };
    };
    
    if (_classname != "") then {
        
        // --- Auto-Size detection if missing from template ---
        if (_vehSize == "") then {
            private _isDrone = getNumber(configFile >> "CfgVehicles" >> _classname >> "isUav") == 1;
            if (_isDrone) then {
                _vehSize = "XXS"; 
            } else {
                if (_classname isKindOf "Helicopter" || _classname isKindOf "VTOL_Base_F") then {
                    _vehSize = "OPEN";
                } else {
                    if (_classname isKindOf "Plane") then { _vehSize = "L"; } 
                    else {
                        if (_classname isKindOf "Quadbike_01_base_F" || _classname isKindOf "Motorcycle") then { _vehSize = "S"; } 
                        else { _vehSize = "M"; };
                    };
                };
            };
        };

        // Convert vehicle string size to numeric index for direct comparison
        private _reqSz = 6;
        switch (toUpper _vehSize) do {
            case "XXS": { _reqSz = 0; };
            case "XS":  { _reqSz = 1; };
            case "S":   { _reqSz = 2; };
            case "M":   { _reqSz = 3; };
            case "L":   { _reqSz = 4; };
            case "XL":  { _reqSz = 5; };
            case "OPEN": { _reqSz = 6; };
        };

        // --- Core Template Filters ---
        private _validSystem = ("ALL" in _systemsArray || "Quartermaster" in _systemsArray);
        private _validFaction = (toUpper _faction == "ALL" || toUpper _faction == _playerFaction);
        private _terrainUpper = _terrainArray apply { toUpper _x };
        private _validTerrain = ("ALL" in _terrainUpper || _currentTerrain in _terrainUpper);
        
        // Base Restriction explicitly handled by Booleans
        private _validBaseRestriction = false;
        private _restUpper = toUpper _restrictionType;
        
        if (_restUpper == "ALL") then { _validBaseRestriction = true; };
        if (_restUpper == "SB" && _isSB) then { _validBaseRestriction = true; };
        if (_restUpper == "FOB" && _isFOB) then { _validBaseRestriction = true; };
        
        // --- Infrastructure Fit Check ---
        private _canFit = false;
        if (_classname isKindOf "Ship") then {
            if (_maxBoatSize >= _reqSz) then { _canFit = true; };
        };
        if (_classname isKindOf "Plane" && !(_classname isKindOf "Helicopter")) then {
            if (_maxPlaneSize >= _reqSz) then { _canFit = true; };
        };
        if (_classname isKindOf "Helicopter") then {
            if (_maxHeliSize >= _reqSz) then { _canFit = true; };
        };
        if (!(_classname isKindOf "Ship") && !(_classname isKindOf "Plane") && !(_classname isKindOf "Helicopter")) then {
            if (_maxGroundSize >= _reqSz) then { _canFit = true; };
        };

        // Build the UI if the vehicle passes all tests
        if (_validSystem && _validFaction && _validTerrain && _validBaseRestriction && _canFit) then {
            
            private _isDrone = getNumber (configFile >> "CfgVehicles" >> _classname >> "isUav") == 1;
            private _isBoat    = _classname isKindOf "Ship";
            private _isPlane   = _classname isKindOf "Plane";
            private _isHeli    = _classname isKindOf "Helicopter";
            private _isTracked = _classname isKindOf "Tank";
            private _isWheeled = _classname isKindOf "Car" || _classname isKindOf "Motorcycle"; 
            private _isSupply  = !(_isBoat || _isPlane || _isHeli || _isTracked || _isWheeled || _isDrone);
            
            // Filter array logic into current clicked UI Tab
            private _tabMatch = false;
            switch (_tabIndex) do {
                case 0: { _tabMatch = _isWheeled && !_isDrone; };
                case 1: { _tabMatch = _isTracked && !_isDrone; };
                case 2: { _tabMatch = _isHeli && !_isDrone; };
                case 3: { _tabMatch = _isPlane && !_isDrone; };
                case 4: { _tabMatch = _isBoat && !_isDrone; };
                case 5: { _tabMatch = _isDrone; };
                case 6: { _tabMatch = _isSupply && !_isDrone; };
            };
            
            if (_tabMatch) then {
                private _costStringArray = [];
                {
                    _x params ["_poolName", "_poolVal"];
                    if (_poolVal > 0 && _poolVal < 10000000) then { 
                        private _shortName = switch (_poolName) do {
                            case "Vehicle": { "Veh" }; case "Cargo": { "Crg" }; case "Ammo": { "Ammo" };
                            case "Fuel": { "Fuel" }; case "Medical": { "Med" }; case "Repair": { "Rep" };
                            case "Troops": { "Trp" }; default { _poolName };
                        };
                        _costStringArray pushBack format ["%1 %2", round _poolVal, _shortName];
                    };
                } forEach _costArray;
                
                private _costStr = _costStringArray joinString " | ";
                if (_costStr == "") then { _costStr = "Free"; };

                private _label = format ["[%2] - %1", _displayName, _costStr];
                private _idx = _listBox lbAdd _label;
                _listBox lbSetValue [_idx, _forEachIndex];
                
                private _pic = getText (configFile >> "CfgVehicles" >> _classname >> "editorPreview");
                if (_pic == "") then { _pic = getText (configFile >> "CfgVehicles" >> _classname >> "picture"); };
                if (_pic != "") then { _listBox lbSetPicture [_idx, _pic]; };
            };
        };
    };
} forEach G_Procureable_Vehicles;

if (lbSize _listBox > 0) then { _listBox lbSetCurSel 0; };