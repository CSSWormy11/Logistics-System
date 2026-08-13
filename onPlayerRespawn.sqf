// ============================================================================
// LOGISTICS SYSTEM: CLIENT/SERVER HANDOFF ON SPAWN (PART 2)
// File: onPlayerRespawn.sqf
// Description: Automatically triggers when a player materializes via selection.
//              Handles point deduction. Native engine handles actual placement.
// Called By: Arma 3 Engine (Native Event Handler upon Player Respawn)
// ============================================================================

params ["_newUnit", "_oldUnit", "_respawn", "_hasRespawnDelay"];

if (!hasInterface) exitWith {}; 

private _closestBase = "";
private _shortestDistance = 99999;

{
    private _markerPos = getMarkerPos _x;
    private _dist = _newUnit distance2D _markerPos;
    if (_dist < _shortestDistance) then {
        _shortestDistance = _dist;
        _closestBase = _x;
    };
} forEach logisticsBases;

// Only deduct points if they spawned inside the radius of a logistics base
if (_closestBase == "" || _shortestDistance > 250) exitWith {};

// --- STEP 1: DEDUCT THE TROOP POINT ON THE SERVER ---
[_closestBase] remoteExec ["QM_fnc_deductRespawnTroop", 2];

systemChat format ["Welcome back. Deployment authenticated at %1.", _closestBase];

// --- STEP 2: INDOOR STRUCTURAL PLACEMENT (Barracks Whitelist Only) ---
private _basePos = getMarkerPos _closestBase;
private _allowedBarracksTypes = ["Land_Cargo_House_V3_F"];

private _nearObjects = nearestObjects [_basePos, ["AllVehicles", "Static", "Thing", "Building"], 100];
private _validBuildings = _nearObjects select {
    (typeOf _x) in _allowedBarracksTypes && alive _x
};

private _spawnedSafe = false;

if (count _validBuildings > 0) then {
    private _chosenBuilding = _validBuildings select 0; 
    private _allPositions = _chosenBuilding buildingPos -1; 

    if (count _allPositions > 0) then {
        private _randomSpawnPos = selectRandom _allPositions;
        
        if ((_randomSpawnPos select 2) < 25) then {
            _newUnit setPosATL _randomSpawnPos;
            _spawnedSafe = true;
            systemChat format ["Logistics deployment authenticated. Assigned to barracks at %1.", _closestBase];
        };
    };
    
    if (!_spawnedSafe) then {
        _newUnit setPos (_chosenBuilding modelToWorld [0, 2, 0]);
        _spawnedSafe = true;
        systemChat format ["Deployed safely outside barracks threshold at %1.", _closestBase];
    };
};

if (!_spawnedSafe) then {
    _newUnit setPos [_basePos select 0, _basePos select 1, 0];
    systemChat format ["Welcome back. Deployed in open camp yard at %1.", _closestBase];
};