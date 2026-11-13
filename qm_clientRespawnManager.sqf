// ============================================================================
// LOGISTICS SYSTEM: CLIENT RESPAWN & FOB COOLDOWN MANAGER
// File: qm_clientRespawnManager.sqf
// Description: Manages per-player respawn positions based on troop supply
//              availability and individual FOB redeployment cooldown timers.
//              Supply Bases (SB / MSR) have zero cooldown.
// Execution: Client-side only (hasInterface)
// ============================================================================

if (!hasInterface) exitWith {};

waitUntil { !isNull player && { !isNil "logisticsBases" } };

if (isNil "QM_Local_FOBCooldowns") then { QM_Local_FOBCooldowns = createHashMap; };
if (isNil "QM_Respawn_FOBCooldown") then { QM_Respawn_FOBCooldown = 120; };

// Format: [BaseKey, [Array of Respawn IDs], LastKnownTroopCount, WasOnCooldown]
QM_ClientRespawnHandles = [];

diag_log "[QUARTERMASTER]: Client-side per-player respawn and FOB cooldown daemon started.";

while {true} do {
    private _currentTime = diag_tickTime;

    {
        private _baseKey = _x;
        private _isSB = (["SB", _baseKey] call BIS_fnc_inString || { "MSR" in (toUpper _baseKey) });
        private _troopVarName = format ["LogiScore_%1_Troops", _baseKey];
        private _currentTroops = missionNamespace getVariable [_troopVarName, 0];

        // Evaluate Cooldown: SBs never have a cooldown; FOBs check local player timer
        private _cooldownExpiry = QM_Local_FOBCooldowns getOrDefault [_baseKey, 0];
        private _onCooldown = (!_isSB && { _currentTime < _cooldownExpiry });

        // Eligibility: Must have troop points (> 0 or -1 infinite) AND not be on cooldown
        private _isEligible = (_currentTroops > 0 || _currentTroops == -1) && !_onCooldown;

        private _idx = QM_ClientRespawnHandles findIf { (_x # 0) == _baseKey };
        private _hasMenuSlot = (_idx != -1);

        private _lastTroops = if (_hasMenuSlot) then { (QM_ClientRespawnHandles select _idx) select 2 } else { -999 };
        private _lastCooldown = if (_hasMenuSlot) then { (QM_ClientRespawnHandles select _idx) select 3 } else { false };

        // Process updates if eligibility state changed or troop count shifted
        if (_isEligible) then {
            if (!_hasMenuSlot || _currentTroops != _lastTroops || _lastCooldown != _onCooldown) then {
                // 1. Purge existing positions for this base before updating
                if (_hasMenuSlot) then {
                    private _trackedIDs = (QM_ClientRespawnHandles select _idx) select 1;
                    { _x call BIS_fnc_removeRespawnPosition; } forEach _trackedIDs;
                };

                // 2. Format clean display string
                private _baseDisplayName = _baseKey;
                if (_baseDisplayName select [0, 4] == "FOB_") then { _baseDisplayName = _baseDisplayName select [4]; };
                if (_baseDisplayName select [0, 3] == "SB_") then { _baseDisplayName = _baseDisplayName select [3]; };

                private _displayString = if (_currentTroops == -1) then {
                    format ["%1 (Infinite)", _baseDisplayName]
                } else {
                    format ["%1 (Troops: %2)", _baseDisplayName, _currentTroops]
                };

                // 3. Find all editor-placed 3D _Spawn objects for this base
                private _locations = [_baseKey, "Spawn"] call QM_fnc_getLocationsByPrefix;
                private _newIDs = [];

                if (count _locations > 0) then {
                    {
                        _x params ["_entity", "_pos", "_dir", "_type", "_identityName"];
                        if (_entity isEqualType objNull && { !isNull _entity }) then {
                            private _cleanPadName = _identityName;
                            if (_cleanPadName select [0, 4] == "FOB_") then { _cleanPadName = _cleanPadName select [4]; };
                            if (_cleanPadName select [0, 3] == "SB_") then { _cleanPadName = _cleanPadName select [3]; };

                            private _finalString = if (count _locations > 1) then {
                                format ["%1 [%2]", _displayString, _cleanPadName]
                            } else {
                                _displayString
                            };
                            // Add position targeted strictly to local player unit
                            private _rID = [player, _entity, _finalString] call BIS_fnc_addRespawnPosition;
                            _newIDs pushBack _rID;
                        };
                    } forEach _locations;
                };

                // 4. Save to memory
                if (_hasMenuSlot) then {
                    private _record = QM_ClientRespawnHandles select _idx;
                    _record set [1, _newIDs];
                    _record set [2, _currentTroops];
                    _record set [3, _onCooldown];
                } else {
                    QM_ClientRespawnHandles pushBack [_baseKey, _newIDs, _currentTroops, _onCooldown];
                };
            };
        } else {
            // Ineligible (either depleted troops or active cooldown) - remove from menu
            if (_hasMenuSlot) then {
                private _trackedIDs = (QM_ClientRespawnHandles select _idx) select 1;
                { _x call BIS_fnc_removeRespawnPosition; } forEach _trackedIDs;
                QM_ClientRespawnHandles deleteAt _idx;
            };
        };

    } forEach (missionNamespace getVariable ["logisticsBases", []]);

    uiSleep 2;
};
