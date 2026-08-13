// ============================================================================
// LOGISTICS SYSTEM: INFANTRY BARRACKS DATA LOADER (PART 2)
// File: fn_recruiter_list.sqf
// Description: Feeds configurations into Column 1 (Individual) and Column 2 (Group)
//              of the recruitment UI. Updates title card with live manpower pool.
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

// --- V8 BIOME RETRIEVAL ---
private _currentTerrain = if (fileExists "fn_G_getTerrain.sqf") then { call compile preprocessFileLineNumbers "fn_G_getTerrain.sqf" } else { "ALL" };

// --- 1. POPULATE COLUMN 1: INDIVIDUAL BLUEPRINTS ( createUnit Matrix ) ---
private _listBox1 = _display displayCtrl 1500;
lbClear _listBox1;

// Reformatted hardcoded arrays to exact V8 7-Element Standards to ensure loop compatibility
G_Individual_Blueprints = [
    ["Rifleman Guard", ["B_Soldier_F"], [["Troops", 1]], "ALL", "WEST", ["ALL"], ["Quartermaster"]],
    ["Combat Paramedic", ["B_medic_F"], [["Troops", 1]], "ALL", "WEST", ["ALL"], ["Quartermaster"]],
    ["Light Machine Gunner", ["B_soldier_AR_F"], [["Troops", 1]], "ALL", "WEST", ["ALL"], ["Quartermaster"]],
    ["Grenadier Specialist", ["B_Soldier_GL_F"], [["Troops", 1]], "ALL", "WEST", ["ALL"], ["Quartermaster"]],
    ["Heavy Ammo Bearer", ["B_HeavyGunner_F"], [["Troops", 1]], "ALL", "WEST", ["ALL"], ["Quartermaster"]],
    ["AT Missile Specialist", ["B_soldier_AT_F"], [["Troops", 1]], "ALL", "WEST", ["ALL"], ["Quartermaster"]],
    ["Assistant AT Team", ["B_soldier_A_F"], [["Troops", 1]], "ALL", "WEST", ["ALL"], ["Quartermaster"]],
    ["AA Missile Specialist", ["B_soldier_AA_F"], [["Troops", 1]], "ALL", "WEST", ["ALL"], ["Quartermaster"]],
    ["Armored Vehicle Crewman", ["B_crew_F"], [["Troops", 1]], "ALL", "WEST", ["ALL"], ["Quartermaster"]],
    ["Armored Vehicle Commander", ["B_officer_F"], [["Troops", 1]], "ALL", "WEST", ["ALL"], ["Quartermaster"]],
    ["Helicopter Crew Chief", ["B_helicrew_F"], [["Troops", 1]], "ALL", "WEST", ["ALL"], ["Quartermaster"]],
    ["Helicopter Pilot Element", ["B_helipilot_F"], [["Troops", 1]], "ALL", "WEST", ["ALL"], ["Quartermaster"]]
];

{
    // Extract V8 Structure
    _x params ["_name", "_classArray", "_costArray", ["_restriction", "ALL"], ["_faction", "WEST"], ["_terrainBiomes", ["ALL"]], ["_allowedSystems", ["Quartermaster"]]];
    
    // --- V8 METADATA FILTERING ---
    private _validSystem = ("ALL" in _allowedSystems) || ("Quartermaster" in _allowedSystems);
    private _validTerrain = ("ALL" in _terrainBiomes) || (_currentTerrain in _terrainBiomes);
    
    if (_validSystem && _validTerrain) then {
        // Extract Troop point cost from the 2D V8 Cost Array
        private _cost = 0;
        { if ((_x select 0) == "Troops") then { _cost = _x select 1; }; } forEach _costArray;
        
        private _label = format ["[%1 Manpower] -> %2", _cost, _name];
        private _idx = _listBox1 lbAdd _label;
        _listBox1 lbSetValue [_idx, _forEachIndex];
    };
} forEach G_Individual_Blueprints;

if (lbSize _listBox1 > 0) then { _listBox1 lbSetCurSel 0; };

// --- 2. POPULATE COLUMN 2: GROUP TEMPLATES (Manual Classname Arrays) ---
private _listBox2 = _display displayCtrl 1550;
lbClear _listBox2;

// Reformatted hardcoded arrays to exact V8 7-Element Standards to ensure loop compatibility
G_Group_Blueprints = [
    [
        "BLUFOR Infantry Fireteam", 
        ["B_Soldier_TL_F", "B_soldier_AR_F", "B_Soldier_GL_F", "B_Soldier_F"], 
        [["Troops", 4]], "ALL", "WEST", ["ALL"], ["Quartermaster"]
    ],
    [
        "BLUFOR Infantry Squad", 
        ["B_Soldier_SL_F", "B_Soldier_TL_F", "B_soldier_AR_F", "B_Soldier_GL_F", "B_Soldier_TL_F", "B_soldier_AR_F", "B_soldier_LAT_F", "B_Soldier_F"], 
        [["Troops", 8]], "ALL", "WEST", ["ALL"], ["Quartermaster"]
    ],
    [
        "BLUFOR AT Support Section", 
        ["B_Soldier_TL_F", "B_soldier_AT_F", "B_soldier_A_F", "B_soldier_AT_F", "B_soldier_A_F"], 
        [["Troops", 5]], "ALL", "WEST", ["ALL"], ["Quartermaster"]
    ],
    [
        "BLUFOR AA Support Section", 
        ["B_Soldier_TL_F", "B_soldier_AA_F", "B_soldier_AAA_F", "B_soldier_AA_F", "B_soldier_AAA_F"], 
        [["Troops", 5]], "ALL", "WEST", ["ALL"], ["Quartermaster"]
    ],
    [
        "Standard Mechanized Crew Detail", 
        ["B_crew_F", "B_crew_F", "B_crew_F", "B_officer_F"], 
        [["Troops", 4]], "ALL", "WEST", ["ALL"], ["Quartermaster"]
    ]
];

{
    // Extract V8 Structure (Note: for groups, _unitArray naturally contains multiple strings)
    _x params ["_name", "_unitArray", "_costArray", ["_restriction", "ALL"], ["_faction", "WEST"], ["_terrainBiomes", ["ALL"]], ["_allowedSystems", ["Quartermaster"]]];
    
    // --- V8 METADATA FILTERING ---
    private _validSystem = ("ALL" in _allowedSystems) || ("Quartermaster" in _allowedSystems);
    private _validTerrain = ("ALL" in _terrainBiomes) || (_currentTerrain in _terrainBiomes);
    
    if (_validSystem && _validTerrain) then {
        // Extract Troop point cost from the 2D V8 Cost Array
        private _cost = 0;
        { if ((_x select 0) == "Troops") then { _cost = _x select 1; }; } forEach _costArray;
        
        private _label = format ["[%1 Troops] -> %2 Template", _cost, _name];
        private _idx = _listBox2 lbAdd _label;
        _listBox2 lbSetValue [_idx, _forEachIndex];
    };
} forEach G_Group_Blueprints;

if (lbSize _listBox2 > 0) then { _listBox2 lbSetCurSel 0; };