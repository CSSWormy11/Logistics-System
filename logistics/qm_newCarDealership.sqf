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

// ------------------------------------------------------------------------
// V8 TEMPLATE DATA EXTRACTION
// RESTORED: Index 5 is now Index 7 (_vehSize) and is actively unpacked from the template.
// Why: Captures the nested classname and the multi-resource 2D cost array. 
//      Note: The legacy vehicle size tier has been deprecated in V8.
// ------------------------------------------------------------------------
_vehicleConfig params [
    "_name", 
    "_classArray", 
    "_costArray", 
    "_restriction", 
    "_faction", 
    //"_vehSize",
    "_terrainBiomes", 
    "_allowedSystems",
    ["_vehSize", "OPEN"]
    //"_vehSize"
];

// How: Extract the precise vehicle classname string from the nested V8 array
// Why: The remote server spawner requires a flat string to execute createVehicle
private _classname = _classArray select 0;
private _baseKey = player getVariable ["QM_Current_Terminal_Base", ""];

// ------------------------------------------------------------------------
// SERVER DISPATCH
// Pass the untouched 2D _costArray AND the _vehSize parameter to the server
// Why: The server processes multi-pool point deductions dynamically by 
//      looping through this array.
// ------------------------------------------------------------------------
[_baseKey, _classname, player, _costArray, _vehSize] remoteExec ["QM_fnc_processGarageSpawn", 2];