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

// Base Type & Operational Role Evaluation
private _baseType = if (!isNil "logi_fnc_getBaseType") then { [_baseKey] call logi_fnc_getBaseType } else { "FOB" };
private _baseRole = if (!isNil "logi_fnc_getBaseRole") then { [_baseKey] call logi_fnc_getBaseRole } else { "TACTICAL" };

private _isSB = (_baseRole == "STRATEGIC");
private _isFOB = (_baseRole in ["TACTICAL", "CLT"]);

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
{
    if ((toUpper _x) find _prefixUpper == 0) then {
        private _val = missionNamespace getVariable [_x, objNull];
        if (_val isEqualType objNull && { !isNull _val }) then { _allGarages pushBackUnique _x; };
    };
} forEach (allVariables missionNamespace);

// Also include garage pads synced in Eden Editor to the master base anchor/flagpole
private _baseObj = missionNamespace getVariable [_baseKey, objNull];
if (!isNull _baseObj) then {
    {
        if !(_x isKindOf "EmptyDetector") then {
            private _cName = vehicleVarName _x;
            private _cUpper = toUpper _cName;
            if (_cUpper find "GARAGE" >= 0 || _cUpper find "BOAT" >= 0 || _cUpper find "GROUND" >= 0 || _cUpper find "AIR" >= 0 || _cUpper find "HELI" >= 0 || _cUpper find "PLANE" >= 0 || _cUpper find "PAD" >= 0) then {
                _allGarages pushBackUnique _cName;
            };
        };
    } forEach ([_baseObj] call QM_fnc_getSyncedObjects);
};

{
    private _mUpper = toUpper _x;
    
    // Slice off prefix length (if full name like SB_Main_Garage_Air_1) or local garage token (if synced short name like _garage_air_1)
    private _remainder = if (_mUpper find _prefixUpper == 0) then {
        _mUpper select [_prefixLen]
    } else {
        private _gIdx = _mUpper find "GARAGE";
        if (_gIdx >= 0) then { _mUpper select [_gIdx + 6] } else { _mUpper };
    }; 
    
    // Multi-Category & Granular Per-Category Size Parser
    private _tokens = _remainder splitString "_";
    private _padGroundSize = -1;
    private _padHeliSize = -1;
    private _padPlaneSize = -1;
    private _padBoatSize = -1;
    private _hasGround = false;
    private _hasHeli = false;
    private _hasPlane = false;
    private _hasBoat = false;
    private _defaultPadSize = 6;
    private _lastCat = "";

    {
        private _t = _x;
        if (_t in ["GROUND", "CAR", "TANK"]) then { _hasGround = true; _lastCat = "GROUND"; };
        if (_t in ["HELI", "HELICOPTER"]) then { _hasHeli = true; _lastCat = "HELI"; };
        if (_t in ["PLANE"]) then { _hasPlane = true; _lastCat = "PLANE"; };
        if (_t in ["BOAT"]) then { _hasBoat = true; _lastCat = "BOAT"; };
        if (_t in ["AIR"]) then { _hasHeli = true; _hasPlane = true; _lastCat = "AIR"; };

        private _szVal = -1;
        switch (_t) do {
            case "XXS":  { _szVal = 0; };
            case "XS":   { _szVal = 1; };
            case "S":    { _szVal = 2; };
            case "M":    { _szVal = 3; };
            case "L":    { _szVal = 4; };
            case "XL":   { _szVal = 5; };
            case "OPEN": { _szVal = 6; };
        };

        if (_szVal != -1) then {
            switch (_lastCat) do {
                case "GROUND": { _padGroundSize = _szVal; };
                case "HELI":   { _padHeliSize = _szVal; };
                case "PLANE":  { _padPlaneSize = _szVal; };
                case "BOAT":   { _padBoatSize = _szVal; };
                case "AIR":    { _padHeliSize = _szVal; _padPlaneSize = _szVal; };
                default        { _defaultPadSize = _szVal; };
            };
        };
    } forEach _tokens;

    // Universal pad fallback: If no specific category was appended, it handles all categories with _defaultPadSize
    private _isUniversalPad = (!_hasGround && !_hasHeli && !_hasPlane && !_hasBoat);
    if (_isUniversalPad) then {
        _maxGroundSize = _maxGroundSize max _defaultPadSize;
        _maxHeliSize = _maxHeliSize max _defaultPadSize;
        _maxPlaneSize = _maxPlaneSize max _defaultPadSize;
        _maxBoatSize = _maxBoatSize max _defaultPadSize;
    } else {
        if (_hasGround) then {
            private _effGround = if (_padGroundSize != -1) then { _padGroundSize } else { _defaultPadSize };
            _maxGroundSize = _maxGroundSize max _effGround;
        };
        if (_hasHeli) then {
            private _effHeli = if (_padHeliSize != -1) then { _padHeliSize } else { _defaultPadSize };
            _maxHeliSize = _maxHeliSize max _effHeli;
        };
        if (_hasPlane) then {
            private _effPlane = if (_padPlaneSize != -1) then { _padPlaneSize } else { _defaultPadSize };
            _maxPlaneSize = _maxPlaneSize max _effPlane;
        };
        if (_hasBoat) then {
            private _effBoat = if (_padBoatSize != -1) then { _padBoatSize } else { _defaultPadSize };
            _maxBoatSize = _maxBoatSize max _effBoat;
        };
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
    
    if (_classname != "" && { isClass (configFile >> "CfgVehicles" >> _classname) }) then {
        
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

        // --- Core Template Filters (Case-Insensitive) ---
        private _systemsUpper = _systemsArray apply { toUpper _x };
        private _validSystem = ("ALL" in _systemsUpper || "QUARTERMASTER" in _systemsUpper);
        private _validFaction = (toUpper _faction == "ALL" || toUpper _faction == _playerFaction);
        private _terrainUpper = _terrainArray apply { toUpper _x };
        private _validTerrain = ("ALL" in _terrainUpper || _currentTerrain in _terrainUpper);
        
        // Base Restriction ("ALL"/"BOTH" = Strategic or Tactical, "SB" = Strategic, "FOB" = Tactical, or Specific Base Type / Base Name)
        private _validBaseRestriction = false;
        if (_restrictionType isEqualType []) then {
            private _restList = _restrictionType apply { toUpper _x };
            if ("ALL" in _restList || "BOTH" in _restList) then { _validBaseRestriction = (_isSB || _isFOB); };
            if ("SB" in _restList && _isSB) then { _validBaseRestriction = true; };
            if ("FOB" in _restList && _isFOB) then { _validBaseRestriction = true; };
            if (_baseType in _restList || _bkUpper in _restList) then { _validBaseRestriction = true; };
        } else {
            private _restUpper = toUpper _restrictionType;
            if (_restUpper in ["ALL", "BOTH"]) then { _validBaseRestriction = (_isSB || _isFOB); };
            if (_restUpper == "SB" && _isSB) then { _validBaseRestriction = true; };
            if (_restUpper == "FOB" && _isFOB) then { _validBaseRestriction = true; };
            if (_restUpper == _baseType || _restUpper == _bkUpper) then { _validBaseRestriction = true; };
        };
        
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
                    // If drivable vehicle, ignore Troops and Cargo costs since vehicle spawns empty
                    private _isIgnored = (!_isSupply && !_isDrone && (_poolName in ["Troops", "Cargo"]));
                    if (!_isIgnored && _poolVal > 0 && _poolVal < 1000000) then { 
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