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

// Ensure the parsed UI value corresponds to a valid array index
if (_actionValue >= 0 && _actionValue < count G_Procureable_Vehicles) then {
    
    private _vehicleConfig = G_Procureable_Vehicles select _actionValue;
    
    // ------------------------------------------------------------------------
    // V8 TEMPLATE DATA EXTRACTION
    // How: Unpack the new 8-parameter V8 array structure. 
    // RESTORED: Index 5 is now Index 7 (_vehSize) and is now actively unpacked from the template.
    // Why: We must capture the nested classname array and the 2D multi-resource cost array.
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

    // How: Extract the actual vehicle classname string from the nested array
    // Why: The remote spawner engine requires a flat string, not a single-element array
    private _classname = _classArray select 0;

    // Output multi-resource allocation notices (Costs omitted from string since it's a 2D array now)
    systemChat format ["[LOGISTICS HUB]: Processing procurement allocation for %1 at %2.", _name, _baseKey];
    diag_log format ["[LOGISTICS MOTORPOOL]: Dispatched procurement allocation for %1 at %2.", _name, _baseKey];
    
    // ------------------------------------------------------------------------
    // SERVER DISPATCH
    // How: Pass the untouched 2D _costArray to the server payload instead of a flat integer
    // Why: The Server handles multi-pool point deductions natively by looping through this array
    // Pass the untouched 2D _costArray AND the _vehSize parameter to the server
    // ------------------------------------------------------------------------
    [_baseKey, _classname, player, _costArray, _vehSize] remoteExec ["QM_fnc_processGarageSpawn", 2];
};