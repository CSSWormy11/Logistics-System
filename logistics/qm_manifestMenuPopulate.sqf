// ============================================================================
// LOGISTICS SYSTEM: SELECTIVE CARGO MANIFEST POPULATOR (SECTION 5.3)
// File: fn_manifestMenuPopulate.sqf
// Description: Queries nearby valid supply crates and current vehicle cargo,
//              filters out props/clutter/terminals, evaluates ViV fit status
//              and field-loading rules, and populates the dual manifest UI.
// Execution: Client-side (Called on dialog open and refresh)
// ============================================================================

disableSerialization;

private _display = uiNamespace getVariable ["QM_Manifest_Display", displayNull];
if (isNull _display) exitWith {};

private _veh = uiNamespace getVariable ["QM_Manifest_TargetVehicle", objNull];
if (isNull _veh || !alive _veh) exitWith {
    closeDialog 0;
};

private _listBoxGround = _display displayCtrl 1500;
lbClear _listBoxGround;

private _listBoxBay = _display displayCtrl 1550;
lbClear _listBoxBay;

private _statusCtrl = _display displayCtrl 1001;

// --- 1. EVALUATE VEHICLE STATE & ENVIRONMENT ---
private _vehClass = typeOf _veh;
private _vehName = getText (configFile >> "CfgVehicles" >> _vehClass >> "displayName");
if (_vehName == "") then { _vehName = _vehClass; };

private _inLoadingZone = [_veh] call QM_fnc_isInsideLoadingZone;
private _caps = [_veh] call QM_fnc_getFieldLoadingCapabilities;
private _hasCrane = ("ALL" in _caps);
private _hasWinch = ("Huron_Containers" in _caps || "Slingload_01_Base_F" in _caps);

private _zoneLabel = if (_inLoadingZone) then {
    "Base Loading Zone (Unrestricted ViV)"
} else {
    if (_hasCrane) then {
        "Field Zone (Onboard Crane Active)"
    } else {
        if (_hasWinch) then {
            "Field Zone (Container Winch Active)"
        } else {
            "Field Zone (Human Weight Tiers Active)"
        }
    }
};

private _currentCargo = getVehicleCargo _veh;
private _loadedCount = count _currentCargo;

_statusCtrl ctrlSetText format ["Vehicle: %1  |  Location: %2  |  Bay Load: %3 item(s)", _vehName, _zoneLabel, _loadedCount];

// --- 2. POPULATE RIGHT COLUMN: VEHICLE CARGO BAY ---
private _bayObjects = [];
{
    private _cargoObj = _x;
    if (!isNull _cargoObj) then {
        private _cClass = typeOf _cargoObj;
        private _cName = getText (configFile >> "CfgVehicles" >> _cClass >> "displayName");
        if (_cName == "") then { _cName = _cClass; };
        
        private _category = [_cargoObj] call QM_fnc_getCargoCategory;
        private _mass = getMass _cargoObj;
        if (_mass <= 0) then {
            _mass = getNumber (configFile >> "CfgVehicles" >> _cClass >> "mass");
        };

        private _entryText = format ["[%1] %2 (%3 lbs)", _category, _cName, round _mass];
        private _idx = _listBoxBay lbAdd _entryText;
        _listBoxBay lbSetValue [_idx, count _bayObjects];
        _bayObjects pushBack _cargoObj;

        private _pic = getText (configFile >> "CfgVehicles" >> _cClass >> "editorPreview");
        if (_pic == "") then { _pic = getText (configFile >> "CfgVehicles" >> _cClass >> "picture"); };
        if (_pic != "") then { _listBoxBay lbSetPicture [_idx, _pic]; };
    };
} forEach _currentCargo;

uiNamespace setVariable ["QM_Manifest_BayObjects", _bayObjects];

if (count _bayObjects == 0) then {
    private _idx = _listBoxBay lbAdd "Vehicle cargo bay is currently empty.";
    _listBoxBay lbSetColor [_idx, [0.6, 0.6, 0.6, 0.8]];
};

// --- 3. SCAN & FILTER LEFT COLUMN: GROUND SUPPLIES ---
private _nearEntities = nearestObjects [_veh, ["ReammoBox_F", "ThingX", "LandVehicle", "Air", "Ship"], 25];
private _groundCandidates = [];

// Scene props, clutter, and non-cargo blacklists
private _propBlacklist = [
    "RoadCone_F", "RoadCone_L_F", "TargetBase", "Sign_F", "Land_BarGate_F",
    "Land_HelipadEmpty_F", "Land_HelipadSquare_F", "Land_HelipadCivil_F", "Land_HelipadRescue_F",
    "Land_Can_V3_F", "WeaponHolder", "GroundWeaponHolder", "WeaponHolderSimulated", "Helper_Base_F"
];

private _supplyScores = missionNamespace getVariable ["supplyScores", []];

