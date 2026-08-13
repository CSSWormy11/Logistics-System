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

                // Use the universal helper to find all _Spawn locations (objects or markers)
                private _locations = [_baseKey, "Spawn"] call QM_fnc_getLocationsByPrefix;
                private _newIDs = [];

                if (count _locations > 0) then {
                    // Create a separate respawn point for every specific location placed
                    {
                        _x params ["_entity", "_pos", "_dir", "_type", "_identityName"];
                        
                        private _markerText = "";
                        if (_type == "MARKER") then { 
                            _markerText = markerText _entity; 
                        } else { 
                            _markerText = getText(configFile >> "CfgVehicles" >> typeOf _entity >> "displayName"); 
                        };

                        private _finalString = if (_markerText != "") then { format ["%1 - %2", _displayString, _markerText] } else { format ["%1 (%2)", _displayString, _identityName] };
                        
                        // --- CARRIER DECK FIX: Convert 2D Markers into 3D Physical Objects ---
                        // Markers default to sea-level (Z=0). This traces a line from the sky to find the flight deck 
                        // and places a physical invisible object there for players to safely spawn onto.
                        private _spawnTarget = _entity;
                        if (_type == "MARKER") then {
                            private _helperVarName = format ["QM_SpawnHelper_%1", _identityName];
                            private _helperObj = missionNamespace getVariable [_helperVarName, objNull];
                            
                            if (isNull _helperObj) then {
                                _helperObj = createVehicle ["Land_HelipadEmpty_F", [0,0,0], [], 0, "CAN_COLLIDE"];
                                
                                private _startPos = [_pos select 0, _pos select 1, 150];
                                private _endPos = [_pos select 0, _pos select 1, -10];
                                private _intersects = lineIntersectsSurfaces [_startPos, _endPos, objNull, objNull, true, 1, "GEOM", "NONE"];
                                
                                if (count _intersects > 0) then {
                                    _helperObj setPosASL ((_intersects select 0) select 0);
                                } else {
                                    _helperObj setPosATL [_pos select 0, _pos select 1, 0.1];
                                };
                                _helperObj setDir _dir;
                                missionNamespace setVariable [_helperVarName, _helperObj, true];
                            };
                            _spawnTarget = _helperObj;
                        };

                        // BIS_fnc_addRespawnPosition fully accepts physical objects!
                        private _rID = [west, _spawnTarget, _finalString] call BIS_fnc_addRespawnPosition;
                        _newIDs pushBack _rID;
                    } forEach _locations;
                } else {
                    // Fallback to the center of the base if no specific spawn tents/markers were placed
                    private _helperVarName = format ["QM_SpawnHelper_Fallback_%1", _baseKey];
                    private _helperObj = missionNamespace getVariable [_helperVarName, objNull];
                    
                    if (isNull _helperObj) then {
                        private _pos = getMarkerPos _baseKey;
                        _helperObj = createVehicle ["Land_HelipadEmpty_F", [0,0,0], [], 0, "CAN_COLLIDE"];
                        
                        private _startPos = [_pos select 0, _pos select 1, 150];
                        private _endPos = [_pos select 0, _pos select 1, -10];
                        private _intersects = lineIntersectsSurfaces [_startPos, _endPos, objNull, objNull, true, 1, "GEOM", "NONE"];
                        
                        if (count _intersects > 0) then {
                            _helperObj setPosASL ((_intersects select 0) select 0);
                        } else {
                            _helperObj setPosATL [_pos select 0, _pos select 1, 0.1];
                        };
                        missionNamespace setVariable [_helperVarName, _helperObj, true];
                    };

                    private _rID = [west, _helperObj, _displayString] call BIS_fnc_addRespawnPosition;
                    _newIDs pushBack _rID;
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