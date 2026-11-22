// ============================================================================
// LOGISTICS SYSTEM: VEHICLE CONFIGURATION MANIFEST
// File: spawnableVehicleTemplate.sqf
// Description: Single source of truth for all spawnable vehicles, statics,
//              drones, and logistics containers.
//              Used by Quartermaster motorpool and World AI spawner systems.
// ============================================================================
// TEMPLATE INDEX MAP
// ============================================================================
//
// [0] Display Name
// [1] Classname Array
// [2] Resource Cost Array (Includes Crew 'Troop' costs for AI Spawner)
// [3] Base Restriction
// [4] Side / Faction
// [5] Terrain Compatibility Array
// [6] Allowed Systems Array
// [7] Size Category (XS, S, M, L, XL, OPEN)
//
// ============================================================================

G_Procureable_Vehicles = [

    // ========================================================================
    // FACTION: BLUFOR (WEST / NATO)
    // ========================================================================

    // ------------------------------------------------------------------------
    // LIGHT & RECON VEHICLES
    // ------------------------------------------------------------------------
    ["Quad Bike", ["B_Quadbike_01_F"], [["Cargo", 600], ["Ammo", 0], ["Fuel", 10], ["Medical", 0], ["Repair", 0], ["Vehicle", 280], ["Troops", 1]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "S"],
    ["Prowler (Unarmed)", ["B_LSV_01_unarmed_F"], [["Cargo", 1800], ["Ammo", 0], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 3308], ["Troops", 1]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["Prowler (HMG)", ["B_LSV_01_armed_F"], [["Cargo", 1800], ["Ammo", 0], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 3413], ["Troops", 2]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["Prowler (AT)", ["B_LSV_01_AT_F"], [["Cargo", 1800], ["Ammo", 0], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 3413], ["Troops", 2]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["Prowler (Light)", ["B_CTRG_LSV_01_light_F"], [["Cargo", 1800], ["Ammo", 0], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 3413], ["Troops", 1]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["Hunter", ["B_MRAP_01_F"], [["Cargo", 2000], ["Ammo", 0], ["Fuel", 26], ["Medical", 0], ["Repair", 0], ["Vehicle", 8306], ["Troops", 1]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    
    ["Quad Bike (Tropic)", ["B_T_Quadbike_01_F"], [["Cargo", 600], ["Ammo", 0], ["Fuel", 10], ["Medical", 0], ["Repair", 0], ["Vehicle", 280], ["Troops", 1]], "ALL", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "S"],
    ["Prowler (Unarmed / Tropic)", ["B_T_LSV_01_unarmed_F"], [["Cargo", 1800], ["Ammo", 0], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 3413], ["Troops", 1]], "ALL", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["Prowler (HMG / Tropic)", ["B_T_LSV_01_armed_F"], [["Cargo", 1800], ["Ammo", 0], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 3413], ["Troops", 2]], "ALL", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["Prowler (AT / Tropic)", ["B_T_LSV_01_AT_F"], [["Cargo", 1800], ["Ammo", 0], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 3413], ["Troops", 2]], "ALL", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["Hunter (Tropic)", ["B_T_MRAP_01_F"], [["Cargo", 2000], ["Ammo", 0], ["Fuel", 26], ["Medical", 0], ["Repair", 0], ["Vehicle", 8306], ["Troops", 1]], "ALL", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],

    // ------------------------------------------------------------------------
    // LOGISTICS TRUCKS
    // ------------------------------------------------------------------------
    ["HEMTT Mover", ["B_Truck_01_mover_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 28], ["Medical", 0], ["Repair", 0], ["Vehicle", 10842], ["Troops", 1]], "SB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["HEMTT Transport", ["B_Truck_01_transport_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 28], ["Medical", 0], ["Repair", 0], ["Vehicle", 10942], ["Troops", 1]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["HEMTT Transport (Covered)", ["B_Truck_01_covered_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 28], ["Medical", 0], ["Repair", 0], ["Vehicle", 11026], ["Troops", 1]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["HEMTT Flatbed", ["B_Truck_01_flatbed_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 28], ["Medical", 0], ["Repair", 0], ["Vehicle", 11739], ["Troops", 1]], "SB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["HEMTT Cargo", ["B_Truck_01_cargo_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 28], ["Medical", 0], ["Repair", 0], ["Vehicle", 11786], ["Troops", 1]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["HEMTT Ammo", ["B_Truck_01_ammo_F"], [["Cargo", 3000], ["Ammo", 1000000], ["Fuel", 28], ["Medical", 0], ["Repair", 0], ["Vehicle", 12407], ["Troops", 1]], "SB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["HEMTT Box", ["B_Truck_01_box_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 28], ["Medical", 0], ["Repair", 0], ["Vehicle", 11692], ["Troops", 1]], "SB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["HEMTT Fuel", ["B_Truck_01_fuel_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 1000000], ["Medical", 0], ["Repair", 0], ["Vehicle", 13181], ["Troops", 1]], "SB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["HEMTT Medical", ["B_Truck_01_medical_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 28], ["Medical", 1], ["Repair", 0], ["Vehicle", 11026], ["Troops", 2]], "SB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["HEMTT Repair", ["B_Truck_01_Repair_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 28], ["Medical", 0], ["Repair", 1000000], ["Vehicle", 11692], ["Troops", 2]], "SB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],

    ["HEMTT Mover (Tropic)", ["B_T_Truck_01_mover_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 28], ["Medical", 0], ["Repair", 0], ["Vehicle", 10842], ["Troops", 1]], "SB", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["HEMTT Transport (Tropic)", ["B_T_Truck_01_transport_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 28], ["Medical", 0], ["Repair", 0], ["Vehicle", 10942], ["Troops", 1]], "ALL", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["HEMTT Transport (Covered / Tropic)", ["B_T_Truck_01_covered_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 28], ["Medical", 0], ["Repair", 0], ["Vehicle", 11026], ["Troops", 1]], "ALL", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["HEMTT Flatbed (Tropic)", ["B_T_Truck_01_flatbed_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 28], ["Medical", 0], ["Repair", 0], ["Vehicle", 11739], ["Troops", 1]], "SB", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["HEMTT Cargo (Tropic)", ["B_T_Truck_01_cargo_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 28], ["Medical", 0], ["Repair", 0], ["Vehicle", 11786], ["Troops", 1]], "ALL", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["HEMTT Ammo (Tropic)", ["B_T_Truck_01_ammo_F"], [["Cargo", 3000], ["Ammo", 1000000], ["Fuel", 28], ["Medical", 0], ["Repair", 0], ["Vehicle", 12407], ["Troops", 1]], "SB", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["HEMTT Box (Tropic)", ["B_T_Truck_01_box_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 28], ["Medical", 0], ["Repair", 0], ["Vehicle", 11692], ["Troops", 1]], "SB", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["HEMTT Fuel (Tropic)", ["B_T_Truck_01_fuel_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 1000000], ["Medical", 0], ["Repair", 0], ["Vehicle", 13181], ["Troops", 1]], "SB", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["HEMTT Medical (Tropic)", ["B_T_Truck_01_medical_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 28], ["Medical", 1], ["Repair", 0], ["Vehicle", 11026], ["Troops", 2]], "SB", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["HEMTT Repair (Tropic)", ["B_T_Truck_01_Repair_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 28], ["Medical", 0], ["Repair", 1000000], ["Vehicle", 11692], ["Troops", 2]], "SB", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],

    // ------------------------------------------------------------------------
    // ARMORED RECON & OVERWATCH
    // ------------------------------------------------------------------------
    ["Hunter HMG", ["B_MRAP_01_hmg_F"], [["Cargo", 2000], ["Ammo", 0], ["Fuel", 26], ["Medical", 0], ["Repair", 0], ["Vehicle", 8389], ["Troops", 2]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["Hunter GMG", ["B_MRAP_01_gmg_F"], [["Cargo", 2000], ["Ammo", 0], ["Fuel", 26], ["Medical", 0], ["Repair", 0], ["Vehicle", 8389], ["Troops", 2]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["AFV-4 Gorgon", ["B_APC_Wheeled_03_cannon_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 24], ["Medical", 0], ["Repair", 0], ["Vehicle", 21700], ["Troops", 3]], "SB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["AMV-7 Marshall", ["B_APC_Wheeled_01_cannon_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 24], ["Medical", 0], ["Repair", 0], ["Vehicle", 23299], ["Troops", 3]], "SB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["Rhino MGS", ["B_AFV_Wheeled_01_cannon_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 24], ["Medical", 0], ["Repair", 0], ["Vehicle", 23900], ["Troops", 3]], "SB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["Rhino MGS UP", ["B_AFV_Wheeled_01_up_cannon_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 24], ["Medical", 0], ["Repair", 0], ["Vehicle", 24200], ["Troops", 3]], "SB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],

    ["Hunter HMG (Tropic)", ["B_T_MRAP_01_hmg_F"], [["Cargo", 2000], ["Ammo", 0], ["Fuel", 26], ["Medical", 0], ["Repair", 0], ["Vehicle", 8389], ["Troops", 2]], "ALL", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["Hunter GMG (Tropic)", ["B_T_MRAP_01_gmg_F"], [["Cargo", 2000], ["Ammo", 0], ["Fuel", 26], ["Medical", 0], ["Repair", 0], ["Vehicle", 8389], ["Troops", 2]], "ALL", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["AMV-7 Marshall (Tropic)", ["B_T_APC_Wheeled_01_cannon_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 24], ["Medical", 0], ["Repair", 0], ["Vehicle", 23299], ["Troops", 3]], "SB", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["Rhino MGS (Tropic)", ["B_T_AFV_Wheeled_01_cannon_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 24], ["Medical", 0], ["Repair", 0], ["Vehicle", 23900], ["Troops", 3]], "SB", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["Rhino MGS UP (Tropic)", ["B_T_AFV_Wheeled_01_up_cannon_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 24], ["Medical", 0], ["Repair", 0], ["Vehicle", 24200], ["Troops", 3]], "SB", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],

    // ------------------------------------------------------------------------
    // HEAVY ARMOR & MECHANIZED
    // ------------------------------------------------------------------------
    ["IFV-6c Panther", ["B_APC_Tracked_01_rcws_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 18], ["Medical", 0], ["Repair", 0], ["Vehicle", 62385], ["Troops", 3]], "SB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["CRV-6e Bobcat", ["B_APC_Tracked_01_CRV_F"], [["Cargo", 3000], ["Ammo", 1000000], ["Fuel", 1000000], ["Medical", 0], ["Repair", 1000000], ["Vehicle", 65255], ["Troops", 3]], "SB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["IFV-6a Cheetah", ["B_APC_Tracked_01_AA_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 18], ["Medical", 0], ["Repair", 0], ["Vehicle", 63585], ["Troops", 3]], "SB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["M2A1 Slammer", ["B_MBT_01_cannon_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 65047], ["Troops", 3]], "SB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["M2A4 Slammer UP", ["B_MBT_01_TUSK_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 70000], ["Troops", 3]], "SB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["M4 Scorcher", ["B_MBT_01_arty_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 65348], ["Troops", 3]], "SB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["M5 Sandstorm MLRS", ["B_MBT_01_mlrs_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 67663], ["Troops", 3]], "SB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],

    ["IFV-6c Panther (Tropic)", ["B_T_APC_Tracked_01_rcws_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 18], ["Medical", 0], ["Repair", 0], ["Vehicle", 62385], ["Troops", 3]], "SB", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["CRV-6e Bobcat (Tropic)", ["B_T_APC_Tracked_01_CRV_F"], [["Cargo", 3000], ["Ammo", 1000000], ["Fuel", 1000000], ["Medical", 0], ["Repair", 1000000], ["Vehicle", 65255], ["Troops", 3]], "SB", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["IFV-6a Cheetah (Tropic)", ["B_T_APC_Tracked_01_AA_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 18], ["Medical", 0], ["Repair", 0], ["Vehicle", 63585], ["Troops", 3]], "SB", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["M2A1 Slammer (Tropic)", ["B_T_MBT_01_cannon_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 65047], ["Troops", 3]], "SB", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["M2A4 Slammer UP (Tropic)", ["B_T_MBT_01_TUSK_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 70000], ["Troops", 3]], "SB", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["M4 Scorcher (Tropic)", ["B_T_MBT_01_arty_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 65348], ["Troops", 3]], "SB", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["M5 Sandstorm MLRS (Tropic)", ["B_T_MBT_01_mlrs_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 67663], ["Troops", 3]], "SB", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],

    // ------------------------------------------------------------------------
    // UNMANNED SYSTEMS (UGV & UAV)
    // ------------------------------------------------------------------------
    ["ED-1D Pelter", ["B_UGV_02_Demining_F"], [["Cargo", 0], ["Ammo", 0], ["Fuel", 2], ["Medical", 0], ["Repair", 0], ["Vehicle", 255], ["Troops", 0]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "XS"],
    ["ED-1E Roller", ["B_UGV_02_Science_F"], [["Cargo", 0], ["Ammo", 0], ["Fuel", 2], ["Medical", 0], ["Repair", 0], ["Vehicle", 255], ["Troops", 0]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "XS"],
    ["UGV Stomper", ["B_UGV_01_F"], [["Cargo", 1000], ["Ammo", 0], ["Fuel", 14], ["Medical", 0], ["Repair", 0], ["Vehicle", 4266], ["Troops", 0]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["UGV Stomper RCWS", ["B_UGV_01_rcws_F"], [["Cargo", 1000], ["Ammo", 0], ["Fuel", 14], ["Medical", 0], ["Repair", 0], ["Vehicle", 4266], ["Troops", 0]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    
    ["UGV Stomper (Tropic)", ["B_T_UGV_01_olive_F"], [["Cargo", 1000], ["Ammo", 0], ["Fuel", 14], ["Medical", 0], ["Repair", 0], ["Vehicle", 4266], ["Troops", 0]], "ALL", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["UGV Stomper RCWS (Tropic)", ["B_T_UGV_01_rcws_olive_F"], [["Cargo", 1000], ["Ammo", 0], ["Fuel", 14], ["Medical", 0], ["Repair", 0], ["Vehicle", 4266], ["Troops", 0]], "ALL", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],

    ["AR-2 Darter", ["B_UAV_01_F"], [["Cargo", 999], ["Ammo", 0], ["Fuel", 100], ["Medical", 0], ["Repair", 0], ["Vehicle", 170], ["Troops", 0]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "XS"],
    ["AL-6 Pelican", ["B_UAV_06_F"], [["Cargo", 120], ["Ammo", 0], ["Fuel", 100], ["Medical", 0], ["Repair", 0], ["Vehicle", 251], ["Troops", 0]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "XS"],
    ["AL-6 Pelican (Medical)", ["B_UAV_06_medical_F"], [["Cargo", 120], ["Ammo", 0], ["Fuel", 100], ["Medical", 1], ["Repair", 0], ["Vehicle", 251], ["Troops", 0]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "XS"],
    ["MQ-4A Greyhawk", ["B_UAV_02_dynamicLoadout_F"], [["Cargo", 250], ["Ammo", 0], ["Fuel", 1000], ["Medical", 0], ["Repair", 0], ["Vehicle", 3000], ["Troops", 0]], "SB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "L"],
    ["UCAV Sentinel", ["B_UAV_05_F"], [["Cargo", 999], ["Ammo", 0], ["Fuel", 1000], ["Medical", 0], ["Repair", 0], ["Vehicle", 11450], ["Troops", 0]], "SB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "XL"],
    ["MQ-12 Falcon", ["B_T_UAV_03_dynamicLoadout_F"], [["Cargo", 999], ["Ammo", 0], ["Fuel", 100], ["Medical", 0], ["Repair", 0], ["Vehicle", 5154], ["Troops", 0]], "SB", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "OPEN"],

    // ------------------------------------------------------------------------
    // ROTARY WING / HELICOPTERS
    // ------------------------------------------------------------------------
    ["MH-9 Hummingbird", ["B_Heli_Light_01_F"], [["Cargo", 1000], ["Ammo", 0], ["Fuel", 242], ["Medical", 0], ["Repair", 0], ["Vehicle", 500], ["Troops", 2]], "SB", "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "OPEN"],
    ["AH-9 Pawnee", ["B_Heli_Light_01_dynamicLoadout_F"], [["Cargo", 1000], ["Ammo", 0], ["Fuel", 242], ["Medical", 0], ["Repair", 0], ["Vehicle", 500], ["Troops", 2]], "SB", "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "OPEN"],
    ["AH-99 Blackfoot", ["B_Heli_Attack_01_dynamicLoadout_F"], [["Cargo", 999], ["Ammo", 0], ["Fuel", 500], ["Medical", 0], ["Repair", 0], ["Vehicle", 10056], ["Troops", 2]], "SB", "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "OPEN"],
    ["AH-99 Blackfoot (Stub Wings)", ["B_Heli_Attack_01_pylons_dynamicLoadout_F"], [["Cargo", 999], ["Ammo", 0], ["Fuel", 500], ["Medical", 0], ["Repair", 0], ["Vehicle", 10056], ["Troops", 2]], "SB", "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "OPEN"],
    ["UH-80 Ghost Hawk", ["B_Heli_Transport_01_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 1360], ["Medical", 0], ["Repair", 0], ["Vehicle", 4000], ["Troops", 4]], "SB", "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "OPEN"],
    ["UH-80 Ghost Hawk (Stub Wings)", ["B_Heli_Transport_01_pylons_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 1360], ["Medical", 0], ["Repair", 0], ["Vehicle", 4000], ["Troops", 4]], "SB", "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "OPEN"],
    ["CH-67 Huron (Unarmed)", ["B_Heli_Transport_03_unarmed_F"], [["Cargo", 6000], ["Ammo", 0], ["Fuel", 1360], ["Medical", 0], ["Repair", 0], ["Vehicle", 12000], ["Troops", 4]], "SB", "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "OPEN"],
    ["CH-67 Huron", ["B_Heli_Transport_03_F"], [["Cargo", 6000], ["Ammo", 0], ["Fuel", 1360], ["Medical", 0], ["Repair", 0], ["Vehicle", 12000], ["Troops", 4]], "SB", "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "OPEN"],
    
    ["UH-80 Ghost Hawk (Sand)", ["B_CTRG_Heli_Transport_01_sand_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 1360], ["Medical", 0], ["Repair", 0], ["Vehicle", 4000], ["Troops", 4]], "SB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "OPEN"],
    ["UH-80 Ghost Hawk (Tropic)", ["B_CTRG_Heli_Transport_01_tropic_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 1360], ["Medical", 0], ["Repair", 0], ["Vehicle", 4000], ["Troops", 4]], "SB", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "OPEN"],

    // ------------------------------------------------------------------------
    // FIXED WING & VTOL
    // ------------------------------------------------------------------------
    ["V-44 X Blackfish (Infantry Transport)", ["B_T_VTOL_01_infantry_F"], [["Cargo", 12000], ["Ammo", 0], ["Fuel", 1000], ["Medical", 0], ["Repair", 0], ["Vehicle", 47709], ["Troops", 4]], "SB", "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "OPEN"],
    ["V-44 X Blackfish (Vehicle Transport)", ["B_T_VTOL_01_vehicle_F"], [["Cargo", 12000], ["Ammo", 0], ["Fuel", 1000], ["Medical", 0], ["Repair", 0], ["Vehicle", 47709], ["Troops", 4]], "SB", "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "OPEN"],
    ["V-44 X Blackfish (Armed)", ["B_T_VTOL_01_armed_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 1000], ["Medical", 0], ["Repair", 0], ["Vehicle", 47759], ["Troops", 4]], "SB", "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "OPEN"],
    ["A-164 Wipeout (CAS)", ["B_Plane_CAS_01_dynamicLoadout_F"], [["Cargo", 500], ["Ammo", 0], ["Fuel", 1000], ["Medical", 0], ["Repair", 0], ["Vehicle", 19500], ["Troops", 1]], "SB", "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "L"],
    ["F/A-181 Black Wasp II", ["B_Plane_Fighter_01_F"], [["Cargo", 500], ["Ammo", 0], ["Fuel", 1550], ["Medical", 0], ["Repair", 0], ["Vehicle", 11000], ["Troops", 1]], "SB", "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "L"],
    ["F/A-181 Black Wasp II (Stealth)", ["B_Plane_Fighter_01_Stealth_F"], [["Cargo", 500], ["Ammo", 0], ["Fuel", 1550], ["Medical", 0], ["Repair", 0], ["Vehicle", 11000], ["Troops", 1]], "SB", "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "L"],

    // ------------------------------------------------------------------------
    // NAVAL / BOATS
    // ------------------------------------------------------------------------
    ["Rescue Boat", ["B_Lifeboat"], [["Cargo", 500], ["Ammo", 0], ["Fuel", 12], ["Medical", 0], ["Repair", 0], ["Vehicle", 565], ["Troops", 1]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["Assault Boat", ["B_Boat_Transport_01_F"], [["Cargo", 500], ["Ammo", 0], ["Fuel", 12], ["Medical", 0], ["Repair", 0], ["Vehicle", 565], ["Troops", 1]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["Speedboat Minigun", ["B_Boat_Armed_01_minigun_F"], [["Cargo", 500], ["Ammo", 0], ["Fuel", 12], ["Medical", 0], ["Repair", 0], ["Vehicle", 9002], ["Troops", 3]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["SDV", ["B_SDV_01_F"], [["Cargo", 500], ["Ammo", 0], ["Fuel", 120], ["Medical", 0], ["Repair", 0], ["Vehicle", 2600], ["Troops", 2]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    
    ["Rescue Boat (Tropic)", ["B_T_Lifeboat"], [["Cargo", 500], ["Ammo", 0], ["Fuel", 12], ["Medical", 0], ["Repair", 0], ["Vehicle", 565], ["Troops", 1]], "ALL", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["Assault Boat (Tropic)", ["B_T_Boat_Transport_01_F"], [["Cargo", 500], ["Ammo", 0], ["Fuel", 12], ["Medical", 0], ["Repair", 0], ["Vehicle", 565], ["Troops", 1]], "ALL", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["Speedboat Minigun (Tropic)", ["B_T_Boat_Armed_01_minigun_F"], [["Cargo", 500], ["Ammo", 0], ["Fuel", 12], ["Medical", 0], ["Repair", 0], ["Vehicle", 9002], ["Troops", 3]], "ALL", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],

    // ------------------------------------------------------------------------
    // STATIC WEAPONS & OBJECTS
    // ------------------------------------------------------------------------
    ["Mk30 HMG .50", ["B_HMG_01_F"], [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 160], ["Troops", 1]], "FOB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["Mk30 HMG .50 (Raised)", ["B_HMG_01_high_F"], [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 172], ["Troops", 1]], "FOB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["Mk30A HMG .50", ["B_HMG_01_A_F"], [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 160], ["Troops", 1]], "FOB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["Mk32 GMG 20 mm", ["B_GMG_01_F"], [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 168], ["Troops", 1]], "FOB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["Mk32 GMG 20 mm (Raised)", ["B_GMG_01_high_F"], [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 161], ["Troops", 1]], "FOB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["Mk32A GMG 20 mm", ["B_GMG_01_A_F"], [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 168], ["Troops", 1]], "FOB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["Static Titan Launcher (AA) [NATO]", ["B_static_AA_F"], [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 127], ["Troops", 1]], "FOB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["Static Titan Launcher (AT) [NATO]", ["B_static_AT_F"], [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 127], ["Troops", 1]], "FOB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["Remote Designator [NATO]", ["B_Static_Designator_01_F"], [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 100], ["Troops", 0]], "FOB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["Mk6 Mortar", ["B_Mortar_01_F"], [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 50], ["Troops", 1]], "FOB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],

    ["Static Titan Launcher (AA) [NATO] (Tropic)", ["B_T_Static_AA_F"], [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 127], ["Troops", 1]], "FOB", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["Static Titan Launcher (AT) [NATO] (Tropic)", ["B_T_Static_AT_F"], [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 127], ["Troops", 1]], "FOB", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["Remote Designator [NATO] (Tropic)", ["B_W_Static_Designator_01_F"], [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 100], ["Troops", 0]], "FOB", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["Mk6 Mortar (Tropic)", ["B_T_Mortar_01_F"], [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 50], ["Troops", 1]], "FOB", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["Mk30 HMG .50 (Tropic)", ["B_T_HMG_01_F"], [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 160], ["Troops", 1]], "FOB", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["Mk32 GMG 20 mm (Tropic)", ["B_T_GMG_01_F"], [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 168], ["Troops", 1]], "FOB", "WEST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],

    // ------------------------------------------------------------------------
    // LOGISTICS SUPPLY CONTAINER OBJECTS
    // ------------------------------------------------------------------------
    ["Explosives [NATO]", ["Box_NATO_AmmoOrd_F"], [["Cargo", 2000], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 0], ["Troops", 0]], "SB", "WEST", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["Huron Ammo Container", ["B_Slingload_01_Ammo_F"], [["Cargo", 0], ["Ammo", 1000000], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 0], ["Troops", 0]], "SB", "WEST", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["Huron Fuel Container", ["B_Slingload_01_Fuel_F"], [["Cargo", 0], ["Ammo", 0], ["Fuel", 1000000], ["Medical", 0], ["Repair", 0], ["Vehicle", 0], ["Troops", 0]], "SB", "WEST", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["Huron Medical Container", ["B_Slingload_01_Medevac_F"], [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 1], ["Repair", 0], ["Vehicle", 0], ["Troops", 0]], "SB", "WEST", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["Huron Repair Container", ["B_Slingload_01_Repair_F"], [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 1000000], ["Vehicle", 0], ["Troops", 0]], "SB", "WEST", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["Huron Cargo Container", ["B_Slingload_01_Cargo_F"], [["Cargo", 1000000], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 0], ["Troops", 0]], "SB", "WEST", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    
    ["Flexible Fuel Tank (Sand)", ["FlexibleTank_01_sand_F"], [["Cargo", 0], ["Ammo", 0], ["Fuel", 300], ["Medical", 0], ["Repair", 0], ["Vehicle", 0], ["Troops", 0]], "SB", "WEST", ["Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["Flexible Fuel Tank (Forest)", ["FlexibleTank_01_forest_F"], [["Cargo", 0], ["Ammo", 0], ["Fuel", 300], ["Medical", 0], ["Repair", 0], ["Vehicle", 0], ["Troops", 0]], "SB", "WEST", ["Woodland", "Jungle", "Mediterranean"], ["Quartermaster", "WorldAI"], "M"],
    
    ["Vehicle Ammo [NATO]", ["Box_NATO_AmmoVeh_F"], [["Cargo", 0], ["Ammo", 30000], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 0], ["Troops", 0]], "SB", "WEST", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["Cargo Net [NATO]", ["B_CargoNet_01_ammo_F"], [["Cargo", 22000], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 0], ["Troops", 0]], "SB", "WEST", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["Supply Box [NATO]", ["B_supplyCrate_F"], [["Cargo", 4000], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 0], ["Troops", 0]], "SB", "WEST", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["Basic Ammo [NATO]", ["Box_NATO_Ammo_F"], [["Cargo", 1000], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 0], ["Troops", 0]], "SB", "WEST", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["Grenades [NATO]", ["Box_NATO_Grenades_F"], [["Cargo", 500], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 0], ["Troops", 0]], "SB", "WEST", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["Basic Weapons [NATO]", ["Box_NATO_Wps_F"], [["Cargo", 2000], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 0], ["Troops", 0]], "SB", "WEST", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["Launchers [NATO]", ["Box_NATO_WpsLaunch_F"], [["Cargo", 2000], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 0], ["Troops", 0]], "SB", "WEST", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["Special Weapons [NATO]", ["Box_NATO_WpsSpecial_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 0], ["Troops", 0]], "SB", "WEST", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["Equipment Box [NATO]", ["Box_NATO_Equip_F"], [["Cargo", 7000], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 0], ["Troops", 0]], "SB", "WEST", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["Uniforms Box [NATO]", ["Box_NATO_Uniforms_F"], [["Cargo", 7000], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 0], ["Troops", 0]], "SB", "WEST", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["Support [NATO]", ["Box_NATO_Support_F"], [["Cargo", 1500], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 0], ["Troops", 0]], "SB", "WEST", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],


    // ========================================================================
    // FACTION: OPFOR (EAST / CSAT)
    // ========================================================================

    // ------------------------------------------------------------------------
    // ANTI-AIR (VEHICLES & AIRCRAFT)
    // ------------------------------------------------------------------------
    ["ZSU-39 Tigris", ["O_APC_Tracked_02_AA_F"], [["Cargo", 3000], ["Ammo", 500], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 63000], ["Troops", 3]], "SB", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["To-201 Shikra", ["O_Plane_Fighter_02_F"], [["Cargo", 500], ["Ammo", 600], ["Fuel", 1500], ["Medical", 0], ["Repair", 0], ["Vehicle", 20000], ["Troops", 1]], "SB", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "L"],
    ["To-201 Shikra (Stealth)", ["O_Plane_Fighter_02_Stealth_F"], [["Cargo", 500], ["Ammo", 600], ["Fuel", 1500], ["Medical", 0], ["Repair", 0], ["Vehicle", 22000], ["Troops", 1]], "SB", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "L"],

    // ------------------------------------------------------------------------
    // ANTI-TANK & HEAVY ARMOR
    // ------------------------------------------------------------------------
    ["Qilin (AT)", ["O_LSV_02_AT_F"], [["Cargo", 1800], ["Ammo", 200], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 3500], ["Troops", 2]], "FOB", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["BTR-K Kamysh", ["O_APC_Tracked_02_cannon_F"], [["Cargo", 3000], ["Ammo", 350], ["Fuel", 18], ["Medical", 0], ["Repair", 0], ["Vehicle", 55000], ["Troops", 3]], "SB", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["T-100 Varsuk", ["O_MBT_02_cannon_F"], [["Cargo", 3000], ["Ammo", 500], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 65000], ["Troops", 3]], "SB", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["T-100X Futura", ["O_MBT_02_railgun_F"], [["Cargo", 3000], ["Ammo", 600], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 70000], ["Troops", 3]], "SB", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["T-140 Angara", ["O_MBT_04_cannon_F"], [["Cargo", 3000], ["Ammo", 550], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 75000], ["Troops", 3]], "SB", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["T-140K Angara (Command)", ["O_MBT_04_command_F"], [["Cargo", 3000], ["Ammo", 550], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 78000], ["Troops", 3]], "SB", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    
    // AT/CAS Aircraft
    ["Mi-48 Kajman", ["O_Heli_Attack_02_dynamicLoadout_F"], [["Cargo", 1000], ["Ammo", 700], ["Fuel", 500], ["Medical", 0], ["Repair", 0], ["Vehicle", 15000], ["Troops", 2]], "SB", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "OPEN"],
    ["To-199 Neophron (CAS)", ["O_Plane_CAS_02_dynamicLoadout_F"], [["Cargo", 500], ["Ammo", 800], ["Fuel", 1000], ["Medical", 0], ["Repair", 0], ["Vehicle", 18000], ["Troops", 1]], "SB", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "L"],
    ["Ababil-3 (UCAV)", ["O_UAV_02_dynamicLoadout_F"], [["Cargo", 250], ["Ammo", 300], ["Fuel", 800], ["Medical", 0], ["Repair", 0], ["Vehicle", 5000], ["Troops", 0]], "SB", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "L"],

    // ------------------------------------------------------------------------
    // INFANTRY SUPPORT & LIGHT ARMOR
    // ------------------------------------------------------------------------
    ["Qilin (Unarmed)", ["O_LSV_02_unarmed_F"], [["Cargo", 1800], ["Ammo", 0], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 2174], ["Troops", 1]], "ALL", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["Qilin (Armed)", ["O_LSV_02_armed_F"], [["Cargo", 1800], ["Ammo", 100], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 3500], ["Troops", 2]], "FOB", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["Ifrit", ["O_MRAP_02_F"], [["Cargo", 2000], ["Ammo", 0], ["Fuel", 26], ["Medical", 0], ["Repair", 0], ["Vehicle", 8306], ["Troops", 1]], "ALL", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["Ifrit (HMG)", ["O_MRAP_02_hmg_F"], [["Cargo", 2000], ["Ammo", 200], ["Fuel", 26], ["Medical", 0], ["Repair", 0], ["Vehicle", 8389], ["Troops", 2]], "FOB", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["Ifrit (GMG)", ["O_MRAP_02_gmg_F"], [["Cargo", 2000], ["Ammo", 250], ["Fuel", 26], ["Medical", 0], ["Repair", 0], ["Vehicle", 8500], ["Troops", 2]], "FOB", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["MSE-3 Marid", ["O_APC_Wheeled_02_rcws_v2_F"], [["Cargo", 3000], ["Ammo", 300], ["Fuel", 24], ["Medical", 0], ["Repair", 0], ["Vehicle", 20000], ["Troops", 3]], "SB", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["UGV Saif", ["O_UGV_01_rcws_F"], [["Cargo", 1000], ["Ammo", 150], ["Fuel", 14], ["Medical", 0], ["Repair", 0], ["Vehicle", 4500], ["Troops", 0]], "FOB", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    
    // Support Aircraft
    ["PO-30 Orca", ["O_Heli_Light_02_dynamicLoadout_F"], [["Cargo", 2000], ["Ammo", 200], ["Fuel", 300], ["Medical", 0], ["Repair", 0], ["Vehicle", 6000], ["Troops", 2]], "FOB", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "OPEN"],

    // ------------------------------------------------------------------------
    // CORE LOGISTICS & TRANSPORT TRUCKS
    // ------------------------------------------------------------------------
    ["Tempest Transport", ["O_Truck_03_covered_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 30], ["Medical", 0], ["Repair", 0], ["Vehicle", 13200], ["Troops", 1]], "MSR", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["Tempest Transport (Tropic)", ["O_T_Truck_03_covered_ghex_F"], [["Cargo", 3000], ["Ammo", 0], ["Fuel", 30], ["Medical", 0], ["Repair", 0], ["Vehicle", 13200], ["Troops", 1]], "MSR", "EAST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],
    ["Ifrit (Tropic)", ["O_T_MRAP_02_ghex_F"], [["Cargo", 2000], ["Ammo", 0], ["Fuel", 26], ["Medical", 0], ["Repair", 0], ["Vehicle", 8306], ["Troops", 1]], "ALL", "EAST", ["Woodland", "Jungle"], ["Quartermaster", "WorldAI"], "M"],

    // ------------------------------------------------------------------------
    // WORLD AI CONVOYS
    // ------------------------------------------------------------------------
    [
        "CSAT Jungle Convoy", 
        ["O_T_MRAP_02_hmg_ghex_F", "O_T_Truck_03_covered_ghex_F", "O_T_MRAP_02_hmg_ghex_F"], 
        [["Cargo", 7000], ["Ammo", 200], ["Fuel", 80], ["Medical", 0], ["Repair", 0], ["Vehicle", 29978], ["Troops", 5]], 
        "SB", 
        "EAST", 
        ["Woodland", "Jungle"], 
        ["WorldAI"],
        "M"
    ],


    // ========================================================================
    // FACTION: INDEPENDENT (GUER / AAF)
    // ========================================================================

    // ------------------------------------------------------------------------
    // ANTI-AIR (VEHICLES & AIRCRAFT)
    // ------------------------------------------------------------------------
    ["AWC 302 Nyx (AA)", ["I_LT_01_AA_F"], [["Cargo", 1000], ["Ammo", 200], ["Fuel", 15], ["Medical", 0], ["Repair", 0], ["Vehicle", 12000], ["Troops", 2]], "FOB", "GUER", ["Woodland", "Jungle", "Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["A&D Griffon", ["I_Plane_Fighter_04_F"], [["Cargo", 500], ["Ammo", 500], ["Fuel", 1200], ["Medical", 0], ["Repair", 0], ["Vehicle", 18000], ["Troops", 1]], "SB", "GUER", ["Woodland", "Jungle", "Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "L"],

    // ------------------------------------------------------------------------
    // ANTI-TANK & HEAVY ARMOR
    // ------------------------------------------------------------------------
    ["AWC 302 Nyx (AT)", ["I_LT_01_AT_F"], [["Cargo", 1000], ["Ammo", 250], ["Fuel", 15], ["Medical", 0], ["Repair", 0], ["Vehicle", 12500], ["Troops", 2]], "FOB", "GUER", ["Woodland", "Jungle", "Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["AFV-4 Gorgon", ["I_APC_Wheeled_03_cannon_F"], [["Cargo", 3000], ["Ammo", 350], ["Fuel", 24], ["Medical", 0], ["Repair", 0], ["Vehicle", 23000], ["Troops", 3]], "SB", "GUER", ["Woodland", "Jungle", "Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["MBT-52 Kuma", ["I_MBT_03_cannon_F"], [["Cargo", 3000], ["Ammo", 500], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 62000], ["Troops", 3]], "SB", "GUER", ["Woodland", "Jungle", "Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    
    // AT/CAS Aircraft
    ["A-143 Buzzard (CAS)", ["I_Plane_Fighter_03_dynamicLoadout_F"], [["Cargo", 500], ["Ammo", 600], ["Fuel", 1000], ["Medical", 0], ["Repair", 0], ["Vehicle", 15000], ["Troops", 1]], "SB", "GUER", ["Woodland", "Jungle", "Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "L"],
    ["K40 Ababil-3 (UCAV)", ["I_UAV_02_dynamicLoadout_F"], [["Cargo", 250], ["Ammo", 300], ["Fuel", 800], ["Medical", 0], ["Repair", 0], ["Vehicle", 5000], ["Troops", 0]], "SB", "GUER", ["Woodland", "Jungle", "Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "L"],

    // ------------------------------------------------------------------------
    // INFANTRY SUPPORT & LIGHT ARMOR
    // ------------------------------------------------------------------------
    ["Offroad", ["I_G_Offroad_01_F"], [["Cargo", 1000], ["Ammo", 0], ["Fuel", 15], ["Medical", 0], ["Repair", 0], ["Vehicle", 1500], ["Troops", 1]], "ALL", "GUER", ["Woodland", "Jungle", "Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["Strider", ["I_MRAP_03_F"], [["Cargo", 2000], ["Ammo", 0], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 8000], ["Troops", 1]], "ALL", "GUER", ["Woodland", "Jungle", "Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["Strider (HMG)", ["I_MRAP_03_hmg_F"], [["Cargo", 2000], ["Ammo", 100], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 8500], ["Troops", 2]], "FOB", "GUER", ["Woodland", "Jungle", "Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["Strider (GMG)", ["I_MRAP_03_gmg_F"], [["Cargo", 2000], ["Ammo", 250], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 8500], ["Troops", 2]], "FOB", "GUER", ["Woodland", "Jungle", "Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["AWC 301 Nyx (Cannon)", ["I_LT_01_cannon_F"], [["Cargo", 1000], ["Ammo", 250], ["Fuel", 15], ["Medical", 0], ["Repair", 0], ["Vehicle", 12000], ["Troops", 2]], "FOB", "GUER", ["Woodland", "Jungle", "Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["FV-720 Mora", ["I_APC_tracked_03_cannon_F"], [["Cargo", 3000], ["Ammo", 350], ["Fuel", 18], ["Medical", 0], ["Repair", 0], ["Vehicle", 55000], ["Troops", 3]], "SB", "GUER", ["Woodland", "Jungle", "Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["UGV Stomper (AAF)", ["I_UGV_01_rcws_F"], [["Cargo", 1000], ["Ammo", 150], ["Fuel", 14], ["Medical", 0], ["Repair", 0], ["Vehicle", 4500], ["Troops", 0]], "FOB", "GUER", ["Woodland", "Jungle", "Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    
    // Support Aircraft
    ["AW159 Hellcat", ["I_Heli_light_03_dynamicLoadout_F"], [["Cargo", 1500], ["Ammo", 200], ["Fuel", 200], ["Medical", 0], ["Repair", 0], ["Vehicle", 5500], ["Troops", 2]], "FOB", "GUER", ["Woodland", "Jungle", "Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "OPEN"],

    // ------------------------------------------------------------------------
    // CORE LOGISTICS TRUCKS
    // ------------------------------------------------------------------------
    ["Zamak Transport", ["I_Truck_02_transport_F"], [["Cargo", 2500], ["Ammo", 0], ["Fuel", 25], ["Medical", 0], ["Repair", 0], ["Vehicle", 9000], ["Troops", 1]], "ALL", "GUER", ["Woodland", "Jungle", "Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],
    ["Zamak Covered", ["I_Truck_02_covered_F"], [["Cargo", 2500], ["Ammo", 0], ["Fuel", 25], ["Medical", 0], ["Repair", 0], ["Vehicle", 9500], ["Troops", 1]], "ALL", "GUER", ["Woodland", "Jungle", "Mediterranean", "Desert"], ["Quartermaster", "WorldAI"], "M"],

    // ------------------------------------------------------------------------
    // WORLD AI CONVOYS
    // ------------------------------------------------------------------------
    [
        "AAF QRF Patrol", 
        ["I_MRAP_03_hmg_F", "I_MRAP_03_F"], 
        [["Cargo", 4000], ["Ammo", 100], ["Fuel", 40], ["Medical", 0], ["Repair", 0], ["Vehicle", 16500], ["Troops", 3]], 
        "FOB", 
        "GUER", 
        ["Woodland", "Jungle", "Mediterranean", "Desert"], 
        ["WorldAI"],
        "M"
    ]

];