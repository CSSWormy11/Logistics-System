// ============================================================================
// LOGISTICS SYSTEM: PLAYER MASS DELTA LEDGER & ARSENAL ENGINE (PART 2)
// File: fn_equipmentTrader.sqf
// Description: Unifies transaction paths (Arsenal, Box Inventory, and Rearm prompts)
//              and pipes comprehensive diagnostic traces directly into the RPT log.
//              V8 UPDATE: Now includes dynamic Virtual Arsenal population based
//              on strict Terrain and Faction 4-index template filtering.
// Called By: init.sqf (Compiled during client initialization)
// ============================================================================

// ----------------------------------------------------------------------------
// --- V8 ARSENAL POPULATOR (NEW ENGINES) ---
// ----------------------------------------------------------------------------
QM_fnc_initVirtualArsenal = {
    params ["_container"];
    if (isNull _container) exitWith {};

    diag_log "======================================================================";
    diag_log format ["VIRTUAL ARSENAL DIAGNOSTIC: INITIATING WHITELIST ON %1", typeOf _container];
    
    // 1. OBLITERATE EDEN EDITOR DEFAULTS
    [_container, ["%ALL"], true, false] call BIS_fnc_removeVirtualWeaponCargo;
    [_container, ["%ALL"], true, false] call BIS_fnc_removeVirtualMagazineCargo;
    [_container, ["%ALL"], true, false] call BIS_fnc_removeVirtualItemCargo;
    [_container, ["%ALL"], true, false] call BIS_fnc_removeVirtualBackpackCargo;

    _container setVariable ["bis_addVirtualWeaponCargo_cargo", [], true];
    _container setVariable ["bis_addVirtualMagazineCargo_cargo", [], true];
    _container setVariable ["bis_addVirtualItemCargo_cargo", [], true];
    _container setVariable ["bis_addVirtualBackpackCargo_cargo", [], true];

    private _playerFaction = toUpper (str playerSide); 
    private _currentTerrain = toUpper (call fn_G_getTerrain);

    diag_log format ["- Evaluated Player Faction: '%1'", _playerFaction];
    diag_log format ["- Evaluated Terrain Biome: '%1'", _currentTerrain];

    private _filteredWeapons = [];
    private _filteredMagazines = [];
    private _filteredItems = [];
    private _filteredBackpacks = [];

    private _fnc_parseArsenalArray = {
        params ["_masterArray", "_targetList", "_logCategory"];
        if (isNil "_masterArray") exitWith { diag_log format ["- ERROR: Master Array for %1 is NIL!", _logCategory]; };
        
        private _addedCount = 0;
        private _rejectedCount = 0;
        
        {
            _x params ["_classname", "_stockQty", ["_faction", "ALL"], ["_terrainBiomes", ["ALL"]]];
            
            private _validFaction = (toUpper _faction == "ALL" || toUpper _faction == _playerFaction);
            private _terrainUpper = _terrainBiomes apply { toUpper _x };
            private _validTerrain = ("ALL" in _terrainUpper || _currentTerrain in _terrainUpper);
            
            if (_validFaction && _validTerrain) then {
                _targetList pushBackUnique _classname;
                _addedCount = _addedCount + 1;
            } else {
                _rejectedCount = _rejectedCount + 1;
                // Specific trace to see if enemy weapons are being actively rejected by the script
                if (toUpper _faction == "EAST" || toUpper _faction == "GUER") then {
                    diag_log format ["   [X] REJECTED %1 | Template Faction: %2 | Evaluated Match: %3", _classname, _faction, _validFaction];
                };
            };
        } forEach _masterArray;
        
        diag_log format ["- %1 Array Parsed: %2 Approved | %3 Rejected", _logCategory, _addedCount, _rejectedCount];
    };

    [missionNamespace getVariable ["G_Allowed_Weapons", []], _filteredWeapons, "WEAPONS"] call _fnc_parseArsenalArray;
    [missionNamespace getVariable ["G_Allowed_Magazines", []], _filteredMagazines, "MAGAZINES"] call _fnc_parseArsenalArray;
    [missionNamespace getVariable ["G_Allowed_Items", []], _filteredItems, "ITEMS"] call _fnc_parseArsenalArray;
    [missionNamespace getVariable ["G_Allowed_Backpacks", []], _filteredBackpacks, "BACKPACKS"] call _fnc_parseArsenalArray;

    [_container, _filteredWeapons, false, false] call BIS_fnc_addVirtualWeaponCargo;
    [_container, _filteredMagazines, false, false] call BIS_fnc_addVirtualMagazineCargo;
    [_container, _filteredItems, false, false] call BIS_fnc_addVirtualItemCargo;
    [_container, _filteredBackpacks, false, false] call BIS_fnc_addVirtualBackpackCargo;
    
    diag_log "VIRTUAL ARSENAL DIAGNOSTIC: COMPLETED";
    diag_log "======================================================================";
};

