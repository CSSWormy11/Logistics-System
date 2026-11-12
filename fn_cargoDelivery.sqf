// ============================================================================
// LOGISTICS SYSTEM: CARGO OFFLOAD & DELIVERY ENGINE (PART 1)
// File: fn_cargoDelivery.sqf
// Description: Scans the delivery pad for dropped logistics containers, 
//              calculates their point value, deletes the container, and 
//              credits the target base's global economy pool.
// Called By: Eden Editor "EmptyDetector" Trigger (On Activation) at Dropoff Pads
//            e.g., [thisTrigger, "SB"] execVM "fn_cargoDelivery.sqf";
// ============================================================================

params ["_triggerArea", "_baseKey"];

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

while { _triggerArea getVariable ["isProcessingLogistics", false] } do {

    private _allTrucksInZone = vehicles select {_x inArea _triggerArea && (typeOf _x in allowedLogisticsVehicles)};
    if (count _allTrucksInZone == 0) exitWith {
        _triggerArea setVariable ["isProcessingLogistics", false];
    };

    private _activeTruck = _allTrucksInZone # 0;
    private _currentLoadedType = _activeTruck getVariable ["logistics_loaded_type", ""];
    
    if (_currentLoadedType == "" || _currentLoadedType == "Troops") exitWith {
        _triggerArea setVariable ["isProcessingLogistics", false];
    };

    // --- PROXIMITY ARRIVAL GUIDANCE ---
    if (!_hasGreetedDriver && abs (speed _activeTruck) < 1) then {
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

        private _cleanBase = _baseKey splitString "_" joinString " ";
        private _driver = driver _activeTruck;
        private _msg = format ["[LOGISTICS CAPTAIN]: Welcome to %1 terminal. Unload the [%2] here to register points.", _cleanBase, _displayAssetName];
        if (!isNull _driver && isPlayer _driver) then {
            [_msg] remoteExec ["systemChat", _driver];
        } else {
            systemChat _msg;
        };
        _hasGreetedDriver = true;
    };

    // --- IMMEDIATE CRATE DETECTION & DELETION ---
    // Scans the tarmac every tick and instantly deletes/credits each unloaded crate,
    // completely eliminating Arma physics crate-on-crate collisions.
    private _triggerPos = getPos _triggerArea;
    private _tArea = triggerArea _triggerArea;
    private _triggerScale = (((_tArea # 0) max (_tArea # 1)) max 15) + 5; 
    private _nearbyObjects = nearestObjects [_triggerPos, ["Strategic", "ReammoBox_F", "Cargo_base_F", "AllVehicles", "ThingX", "Air"], _triggerScale];

    {
        private _object = _x;
        private _type = typeOf _object;
        private _isWithinUnloadZone = (_object inArea _triggerArea) || { (_object distance2D _triggerPos) <= 15 };
        private _isNotTheTransportTruck = !(_object in allowedLogisticsVehicles) && _object != _activeTruck;

        // Strict safety check: Never delete or consume base infrastructure, Arsenals, Terminals, or player assets
        private _objName = vehicleVarName _object;
        private _objNameUpper = toUpperANSI _objName;
        private _isBaseInfrastructure = (
            (_object getVariable ["QM_Crate_OwningBase", ""]) != "" ||
            { _object getVariable ["QM_TerminalUnifiedActionsActive", false] } ||
            { _object in (missionNamespace getVariable ["QM_Global_Terminals", []]) } ||
            { !isNull (_object getVariable ["bis_fnc_arsenal_action", objNull]) } ||
            { "ARSENAL" in _objNameUpper || "TERMINAL" in _objNameUpper || "SERVICE" in _objNameUpper || "_AMMO" in _objNameUpper || "_FUEL" in _objNameUpper || "_REPAIR" in _objNameUpper || "_SPAWN" in _objNameUpper || "_GARAGE" in _objNameUpper }
        );

        if (_isWithinUnloadZone && isNull (attachedTo _object) && _isNotTheTransportTruck && !(_type isKindOf "Man") && !_isBaseInfrastructure) then {
            private _lowerSearchType = toLowerANSI _type;
            private _scoreIndex = supplyScores findIf { toLowerANSI (_x # 0) == _lowerSearchType };

            if (!_isMSR) then {
                // Only credit and delete valid supply score items
                if (_scoreIndex != -1) then {
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
                    _anyDeliveryRecorded = true;
                    deleteVehicle _object;
                };
            };
        };
    } forEach _nearbyObjects;

    // Check if the transport truck has fully finished unloading all cargo
    private _allInternalCargo = getVehicleCargo _activeTruck;
    private _hasSlingLoadAttached = !isNull (getSlingLoad _activeTruck);

    if (count _allInternalCargo == 0 && !_hasSlingLoadAttached && _anyDeliveryRecorded) exitWith {
        private _driver = driver _activeTruck;
        private _receiptMsg = format ["LOGISTICS RECEIPT: Cargo safely verified on tarmac. Caches increased at %1.", _baseKey splitString "_" joinString " "];
        if (!isNull _driver && isPlayer _driver) then {
            [_receiptMsg] remoteExec ["systemChat", _driver];
        } else {
            systemChat _receiptMsg;
        };
        
        _activeTruck setVariable ["logistics_is_loaded", false, true];
        _activeTruck setVariable ["logistics_loaded_type", "", true];
        _activeTruck setVariable ["logistics_loaded_weight", 0, true];
        _triggerArea setVariable ["isProcessingLogistics", false];
    };

    sleep 0.5;
};

_triggerArea setVariable ["isProcessingLogistics", false];