// ============================================================================
// LOGISTICS SYSTEM: RECRUITMENT SQUAD SPAWNER EXECUTION (PART 2)
// File: fn_recruiter.sqf
// Description: Dispatches individual selections or group arrays straight 
//              into the player-local squad pipeline without restrictions.
// Called By: qm_quartermasterUI.hpp (Button Actions from Control Hub Menu)
// ============================================================================

private _mode = param [0, 0, [0]]; // 0 = Individual Specialty, 1 = Group Template
disableSerialization;

private _display = uiNamespace getVariable ["QM_Menu_Display", displayNull];
if (isNull _display) exitWith {};

private _baseKey = player getVariable ["QM_Current_Terminal_Base", ""];
if (_baseKey == "") exitWith { closeDialog 0; hint "LOGISTICS ERROR: Missing anchor installation profile tracking."; };

// --- EXECUTION PATH A: INDIVIDUAL SQUAD TUNING ---
if (_mode == 0) exitWith {
    private _listBox = _display displayCtrl 1500;
    private _selIdx = lbCurSel _listBox;
    if (_selIdx == -1) exitWith { hint "Select an individual specialty blueprint record row."; };
    
    private _actionVal = _listBox lbValue _selIdx;
    private _blueprint = G_Individual_Blueprints select _actionVal;
    
    // Exact extraction of the new V8 7-parameter template layout
    _blueprint params ["_name", "_classnameArray", "_costArray", "_restriction", "_faction", "_terrainBiomes", "_allowedSystems"];
    
    // Un-nest the single string classname for the server spawner
    private _classname = _classnameArray select 0;

    closeDialog 0;
    systemChat format ["[LOGISTICS REC-HUB]: Processing individual draft for %1...", _name];
    
    // V8 2D Cost Array is passed intact to the server executor
    [_baseKey, _classname, player, _costArray, _name] remoteExec ["QM_fnc_serverCreateLocalUnit", 2];
};

// --- EXECUTION PATH B: QUICK-DRAFT GROUP TEMPLATES ---
if (_mode == 1) exitWith {
    private _listBox = _display displayCtrl 1550;
    private _selIdx = lbCurSel _listBox;
    if (_selIdx == -1) exitWith { hint "Select an active group deployment layout configuration row."; };

    private _actionVal = _listBox lbValue _selIdx;
    private _blueprint = G_Group_Blueprints select _actionVal;
    
    // Exact extraction of the new V8 7-parameter template layout
    _blueprint params ["_name", "_unitArray", "_costArray", "_restriction", "_faction", "_terrainBiomes", "_allowedSystems"];

    closeDialog 0;
    systemChat format ["[LOGISTICS REC-HUB]: Dispatching operational group template %1...", _name];
    
    // Because _unitArray is already an array of strings in V8, we can pass it natively
    [_baseKey, _unitArray, player, _costArray, _name] remoteExec ["QM_fnc_serverCreateLocalGroup", 2];
};