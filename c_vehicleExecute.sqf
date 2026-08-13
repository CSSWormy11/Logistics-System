// ============================================================================
// LOGISTICS SYSTEM: VEHICLE PURCHASE EXECUTION PROTOCOL (PART 2)
// File: c_vehicleExecute.sqf
// Description: Processes user selection index numbers to trigger motorpool allocations.
// Called By: qm_quartermasterUI.hpp (Button Actions from Motorpool Menu)
// ============================================================================

disableSerialization;
private _display = findDisplay 8888;
if (isNull _display) then { _display = uiNamespace getVariable ["QM_Vehicle_Display", displayNull]; };
if (isNull _display) exitWith {};

private _listBox = _display displayCtrl 1600;
private _selectionIdx = lbCurSel _listBox;
if (_selectionIdx == -1) exitWith { hint "Please select a vehicle blueprint template option."; };

private _actionValue = _listBox lbValue _selectionIdx;
private _baseKey = player getVariable ["QM_Current_Terminal_Base", ""];

// Evaluate Auto-Close Flag (1 = Close, 0 = Keep Open)
private _autoClose = missionNamespace getVariable ["QM_AutoCloseMotorpool", 1];
if (_autoClose == 1) then { closeDialog 0; };

if (_baseKey == "") exitWith { hint "LOGISTICS ERROR: Missing destination base identifier credentials."; };

if (_actionValue >= 0 && _actionValue < count G_Procureable_Vehicles) then {
    private _vehicleConfig = G_Procureable_Vehicles select _actionValue;
    // Unpack the new 6th variable holding the size tag
    _vehicleConfig params ["_name", "_classname", "_massCost", "_restriction", ["_faction", "ALL"], ["_vehSize", "M"]];

    systemChat format ["[LOGISTICS HUB]: Processing procurement allocation for %1 (%2 Points) at %3.", _name, _massCost, _baseKey];
    diag_log format ["[LOGISTICS MOTORPOOL]: Dispatched procurement allocation for %1 (%2 Points) at %3.", _name, _massCost, _baseKey];
    
    // Pass execution and the requested size tier to the server (Server handles pad routing automatically)
    [_baseKey, _classname, player, [["Vehicle", _massCost]], _vehSize] remoteExec ["QM_fnc_processGarageSpawn", 2];
};