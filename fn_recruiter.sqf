// ============================================================================
// LOGISTICS SYSTEM: RECRUITMENT SQUAD SPAWNER EXECUTION (PART 2)
// File: fn_recruiter.sqf
// Description: Dispatches individual selections or group arrays straight 
//              into the player-local squad pipeline without restrictions.
//              V8 UPDATE: Now parses data directly from the unified 
//              G_Procureable_Infantry global catalog.
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
    
    // ------------------------------------------------------------------------
    // V8 DATA EXTRACTION (INDIVIDUAL)
    // How: Look up the selection index in the unified master array.
    // Why: Legacy G_Individual_Blueprints array has been deprecated in V8.
    // ------------------------------------------------------------------------
    private _blueprint = G_Procureable_Infantry select _actionVal;
    
    // Unpack the new 7-parameter V8 array structure
    _blueprint params [
        "_name", 
        "_classArray", 
        "_costArray", 
        "_restriction", 
        "_faction", 
        "_terrainBiomes", 
        "_allowedSystems"
    ];

    // How: Extract the actual unit classname string from the nested array
    // Why: The server-side individual createUnit engine requires a flat string
    private _classname = _classArray select 0;

    closeDialog 0;
    systemChat format ["[LOGISTICS REC-HUB]: Processing individual draft for %1...", _name];
    
    // Pass execution and the untouched 2D _costArray to the server for multi-pool point deduction
    [_baseKey, _classname, player, _costArray, _name] remoteExec ["QM_fnc_serverCreateLocalUnit", 2];
};

// --- EXECUTION PATH B: QUICK-DRAFT GROUP TEMPLATES ---
if (_mode == 1) exitWith {
    private _listBox = _display displayCtrl 1550;
    private _selIdx = lbCurSel _listBox;
    if (_selIdx == -1) exitWith { hint "Select an active group deployment layout configuration row."; };

    private _actionVal = _listBox lbValue _selIdx;
    
    // ------------------------------------------------------------------------
    // V8 DATA EXTRACTION (GROUP)
    // How: Look up the selection index in the unified master array.
    // Why: Legacy G_Group_Blueprints array has been deprecated in V8.
    // ------------------------------------------------------------------------
    private _blueprint = G_Procureable_Infantry select _actionVal;
    
    // Unpack the new 7-parameter V8 array structure
    _blueprint params [
        "_name", 
        "_classArray", 
        "_costArray", 
        "_restriction", 
        "_faction", 
        "_terrainBiomes", 
        "_allowedSystems"
    ];

    // How: Assign the entire _classArray directly as the _unitArray
    // Why: In V8, groups are already formatted as arrays of strings inside the configuration
    private _unitArray = _classArray;

    closeDialog 0;
    systemChat format ["[LOGISTICS REC-HUB]: Dispatching operational group template %1...", _name];
    
    // Pass execution and the untouched 2D _costArray to the server for multi-pool point deduction
    [_baseKey, _unitArray, player, _costArray, _name] remoteExec ["QM_fnc_serverCreateLocalGroup", 2];
};