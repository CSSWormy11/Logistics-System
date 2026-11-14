// ============================================================================
// LOGISTICS SYSTEM: SELECTIVE CARGO MANIFEST OPENER (SECTION 5.3)
// File: fn_manifestMenuOpen.sqf
// Description: Initializes target vehicle context and launches the selective
//              cargo manifest loading dialog.
// Execution: Client-side (hasInterface)
// ============================================================================

if (!hasInterface) exitWith {};

params [["_vehicle", objNull, [objNull]]];

// Fallback detection if launched without explicit parameter
if (isNull _vehicle) then {
    if (vehicle player != player) then {
        _vehicle = vehicle player;
    } else {
        if (!isNull cursorObject && { player distance cursorObject < 12 }) then {
            _vehicle = cursorObject;
        };
    };
};

if (isNull _vehicle || !alive _vehicle) exitWith {
    hint "CARGO MANIFEST: No valid target vehicle detected.";
};

// Verify vehicle has ViV cargo capability
private _vehClass = typeOf _vehicle;
private _cfgViV = getNumber (configFile >> "CfgVehicles" >> _vehClass >> "vehicleCargo");
private _maxMass = maxVehicleCargoMass _vehicle;
private _isAllowedLogi = _vehClass in (missionNamespace getVariable ["allowedLogisticsVehicles", []]);

if (_cfgViV <= 0 && _maxMass <= 0 && !_isAllowedLogi) exitWith {
    hint format ["CARGO MANIFEST: %1 does not support Vehicle-in-Vehicle cargo.", getText (configFile >> "CfgVehicles" >> _vehClass >> "displayName")];
};

// Store authoritative reference for the active dialog session
uiNamespace setVariable ["QM_Manifest_TargetVehicle", _vehicle];

// Open the Dialog
private _created = createDialog "CfgCargoManifestMenu";
if (!_created) then {
    diag_log "[QUARTERMASTER ERROR]: Failed to create CfgCargoManifestMenu dialog.";
};
