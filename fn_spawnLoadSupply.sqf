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

// Normalize base key in case a numbered trigger passed "<Base>_pickup"
private _pLower = toLowerANSI _pickupBaseKey;
private _pIdx = _pLower find "_pickup";
if (_pIdx != -1) then { _pickupBaseKey = _pickupBaseKey select [0, _pIdx]; };

// Double-load protection block
if (_vehicle getVariable ["logistics_is_loaded", false]) exitWith {};

private _vehType = typeOf _vehicle;
private _templateIndex = allowedLogisticsVehicles find _vehType;
if (_templateIndex == -1) exitWith {};
private _entry = logisticsCargoTemplates # _templateIndex;
private _allVehicleSupplies = if (count _entry > 2 && { (_entry # 2) isEqualType [] }) then { _entry # 2 } else { _entry # 1 };

private _supplyType = player getVariable ["logistics_current_assigned_category", ""];

if (_supplyType == "" || {({_x # 0 == _supplyType} count _allVehicleSupplies) == 0}) then {
    private _availCategories = _allVehicleSupplies apply {_x # 0};
    _supplyType = if ("Troops" in _availCategories) then {"Troops"} else {"Cargo"};
};

private _cargoList = [];
{ if (_x # 0 == _supplyType) exitWith { _cargoList = _x # 1; }; } forEach _allVehicleSupplies;

// Support both flat classname arrays and nested route-tiered arrays:
// [["Strategic", ["Class1"]], ["Tactical", ["Class2", "Class2"]], ["CLT", ["Class3"]]]
if (count _cargoList > 0 && { (_cargoList # 0) isEqualType [] }) then {
    private _activeRoute = if ("MSR" in toUpper _pickupBaseKey) then { "Strategic" } else { "Tactical" };
    private _realTask = currentTask player;
    if (!isNull _realTask) then {
        if (["Logi_Strategic_Task"] call BIS_fnc_taskExists && { _realTask isEqualTo (["Logi_Strategic_Task", player] call BIS_fnc_taskReal) }) then { _activeRoute = "Strategic"; };
        if (["Logi_Tactical_Task"] call BIS_fnc_taskExists && { _realTask isEqualTo (["Logi_Tactical_Task", player] call BIS_fnc_taskReal) }) then { _activeRoute = "Tactical"; };
        if (["Logi_CLT_Task"] call BIS_fnc_taskExists && { _realTask isEqualTo (["Logi_CLT_Task", player] call BIS_fnc_taskReal) }) then { _activeRoute = "CLT"; };
    };
    private _routeIdx = _cargoList findIf { toUpper (_x # 0) == toUpper _activeRoute };
    if (_routeIdx != -1) then {
        _cargoList = (_cargoList # _routeIdx) # 1;
    } else {
        _cargoList = (_cargoList # 0) # 1;
    };
};

// Calculate true height above underlying surface (ground, water, or carrier/ship deck)
private _vehPosASL = getPosASL _vehicle;
private _surfaceASL = [_vehPosASL # 0, _vehPosASL # 1, 0];
private _intersects = lineIntersectsSurfaces [_vehPosASL, [_vehPosASL # 0, _vehPosASL # 1, (_vehPosASL # 2) - 200], _vehicle, objNull, true, 1, "GEOM", "NONE"];
private _heightAboveSurface = (getPosATL _vehicle) # 2;
if (count _intersects > 0) then {
    _surfaceASL = (_intersects # 0) # 0;
    _heightAboveSurface = ((_vehPosASL # 2) - (_surfaceASL # 2)) max 0;
};

private _isPlane = _vehicle isKindOf "Plane";
private _isHelicopter = _vehicle isKindOf "Helicopter";

// Require troop transports to be stationary on the ground/deck before boarding
if (_supplyType == "Troops" && (_heightAboveSurface > 2.5 || abs (speed _vehicle) >= 1)) exitWith {
    systemChat "LOGISTICS COMMAND: Land and come to a complete stop on the pickup pad to board troops.";
};

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

// Stock storage verification protection guard (top-level exitWith so it properly halts script)
private _targetVar = format ["LogiScore_%1_%2", _pickupBaseKey, _supplyType];
private _availablePoints = missionNamespace getVariable [_targetVar, 0];

if (_availablePoints != -1 && _availablePoints < _totalCargoPointWeight) exitWith {
    [west, "HQ"] sideChat format ["WARNING: Stores low on %1 at %2.", _supplyType, _pickupBaseKey];
};

if (_availablePoints != -1) then {
    missionNamespace setVariable [_targetVar, 0 max (_availablePoints - _totalCargoPointWeight), true];
};

private _displayAssetName = "Supplies";
if (count _cargoList > 0) then {
    _displayAssetName = getText (configFile >> "CfgVehicles" >> (_cargoList # 0) >> "displayName");
};

// =========================================================================
// CRITICAL ROUTING CONTEXT READ
// =========================================================================
private _allSBs = (missionNamespace getVariable ["logisticsBases", []]) select { "SB" in toUpper _x };
private _defaultSB = _allSBs param [0, "SB"];
private _targetDeliveryBase = _vehicle getVariable ["logistics_intended_fob", _defaultSB];
private _deliveryMarker = format ["Dropoff_%1", _targetDeliveryBase];
if (getMarkerColor _deliveryMarker == "" && _targetDeliveryBase == "SB") then { _deliveryMarker = "Dropoff_SB"; };
private _deliveryPos = if (getMarkerColor _deliveryMarker != "") then { getMarkerPos _deliveryMarker } else { getMarkerPos _targetDeliveryBase };

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
    [_grp, _deliveryPos, _targetDeliveryBase] spawn {
        params ["_group", "_targetPos2D", "_destinationKey"];
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

// --- STANDARD FREIGHT CARGO AND VEHICLE SLINGLOAD / VIV PACKING PROFILE ---
if (_isPlane && !_isHelicopter && _heightAboveSurface > 30) exitWith {
    systemChat format ["LOGISTICS COMMAND: Flight deck cargo internal pack: [%1].", _displayAssetName];
    { private _cargoObj = _x createVehicle [0,0,0]; _vehicle setVehicleCargo _cargoObj; } forEach _cargoList;
    _vehicle setVariable ["logistics_is_loaded", true, true];
    _vehicle setVariable ["logistics_loaded_type", _supplyType, true];
    _vehicle setVariable ["logistics_loaded_weight", _totalCargoPointWeight, true];
};

if (_isHelicopter) exitWith {
    systemChat format ["LOGISTICS COMMAND: Surface containers staged for slingload: [%1].", _displayAssetName];
    private _pickupMarker = format ["Pickup_%1", _pickupBaseKey];
    private _basePadPos2D = if (getMarkerColor _pickupMarker != "") then { getMarkerPos _pickupMarker } else { [_vehPosASL # 0, _vehPosASL # 1, 0] };

    // If the helicopter is at a secondary trigger (e.g. MSR_pickup_3) or >25m from the primary icon marker, stage at the helicopter's location
    if ((_vehicle distance2D _basePadPos2D) > 25) then {
        _basePadPos2D = [_vehPosASL # 0, _vehPosASL # 1, 0];
    };

    // If the helicopter is landed near the spawn point, offset the spawn slightly in front so the pod doesn't clip the airframe
    if (_heightAboveSurface < 2.5 && (_vehicle distance2D _basePadPos2D) < 10) then {
        _basePadPos2D = _vehicle modelToWorld [0, (sizeOf _vehType) * 0.65, 0];
    };

    {
        private _pod = createVehicle [_x, [0, 0, 500], [], 0, "CAN_COLLIDE"];
        private _rayStart = [_basePadPos2D # 0, _basePadPos2D # 1, (_vehPosASL # 2) + 50];
        private _rayEnd   = [_basePadPos2D # 0, _basePadPos2D # 1, -20];
        private _podHits  = lineIntersectsSurfaces [_rayStart, _rayEnd, _pod, _vehicle, true, 1, "GEOM", "NONE"];
        if (count _podHits > 0) then {
            _pod setPosASL ((_podHits # 0) # 0);
        } else {
            _pod setPosATL [_basePadPos2D # 0, _basePadPos2D # 1, 0];
        };
        _basePadPos2D = _pod modelToWorld [0, 4, 0];
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