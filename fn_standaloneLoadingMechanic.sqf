// ============================================================================
// LOGISTICS SYSTEM: STANDALONE LOADING MECHANIC
// File: fn_standaloneLoadingMechanic.sqf
// Description: Regulates Vehicle-in-Vehicle (ViV) loading based on location,
//              cargo mass, crew complement, and vehicle specialization.
//
// Loading Rules:
// 1. Loading Zones (Base Pickup Pads):
//    - Any cargo a vehicle can physically fit can be loaded freely.
// 2. Non-Loading Zones (The Field):
//    - Vehicles with Onboard Crane (["ALL"], e.g. RHS M1084, KamAZ Crane):
//      Authorized to field-load ANY cargo they can physically carry.
//    - Vehicles with Container Winch (["Huron_Containers"], e.g. HEMTT Flatbed):
//      Authorized to field-load Huron Containers ONLY. Heavy cargo nets or ammo
//      boxes (> 250 lbs) cannot be field-loaded onto flatbeds.
//    - Standard Vehicles without cranes (HEMTT Cargo, Blackfish, Vans, LSVs):
//      * Tier 1 (<= 120 lbs): Can be loaded anywhere by a single player.
//      * Tier 2 (121 - 250 lbs): Requires at least TWO players within 12m to load.
//      * Tier 3 (> 250 lbs): Prohibited in the field! Must be loaded inside a
//        designated Base Loading Zone (or requires a vehicle with an onboard crane).
// ============================================================================

// --- HELPER 1: DETECT IF VEHICLE IS INSIDE A DESIGNATED LOADING ZONE ---
QM_fnc_isInsideLoadingZone = {
    params [["_vehicle", objNull]];
    if (isNull _vehicle) exitWith { false };

    private _allPickupTriggers = missionNamespace getVariable ["Logi_AllPickupTriggers", []];
    if (count _allPickupTriggers == 0) then {
        {
            private _trigs = missionNamespace getVariable [format ["LogiPickupTriggers_%1", _x], []];
            _allPickupTriggers append _trigs;
        } forEach (missionNamespace getVariable ["logisticsBases", []]);
        missionNamespace setVariable ["Logi_AllPickupTriggers", _allPickupTriggers];
    };

    ({ _vehicle inArea _x } count _allPickupTriggers > 0)
};

