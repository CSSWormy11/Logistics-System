// ============================================================================
// LOGISTICS SYSTEM: SELECTIVE CARGO LOAD EXECUTOR (SECTION 5.3)
// File: fn_manifestLoadExecute.sqf
// Description: Validates physical fit and capability rules, loads the selected
//              supply item into the vehicle, and refreshes the manifest UI.
// Execution: Client-side (Triggered by [LOAD SELECTED INTO VEHICLE] button)
// ============================================================================

disableSerialization;

private _display = uiNamespace getVariable ["QM_Manifest_Display", displayNull];
if (isNull _display) exitWith {};

private _veh = uiNamespace getVariable ["QM_Manifest_TargetVehicle", objNull];
if (isNull _veh || !alive _veh) exitWith {
    hint "CARGO MANIFEST: Target vehicle is no longer accessible.";
    closeDialog 0;
};

private _listBoxGround = _display displayCtrl 1500;
private _selIdx = lbCurSel _listBoxGround;
if (_selIdx == -1) exitWith {
    hint "Please select an available supply item from the Ground Supplies list.";
};

private _groundObjects = uiNamespace getVariable ["QM_Manifest_GroundObjects", []];
private _val = _listBoxGround lbValue _selIdx;

if (_val < 0 || _val >= count _groundObjects) exitWith {
    hint "Selection index invalid. Please refresh the manifest.";
    [] execVM "fn_manifestMenuPopulate.sqf";
};

private _cargoObj = _groundObjects select _val;
if (isNull _cargoObj || !alive _cargoObj) exitWith {
    hint "The selected cargo is no longer present or has been moved.";
    [] execVM "fn_manifestMenuPopulate.sqf";
};

// --- STEP 1: PHYSICAL FIT & SPACE VALIDATION ---
private _fitData = _veh canVehicleCargo _cargoObj;
private _canFit = _fitData # 0;
private _reason = _fitData # 1;

if (!_canFit) exitWith {
    private _err = switch (_reason) do {
        case 3: { "Cargo bay has insufficient remaining capacity for this item." };
        case 2: { "This vehicle does not possess a cargo bay." };
        default { "Item dimensions exceed vehicle cargo bay capacity." };
    };
    hint format ["CANNOT LOAD: %1", _err];
};

// --- STEP 2: FIELD-LOADING CAPABILITY RULES VALIDATION ---
private _inZone = [_veh] call QM_fnc_isInsideLoadingZone;
private _caps = [_veh] call QM_fnc_getFieldLoadingCapabilities;
private _hasCrane = ("ALL" in _caps);
private _hasWinch = ("Huron_Containers" in _caps || "Slingload_01_Base_F" in _caps);
private _isHuron = (_cargoObj isKindOf "Slingload_01_Base_F" || "B_Slingload_01_" in (typeOf _cargoObj));

private _mass = getMass _cargoObj;
if (_mass <= 0) then {
    _mass = getNumber (configFile >> "CfgVehicles" >> typeOf _cargoObj >> "mass");
};

private _allowed = true;

// Enforce field rules if outside designated base loading zone
if (!_inZone && !_hasCrane) then {
    if (_isHuron && !_hasWinch) exitWith {
        _allowed = false;
        hint "FIELD LOADING DENIED: Huron containers in the field require a vehicle equipped with a container winch (e.g. HEMTT Flatbed) or a Base Loading Zone!";
    };

    if (_mass > 250 && !_isHuron) exitWith {
        _allowed = false;
        hint format ["FIELD LOADING DENIED: Heavy cargo (%1 lbs) exceeds 250 lbs field limit! Requires a vehicle with an onboard crane or a Base Loading Zone.", round _mass];
    };

    if (_mass > 120 && _mass <= 250) then {
        private _nearbyPlayers = allPlayers select { alive _x && { (_x distance _veh) <= 12 || (_x distance _cargoObj) <= 12 } };
        if (count _nearbyPlayers < 2) then {
            _allowed = false;
            hint format ["TEAM LIFT REQUIRED: Cargo weighs %1 lbs. Loading medium items in the field requires at least TWO players nearby!", round _mass];
        };
    };
};

if (!_allowed) exitWith {};

// --- STEP 3: EXECUTE NATIVE VIV LOAD ---
private _cargoName = getText (configFile >> "CfgVehicles" >> typeOf _cargoObj >> "displayName");
if (_cargoName == "") then { _cargoName = typeOf _cargoObj; };

private _vehName = getText (configFile >> "CfgVehicles" >> typeOf _veh >> "displayName");
if (_vehName == "") then { _vehName = typeOf _veh; };

_cargoObj setVariable ["QM_ManifestValidated", true];
_veh setVariable ["QM_SystemLoading", true];
private _loaded = _veh setVehicleCargo _cargoObj;
_veh setVariable ["QM_SystemLoading", false];
_cargoObj setVariable ["QM_ManifestValidated", nil];

if (_loaded) then {
    _veh setVariable ["logistics_is_loaded", true, true];
    private _cat = [_cargoObj] call QM_fnc_getCargoCategory;
    _veh setVariable ["logistics_loaded_type", _cat, true];

    playSound "hint";
    systemChat format ["[MANIFEST LOADED]: %1 secured into %2.", _cargoName, _vehName];

    // Refresh UI to reflect updated space and bay contents
    [] execVM "fn_manifestMenuPopulate.sqf";
} else {
    hint "LOAD FAILED: Vehicle cargo bay rejected the item. The bay may be obstructed or at maximum weight limit.";
};
