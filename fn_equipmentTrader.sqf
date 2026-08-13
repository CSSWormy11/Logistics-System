// ============================================================================
// LOGISTICS SYSTEM: PLAYER MASS DELTA LEDGER (PART 2)
// File: fn_equipmentTrader.sqf
// Description: Unifies transaction paths (Arsenal, Box Inventory, and Rearm prompts)
//              and pipes comprehensive diagnostic traces directly into the RPT log.
// Called By: init.sqf (Compiled during client initialization)
// ============================================================================

// --- ENGINE RECEPTACLE: NATIVE INVENTORY OPENED ---
QM_fnc_traderOnContainerOpened = {
    params ["_container", "_unit"];
    if (_unit != player) exitWith {};

    // Snapshot player weight parameters at millisecond zero
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

    // 1. Audit Failure Logs to both Chat and RPT
    if (_initialMass == -1) exitWith {
        private _err = "QUARTERMASTER ERROR: Transaction aborted. Missing initial mass snapshot.";
        systemChat _err; diag_log _err;
    };
    if (_baseKey == "") exitWith {
        private _err = "QUARTERMASTER ERROR: Transaction aborted. Active base key could not be identified.";
        systemChat _err; diag_log _err;
    };

    private _massDelta = _finalMass - _initialMass;
    
    // 2. Audit Successful Logs to both Chat and RPT
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
                    
                    // FIXED SYNTAX CRITICAL PATCH:
                    // Verifies if an active menu transaction is currently running by testing fallback state parameters
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