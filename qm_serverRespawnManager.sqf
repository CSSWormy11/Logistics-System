// ============================================================================
// LOGISTICS SYSTEM: AUTOMATED RESPAWN MANAGER (PART 2)
// File: qm_serverRespawnManager.sqf
// Description: Pure scripted respawn framework. Eliminates editor modules
//              completely. Automatically updates map lists off base markers/objects
//              and troop pool availability. Supports multiple spawn points.
// Called By: init.sqf (Executed during server initialization)
// ============================================================================

if (!isServer) exitWith {};

// Format: [BaseKey, [Array of Respawn IDs], LastKnownTroopCount]
QM_ScriptedRespawnHandles = [];

diag_log "QUARTERMASTER: Scripted Automated Respawn Loop Started.";

while {true} do {
    {
        private _baseKey = _x;
        private _troopVarName = format ["LogiScore_%1_Troops", _baseKey];
        private _currentTroops = missionNamespace getVariable [_troopVarName, 0];

        private _idx = QM_ScriptedRespawnHandles findIf {(_x select 0) == _baseKey};
        private _hasMenuSlot = (_idx != -1);
        
        // Fetch the last known troop count to prevent rebuilding the UI every 4 seconds
        private _lastTroops = if (_hasMenuSlot) then { (QM_ScriptedRespawnHandles select _idx) select 2 } else { -999 };

        // Only process changes if the troop pool size shifted (or if it's brand new)
        if (_currentTroops != _lastTroops) then {
            
            // 1. Purge all existing respawn modules for this base before updating
            if (_hasMenuSlot) then {
                private _targetRecord = QM_ScriptedRespawnHandles select _idx;
                private _trackedIDs = _targetRecord select 1;
                { _x call BIS_fnc_removeRespawnPosition; } forEach _trackedIDs;
            };

            // 2. Rebuild the positions if we have the manpower
            if (_currentTroops > 0 || _currentTroops == -1) then {
                
                private _displayString = if (_currentTroops == -1) then {
                    format ["%1 (Infinite)", _baseKey]
                } else {
                    format ["%1 (Troops: %2)", _baseKey, _currentTroops]
                };

                // Find all editor-placed 3D _Spawn objects for this base
                private _locations = [_baseKey, "Spawn"] call QM_fnc_getLocationsByPrefix;
                private _newIDs = [];

                if (count _locations > 0) then {
                    {
                        _x params ["_entity", "_pos", "_dir", "_type", "_identityName"];
                        if (_entity isEqualType objNull && { !isNull _entity }) then {
                            private _finalString = format ["%1 (%2)", _displayString, _identityName];
                            private _rID = [west, _entity, _finalString] call BIS_fnc_addRespawnPosition;
                            _newIDs pushBack _rID;
                        };
                    } forEach _locations;
                };

                // Save to memory
                if (_hasMenuSlot) then {
                    private _targetRecord = QM_ScriptedRespawnHandles select _idx;
                    _targetRecord set [1, _newIDs];
                    _targetRecord set [2, _currentTroops];
                } else {
                    QM_ScriptedRespawnHandles pushBack [_baseKey, _newIDs, _currentTroops];
                };
                
                diag_log format ["QUARTERMASTER AUTO-SPAWN: Created/Updated %2 map option(s) for %1.", _baseKey, count _newIDs];
                
            } else {
                // 3. Troops depleted completely, delete the slot from the tracking array
                if (_hasMenuSlot) then {
                    QM_ScriptedRespawnHandles deleteAt _idx;
                    diag_log format ["QUARTERMASTER AUTO-SPAWN: Removed map options for %1 due to depletion.", _baseKey];
                };
            };
        };

    } forEach logisticsBases;

    uiSleep 4;
};