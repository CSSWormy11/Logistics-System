// ============================================================================
// LOGISTICS SYSTEM: PHYSICAL DEPLOYMENT ENGINE (PART 1)
// File: fn_spawnLoadSupply.sqf
// Description: Spawns the requested cargo, calculates its mass via SupplyScores,
//              deducts points from the source base, and loads it into the transport.
//              Also handles specific spawn routing for troops, planes, and helis.
// Called By: Eden Editor Trigger (On Activation) at Loading Pads
//            e.g., [vehicle player, "MSR"] execVM "fn_spawnLoadSupply.sqf";
// ============================================================================

params [
    ["_vehicle", objNull, [objNull]], 
    ["_pickupBaseKey", "", [""]]
];

if (isNull _vehicle) exitWith {};

// Double-load protection block
if (_vehicle getVariable ["logistics_is_loaded", false]) exitWith {};

private _vehType = typeOf _vehicle;
private _templateIndex = allowedLogisticsVehicles find _vehType;
private _allVehicleSupplies = (logisticsCargoTemplates # _templateIndex) # 1;

private _supplyType = player getVariable ["logistics_current_assigned_category", ""];

if (_supplyType == "" || {({_x # 0 == _supplyType} count _allVehicleSupplies) == 0}) then {
    private _availCategories = _allVehicleSupplies apply {_x # 0};
    _supplyType = if ("Troops" in _availCategories) then {"Troops"} else {"Cargo"};
};

private _cargoList = [];
{ if (_x # 0 == _supplyType) exitWith { _cargoList = _x # 1; }; } forEach _allVehicleSupplies;

// Calculate point footprint cost
private _totalCargoPointWeight = 0;
{
    private _itemClassname = _x;
    private _scoreIndex = supplyScores findIf {_x # 0 == _itemClassname};
    if (_scoreIndex != -1) then {
        private _scoreData = (supplyScores # _scoreIndex) # 1;
        { if (_x # 0 == _supplyType) exitWith { _totalCargoPointWeight = _totalCargoPointWeight + (_x # 1); }; } forEach _scoreData;
    } else {
        _totalCargoPointWeight = _totalCargoPointWeight + (if (_supplyType == "Troops") then { 1 } else { 2000 });
    };
} forEach _cargoList;

// Stock storage verification protection guard
private _targetVar = format ["LogiScore_%1_%2", _pickupBaseKey, _supplyType];
private _availablePoints = missionNamespace getVariable [_targetVar, 0];

if (_availablePoints != -1) then {
    if (_availablePoints < _totalCargoPointWeight) exitWith {
        [west, "HQ"] sideChat format ["WARNING: Stores low on %1 at %2.", _supplyType, _pickupBaseKey];
    };
    missionNamespace setVariable [_targetVar, 0 max (_availablePoints - _totalCargoPointWeight), true];
};

private _displayAssetName = "Supplies";
if (count _cargoList > 0) then {
    _displayAssetName = getText (configFile >> "CfgVehicles" >> (_cargoList # 0) >> "displayName");
};

// =========================================================================
// CRITICAL ROUTING CONTEXT READ
// =========================================================================
private _targetDeliveryBase = _vehicle getVariable ["logistics_intended_fob", "SB"];
private _deliveryMarker = if (_targetDeliveryBase == "SB") then { "Dropoff_SB" } else { format ["Dropoff_%1", _targetDeliveryBase] };
private _deliveryPos = getMarkerPos _deliveryMarker;

// =========================================================================
// UNLOADED EXECUTION PROFILES
// =========================================================================
if (_supplyType == "Troops") exitWith {
    systemChat format ["LOGISTICS COMMAND: Manifest compiled. Boarding [%1] reinforcement squad...", _displayAssetName];
    
    private _grp = createGroup [playerSide, true];
    {
        private _unit = _grp createUnit [_x, [0,0,0], [], 0, "NONE"];
        _unit moveInCargo _vehicle;
    } forEach _cargoList;

    // Give the group a physical moving waypoint to the delivery zone marker location
    private _wp = _grp addWaypoint [_deliveryPos, 0];
    _wp setWaypointType "MOVE";
    _wp setWaypointBehaviour "SAFE";
    _wp setWaypointSpeed "FULL";

    // Launch independent tracking loop locked strictly to these infantry units
    [_grp, _deliveryMarker, _targetDeliveryBase] spawn {
        params ["_group", "_targetMarkerID", "_destinationKey"];
        private _targetPos2D = getMarkerPos _targetMarkerID;
        private _processingActive = true;

        while { _processingActive && {count (units _group) > 0} } do {
            {
                private _unit = _x;
                if (alive _unit && {(_unit distance2D _targetPos2D) < 35}) then {
                    private _scoreVarName = format ["LogiScore_%1_Troops", _destinationKey];
                    missionNamespace setVariable [_scoreVarName, (missionNamespace getVariable [_scoreVarName, 0]) + 1, true];
                    
                    systemChat format ["[LOGISTICS]: Reinforcement unit arrived and garrisoned at %1.", _destinationKey splitString "_" joinString " "];
                    deleteVehicle _unit;
                };
            } forEach (units _group);

            if (count (units _group) == 0) then { _processingActive = false; };
            sleep 2;
        };
        deleteGroup _group;
    };

    _vehicle setVariable ["logistics_is_loaded", false, true];
    _vehicle setVariable ["logistics_loaded_type", "", true];
    _vehicle setVariable ["logistics_loaded_weight", 0, true];
};

// --- STANDARD FREIGHT CARGO AND VEHICLE SPOD PACKING PROFILE ---
private _isPlane = _vehicle isKindOf "Plane";
private _isHelicopter = _vehicle isKindOf "Helicopter";
private _heightAboveSurface = (getPosVisual _vehicle) # 2; 

if (_isPlane || _heightAboveSurface > 30) exitWith {
    systemChat format ["LOGISTICS COMMAND: Flight deck cargo internal pack: [%1].", _displayAssetName];
    { private _cargoObj = _x createVehicle [0,0,0]; _vehicle setVehicleCargo _cargoObj; } forEach _cargoList;
    _vehicle setVariable ["logistics_is_loaded", true, true];
    _vehicle setVariable ["logistics_loaded_type", _supplyType, true];
    _vehicle setVariable ["logistics_loaded_weight", _totalCargoPointWeight, true];
};

if (_isHelicopter && _heightAboveSurface >= 1.5) exitWith {
    systemChat format ["LOGISTICS COMMAND: Hover creation generated surface containers: [%1].", _displayAssetName];
    private _spawnPos = getPosVisual _vehicle;
    _spawnPos set [2, (_spawnPos # 2) - _heightAboveSurface]; 
    {
        private _pod = _x createVehicle _spawnPos;
        _pod setPos _spawnPos;
        _spawnPos = _pod modelToWorld [0, 3, 0]; 
    } forEach _cargoList;
    _vehicle setVariable ["logistics_is_loaded", true, true];
    _vehicle setVariable ["logistics_loaded_type", _supplyType, true];
    _vehicle setVariable ["logistics_loaded_weight", _totalCargoPointWeight, true];
};

systemChat format ["LOGISTICS COMMAND: Surface cargo grid storage locked down: [%1].", _displayAssetName];
{ private _cargoObj = _x createVehicle [0,0,0]; _vehicle setVehicleCargo _cargoObj; } forEach _cargoList;

_vehicle setVariable ["logistics_is_loaded", true, true];
_vehicle setVariable ["logistics_loaded_type", _supplyType, true];
_vehicle setVariable ["logistics_loaded_weight", _totalCargoPointWeight, true];