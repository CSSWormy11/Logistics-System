// ============================================================================
// LOGISTICS SYSTEM: UNIFIED TERMINAL ACTION COMPILER (PART 2)
// File: qm_clientActionCompiler.sqf
// Description: Binds interface entry points for Arsenals, Motorpool Menus,
//              and vehicle returns directly to the terminal hub crate.
//              *FIX*: Safely clears Virtual Arsenal namespaces using native BIS 
//              functions to prevent array corruption and expected element errors.
//              *UPDATE*: Removed all Virtual Garage functionality and actions.
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

    // Action B: Scrap / Recycle Nearest Vehicle on Pad
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

            // ------------------------------------------------------------------------
            // 1. SAFELY CLEAR ARSENAL MEMORY
            // How: Pulls all raw classnames from the template arrays and uses the 
            //      native BIS removal functions to securely wipe them from missionNamespace.
            // Why: Using setVariable [] directly corrupts the BIS engine array structure.
            //      This method clears enemy gear properly before we inject the filtered items.
            // ------------------------------------------------------------------------
            private _allWeapons = G_Allowed_Weapons apply { _x select 0 };
            private _allMags = G_Allowed_Magazines apply { _x select 0 };
            private _allItems = G_Allowed_Items apply { _x select 0 };
            private _allBags = G_Allowed_Backpacks apply { _x select 0 };

            [missionNamespace, _allWeapons, false, false] call BIS_fnc_removeVirtualWeaponCargo;
            [missionNamespace, _allMags, false, false] call BIS_fnc_removeVirtualMagazineCargo;
            [missionNamespace, _allItems, false, false] call BIS_fnc_removeVirtualItemCargo;
            [missionNamespace, _allBags, false, false] call BIS_fnc_removeVirtualBackpackCargo;

            // Failsafe: Remove the wildcard string in case Eden Editor or another script injected it
            [missionNamespace, ["%ALL"], false, false] call BIS_fnc_removeVirtualWeaponCargo;
            [missionNamespace, ["%ALL"], false, false] call BIS_fnc_removeVirtualMagazineCargo;
            [missionNamespace, ["%ALL"], false, false] call BIS_fnc_removeVirtualItemCargo;
            [missionNamespace, ["%ALL"], false, false] call BIS_fnc_removeVirtualBackpackCargo;

            // ------------------------------------------------------------------------
            // 2. ESTABLISH DYNAMIC FILTERS
            // ------------------------------------------------------------------------
            // Fetch the caller's specific side and terrain to evaluate the gear template
            private _playerFaction = toUpper (str playerSide);
            private _currentTerrain = toUpper (call fn_G_getTerrain);

            private _vWeapons   = [];
            private _vMags      = [];
            private _vItems     = [];
            private _vBackpacks = [];

            // ------------------------------------------------------------------------
            // 3. INLINE PARSER FUNCTION
            // How: Iterates through the given master array and validates index [2] and [3].
            // Why: Stops raw array dumping and strictly enforces whitelist constraints based
            //      on the player's active Faction and Terrain Biome.
            // ------------------------------------------------------------------------
            private _fnc_filterGear = {
                params ["_sourceArray", "_targetArray"];
                if (isNil "_sourceArray") exitWith {};

                {
                    _x params ["_classname", "_stockQty", ["_faction", "ALL"], ["_terrainBiomes", ["ALL"]]];
                    
                    // Logic Gate: Verify Faction and Terrain permissions
                    private _validFaction = (toUpper _faction == "ALL" || toUpper _faction == _playerFaction);
                    private _terrainUpper = _terrainBiomes apply { toUpper _x };
                    private _validTerrain = ("ALL" in _terrainUpper || _currentTerrain in _terrainUpper);
                    
                    if (_validFaction && _validTerrain) then {
                        _targetArray pushBackUnique _classname;
                    };
                } forEach _sourceArray;
            };

            // Process all templates through the filtering gate
            [G_Allowed_Weapons, _vWeapons] call _fnc_filterGear;
            [G_Allowed_Magazines, _vMags] call _fnc_filterGear;
            [G_Allowed_Items, _vItems] call _fnc_filterGear;
            [G_Allowed_Backpacks, _vBackpacks] call _fnc_filterGear;

            // ------------------------------------------------------------------------
            // 4. INJECT FILTERED DATA
            // ------------------------------------------------------------------------
            [missionNamespace, _vWeapons, false, false] call BIS_fnc_addVirtualWeaponCargo;
            [missionNamespace, _vMags, false, false] call BIS_fnc_addVirtualMagazineCargo;
            [missionNamespace, _vItems, false, false] call BIS_fnc_addVirtualItemCargo;
            [missionNamespace, _vBackpacks, false, false] call BIS_fnc_addVirtualBackpackCargo;

            // Launch the BIS Arsenal bound to the dynamically updated namespace
            ["Open", [false, _target, _caller]] call BIS_fnc_arsenal;

            // Await closure to execute mass transaction logs
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