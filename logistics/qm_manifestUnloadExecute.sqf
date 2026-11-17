// ============================================================================
// LOGISTICS SYSTEM: SELECTIVE CARGO UNLOAD EXECUTOR (SECTION 5.3)
// File: fn_manifestUnloadExecute.sqf
// Description: Unloads the selected cargo item from the vehicle cargo bay to
//              the ground, updates bay tracking, and refreshes the manifest UI.
// Execution: Client-side (Triggered by [UNLOAD SELECTED TO GROUND] button)
// ============================================================================

disableSerialization;

private _display = uiNamespace getVariable ["QM_Manifest_Display", displayNull];
if (isNull _display) exitWith {};

private _veh = uiNamespace getVariable ["QM_Manifest_TargetVehicle", objNull];
if (isNull _veh || !alive _veh) exitWith {
    hint "CARGO MANIFEST: Target vehicle is no longer accessible.";
    closeDialog 0;
};

private _listBoxBay = _display displayCtrl 1550;
private _selIdx = lbCurSel _listBoxBay;
if (_selIdx == -1) exitWith {
    hint "Please select a loaded item from the Current Cargo Bay list to unload.";
};

private _bayObjects = uiNamespace getVariable ["QM_Manifest_BayObjects", []];
private _val = _listBoxBay lbValue _selIdx;

if (_val < 0 || _val >= count _bayObjects) exitWith {
    hint "Selection index invalid. Please refresh the manifest.";
    [] execVM "logistics\qm_manifestMenuPopulate.sqf";
};

private _cargoObj = _bayObjects select _val;
if (isNull _cargoObj) exitWith {
    hint "The selected cargo is no longer in the vehicle bay.";
    [] execVM "logistics\qm_manifestMenuPopulate.sqf";
};

private _cargoName = getText (configFile >> "CfgVehicles" >> typeOf _cargoObj >> "displayName");
if (_cargoName == "") then { _cargoName = typeOf _cargoObj; };

// --- EXECUTE NATIVE UNLOAD ---
private _unloaded = objNull setVehicleCargo _cargoObj;

// Geometry fallback if native unload fails to find tarmac clearance
if (!_unloaded) then {
    private _vehRadius = (sizeOf typeOf _veh) * 0.5;
    private _dropPos = _veh modelToWorld [0, -(_vehRadius + 3), 0];
    _dropPos set [2, 0];
    _cargoObj setPosATL _dropPos;
    _unloaded = true;
};

if (_unloaded) then {
    // Update vehicle loading status
    private _remainingCargo = getVehicleCargo _veh;
    if (count _remainingCargo == 0) then {
        _veh setVariable ["logistics_is_loaded", false, true];
        _veh setVariable ["logistics_loaded_type", "", true];
    } else {
        private _topCat = [_remainingCargo # 0] call QM_fnc_getCargoCategory;
        _veh setVariable ["logistics_loaded_type", _topCat, true];
    };

    playSound "hint";
    systemChat format ["[MANIFEST UNLOADED]: %1 offloaded to ground.", _cargoName];

    // Refresh UI to reflect newly available space and ground availability
    [] execVM "logistics\qm_manifestMenuPopulate.sqf";
} else {
    hint "UNLOAD FAILED: Could not deploy item behind vehicle. Check for physical obstruction behind the vehicle.";
};