// --- HELPER 2: RESOLVE CARGO RESOURCE CATEGORY ---
QM_fnc_getCargoCategory = {
    params [["_cargo", objNull]];
    if (isNull _cargo) exitWith { "Cargo" };

    private _typeLower = toLowerANSI (typeOf _cargo);
    private _scores = missionNamespace getVariable ["supplyScores", []];
    private _idx = _scores findIf { toLowerANSI (_x # 0) == _typeLower };

    if (_idx != -1) then {
        (((_scores # _idx) # 1) # 0) # 0
    } else {
        "Cargo"
    };
};

// --- HELPER 3: RESOLVE VEHICLE FIELD-LOADING CAPABILITIES ---
QM_fnc_getFieldLoadingCapabilities = {
    params [["_vehicle", objNull]];
    if (isNull _vehicle) exitWith { [] };

    // 1. Direct object variable override (set via Eden or mission scripts)
    private _override = _vehicle getVariable ["QM_FieldLoadingCapacity", nil];
    if (!isNil "_override") exitWith { _override };

    // 2. Query registry template
    private _matrix = missionNamespace getVariable ["logisticsFieldLoadingTemplate", []];
    private _vehType = typeOf _vehicle;
    private _caps = [];

    // Exact type match
    private _idx = _matrix findIf { (_x # 0) == _vehType };
    if (_idx != -1) then {
        _caps = (_matrix # _idx) # 1;
    } else {
        // Inheritance match
        _idx = _matrix findIf { _vehicle isKindOf (_x # 0) };
        if (_idx != -1) then {
            _caps = (_matrix # _idx) # 1;
        } else {
            // Heuristic fallback for modded crane / flatbed trucks
            private _vehLower = toLowerANSI _vehType;
            if (_vehLower find "crane" != -1 || _vehLower find "m1084" != -1) then {
                _caps = ["ALL"];
            } else {
                if (_vehLower find "flatbed" != -1 || _vehicle isKindOf "B_Truck_01_flatbed_F") then {
                    _caps = ["Huron_Containers"];
                };
            };
        };
    };

    _caps
};

// --- CORE VALIDATOR: EVALUATE VIV CARGO LOAD ATTEMPT ---
QM_fnc_validateVehicleCargoLoad = {
    params ["_vehicle", "_cargo"];
    if (isNull _vehicle || isNull _cargo) exitWith {};

    // Authoritative Server Validation to eliminate MP race conditions and duplicate messages
    if (!isServer) exitWith {};

    private _inLoadingZone = [_vehicle] call QM_fnc_isInsideLoadingZone;
    private _vehClass = typeOf _vehicle;
    private _cargoClass = typeOf _cargo;
    private _cargoName = getText (configFile >> "CfgVehicles" >> _cargoClass >> "displayName");
    if (_cargoName == "") then { _cargoName = _cargoClass; };

    // --- CASE 1: INSIDE DESIGNATED BASE LOADING ZONE ---
    if (_inLoadingZone) exitWith {
        _vehicle setVariable ["logistics_is_loaded", true, true];
        private _cargoType = [_cargo] call QM_fnc_getCargoCategory;
        _vehicle setVariable ["logistics_loaded_type", _cargoType, true];
        private _msg = format ["[LOADING ZONE]: %1 secured into %2.", _cargoName, getText (configFile >> "CfgVehicles" >> _vehClass >> "displayName")];
        [_msg] remoteExec ["systemChat", 0];
    };

    // --- CASE 2: FIELD LOADING (AUSTERE NON-LOADING ZONE) ---
    private _caps = [_vehicle] call QM_fnc_getFieldLoadingCapabilities;
    private _hasCrane = ("ALL" in _caps);
    private _hasContainerWinch = ("Huron_Containers" in _caps || "Slingload_01_Base_F" in _caps);
    private _isHuronContainer = (_cargo isKindOf "Slingload_01_Base_F" || "B_Slingload_01_" in _cargoClass);

    // RULE A: Full Field Crane (RHS M1084, KamAZ Crane, etc.) - Authorized to load anything that fits
    if (_hasCrane) exitWith {
        _vehicle setVariable ["logistics_is_loaded", true, true];
        private _cargoType = [_cargo] call QM_fnc_getCargoCategory;
        _vehicle setVariable ["logistics_loaded_type", _cargoType, true];
        private _msg = format ["[FIELD CRANE]: %1 loaded via onboard hydraulic crane.", _cargoName];
        [_msg] remoteExec ["systemChat", 0];
    };

    // RULE B: Container Winch Specialization (HEMTT Flatbed) - Authorized for Huron containers only
    if (_hasContainerWinch && _isHuronContainer) exitWith {
        _vehicle setVariable ["logistics_is_loaded", true, true];
        private _cargoType = [_cargo] call QM_fnc_getCargoCategory;
        _vehicle setVariable ["logistics_loaded_type", _cargoType, true];
        private _msg = format ["[FLATBED WINCH]: %1 loaded via onboard container winch.", _cargoName];
        [_msg] remoteExec ["systemChat", 0];
    };

    // Calculate effective weight/mass
    private _mass = getMass _cargo;
    if (_mass <= 0) then {
        _mass = getNumber (configFile >> "CfgVehicles" >> _cargoClass >> "mass");
    };

    // RULE C: Heavy Cargo (> 250 lbs) or Huron Containers without appropriate handling gear
    if (_mass > 250 || _isHuronContainer) exitWith {
        [_vehicle, _cargo, _cargoName, _mass, _isHuronContainer, _hasContainerWinch] spawn {
            params ["_v", "_c", "_name", "_m", "_isHuron", "_hasWinch"];
            sleep 0.1;
            private _unloaded = objNull setVehicleCargo _c;
            if (!_unloaded) then {
                private _dropPos = _v modelToWorld [0, -12, 0];
                _dropPos set [2, 0];
                _c setPosATL _dropPos;
            };
            private _reason = if (_isHuron) then {
                "Huron containers in the field require a vehicle equipped with a container winch (e.g. HEMTT Flatbed) or a Base Loading Zone"
            } else {
                if (_hasWinch) then {
                    format ["exceeds field handling capacity (%1 lbs > 250 lbs limit). Flatbed container winch cannot load cargo nets/boxes in the field; requires a Base Loading Zone", round _m]
                } else {
                    format ["exceeds field handling capacity (%1 lbs > 250 lbs limit). Heavy cargo requires a designated Base Loading Zone (or an onboard crane)", round _m]
                }
            };
            private _msg = format ["[LOADING REJECTED]: %1 %2!", _name, _reason];
            [_msg] remoteExec ["systemChat", 0];
        };
    };

    // RULE D: Medium Cargo (121 - 250 lbs) requires at least TWO players nearby to team-lift
    if (_mass > 120 && _mass <= 250) exitWith {
        private _nearbyPlayers = allPlayers select { alive _x && { (_x distance _vehicle) <= 12 || (_x distance _cargo) <= 12 } };
        if (count _nearbyPlayers < 2) then {
            [_vehicle, _cargo, _cargoName, _mass] spawn {
                params ["_v", "_c", "_name", "_m"];
                sleep 0.1;
                private _unloaded = objNull setVehicleCargo _c;
                if (!_unloaded) then {
                    private _dropPos = _v modelToWorld [0, -8, 0];
                    _dropPos set [2, 0];
                    _c setPosATL _dropPos;
                };
                private _msg = format ["[TEAM LIFT REQUIRED]: %1 weighs %2 lbs. Loading this item in the field requires at least TWO players nearby!", _name, round _m];
                [_msg] remoteExec ["systemChat", 0];
            };
        } else {
            _vehicle setVariable ["logistics_is_loaded", true, true];
            private _cargoType = [_cargo] call QM_fnc_getCargoCategory;
            _vehicle setVariable ["logistics_loaded_type", _cargoType, true];
            private _msg = format ["[TEAM LIFT SUCCESS]: %1 loaded by 2-person crew.", _cargoName];
            [_msg] remoteExec ["systemChat", 0];
        };
    };

    // RULE E: Lightweight Cargo (<= 120 lbs) - Single player can load anywhere
    _vehicle setVariable ["logistics_is_loaded", true, true];
    private _cargoType = [_cargo] call QM_fnc_getCargoCategory;
    _vehicle setVariable ["logistics_loaded_type", _cargoType, true];
    private _msg = format ["[CARGO SECURED]: %1 loaded by personnel.", _cargoName];
    [_msg] remoteExec ["systemChat", 0];
};

// --- INITIALIZE VEHICLE CARGO RULES & WINCH/CRANE ACTIONS ---
QM_fnc_initVehicleCargoRules = {
    params [["_veh", objNull]];
    if (isNull _veh || !alive _veh) exitWith {};
    if (_veh getVariable ["QM_CargoRulesActive", false]) exitWith {};
    _veh setVariable ["QM_CargoRulesActive", true];

    // ViV Load & Unload Event Handlers (Executed authoritatively on server)
    if (isServer) then {
        _veh addEventHandler ["CargoLoaded", {
            params ["_parentVehicle", "_cargoVehicle"];
            [_parentVehicle, _cargoVehicle] call QM_fnc_validateVehicleCargoLoad;
        }];

        _veh addEventHandler ["CargoUnloaded", {
            params ["_parentVehicle", "_cargoVehicle"];
            private _remainingCargo = getVehicleCargo _parentVehicle;
            if (count _remainingCargo == 0) then {
                _parentVehicle setVariable ["logistics_is_loaded", false, true];
                _parentVehicle setVariable ["logistics_loaded_type", "", true];
            } else {
                private _topType = [_remainingCargo # 0] call QM_fnc_getCargoCategory;
                _parentVehicle setVariable ["logistics_loaded_type", _topType, true];
            };
        }];
    };

    // Client-side Interactive Actions (Flatbed Winch & Field Crane)
    if (hasInterface) then {
        private _caps = [_veh] call QM_fnc_getFieldLoadingCapabilities;
        private _hasCrane = ("ALL" in _caps);
        private _hasWinch = ("Huron_Containers" in _caps || "Slingload_01_Base_F" in _caps);

        // Dedicated Flatbed Winch Action
        if (_hasWinch) then {
            _veh addAction [
                "<t color='#00FFFF' font='RobotoCondensedBold'>[FLATBED WINCH] Load Nearby Huron Container</t>",
                {
                    params ["_target", "_caller", "_actionId", "_arguments"];
                    private _nearContainers = nearestObjects [_target, ["B_Slingload_01_Cargo_F", "B_Slingload_01_Ammo_F", "B_Slingload_01_Fuel_F", "B_Slingload_01_Repair_F", "B_Slingload_01_Medevac_F", "Slingload_01_Base_F"], 15];
                    _nearContainers = _nearContainers select { isNull (attachedTo _x) && isNull (isVehicleCargo _x) };

                    if (count _nearContainers == 0) exitWith {
                        hint "FLATBED WINCH: No unattached Huron container found within 15 meters!";
                    };

                    private _container = _nearContainers # 0;
                    private _loaded = _target setVehicleCargo _container;
                    if (_loaded) then {
                        _target setVariable ["logistics_is_loaded", true, true];
                        private _cType = [_container] call QM_fnc_getCargoCategory;
                        _target setVariable ["logistics_loaded_type", _cType, true];
                        systemChat format ["[FLATBED WINCH]: %1 loaded onto flatbed bed.", getText (configFile >> "CfgVehicles" >> typeOf _container >> "displayName")];
                    } else {
                        hint "FLATBED WINCH: Unable to load container (cargo bed may already be occupied or obstructed).";
                    };
                },
                [],
                2,
                false,
                true,
                "",
                "alive _target && { player distance _target < 10 } && { count (getVehicleCargo _target) == 0 } && { count (nearestObjects [_target, ['B_Slingload_01_Cargo_F', 'B_Slingload_01_Ammo_F', 'B_Slingload_01_Fuel_F', 'B_Slingload_01_Repair_F', 'B_Slingload_01_Medevac_F', 'Slingload_01_Base_F'], 15] select { isNull (attachedTo _x) && isNull (isVehicleCargo _x) }) > 0 }",
                8
            ];
        };

        // Dedicated Hydraulic Crane Hoist Action (for vehicles with onboard crane)
        if (_hasCrane) then {
            _veh addAction [
                "<t color='#FFA500' font='RobotoCondensedBold'>[FIELD CRANE] Hoist Nearby Cargo</t>",
                {
                    params ["_target", "_caller", "_actionId", "_arguments"];
                    private _nearObjects = nearestObjects [_target, ["ReammoBox_F", "ThingX", "LandVehicle", "Air", "Ship"], 15];
                    _nearObjects = _nearObjects select {
                        _x != _target &&
                        { isNull (attachedTo _x) } &&
                        { isNull (isVehicleCargo _x) } &&
                        { ((_target canVehicleCargo _x) select 0) }
                    };

                    if (count _nearObjects == 0) exitWith {
                        hint "FIELD CRANE: No unattached compatible cargo found within 15 meters!";
                    };

                    private _cargo = _nearObjects # 0;
                    private _cName = getText (configFile >> "CfgVehicles" >> typeOf _cargo >> "displayName");
                    if (_cName == "") then { _cName = typeOf _cargo; };

                    private _loaded = _target setVehicleCargo _cargo;
                    if (_loaded) then {
                        _target setVariable ["logistics_is_loaded", true, true];
                        private _cType = [_cargo] call QM_fnc_getCargoCategory;
                        _target setVariable ["logistics_loaded_type", _cType, true];
                        systemChat format ["[FIELD CRANE]: %1 hoisted into cargo bed via onboard crane.", _cName];
                    } else {
                        hint "FIELD CRANE: Unable to load cargo (cargo bed may be obstructed or at capacity).";
                    };
                },
                [],
                2,
                false,
                true,
                "",
                "alive _target && { player distance _target < 10 } && { count (nearestObjects [_target, ['ReammoBox_F', 'ThingX', 'LandVehicle', 'Air', 'Ship'], 15] select { _x != _target && isNull (attachedTo _x) && isNull (isVehicleCargo _x) && ((_target canVehicleCargo _x) select 0) }) > 0 }",
                8
            ];
        };
    };
};

// --- STARTUP DAEMON & DYNAMIC SPAWN HOOK ---
{
    if (_x isKindOf "LandVehicle" || _x isKindOf "Air" || _x isKindOf "Ship") then {
        [_x] call QM_fnc_initVehicleCargoRules;
    };
} forEach vehicles;

// Hook dynamically spawned vehicles (e.g. from Motorpool or mission scripts)
addMissionEventHandler ["EntityCreated", {
    params ["_entity"];
    if (!isNull _entity && { _entity isKindOf "LandVehicle" || _entity isKindOf "Air" || _entity isKindOf "Ship" }) then {
        [_entity] call QM_fnc_initVehicleCargoRules;
    };
}];

diag_log "[LOGISTICS FRAMEWORK]: Standalone Loading Mechanic initialized with Field-Loading Capability Registry.";
