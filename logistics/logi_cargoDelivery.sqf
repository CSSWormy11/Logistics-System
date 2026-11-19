// ============================================================================
// LOGISTICS SYSTEM: CARGO OFFLOAD & DELIVERY ENGINE (PART 1)
// File: logi_cargoDelivery.sqf
// Description: Scans the delivery pad for dropped logistics containers, 
//              calculates their point value, deletes the container, and 
//              credits the target base's global economy pool.
// Called By: Eden Editor "EmptyDetector" Trigger (On Activation) at Dropoff Pads
//            e.g., [thisTrigger, "SB"] execVM "logistics\logi_cargoDelivery.sqf";
// ============================================================================

params ["_triggerArea", "_baseKey"];
if (!isServer) exitWith {};

// Strip any trailing "_dropoff" (and optional index) if passed a raw trigger name like "FOB1_dropoff" or "SB_Carrier_dropoff_1"
private _dropoffIdx = (toLowerANSI _baseKey) find "_dropoff";
if (_dropoffIdx != -1) then {
    _baseKey = _baseKey select [0, _dropoffIdx];
};

if (_triggerArea getVariable ["isProcessingLogistics", false]) exitWith {};
_triggerArea setVariable ["isProcessingLogistics", true];

private _isMSR = "MSR" in (toUpper _baseKey);
private _hasGreetedDriver = false;
private _anyDeliveryRecorded = false;
private _cleanBase = _baseKey splitString "_" joinString " ";

