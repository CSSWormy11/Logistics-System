// ============================================================================
// LOGISTICS SYSTEM: VEHICLE CARGO CAPACITIES (PART 1)
// File: logisticsCargoTemplates.sqf
// Description: Defines the specific cargo configurations, categories, and 
//              loadout classnames that each logistics vehicle can transport. 
//              Used by the cargo spawning engine to determine what physically 
//              spawns when a vehicle is loaded at a supply pad.
// Called By: init.sqf (Compiled during server/master initialization)
// ============================================================================

logisticsCargoTemplates = [
    // HEMTT Flatbed (Sand)
    [
        "B_Truck_01_flatbed_F",
        [
            ["Cargo", ["B_Slingload_01_Cargo_F"]],
            ["Ammo", ["B_Slingload_01_Ammo_F"]],
            ["Fuel", ["B_Slingload_01_Fuel_F"]],
            ["Medical", ["B_Slingload_01_Medevac_F"]],
            ["Repair", ["B_Slingload_01_Repair_F"]],
            ["Vehicle", ["B_MRAP_01_F"]]
        ]
    ],

    // HEMTT Flatbed (Jungle)
    [
        "B_T_Truck_01_flatbed_F",
        [
            ["Cargo", ["B_Slingload_01_Cargo_F"]],
            ["Ammo", ["B_Slingload_01_Ammo_F"]],
            ["Fuel", ["B_Slingload_01_Fuel_F"]],
            ["Medical", ["B_Slingload_01_Medevac_F"]],
            ["Repair", ["B_Slingload_01_Repair_F"]],
            ["Vehicle", ["B_T_MRAP_01_F"]]
        ]
    ],

    // HEMTT Cargo (Sand)
    [
        "B_Truck_01_cargo_F",
        [
            ["Cargo", ["B_CargoNet_01_ammo_F","B_CargoNet_01_ammo_F","B_CargoNet_01_ammo_F"]],
            ["Ammo", ["Box_NATO_AmmoVeh_F","Box_NATO_AmmoVeh_F","Box_NATO_AmmoVeh_F"]],
            ["Fuel", ["FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F"]],
            ["Medical", ["Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F"]],
            ["Mixed", ["B_CargoNet_01_ammo_F","Box_NATO_AmmoVeh_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F"]],
            ["Vehicle", ["B_LSV_01_AT_F"]]
        ]
    ],

    // HEMTT Cargo (Jungle)
    [
        "B_T_Truck_01_cargo_F",
        [
            ["Cargo", ["B_CargoNet_01_ammo_F","B_CargoNet_01_ammo_F","B_CargoNet_01_ammo_F"]],
            ["Ammo", ["Box_NATO_AmmoVeh_F","Box_NATO_AmmoVeh_F","Box_NATO_AmmoVeh_F"]],
            ["Fuel", ["FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F"]],
            ["Medical", ["Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F"]],
            ["Mixed", ["B_CargoNet_01_ammo_F","Box_NATO_AmmoVeh_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F", "Box_B_UAV_06_medical_F"]],
            ["Vehicle", ["B_T_LSV_01_AT_F"]]
        ]
    ],

    // HEMTT Transport (Sand)
    [
        "B_Truck_01_transport_F",
        [
            ["Troops", ["B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F"]]
        ]
    ],

    // HEMTT Transport (Jungle)
    [
        "B_T_Truck_01_transport_F",
        [
            ["Troops", ["B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F"]]
        ]
    ],

    // HEMTT Transport (Covered - Sand)
    [
        "B_Truck_01_covered_F",
        [
            ["Troops", ["B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F"]]
        ]
    ],

    // HEMTT Transport (Covered - Jungle)
    [
        "B_T_Truck_01_covered_F",
        [
            ["Troops", ["B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F"]]
        ]
    ],

    // Huron (Armed)
    [
        "B_Heli_Transport_03_F",
        [
            ["Cargo", ["B_Slingload_01_Cargo_F"]],
            ["Ammo", ["B_Slingload_01_Ammo_F"]],
            ["Fuel", ["B_Slingload_01_Fuel_F"]],
            ["Medical", ["B_Slingload_01_Medevac_F"]],
            ["Repair", ["B_Slingload_01_Repair_F"]],
            ["Troops", ["B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F"]],
            ["Vehicle", ["B_AFV_Wheeled_01_up_cannon_F"]]
        ]
    ],

    // Huron (Unarmed)
    [
        "B_Heli_Transport_03_unarmed_F",
        [
            ["Cargo", ["B_Slingload_01_Cargo_F"]],
            ["Ammo", ["B_Slingload_01_Ammo_F"]],
            ["Fuel", ["B_Slingload_01_Fuel_F"]],
            ["Medical", ["B_Slingload_01_Medevac_F"]],
            ["Repair", ["B_Slingload_01_Repair_F"]],
            ["Troops", ["B_HeavyGunner_F","B_HeavyGunner_F","B_HeavyGunner_F","B_HeavyGunner_F","B_HeavyGunner_F","B_HeavyGunner_F","B_HeavyGunner_F","B_HeavyGunner_F","B_HeavyGunner_F","B_HeavyGunner_F","B_HeavyGunner_F","B_HeavyGunner_F","B_HeavyGunner_F","B_HeavyGunner_F","B_HeavyGunner_F","B_HeavyGunner_F","B_HeavyGunner_F","B_HeavyGunner_F"]],
            ["Vehicle", ["B_AFV_Wheeled_01_up_cannon_F"]]
        ]
    ],

    // Prowler (Sand)
    [
        "B_LSV_01_unarmed_F",
        [
            ["Troops", ["B_HeavyGunner_F","B_HeavyGunner_F","B_HeavyGunner_F","B_HeavyGunner_F","B_HeavyGunner_F","B_HeavyGunner_F"]]
        ]
    ],

    // Prowler HMG (Sand)
    [
        "B_LSV_01_armed_F",
        [
            ["Troops", ["B_HeavyGunner_F","B_HeavyGunner_F","B_HeavyGunner_F","B_HeavyGunner_F"]]
        ]
    ],

    // Prowler AT (Sand)
    [
        "B_LSV_01_AT_F",
        [
            ["Troops", ["B_HeavyGunner_F","B_HeavyGunner_F","B_HeavyGunner_F","B_HeavyGunner_F"]]
        ]
    ],

    // Prowler (Jungle)
    [
        "B_T_LSV_01_unarmed_F",
        [
            ["Troops", ["B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F"]]
        ]
    ],

    // Prowler HMG (Jungle)
    [
        "B_T_LSV_01_armed_F",
        [
            ["Troops", ["B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F"]]
        ]
    ],

    // Prowler AT (Jungle)
    [
        "B_T_LSV_01_AT_F",
        [
            ["Troops", ["B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F"]]
        ]
    ],

    // Prowler (CTRG)
    [
        "B_T_LSV_01_unarmed_F",
        [
            ["Troops", ["B_CTRG_Soldier_TL_tna_F","B_CTRG_Soldier_tna_F","B_CTRG_Soldier_LAT2_tna_F","B_CTRG_Soldier_LAT_tna_F","B_CTRG_Soldier_AR_tna_F","B_CTRG_Soldier_Medic_tna_F"]]
        ]
    ],

    // Hunter (Sand)
    [
        "B_MRAP_01_F",
        [
            ["Troops", ["B_Soldier_F","B_Soldier_F","B_Soldier_F"]]
        ]
    ],

    // Hunter (Jungle)
    [
        "B_T_MRAP_01_F",
        [
            ["Troops", ["B_T_Soldier_F","B_T_Soldier_F","B_T_Soldier_F"]]
        ]
    ],

    // Pawnee
    [
        "B_Heli_Light_01_dynamicLoadout_F",
        [
            ["Cargo", ["B_supplyCrate_F"]],
            ["Fuel", ["FlexibleTank_01_sand_F"]],
            ["Medical", ["Box_B_UAV_06_medical_F"]],
            ["Vehicle", ["B_Quadbike_01_F"]]
        ]
    ],

    // Hummingbird
    [
        "B_Heli_Light_01_F",
        [
            ["Cargo", ["B_supplyCrate_F"]],
            ["Fuel", ["FlexibleTank_01_sand_F"]],
            ["Medical", ["Box_B_UAV_06_medical_F"]],
            ["Troops", ["B_HeavyGunner_F","B_HeavyGunner_F","B_HeavyGunner_F","B_HeavyGunner_F","B_HeavyGunner_F","B_HeavyGunner_F"]],
            ["Vehicle", ["B_Quadbike_01_F"]]
        ]
    ],

    // Ghost Hawk
    [
        "B_Heli_Transport_01_F",
        [
            ["Cargo", ["B_CargoNet_01_ammo_F"]],
            ["Fuel", ["FlexibleTank_01_sand_F"]],
            ["Medical", ["Box_B_UAV_06_medical_F"]],
            ["Troops", ["B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F"]],
            ["Vehicle", ["B_LSV_01_unarmed_F"]]
        ]
    ],

    // Ghost Hawk CTRG (Sand)
    [
        "B_CTRG_Heli_Transport_01_sand_F",
        [
            ["Cargo", ["B_CargoNet_01_ammo_F"]],
            ["Fuel", ["FlexibleTank_01_sand_F"]],
            ["Medical", ["Box_B_UAV_06_medical_F"]],
            ["Troops", ["B_recon_TL_F","B_Recon_Sharpshooter_F","B_recon_LAT_F","B_recon_F","B_recon_medic_F","B_recon_M_F","B_recon_JTAC_F","B_recon_exp_F"]],
            ["Vehicle", ["B_LSV_01_unarmed_F"]]
        ]
    ],

    // Ghost Hawk CTRG (Jungle)
    [
        "B_CTRG_Heli_Transport_01_tropic_F",
        [
            ["Cargo", ["B_CargoNet_01_ammo_F"]],
            ["Fuel", ["FlexibleTank_01_forest_F"]],
            ["Medical", ["Box_B_UAV_06_medical_F"]],
            ["Troops", ["B_CTRG_Soldier_TL_tna_F","B_CTRG_Soldier_tna_F","B_CTRG_Soldier_LAT2_tna_F","B_CTRG_Soldier_LAT_tna_F","B_CTRG_Soldier_AR_tna_F","B_CTRG_Soldier_Medic_tna_F","B_CTRG_Soldier_M_tna_F","B_CTRG_Soldier_JTAC_tna_F"]],
            ["Vehicle", ["B_CTRG_LSV_01_light_F"]]
        ]
    ],

    // Ghost Hawk (Stub Wings)
    [
        "B_Heli_Transport_01_pylons_F",
        [
            ["Cargo", ["B_CargoNet_01_ammo_F"]],
            ["Fuel", ["FlexibleTank_01_sand_F"]],
            ["Medical", ["Box_B_UAV_06_medical_F"]],
            ["Troops", ["B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F"]],
            ["Vehicle", ["B_LSV_01_unarmed_F"]]
        ]
    ],

    // Blackfish
    [
        "B_T_VTOL_01_vehicle_F",
        [
            ["Cargo", ["B_Slingload_01_Cargo_F","B_CargoNet_01_ammo_F","B_CargoNet_01_ammo_F"]],
            ["Ammo", ["B_Slingload_01_Ammo_F","Box_NATO_AmmoVeh_F","Box_NATO_AmmoVeh_F"]],
            ["Fuel", ["B_Slingload_01_Fuel_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F","FlexibleTank_01_sand_F"]],
            ["Medical", ["B_Slingload_01_Medevac_F"]],
            ["Repair", ["B_Slingload_01_Repair_F"]],
            ["Vehicle", ["B_AFV_Wheeled_01_up_cannon_F","B_Quadbike_01_F"]]
        ]
    ],

    // Blackfish
    [
        "B_T_VTOL_01_infantry_F",
        [
            ["Troops", ["B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F","B_Soldier_F"]]
        ]
    ],

    // Van (Cargo - FIA)
    [
        "B_G_Van_02_vehicle_F",
        [
            ["Cargo", ["IG_supplyCrate_F","IG_supplyCrate_F","IG_supplyCrate_F","IG_supplyCrate_F"]],
            ["Fuel", ["FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F"]],
            ["Medical", ["Box_B_UAV_06_medical_F"]],
            ["Vehicle", ["B_UGV_02_Demining_F","B_UGV_02_Demining_F","B_UGV_02_Demining_F","B_UGV_02_Demining_F","B_UGV_02_Demining_F","B_UGV_02_Demining_F","B_UGV_02_Demining_F"]]
        ]
    ],

    // Van (Cargo - Gendamerie)
    [
        "B_GEN_Van_02_vehicle_F",
        [
            ["Cargo", ["Box_GEN_Equip_F","Box_GEN_Equip_F","Box_GEN_Equip_F","Box_GEN_Equip_F"]],
            ["Fuel", ["FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F","FlexibleTank_01_forest_F"]],
            ["Medical", ["Box_B_UAV_06_medical_F"]],
            ["Vehicle", ["B_UGV_02_Demining_F","B_UGV_02_Demining_F","B_UGV_02_Demining_F","B_UGV_02_Demining_F","B_UGV_02_Demining_F","B_UGV_02_Demining_F","B_UGV_02_Demining_F"]]
        ]
    ],

    // Van (Transport - FIA)
    [
        "B_G_Van_02_transport_F",
        [
            ["Troops", ["B_G_Soldier_SL_F","B_G_Soldier_TL_F","B_G_Sharpshooter_F","B_G_Soldier_lite_F","B_G_Soldier_LAT2_F","B_G_Soldier_LAT_F","B_G_Soldier_F","B_G_Soldier_M_F","B_G_Soldier_GL_F","B_G_Soldier_AR_F","B_G_medic_F"]]
        ]
    ],

    // Truck (FIA)
    [
        "B_G_Van_01_transport_F",
        [
            ["Troops", ["B_G_Soldier_SL_F","B_G_Soldier_TL_F","B_G_Sharpshooter_F","B_G_Soldier_lite_F","B_G_Soldier_LAT2_F","B_G_Soldier_LAT_F","B_G_Soldier_F","B_G_Soldier_M_F","B_G_Soldier_GL_F","B_G_Soldier_AR_F","B_G_medic_F","B_G_Soldier_exp_F"]]
        ]
    ],

    // Offroad (FIA)
    [
        "B_G_Offroad_01_F",
        [
            ["Troops", ["B_G_Soldier_SL_F","B_G_Soldier_F","B_G_Soldier_LAT_F","B_G_Soldier_M_F","B_G_Soldier_TL_F"]]
        ]
    ],

    // Van (Transport - Gendamerie)
    [
        "B_GEN_Van_02_transport_F",
        [
            ["Troops", ["B_GEN_Commander_F","B_GEN_Soldier_F","B_GEN_Soldier_F","B_GEN_Soldier_F","B_GEN_Soldier_F","B_GEN_Soldier_F","B_GEN_Soldier_F","B_GEN_Soldier_F","B_GEN_Soldier_F","B_GEN_Soldier_F","B_GEN_Soldier_F"]]
        ]
    ],

    // Offroad (Open - Gendamerie)
    [
        "B_GEN_Offroad_01_gen_F",
        [
            ["Troops", ["B_GEN_Commander_F","B_GEN_Soldier_F","B_GEN_Soldier_F","B_GEN_Soldier_F","B_GEN_Soldier_F"]]
        ]
    ],

    // Offroad (Comms - Gendamerie)
    [
        "B_GEN_Offroad_01_comms_F",
        [
            ["Troops", ["B_GEN_Commander_F","B_GEN_Soldier_F","B_GEN_Soldier_F","B_GEN_Soldier_F","B_GEN_Soldier_F"]]
        ]
    ],

    // Offroad (Covered - Gendamerie)
    [
        "B_GEN_Offroad_01_covered_F",
        [
            ["Troops", ["B_GEN_Commander_F","B_GEN_Soldier_F","B_GEN_Soldier_F","B_GEN_Soldier_F","B_GEN_Soldier_F"]]
        ]
    ]
];