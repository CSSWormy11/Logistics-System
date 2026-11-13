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
//    - Tier 1 (<= 120 lbs): Can be loaded anywhere by a single player.
//    - Tier 2 (121 - 250 lbs): Requires at least TWO players within 12m to load.
//    - Tier 3 (> 250 lbs, e.g. Cargo Nets, Ammo Boxes, Supply Crates, Containers):
//      Prohibited in the field! Must be loaded inside a designated Loading Zone.
//    - EXCEPTION: The HEMTT Flatbed is equipped with a heavy hydraulic crane/winch
//      and is the ONLY vehicle authorized to load Huron Containers anywhere.
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

// --- CORE VALIDATOR: EVALUATE VIV CARGO LOAD ATTEMPT ---
QM_fnc_validateVehicleCargoLoad = {
    params ["_vehicle", "_cargo"];
    if (isNull _vehicle || isNull _cargo) exitWith {};

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

    // --- CASE 2: FIELD LOADING (NON-LOADING ZONE) ---
    private _isFlatbed = (_vehicle isKindOf "B_Truck_01_flatbed_F" || _vehClass == "B_Truck_01_flatbed_F" || _vehClass == "B_T_Truck_01_flatbed_F");
    private _isHuronContainer = (_cargo isKindOf "Slingload_01_Base_F" || "B_Slingload_01_" in _cargoClass);

    // RULE A: HEMTT Flatbed Specialization - Authorized to load Huron Containers anywhere
    if (_isFlatbed && _isHuronContainer) exitWith {
        _vehicle setVariable ["logistics_is_loaded", true, true];
        private _cargoType = [_cargo] call QM_fnc_getCargoCategory;
        _vehicle setVariable ["logistics_loaded_type", _cargoType, true];
        private _msg = format ["[FLATBED WINCH]: %1 loaded via onboard hydraulic winch.", _cargoName];
        [_msg] remoteExec ["systemChat", 0];
    };

    // Calculate effective weight/mass
    private _mass = getMass _cargo;
    if (_mass <= 0) then {
        _mass = getNumber (configFile >> "CfgVehicles" >> _cargoClass >> "mass");
    };

    // RULE B: Heavy Cargo (> 250 lbs) or Huron Containers on non-flatbeds are PROHIBITED in the field
    if (_mass > 250 || _isHuronContainer) exitWith {
        [_vehicle, _cargo, _cargoName, _mass, _isHuronContainer] spawn {
            params ["_v", "_c", "_name", "_m", "_isHuron"];
            sleep 0.1;
            private _unloaded = objNull setVehicleCargo _c;
            if (!_unloaded) then {
                private _dropPos = _v modelToWorld [0, -12, 0];
                _dropPos set [2, 0];
                _c setPosATL _dropPos;
            };
            private _reason = if (_isHuron) then {
                "Huron containers in the field can only be loaded by a HEMTT Flatbed (or require a Base Loading Zone)"
            } else {
                format ["exceeds field handling capacity (%1 lbs > 250 lbs limit). Heavy cargo requires a designated Base Loading Zone", round _m]
            };
            private _msg = format ["[LOADING REJECTED]: %1 %2!", _name, _reason];
            [_msg] remoteExec ["systemChat", 0];
        };
    };

    // RULE C: Medium Cargo (121 - 250 lbs) requires at least TWO players nearby to team-lift
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

    // RULE D: Lightweight Cargo (<= 120 lbs) - Single player can load anywhere
    _vehicle setVariable ["logistics_is_loaded", true, true];
    private _cargoType = [_cargo] call QM_fnc_getCargoCategory;
    _vehicle setVariable ["logistics_loaded_type", _cargoType, true];
    private _msg = format ["[CARGO SECURED]: %1 loaded by personnel.", _cargoName];
    [_msg] remoteExec ["systemChat", 0];
};

// --- INITIALIZE VEHICLE CARGO RULES & WINCH ACTIONS ---
QM_fnc_initVehicleCargoRules = {
    params [["_veh", objNull]];
    if (isNull _veh || !alive _veh) exitWith {};
    if (_veh getVariable ["QM_CargoRulesActive", false]) exitWith {};
    _veh setVariable ["QM_CargoRulesActive", true];

    // Listen for Vehicle-in-Vehicle load events
    _veh addEventHandler ["VehicleCargoLoaded", {
        params ["_vehicle", "_cargo"];
        [_vehicle, _cargo] call QM_fnc_validateVehicleCargoLoad;
    }];

    // Dedicated Flatbed Winch Action for the HEMTT Flatbed
    private _vClass = typeOf _veh;
    if (_veh isKindOf "B_Truck_01_flatbed_F" || _vClass == "B_Truck_01_flatbed_F" || _vClass == "B_T_Truck_01_flatbed_F") then {
        _veh addAction [
            "<t color='#00FFFF' font='RobotoCondensedBold'>[FLATBED WINCH] Load Nearby Huron Container</t>",
            {
                params ["_target", "_caller", "_actionId", "_arguments"];
                // Scan within 15 meters for an unattached Huron container
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
            "alive _target && { count (getVehicleCargo _target) == 0 } && { count (nearestObjects [_target, ['B_Slingload_01_Cargo_F', 'B_Slingload_01_Ammo_F', 'B_Slingload_01_Fuel_F', 'B_Slingload_01_Repair_F', 'B_Slingload_01_Medevac_F', 'Slingload_01_Base_F'], 15] select { isNull (attachedTo _x) && isNull (isVehicleCargo _x) }) > 0 }",
            8
        ];
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

diag_log "[LOGISTICS FRAMEWORK]: Standalone Loading Mechanic initialized.";
