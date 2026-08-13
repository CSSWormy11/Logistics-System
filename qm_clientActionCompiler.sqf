// ============================================================================
// LOGISTICS SYSTEM: UNIFIED TERMINAL ACTION COMPILER (PART 2)
// File: qm_clientActionCompiler.sqf
// Description: Binds interface entry points for Arsenals, Motorpool Menus,
//              and vehicle returns directly to the terminal hub crate.
// Called By: init.sqf (Compiled during client initialization)
// ============================================================================

if (isDedicated) exitWith {};

// --- MODULE 1: INFANTRY GEAR PROCUREMENT ---
QM_fnc_clientRegisterTraderActions = { params [["_crate", objNull], ["_baseKey", ""]]; };

// --- MODULE 2: VEHICLE PROCUREMENT FACTORY ---
QM_fnc_clientRegisterFlagActions = {
    params [["_crate", objNull, [objNull]], ["_baseKey", "", [""]]];
    if (isNull _crate || _baseKey == "") exitWith {};

    // Action A: Open Procurement Blueprint Menu UI (Launches directly into isolated vehicle layout)
    _crate addAction [
        "<t color='#FFFF00' font='RobotoCondensedBold'>[LOGISTICS HUB] Open Vehicle Procurement Menu</t>",
        {
            params ["_target", "_caller", "_actionId", "_arguments"];
            _arguments params ["_bKey"];
            
            _caller setVariable ["QM_Current_Terminal_Box", _target];
            _caller setVariable ["QM_Current_Terminal_Base", _bKey];
            
            // UNTANGLE ATTACHMENT: Launch the correct isolated vehicle class menu sheet
            createDialog "CfgVehicleProcureMenu"; 
        },
        [_baseKey],
        5,
        true,
        true,
        "",
        "alive _target && {player distance _target < 5}",
        5
    ];

    // Action B: Standalone Virtual Garage Inspection Grid (Completely Separated)
    _crate addAction [
        "<t color='#00FFFF' font='RobotoCondensedBold'>[LOGISTICS HUB] Access Virtual Garage Simulation Grid</t>",
        {
            params ["_target", "_caller", "_actionId", "_arguments"];
            _arguments params ["_bKey"];
            
            _caller setVariable ["QM_Current_Terminal_Box", _target];
            _caller setVariable ["QM_Current_Terminal_Base", _bKey];
            
            if (fileExists "fn_openVirtualGarage.sqf") then { [] execVM "fn_openVirtualGarage.sqf"; };
        },
        [_baseKey],
        4.5,
        true,
        true,
        "",
        "alive _target && {player distance _target < 5}",
        5
    ];

    // Action C: Scrap / Recycle Nearest Vehicle on Pad
    _crate addAction [
        "<t color='#FFA500' font='RobotoCondensedBold'>[LOGISTICS HUB] Return Nearest Vehicle for Salvage</t>",
        {
            params ["_target", "_caller", "_actionId", "_arguments"];
            _arguments params ["_bKey"];
            
            _caller setVariable ["QM_Current_Terminal_Base", _bKey];
            if (fileExists "fn_usedCarSalesman.sqf") then { [] execVM "fn_usedCarSalesman.sqf"; };
        },
        [_baseKey],
        4,
        true,
        true,
        "",
        "alive _target && {player distance _target < 5}",
        5
    ];
};

// --- MODULE 3: BARRACKS & TEMPLATE-RESTRICTED VIRTUAL ARSENAL ---
QM_fnc_clientRegisterBarracksActions = {
    params [["_crate", objNull, [objNull]], ["_baseKey", "", [""]]];
    if (isNull _crate || _baseKey == "") exitWith {};

    _crate setVariable ["QM_Crate_OwningBase", _baseKey, true];

    // Action A: Access Isolated Template-Restricted Gear Virtual Arsenal
    _crate addAction [
        "<t color='#FFFFFF' font='RobotoCondensedBold'>[LOGISTICS HUB] Access Base Virtual Arsenal</t>",
        {
            params ["_target", "_caller", "_actionId", "_arguments"];
            _arguments params ["_bKey"];

            _caller setVariable ["QM_Current_Terminal_Base", _bKey];
            private _startingMass = loadAbs _caller;
            _caller setVariable ["QM_LocalTrade_InitialMass", _startingMass];

            [missionNamespace, "virtual", true] call BIS_fnc_addVirtualWeaponCargo;

            private _vWeapons   = G_Allowed_Weapons apply { _x select 0 };
            private _vMags      = G_Allowed_Magazines apply { _x select 0 };
            private _vItems     = G_Allowed_Items apply { _x select 0 };
            private _vBackpacks = G_Allowed_Backpacks apply { _x select 0 };

            [missionNamespace, _vWeapons, false, false] call BIS_fnc_addVirtualWeaponCargo;
            [missionNamespace, _vMags, false, false] call BIS_fnc_addVirtualMagazineCargo;
            [missionNamespace, _vItems, false, false] call BIS_fnc_addVirtualItemCargo;
            [missionNamespace, _vBackpacks, false, false] call BIS_fnc_addVirtualBackpackCargo;

            ["Open", [false, _target, _caller]] call BIS_fnc_arsenal;

            [_target, _caller] spawn {
                params ["_tgt", "_unit"];
                waitUntil { isNull (uiNamespace getVariable ["RscDisplayArsenal", displayNull]) };
                if (!isNil "QM_fnc_traderOnContainerClosed") then {
                    [_tgt, _unit] call QM_fnc_traderOnContainerClosed;
                };
            };
        },
        [_baseKey],
        2,
        true,
        true,
        "",
        "alive _target && {player distance _target < 5}",
        5
    ];

    // Action B: Open Isolated Garrison Infantry Recruitment Hub Dialog Menu Window
    _crate addAction [
        "<t color='#FF8C00' font='RobotoCondensedBold'>[LOGISTICS HUB] Open Infantry Recruitment Hub</t>",
        {
            params ["_target", "_caller", "_actionId", "_arguments"];
            _arguments params ["_bKey"];

            _caller setVariable ["QM_Current_Terminal_Box", _target];
            _caller setVariable ["QM_Current_Terminal_Base", _bKey];

            // Launch the completely separate manpower dialog menu frame cleanly
            createDialog "CfgControlHubMenu";
        },
        [_baseKey],
        1.5,
        true,
        true,
        "",
        "alive _target && {player distance _target < 5}",
        5
    ];
};

diag_log "QUARTERMASTER: Action compiler stabilized. Motorpool dialogue class tracking aligned.";