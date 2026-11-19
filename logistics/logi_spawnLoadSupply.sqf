// ============================================================================
// LOGISTICS SYSTEM: PHYSICAL DEPLOYMENT ENGINE (PART 1)
// File: logi_spawnLoadSupply.sqf
// Description: Spawns the requested cargo, calculates its mass via SupplyScores,
//              deducts points from the source base, and loads it into the transport.
//              Also handles specific spawn routing for troops, planes, and helis.
// Called By: Eden Editor Trigger (On Activation) at Loading Pads
//            e.g., [vehicle player, "MSR"] execVM "logistics\logi_spawnLoadSupply.sqf";
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
private _isMSR = "MSR" in (toUpper _pickupBaseKey);
private _targetVar = format ["LogiScore_%1_%2", _pickupBaseKey, _supplyType];
private _availablePoints = if (_isMSR) then { -1 } else { missionNamespace getVariable [_targetVar, 0] };

if (!_isMSR && _availablePoints != -1 && _availablePoints < _totalCargoPointWeight) exitWith {
    [west, "HQ"] sideChat format ["WARNING: Stores low on %1 at %2.", _supplyType, _pickupBaseKey];
};

if (!_isMSR && _availablePoints != -1) then {
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

// Resolve the destination dropoff trigger geometry (prioritizing 3D Trigger Area over 2D point marker)
private _destTrigList = missionNamespace getVariable [format ["LogiDropoffTriggers_%1", _targetDeliveryBase], []];
private _destTrigger = _destTrigList param [0, objNull];
private _deliveryPos = if (!isNull _destTrigger) then {
    getPos _destTrigger
} else {
    private _m = format ["Dropoff_%1", _targetDeliveryBase];
    if (getMarkerColor _m == "" && _targetDeliveryBase == "SB") then { _m = "Dropoff_SB"; };
    if (getMarkerColor _m != "") then { getMarkerPos _m } else { getMarkerPos _targetDeliveryBase }
};

// =========================================================================
// UNLOADED EXECUTION PROFILES
// =========================================================================
if (_supplyType == "Troops") exitWith {
    systemChat format ["LOGISTICS COMMAND: Manifest compiled. Boarding [%1] reinforcement squad...", _displayAssetName];
    
    private _grp = createGroup [playerSide, true];
    private _troopUnits = [];
    {
        private _unit = _grp createUnit [_x, [0,0,0], [], 0, "NONE"];
        _unit setVariable ["QM_IsLogisticsPassenger", true, true];
        _unit setVariable ["QM_PassengerDestination", _targetDeliveryBase, true];
        _unit moveInCargo _vehicle;
        _troopUnits pushBack _unit;
    } forEach _cargoList;

    // Track state on the vehicle
    _vehicle setVariable ["logistics_is_loaded", true, true];
    _vehicle setVariable ["logistics_loaded_type", "Troops", true];
    _vehicle setVariable ["logistics_loaded_weight", _totalCargoPointWeight, true];
    _vehicle setVariable ["QM_LogisticsTroopsGroup", _grp, true];
    _vehicle setVariable ["QM_LogisticsTroopsUnits", _troopUnits, true];

    // Give squad an initial movement waypoint to the destination dropoff zone trigger center
    private _wp = _grp addWaypoint [_deliveryPos, 0];
    _wp setWaypointType "MOVE";
    _wp setWaypointBehaviour "AWARE";
    _wp setWaypointCombatMode "YELLOW";
    _wp setWaypointSpeed "NORMAL";

    // Launch independent guardian thread: handles both vehicle dropoff disembarkation and foot arrival (if vehicle destroyed)
    [_grp, _vehicle, _destTrigger, _deliveryPos, _targetDeliveryBase] spawn {
        params ["_group", "_veh", "_destTrig", "_destCenterPos", "_destinationKey"];
        private _cleanBase = _destinationKey splitString "_" joinString " ";
        private _delivered = false;

        while { count (units _group) > 0 && !_delivered } do {
            sleep 1.5;
            private _aliveUnits = (units _group) select { alive _x };
            if (count _aliveUnits == 0) exitWith {};

            // Check 1: Vehicle arrived in dropoff zone and stopped
            if (!isNull _veh && { alive _veh } && { abs (speed _veh) < 2 }) then {
                private _isInZone = if (!isNull _destTrig) then {
                    private _tArea = triggerArea _destTrig;
                    _veh inArea [_destTrig, _tArea # 0, _tArea # 1, _tArea # 2, _tArea # 3]
                } else {
                    (_veh distance2D _destCenterPos) < 50
                };

                if (_isInZone) then {
                    _delivered = true;
                    // Move waypoint to the vehicle position and set to GETOUT
                    private _curWP = [_group, currentWaypoint _group];
                    _curWP setWaypointPosition [getPosATL _veh, 0];
                    _curWP setWaypointType "GETOUT";
                    
                    // Execute disembarkation
                    [_veh, _destinationKey] call QM_fnc_disembarkLogisticsTroops;
                };
            };

            // Check 2: Foot arrival (if transport vehicle was destroyed or abandoned)
            if (!_delivered) then {
                private _footUnitsInZone = _aliveUnits select {
                    isNull (objectParent _x) && {
                        if (!isNull _destTrig) then {
                            private _tArea = triggerArea _destTrig;
                            _x inArea [_destTrig, _tArea # 0, _tArea # 1, _tArea # 2, _tArea # 3]
                        } else {
                            (_x distance2D _destCenterPos) < 50
                        }
                    }
                };

                if (count _footUnitsInZone > 0) then {
                    private _fCount = count _footUnitsInZone;
                    [_destinationKey, _fCount, _footUnitsInZone] remoteExec ["QM_fnc_serverProcessTroopDelivery", 2];
                    systemChat format ["[LOGISTICS]: %1 reinforcement troops arrived on foot and garrisoned at %2.", _fCount, _cleanBase];
                };
            };
        };
        deleteGroup _group;
    };

    systemChat format ["[LOGISTICS]: %1 troops secured in passenger bay. Transport them to %2 Dropoff Zone.", count _troopUnits, _targetDeliveryBase splitString "_" joinString " "];
};

// --- STANDARD FREIGHT CARGO AND VEHICLE SLINGLOAD / VIV PACKING PROFILE ---
if (_isPlane && !_isHelicopter && _heightAboveSurface > 30) exitWith {
    systemChat format ["LOGISTICS COMMAND: Flight deck cargo internal pack: [%1].", _displayAssetName];
    { 
        private _cargoObj = _x createVehicle [0,0,0]; 
        _cargoObj setVariable ["isLogisticsCargo", true, true];
        _cargoObj setVariable ["QM_SystemLoaded", true, true];
        _cargoObj setVariable ["QM_CarrierVehicle", _vehicle, true];
        _cargoObj setVariable ["QM_DrivenByPlayer", false, true];
        _vehicle setVariable ["QM_SystemLoading", true];
        _vehicle setVehicleCargo _cargoObj; 
        _vehicle setVariable ["QM_SystemLoading", false];
    } forEach _cargoList;
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
        _pod setVariable ["isLogisticsCargo", true, true];
        _pod setVariable ["QM_SystemLoaded", true, true];
        _pod setVariable ["QM_WasSlingLoaded", true, true];
        _pod setVariable ["QM_SlingCarrier", _vehicle, true];
        _pod setVariable ["QM_DrivenByPlayer", false, true];
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
{
    private _cargoObj = _x createVehicle [0,0,0];
    _cargoObj setVariable ["isLogisticsCargo", true, true];
    _cargoObj setVariable ["QM_SystemLoaded", true, true];
    _cargoObj setVariable ["QM_CarrierVehicle", _vehicle, true];
    _cargoObj setVariable ["QM_DrivenByPlayer", false, true];
    _vehicle setVariable ["QM_SystemLoading", true];
    private _loadedViV = _vehicle setVehicleCargo _cargoObj;
    _vehicle setVariable ["QM_SystemLoading", false];
    if (!_loadedViV) then {
        deleteVehicle _cargoObj;
        diag_log format ["[LOGISTICS ERROR]: setVehicleCargo failed to load %1 into %2", _x, typeOf _vehicle];
    };
} forEach _cargoList;

// Auto-salvage/delivery hook for ViV cargo offloaded in Dropoff Zones
if (isNil { _vehicle getVariable "QM_ViVUnloadEH" }) then {
    private _eh = _vehicle addEventHandler ["VehicleCargoUnloaded", {
        params ["_carrier", "_cargo"];
        _cargo setVariable ["QM_UnloadedFromViV", true, true];
        _cargo setVariable ["QM_CarrierVehicle", _carrier, true];
        _cargo setVariable ["QM_DrivenByPlayer", false, true];

        private _bKey = [_cargo] call QM_fnc_getVehicleDropoffBase;
        if (_bKey == "") then { _bKey = [_carrier] call QM_fnc_getVehicleDropoffBase; };
        if (_bKey != "") then {
            [_cargo, _bKey, driver _carrier] spawn {
                params ["_cObj", "_base", "_drv"];
                sleep 0.5;
                if (alive _cObj) then {
                    [_base, _cObj, _drv] remoteExec ["QM_fnc_serverVehicleSale", 2];
                };
            };
        };
    }];
    _vehicle setVariable ["QM_ViVUnloadEH", _eh];
};

_vehicle setVariable ["logistics_is_loaded", true, true];
_vehicle setVariable ["logistics_loaded_type", _supplyType, true];
_vehicle setVariable ["logistics_loaded_weight", _totalCargoPointWeight, true];