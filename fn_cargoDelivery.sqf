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

if (_triggerArea getVariable ["isProcessingLogistics", false]) exitWith {};
_triggerArea setVariable ["isProcessingLogistics", true];

private _isMSR = "MSR" in _baseKey;
private _hasGreetedDriver = false;

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
    if (!_hasGreetedDriver && speed _activeTruck == 0) then {
        private _templateIndex = allowedLogisticsVehicles find (typeOf _activeTruck);
        private _allVehicleSupplies = (logisticsCargoTemplates # _templateIndex) # 1;
        private _cargoList = [];
        { if (_x # 0 == _currentLoadedType) exitWith { _cargoList = _x # 1; }; } forEach _allVehicleSupplies;
        
        private _displayAssetName = "Supplies";
        if (count _cargoList > 0) then {
            _displayAssetName = getText (configFile >> "CfgVehicles" >> (_cargoList # 0) >> "displayName");
        };

        private _cleanBase = _baseKey splitString "_" joinString " ";
        systemChat format ["[LOGISTICS CAPTAIN]: Welcome to %1 terminal. Unload the [%2] here to register points.", _cleanBase, _displayAssetName];
        _hasGreetedDriver = true;
    };

    private _deliveryRecorded = false;
    private _allInternalCargo = getVehicleCargo _activeTruck;
    private _hasSlingLoadAttached = !isNull (getSlingLoad _activeTruck);

    if (count _allInternalCargo > 0 || _hasSlingLoadAttached) then {
        sleep 1;
    } else {
        private _triggerPos = getPos _triggerArea;
        private _triggerScale = ((triggerArea _triggerArea) # 0) + 8; 
        private _nearbyObjects = nearestObjects [_triggerPos, ["Strategic", "ReammoBox_F", "Cargo_base_F", "AllVehicles", "ThingX", "Air"], _triggerScale];

        {
            private _object = _x;
            private _type = typeOf _object;
            private _isWithinUnloadRadius = (_object distance2D _triggerPos) <= _triggerScale;
            private _isNotTheTransportTruck = !(_object in allowedLogisticsVehicles) && _object != _activeTruck;

            if (_isWithinUnloadRadius && isNull (attachedTo _object) && _isNotTheTransportTruck && !(_type isKindOf "Man")) then {
                if (!_isMSR) then {
                    // FIXED CASE INSENSITIVITY: Forces matching check loop to bypass class letter case mismatches
                    private _lowerSearchType = toLowerANSI _type;
                    private _scoreIndex = supplyScores findIf { toLowerANSI (_x # 0) == _lowerSearchType };
                    
                    if (_scoreIndex != -1) then {
                        {
                            private _targetVar = format ["LogiScore_%1_%2", _baseKey, _x # 0];
                            missionNamespace setVariable [_targetVar, (missionNamespace getVariable [_targetVar, 0]) + (_x # 1), true];
                        } forEach ((supplyScores # _scoreIndex) # 1);
                        _deliveryRecorded = true;
                    };
                };
                deleteVehicle _object;
            };
        } forEach _nearbyObjects;
    };

    if (_deliveryRecorded) exitWith {
        systemChat format ["LOGISTICS RECEIPT: Cargo safely verified on tarmac. Caches increased at %1.", _baseKey splitString "_" joinString " "];
        
        _activeTruck setVariable ["logistics_is_loaded", false, true];
        _activeTruck setVariable ["logistics_loaded_type", "", true];
        _activeTruck setVariable ["logistics_loaded_weight", 0, true];
        _triggerArea setVariable ["isProcessingLogistics", false];
    };

    sleep 0.5;
};

_triggerArea setVariable ["isProcessingLogistics", false];