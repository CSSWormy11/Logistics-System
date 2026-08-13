// ============================================================================
// LOGISTICS SYSTEM: DIRECT MOTORPOOL BLUEPRINTS SPAWNER (PART 2)
// File: fn_newCarDealership.sqf
// Description: Processes vehicle purchase from the UI list and triggers
//              server-side spawn and point deduction.
// Called By: qm_quartermasterUI.hpp (Button Actions from Motorpool Menu)
// ============================================================================

disableSerialization;
private _display = uiNamespace getVariable ["QM_Vehicle_Display", displayNull];
if (isNull _display) exitWith {};

private _listBox = _display displayCtrl 1600;
private _selectionIdx = lbCurSel _listBox;
if (_selectionIdx == -1) exitWith { hint "Please select an active blueprint record array layout."; };

private _actionValue = _listBox lbValue _selectionIdx;

// Evaluate Auto-Close Flag (1 = Close, 0 = Keep Open)
private _autoClose = missionNamespace getVariable ["QM_AutoCloseMotorpool", 1];
if (_autoClose == 1) then { closeDialog 0; };

// Re-map the selected category index threshold back to the G_Procureable_Vehicles lookup row
private _vehicleConfig = G_Procureable_Vehicles select _actionValue;

// Exact extraction of the new 6-parameter template layout
_vehicleConfig params ["_name", "_classname", "_costArray", "_restriction", "_faction", "_vehSize"];

private _baseKey = player getVariable ["QM_Current_Terminal_Base", ""];
[_baseKey, _classname, player, _costArray, _vehSize] remoteExec ["QM_fnc_processGarageSpawn", 2];