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

// --- 1. POPULATE COLUMN 1: INDIVIDUAL BLUEPRINTS ( createUnit Matrix ) ---
private _listBox1 = _display displayCtrl 1500;
lbClear _listBox1;

G_Individual_Blueprints = [
    ["Rifleman Guard", "B_Soldier_F", 1],
    ["Combat Paramedic", "B_medic_F", 1],
    ["Light Machine Gunner", "B_soldier_AR_F", 1],
    ["Grenadier Specialist", "B_Soldier_GL_F", 1],
    ["Heavy Ammo Bearer", "B_HeavyGunner_F", 1],
    ["AT Missile Specialist", "B_soldier_AT_F", 1],
    ["Assistant AT Team", "B_soldier_A_F", 1],
    ["AA Missile Specialist", "B_soldier_AA_F", 1],
    ["Armored Vehicle Crewman", "B_crew_F", 1],
    ["Armored Vehicle Commander", "B_officer_F", 1],
    ["Helicopter Crew Chief", "B_helicrew_F", 1],
    ["Helicopter Pilot Element", "B_helipilot_F", 1]
];

{
    _x params ["_name", "_class", "_cost"];
    private _label = format ["[%1 Manpower] -> %2", _cost, _name];
    private _idx = _listBox1 lbAdd _label;
    _listBox1 lbSetValue [_idx, _forEachIndex];
} forEach G_Individual_Blueprints;

if (lbSize _listBox1 > 0) then { _listBox1 lbSetCurSel 0; };

// --- 2. POPULATE COLUMN 2: GROUP TEMPLATES (Manual Classname Arrays) ---
private _listBox2 = _display displayCtrl 1550;
lbClear _listBox2;

G_Group_Blueprints = [
    // ["Display Name", [Array of Units], PointCost]
    [
        "BLUFOR Infantry Fireteam", 
        ["B_Soldier_TL_F", "B_soldier_AR_F", "B_Soldier_GL_F", "B_Soldier_F"], 
        4
    ],
    [
        "BLUFOR Infantry Squad", 
        ["B_Soldier_SL_F", "B_Soldier_TL_F", "B_soldier_AR_F", "B_Soldier_GL_F", "B_Soldier_TL_F", "B_soldier_AR_F", "B_soldier_LAT_F", "B_Soldier_F"], 
        8
    ],
    [
        "BLUFOR AT Support Section", 
        ["B_Soldier_TL_F", "B_soldier_AT_F", "B_soldier_A_F", "B_soldier_AT_F", "B_soldier_A_F"], 
        5
    ],
    [
        "BLUFOR AA Support Section", 
        ["B_Soldier_TL_F", "B_soldier_AA_F", "B_soldier_AAA_F", "B_soldier_AA_F", "B_soldier_AAA_F"], 
        5
    ],
    [
        "Standard Mechanized Crew Detail", 
        ["B_crew_F", "B_crew_F", "B_crew_F", "B_officer_F"], 
        4
    ]
];

{
    _x params ["_name", "_unitArray", "_cost"];
    private _label = format ["[%1 Troops] -> %2 Template", _cost, _name];
    private _idx = _listBox2 lbAdd _label;
    _listBox2 lbSetValue [_idx, _forEachIndex];
} forEach G_Group_Blueprints;

if (lbSize _listBox2 > 0) then { _listBox2 lbSetCurSel 0; };