// ============================================================================
// MASS LEDGER & WEIGHT MONITORING ENGINES
// ============================================================================

// --- ENGINE RECEPTACLE: NATIVE INVENTORY OPENED ---
QM_fnc_traderOnContainerOpened = {
    params ["_container", "_unit"];
    if (_unit != player) exitWith {};

    private _startingMass = loadAbs _unit;
    _unit setVariable ["QM_LocalTrade_InitialMass", _startingMass];
};

// --- ENGINE RECEPTACLE: NATIVE INVENTORY & ARSENAL CLOSED ENGINE ---
QM_fnc_traderOnContainerClosed = {
    params ["_container", "_unit"];
    if (_unit != player) exitWith {};

    private _initialMass = _unit getVariable ["QM_LocalTrade_InitialMass", -1];
    private _baseKey = _unit getVariable ["QM_Current_Terminal_Base", ""];
    private _finalMass = loadAbs _unit;

    if (_initialMass == -1) exitWith {
        private _err = "QUARTERMASTER ERROR: Transaction aborted. Missing initial mass snapshot.";
        systemChat _err; diag_log _err;
    };
    if (_baseKey == "") exitWith {
        private _err = "QUARTERMASTER ERROR: Transaction aborted. Active base key could not be identified.";
        systemChat _err; diag_log _err;
    };

    private _massDelta = _finalMass - _initialMass;
    
    if (_massDelta != 0) then {
        private _actionText = if (_massDelta > 0) then {"WITHDRAWN from"} else {"DEPOSITED into"};
        private _formattedDelta = abs _massDelta;
        private _msg = format ["[LOGISTICS HUB]: %1 Mass Units %2 %3 Cargo supply pool.", _formattedDelta, _actionText, _baseKey];
        
        systemChat _msg; diag_log _msg;

        private _backupLoadout = getUnitLoadout _unit;
        [_baseKey, _massDelta, _unit, _backupLoadout] remoteExec ["QM_fnc_processInventoryTransaction", 2];
    } else {
        private _msg = format ["[LOGISTICS HUB]: No net mass changes detected at %1.", _baseKey];
        systemChat _msg; diag_log _msg;
    };

    _unit setVariable ["QM_LocalTrade_InitialMass", nil];
};

// --- CLIENT MONITOR: CLOSES THE NATIVE REARM LOOPHOLE ---
if (!isDedicated) then {
    [] spawn {
        while {true} do {
            uiSleep 2;
            
            private _nearCrates = player nearObjects ["VirtualReammoBox_camonet_F", 5];
            
            if (count _nearCrates > 0) then {
                private _activeCrate = _nearCrates select 0;
                private _baseKey = _activeCrate getVariable ["QM_Crate_OwningBase", ""];
                if (_baseKey == "") then { _baseKey = player getVariable ["QM_Current_Terminal_Base", ""]; };
                
                if (_baseKey != "") then {
                    if (player getVariable ["QM_Rearm_TrackingMass", -1] == -1) then {
                        player setVariable ["QM_Current_Terminal_Base", _baseKey];
                        player setVariable ["QM_Rearm_TrackingMass", loadAbs player];
                    };
                };
            } else {
                private _trackedMass = player getVariable ["QM_Rearm_TrackingMass", -1];
                private _baseKey = player getVariable ["QM_Current_Terminal_Base", ""];
                
                if (_trackedMass != -1 && _baseKey != "") then {
                    private _currentMass = loadAbs player;
                    private _massDelta = _currentMass - _trackedMass;
                    
                    private _activeMenuMass = player getVariable ["QM_LocalTrade_InitialMass", -1];
                    
                    if (_massDelta != 0 && _activeMenuMass == -1) then {
                        private _actionText = if (_massDelta > 0) then {"WITHDRAWN via Rearm from"} else {"DEPOSITED into"};
                        private _msg = format ["[LOGISTICS AUTO-REARM]: %1 Mass Units %2 %3 Cargo supply pool.", abs _massDelta, _actionText, _baseKey];
                        
                        systemChat _msg; diag_log _msg;

                        private _backupLoadout = getUnitLoadout player;
                        [_baseKey, _massDelta, player, _backupLoadout] remoteExec ["QM_fnc_processInventoryTransaction", 2];
                    };
                };
                player setVariable ["QM_Rearm_TrackingMass", nil];
            };
        };
    };
};

// --- PUBLIC ROUTE REGISTER COUPLING ---
publicVariable "QM_fnc_traderOnContainerOpened";
publicVariable "QM_fnc_traderOnContainerClosed";