// ============================================================================
// LOGISTICS SYSTEM: INFANTRY BARRACKS DATA LOADER (PART 2)
// File: fn_recruiter_list.sqf
// Description: Feeds configurations into Column 1 (Individual) and Column 2 (Group)
//              of the recruitment UI. Updates title card with live manpower pool.
//              V8 UPDATE: Now reads dynamically from the unified G_Procureable_Infantry array.
// Called By: qm_quartermasterUI.hpp (CfgControlHubMenu onLoad event)
// ============================================================================

disableSerialization;
private _display = uiNamespace getVariable ["QM_Menu_Display", displayNull];
if (isNull _display) exitWith {};

private _baseKey = player getVariable ["QM_Current_Terminal_Base", ""];
private _troopSupplyPool = missionNamespace getVariable [format ["LogiScore_%1_Troops", _baseKey], 0];

// Dynamic Title Card Status
private _titleBox = _display displayCtrl 1000;
_titleBox ctrlSetText format ["GARRISON INFANTRY MOBILIZATION (Current Base Manpower: %1 Personnel)", _troopSupplyPool];

// --- INITIALIZE UI LISTBOXES ---
private _listBox1 = _display displayCtrl 1500;
lbClear _listBox1;

private _listBox2 = _display displayCtrl 1550;
lbClear _listBox2;

// ------------------------------------------------------------------------
// V8 SYSTEM REQUIREMENT: Fetch metadata variables for filtering
// ------------------------------------------------------------------------
private _currentTerrain = call fn_G_getTerrain;
private _playerFaction = str (side group player);

// Base Tier evaluation for restriction checks
private _isSB = (["SB", _baseKey] call BIS_fnc_inString);
private _isFOB = (["FOB", _baseKey] call BIS_fnc_inString);

// ------------------------------------------------------------------------
// V8 MASTER UNIFIED ARRAY PARSING
// How: Iterates through the global G_Procureable_Infantry templates.
// Why: Replaces legacy hardcoded individual/group arrays to ensure total 
//      synchronization with the World AI spawner templates.
// ------------------------------------------------------------------------
{
    // Unpack the new 7-parameter V8 array structure
    _x params [
        "_displayName", 
        "_classArray", 
        "_costArray", 
        ["_restrictionType", "ALL"], 
        ["_faction", "ALL"], 
        ["_terrainArray", ["ALL"]], 
        ["_systemsArray", ["Quartermaster"]]
    ];

    // ------------------------------------------------------------------------
    // V8 METADATA FILTERING
    // How: Verify the blueprint is authorized for the player's side, 
    //      the current map's biome, and the Quartermaster UI system.
    // Why: Prevents WorldAI assets or snow-camo troops from spawning incorrectly.
    // ------------------------------------------------------------------------
    private _validFaction = (_faction == "ALL" || _faction == _playerFaction);
    private _validTerrain = ("ALL" in _terrainArray || _currentTerrain in _terrainArray);
    private _validSystem  = ("ALL" in _systemsArray || "Quartermaster" in _systemsArray);
    
    // Evaluate if base has appropriate tier (SB allows FOB/SB restrictions, FOB allows FOB, ALL allows ALL)
    private _validBaseTier = (_restrictionType == "ALL" || (_restrictionType == "SB" && _isSB) || (_restrictionType == "FOB" && (_isFOB || _isSB)));

    if (_validFaction && _validTerrain && _validSystem && _validBaseTier) then {
        
        // --- MULTI-RESOURCE UI FORMATTER ---
        // How: Loops through the V8 2D cost array to build the UI display label
        // Why: Replaces legacy flat integer cost display, handling both Troops and Cargo mass.
        private _costStringArray = [];
        {
            _x params ["_poolName", "_poolVal"];
            if (_poolVal > 0) then { 
                private _shortName = switch (_poolName) do {
                    case "Troops": { "Trp" };
                    case "Cargo": { "Crg" };
                    case "Vehicle": { "Veh" };
                    default { _poolName };
                };
                _costStringArray pushBack format ["%1 %2", round _poolVal, _shortName];
            };
        } forEach _costArray;
        
        private _costStr = _costStringArray joinString " | ";
        if (_costStr == "") then { _costStr = "Free"; };

        // ------------------------------------------------------------------------
        // DYNAMIC COLUMN SORTING
        // How: Checks the size of the classname array. If 1, it's an individual. 
        //      If > 1, it's a pre-composed group/squad.
        // Why: Eliminates the need for two separate configuration arrays.
        // ------------------------------------------------------------------------
        private _isGroup = (count _classArray > 1);
        private _targetListBox = if (_isGroup) then { _listBox2 } else { _listBox1 };
        
        private _label = format ["[%1] -> %2", _costStr, _displayName];
        if (_isGroup) then { _label = _label + " Template"; }; // Preserve legacy label style for groups

        // Add to the appropriate column listbox and store the master array index
        private _idx = _targetListBox lbAdd _label;
        _targetListBox lbSetValue [_idx, _forEachIndex];
    };

} forEach G_Procureable_Infantry;

// Auto-select first entries if lists are populated
if (lbSize _listBox1 > 0) then { _listBox1 lbSetCurSel 0; };
if (lbSize _listBox2 > 0) then { _listBox2 lbSetCurSel 0; };