{
    private _candidate = _x;
    if (isNull _candidate || !alive _candidate) then { continue; };
    if (_candidate == _veh || _candidate == player) then { continue; };

    // Ignore items already loaded into any vehicle or attached to another object
    if (!isNull (isVehicleCargo _candidate) || !isNull (attachedTo _candidate)) then { continue; };

    // Ignore vehicles occupied by alive crew
    if ({ alive _x } count (crew _candidate) > 0) then { continue; };

    // Filter out blacklisted visual scene props
    private _candType = typeOf _candidate;
    if (_candType in _propBlacklist) then { continue; };
    if (_candidate isKindOf "Sign_F" || _candidate isKindOf "Building" || _candidate isKindOf "FlagCarrierCore") then { continue; };

    // Filter out editor-placed base facilities and terminals
    if (!isNil { _candidate getVariable "bis_fnc_arsenal_action" }) then { continue; };
    if (_candidate getVariable ["QM_TerminalUnifiedActionsActive", false]) then { continue; };
    if ((_candidate getVariable ["QM_Crate_OwningBase", ""]) != "") then { continue; };

    private _vName = vehicleVarName _candidate;
    if (_vName != "") then {
        private _vUpper = toUpper _vName;
        if (["_ARSENAL", "_TERMINAL", "_SPAWN", "_GARAGE", "_SERVICE"] findIf { _vUpper find _x != -1 } != -1) then { continue; };
    };

    // Confirm it is a recognized logistics supply asset
    private _inScores = (_supplyScores findIf { toLowerANSI (_x # 0) == toLowerANSI _candType } != -1);
    private _isLogiTagged = _candidate getVariable ["isLogisticsCargo", false];
    private _isHuronContainer = (_candidate isKindOf "Slingload_01_Base_F" || "B_Slingload_01_" in _candType);
    private _isSupplyBox = (_candidate isKindOf "ReammoBox_F");
    private _isGroundVeh = (_candidate isKindOf "LandVehicle" && _candType != _vehClass);

    if (!_inScores && !_isLogiTagged && !_isHuronContainer && !_isSupplyBox && !_isGroundVeh) then { continue; };

    _groundCandidates pushBack _candidate;
} forEach _nearEntities;

// Sort by distance from target vehicle
_groundCandidates = [_groundCandidates, [], { _veh distance _x }, "ASC"] call BIS_fnc_sortBy;

private _groundObjects = [];
{
    private _cObj = _x;
    private _cClass = typeOf _cObj;
    private _cName = getText (configFile >> "CfgVehicles" >> _cClass >> "displayName");
    if (_cName == "") then { _cName = _cClass; };

    private _category = [_cObj] call QM_fnc_getCargoCategory;
    private _dist = round (_veh distance _cObj);

    private _mass = getMass _cObj;
    if (_mass <= 0) then {
        _mass = getNumber (configFile >> "CfgVehicles" >> _cClass >> "mass");
    };

    // Evaluate native ViV fit data
    private _fitData = _veh canVehicleCargo _cObj;
    private _fitsSpace = _fitData # 0;
    private _fitReason = _fitData # 1;

    // Evaluate field loading rules
    private _fieldAllowed = true;
    private _ruleNote = "";
    private _isHuron = (_cObj isKindOf "Slingload_01_Base_F" || "B_Slingload_01_" in _cClass);

    if (!_inLoadingZone) then {
        if (!_hasCrane) then {
            if (_isHuron) then {
                if (!_hasWinch) then {
                    _fieldAllowed = false;
                    _ruleNote = " [Req Winch/Zone]";
                };
            } else {
                if (_mass > 250) then {
                    _fieldAllowed = false;
                    _ruleNote = " [Req Crane/Zone]";
                } else {
                    if (_mass > 120 && _mass <= 250) then {
                        private _nearbyPlayers = allPlayers select { alive _x && { (_x distance _veh) <= 12 || (_x distance _cObj) <= 12 } };
                        if (count _nearbyPlayers < 2) then {
                            _ruleNote = " [Req 2 Players]";
                        } else {
                            _ruleNote = " [2-Man Ready]";
                        };
                    };
                };
            };
        };
    };

    private _fitTag = "";
    private _tagColor = [1, 1, 1, 1];

    if (_fitsSpace && _fieldAllowed) then {
        _fitTag = "[FITS]";
        _tagColor = [0.2, 0.9, 0.2, 1]; // Green
    } else {
        if (!_fitsSpace) then {
            _fitTag = switch (_fitReason) do {
                case 3: { "[BAY FULL]" };
                case 2: { "[NO BAY]" };
                default { "[TOO LARGE]" };
            };
            _tagColor = [0.9, 0.3, 0.2, 1]; // Red
        } else {
            _fitTag = "[RESTRICTED]";
            _tagColor = [1.0, 0.6, 0.1, 1]; // Orange
        };
    };

    private _labelText = format ["%1 [%2] %3 (%4 lbs, %5m)%6", _fitTag, _category, _cName, round _mass, _dist, _ruleNote];
    private _idx = _listBoxGround lbAdd _labelText;
    _listBoxGround lbSetColor [_idx, _tagColor];
    _listBoxGround lbSetValue [_idx, count _groundObjects];
    _groundObjects pushBack _cObj;

    private _pic = getText (configFile >> "CfgVehicles" >> _cClass >> "editorPreview");
    if (_pic == "") then { _pic = getText (configFile >> "CfgVehicles" >> _cClass >> "picture"); };
    if (_pic != "") then { _listBoxGround lbSetPicture [_idx, _pic]; };

} forEach _groundCandidates;

uiNamespace setVariable ["QM_Manifest_GroundObjects", _groundObjects];

if (count _groundObjects == 0) then {
    private _idx = _listBoxGround lbAdd "No eligible supply crates detected within 25m.";
    _listBoxGround lbSetColor [_idx, [0.6, 0.6, 0.6, 0.8]];
} else {
    // Select first item by default
    _listBoxGround lbSetCurSel 0;
};
