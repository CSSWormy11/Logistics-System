// ============================================================================
// LOGISTICS SYSTEM: SERVER INFRASTRUCTURE MANAGER (PART 2)
// File: qm_serverGarrisonManager.sqf
// Description: Collects mission-maker placed 3D base objects strictly by their
//              variable names (<BaseKey>_Arsenal_# / <BaseKey>_Terminal_#),
//              attaches ContainerOpened/Closed mass accounting handlers,
//              enforces 4-index Terrain/Faction filtering on physical crates,
//              and broadcasts active terminals to clients.
// Called By: init.sqf (Executed during server initialization)
// ============================================================================

if (!isServer) exitWith {};
waitUntil { !isNil "logisticsBases" };

diag_log "QUARTERMASTER: Server Infrastructure Builder booted (Strict 3D Object Mode).";

// ----------------------------------------------------------------------------
// V8 SYSTEM REQUIREMENT: Fetch metadata variables for filtering physical crate loot
// ----------------------------------------------------------------------------
private _currentTerrain = toUpper (call fn_G_getTerrain);
private _serverFaction = toUpper (missionNamespace getVariable ["QM_ServerFaction", "WEST"]); 

while {true} do {
    {
        private _baseKey = _x;
        
        // ====================================================================
        // 1. TERMINALS & ARSENALS (Editor-Placed 3D Objects Only)
        // ====================================================================
        private _terminals = ([_baseKey, "Arsenal"] call QM_fnc_getLocationsByPrefix) + ([_baseKey, "Terminal"] call QM_fnc_getLocationsByPrefix);
        
        if (count _terminals == 0) then { 
            diag_log format ["QUARTERMASTER WARNING: No explicit _Arsenal or _Terminal 3D objects found for %1.", _baseKey];
        };

        {
            _x params ["_entity", "_pos", "_dir", "_type", "_identityName"];
            
            private _activeHub = if (_entity isEqualType objNull) then { _entity } else { objNull };

            // --- INITIALIZE THE HUB OBJECT ---
            if (!isNull _activeHub && alive _activeHub) then {
                if ((_activeHub getVariable ["QM_Crate_OwningBase", ""]) == "") then {
                    _activeHub setVariable ["QM_Crate_OwningBase", _baseKey, true];
                    _activeHub addEventHandler ["ContainerOpened", { _this call QM_fnc_traderOnContainerOpened; }];
                    _activeHub addEventHandler ["ContainerClosed", { _this call QM_fnc_traderOnContainerClosed; }];

                    clearWeaponCargoGlobal _activeHub; clearMagazineCargoGlobal _activeHub; clearItemCargoGlobal _activeHub; clearBackpackCargoGlobal _activeHub;
                    
                    if (!isNil "G_Allowed_Weapons") then {
                        // ------------------------------------------------------------------------
                        // V8 DATA EXTRACTION (PHYSICAL CRATES)
                        // ------------------------------------------------------------------------
                        private _fnc_populatePhysicalCrate = {
                            params ["_crate", "_array", "_type"];
                            private _addedCount = 0;
                            {
                                _x params ["_classname", "_stockQty", ["_faction", "ALL"], ["_terrainBiomes", ["ALL"]]];
                                
                                private _terrainUpper = _terrainBiomes apply { toUpper _x };
                                private _validFaction = (toUpper _faction == "ALL" || toUpper _faction == _serverFaction);
                                private _validTerrain = ("ALL" in _terrainUpper || _currentTerrain in _terrainUpper);
                                
                                if (_validFaction && _validTerrain) then {
                                    switch (_type) do {
                                        case "WEAPON": { _crate addWeaponCargoGlobal [_classname, _stockQty]; };
                                        case "MAGAZINE": { _crate addMagazineCargoGlobal [_classname, _stockQty]; };
                                        case "ITEM": { _crate addItemCargoGlobal [_classname, _stockQty]; };
                                        case "BACKPACK": { _crate addBackpackCargoGlobal [_classname, _stockQty]; };
                                    };
                                    _addedCount = _addedCount + 1;
                                };
                            } forEach _array;
                            
                            diag_log format ["SERVER PHYSICAL LOOT: Added %1 %2s to %3", _addedCount, _type, _baseKey];
                        };

                        diag_log format ["=========================================="];
                        diag_log format ["SERVER PHYSICAL LOOT: Populating Base '%1'", _baseKey];
                        [_activeHub, G_Allowed_Weapons, "WEAPON"] call _fnc_populatePhysicalCrate;
                        [_activeHub, G_Allowed_Magazines, "MAGAZINE"] call _fnc_populatePhysicalCrate;
                        [_activeHub, G_Allowed_Items, "ITEM"] call _fnc_populatePhysicalCrate;
                        [_activeHub, G_Allowed_Backpacks, "BACKPACK"] call _fnc_populatePhysicalCrate;
                        diag_log format ["=========================================="];
                    };
                };

                // --- JIP SAFE PIPELINE ---
                if (!(_activeHub getVariable ["QM_TerminalUnifiedActionsActive", false])) then {
                    _activeHub setVariable ["QM_TerminalUnifiedActionsActive", true, true];
                    private _globalHubs = missionNamespace getVariable ["QM_Global_Terminals", []];
                    _globalHubs pushBackUnique _activeHub;
                    missionNamespace setVariable ["QM_Global_Terminals", _globalHubs, true];
                };
            };
        } forEach _terminals;

    } forEach logisticsBases;
    uiSleep 8; 
};