while { _triggerArea getVariable ["isProcessingLogistics", false] } do {

    // --- PROXIMITY ARRIVAL GUIDANCE (IF A LOGISTICS TRUCK IS PRESENT) ---
    private _allTrucksInZone = vehicles select { _x inArea _triggerArea && (typeOf _x in allowedLogisticsVehicles) };
    private _activeTruck = if (count _allTrucksInZone > 0) then { _allTrucksInZone # 0 } else { objNull };

    if (!isNull _activeTruck && !_hasGreetedDriver && abs (speed _activeTruck) < 1) then {
        private _currentLoadedType = _activeTruck getVariable ["logistics_loaded_type", ""];
        if (_currentLoadedType != "" && _currentLoadedType != "Troops") then {
            private _templateIndex = allowedLogisticsVehicles find (typeOf _activeTruck);
            private _cargoList = [];
            if (_templateIndex != -1) then {
                private _entry = logisticsCargoTemplates # _templateIndex;
                private _allVehicleSupplies = if (count _entry > 2 && { (_entry # 2) isEqualType [] }) then { _entry # 2 } else { _entry # 1 };
                if (_allVehicleSupplies isEqualType []) then {
                    { if (_x # 0 == _currentLoadedType) exitWith { _cargoList = _x # 1; }; } forEach _allVehicleSupplies;
                    if (count _cargoList > 0 && { (_cargoList # 0) isEqualType [] }) then {
                        _cargoList = (_cargoList # 0) # 1;
                    };
                };
            };
            
            private _displayAssetName = "Supplies";
            if (count _cargoList > 0) then {
                _displayAssetName = getText (configFile >> "CfgVehicles" >> (_cargoList # 0) >> "displayName");
            };

            private _driver = driver _activeTruck;
            private _msg = format ["[LOGISTICS CAPTAIN]: Welcome to %1 terminal. Unload the [%2] here to register points.", _cleanBase, _displayAssetName];
            if (!isNull _driver && isPlayer _driver) then {
                [_msg] remoteExec ["systemChat", _driver];
            } else {
                systemChat _msg;
            };
            _hasGreetedDriver = true;
        };

        // --- TROOP CARGO AUTOMATIC DISEMBARKATION ---
        if (_currentLoadedType == "Troops" || { ({ alive _x && { _x getVariable ["QM_IsLogisticsPassenger", false] } } count (crew _activeTruck)) > 0 }) then {
            if (abs (speed _activeTruck) < 2) then {
                [_activeTruck, _baseKey] call QM_fnc_disembarkLogisticsTroops;
                _anyDeliveryRecorded = true;
                _hasGreetedDriver = true;
            };
        };
    };

    // --- IMMEDIATE CRATE & DELIVERED VEHICLE DETECTION, CREDITING & ANTI-COLLISION DELETION ---
    // Scans the tarmac every tick and instantly deletes/credits each unloaded crate or delivered vehicle,
    // completely eliminating Arma physics crate-on-crate collisions and vehicle pile-ups at dropoff pads.
    private _triggerPos = getPos _triggerArea;
    private _tArea = triggerArea _triggerArea;
    private _triggerScale = (((_tArea # 0) max (_tArea # 1)) max 15) + 5; 
    private _nearbyObjects = nearestObjects [_triggerPos, ["Strategic", "ReammoBox_F", "Cargo_base_F", "AllVehicles", "ThingX", "Air"], _triggerScale];

    // Proactively tag any active slingload on an aircraft/carrier in or above the dropoff zone
    {
        private _sling = getSlingLoad _x;
        if (!isNull _sling) then {
            _sling setVariable ["QM_WasSlingLoaded", true, true];
            _sling setVariable ["QM_SlingCarrier", _x, true];
            _sling setVariable ["QM_DrivenByPlayer", false, true];
        };
    } forEach (vehicles select { _x inArea _triggerArea && (_x isKindOf "Air" || _x isKindOf "LandVehicle") });

    private _activeCratesFound = 0;

    {
        private _object = _x;
        private _type = typeOf _object;
        private _isWithinUnloadZone = (_object inArea _triggerArea) || { (_object distance2D _triggerPos) <= 15 };
        
        // STRICT SAFETY CHECK 1: Drivable vehicles vs freight crates
        private _isDrivableVehicle = (_object isKindOf "LandVehicle" || _object isKindOf "Air" || _object isKindOf "Ship");

        // STRICT SAFETY CHECK 2: Never delete base infrastructure, Arsenals, Terminals, or player assets
        private _objName = vehicleVarName _object;
        private _objNameUpper = toUpperANSI _objName;
        private _isBaseInfrastructure = (
            (_object getVariable ["QM_Crate_OwningBase", ""]) != "" ||
            { _object getVariable ["QM_TerminalUnifiedActionsActive", false] } ||
            { _object in (missionNamespace getVariable ["QM_Global_Terminals", []]) } ||
            { !isNull (_object getVariable ["bis_fnc_arsenal_action", objNull]) } ||
            { "ARSENAL" in _objNameUpper || "TERMINAL" in _objNameUpper || "SERVICE" in _objNameUpper || "_AMMO" in _objNameUpper || "_FUEL" in _objNameUpper || "_REPAIR" in _objNameUpper || "_SPAWN" in _objNameUpper || "_GARAGE" in _objNameUpper }
        );

        if (!_isDrivableVehicle && _isWithinUnloadZone && isNull (attachedTo _object) && !(_type isKindOf "Man") && !_isBaseInfrastructure) then {
            private _lowerSearchType = toLowerANSI _type;
            private _scoreIndex = supplyScores findIf { toLowerANSI (_x # 0) == _lowerSearchType };

            if (!_isMSR) then {
                // Only credit and delete valid supply score items
                if (_scoreIndex != -1) then {
                    _activeCratesFound = _activeCratesFound + 1;
                    {
                        private _poolName = if (toUpper (_x # 0) in ["VEHICLE", "VEHICLES"]) then { "Vehicle" } else { _x # 0 };
                        private _targetVar = format ["LogiScore_%1_%2", _baseKey, _poolName];
                        private _curVal = missionNamespace getVariable [_targetVar, 0];
                        if (_curVal != -1) then {
                            missionNamespace setVariable [_targetVar, _curVal + (_x # 1), true];
                        };
                    } forEach ((supplyScores # _scoreIndex) # 1);
                    _anyDeliveryRecorded = true;
                    deleteVehicle _object;
                };
            } else {
                // At MSR, only delete if verified cargo item
                if (_scoreIndex != -1 || (_object getVariable ["isLogisticsCargo", false])) then {
                    _activeCratesFound = _activeCratesFound + 1;
                    _anyDeliveryRecorded = true;
                    deleteVehicle _object;
                };
            };
        };

        // --- AUTOMATIC DELIVERED VEHICLE PROCESSING (SLINGLOAD, VIV, OR LOGISTICS DELIVERY) ---
        // Despawns delivered vehicles and credits base points automatically without requiring pilot disembark
        if (_isDrivableVehicle && _isWithinUnloadZone && !_isBaseInfrastructure) then {
            private _hasPlayerCrew = ({ isPlayer _x } count (crew _object)) > 0;
            private _isSlingAttached = !isNull (ropeAttachedTo _object) || { ({ getSlingLoad _x == _object } count vehicles) > 0 };
            private _isAttachedCargo = !isNull (attachedTo _object);
            private _isPlayerOperating = (vehicle player == _object);
            private _declinedSalvage = _object getVariable ["QM_PlayerDeclinedSalvage", false];
            private _recentlySpawned = (diag_tickTime - (_object getVariable ["QM_Spawn_Time", 0])) < 10;
            private _speedSafe = abs (speed _object) < 3;
            private _heightSafe = (getPosATL _object # 2) < 2.5;

            private _isDeliveredVehicle = (
                !_hasPlayerCrew &&
                !_isSlingAttached &&
                !_isAttachedCargo &&
                !_isPlayerOperating &&
                !_declinedSalvage &&
                !_recentlySpawned &&
                _speedSafe &&
                _heightSafe &&
                (
                    (_object getVariable ["QM_WasSlingLoaded", false]) ||
                    (_object getVariable ["QM_DroppedFromSling", false]) ||
                    (_object getVariable ["QM_UnloadedFromViV", false]) ||
                    (_object getVariable ["isLogisticsCargo", false]) ||
                    (_object getVariable ["QM_SystemLoaded", false]) ||
                    (!(_object getVariable ["QM_DrivenByPlayer", false]))
                )
            );

            if (_isDeliveredVehicle) then {
                _activeCratesFound = _activeCratesFound + 1;
                _anyDeliveryRecorded = true;

                private _carrier = _object getVariable ["QM_SlingCarrier", _object getVariable ["QM_CarrierVehicle", objNull]];
                private _pilotUnit = if (!isNull _carrier) then { driver _carrier } else { objNull };

                [_baseKey, _object, _pilotUnit] call QM_fnc_serverVehicleSale;
            };
        };
    } forEach _nearbyObjects;

    // --- CHECK UNLOAD / COMPLETION STATUS ---
    // If a transport truck was unloading, check if it has completely finished
    if (!isNull _activeTruck) then {
        private _allInternalCargo = getVehicleCargo _activeTruck;
        private _hasSlingLoadAttached = !isNull (getSlingLoad _activeTruck);

        if (count _allInternalCargo == 0 && !_hasSlingLoadAttached && _anyDeliveryRecorded) then {
            private _driver = driver _activeTruck;
            private _receiptMsg = format ["LOGISTICS RECEIPT: Cargo safely verified on tarmac. Caches increased at %1.", _cleanBase];
            if (!isNull _driver && isPlayer _driver) then {
                [_receiptMsg] remoteExec ["systemChat", _driver];
            } else {
                systemChat _receiptMsg;
            };
            
            _activeTruck setVariable ["logistics_is_loaded", false, true];
            _activeTruck setVariable ["logistics_loaded_type", "", true];
            _activeTruck setVariable ["logistics_loaded_weight", 0, true];
            _activeTruck setVariable ["logistics_intended_fob", "", true];
        };
    } else {
        // Ad-hoc dropoff (foot delivery, slingload drop & depart, recovered salvage crate)
        if (_anyDeliveryRecorded && _activeCratesFound == 0) then {
            private _receiptMsg = format ["LOGISTICS RECEIPT: Supplies processed into base stores. Caches increased at %1.", _cleanBase];
            [_receiptMsg] remoteExec ["systemChat", 0];
            _anyDeliveryRecorded = false;
        };
    };

    // If no cargo remains on the tarmac and no truck with cargo or troops is in the zone, exit the loop
    private _truckStillHasCargo = !isNull _activeTruck && { 
        count (getVehicleCargo _activeTruck) > 0 || 
        !isNull (getSlingLoad _activeTruck) ||
        (_activeTruck getVariable ["logistics_loaded_type", ""] == "Troops") ||
        ({ alive _x && { _x getVariable ["QM_IsLogisticsPassenger", false] } } count (crew _activeTruck) > 0)
    };
    if (_activeCratesFound == 0 && !_truckStillHasCargo) exitWith {
        _triggerArea setVariable ["isProcessingLogistics", false];
    };

    sleep 0.5;
};

_triggerArea setVariable ["isProcessingLogistics", false];