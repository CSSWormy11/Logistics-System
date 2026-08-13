// ============================================================================
// LOGISTICS SYSTEM: VEHICLE CONFIGURATION MANIFEST (PART 2)
// File: spawnableVehicleTemplate.sqf
// Description: Defines the master array of vehicles available for procurement.
//              Includes display names, classnames, detailed multi-resource costs, 
//              base restriction requirements, faction locks, and SIZE categories.
// Called By: init.sqf (Compiled during server/master initialization)
// ============================================================================

// Format: 
// ["Display Name", "Classname", [["Cargo", X], ["Ammo", X], ["Fuel", X], ["Medical", X], ["Repair", X], ["Vehicle", Cost], ["Troops", X]], "Base Restriction", "Faction", "Size"]
// Factions: WEST, EAST, GUER, CIV, ALL
// Sizes: XS, S, M, L, XL, OPEN

G_Procureable_Vehicles = [
    // --- LIGHT & RECON VEHICLES (ALL) ---
    ["Quad Bike", "B_Quadbike_01_F", [["Cargo", 600], ["Ammo", 0], ["Fuel", 10], ["Medical", 0], ["Repair", 0], ["Vehicle", 280.831], ["Troops", 1]], "ALL", "WEST", "S"],
    ["Prowler (Unarmed)", "B_LSV_01_unarmed_F", [["Cargo", 1800], ["Ammo", 0], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 3308.35], ["Troops", 0]], "ALL", "WEST", "M"],
    ["Prowler (HMG)", "B_LSV_01_armed_F", [["Cargo", 1800], ["Ammo", 0], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 3413.35], ["Troops", 0]], "ALL", "WEST", "M"],
    ["Prowler (AT)", "B_LSV_01_AT_F", [["Cargo", 1800], ["Ammo", 0], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 3413.35], ["Troops", 0]], "ALL", "WEST", "M"],
    ["Hunter", "B_MRAP_01_F", [["Cargo", 2000], ["Ammo", 0], ["Fuel", 26], ["Medical", 0], ["Repair", 0], ["Vehicle", 8306.63], ["Troops", 3]], "ALL", "WEST", "M"],
    ["Prowler (Light)", "B_CTRG_LSV_01_light_F", [["Cargo", 1800], ["Ammo", 0], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 3413.35], ["Troops", 0]], "ALL", "WEST", "M"],
    ["Quad Bike", "B_T_Quadbike_01_F", [["Cargo", 600], ["Ammo", 0], ["Fuel", 10], ["Medical", 0], ["Repair", 0], ["Vehicle", 280.831], ["Troops", 1]], "ALL", "WEST", "S"],
    ["Prowler (Unarmed)", "B_T_LSV_01_unarmed_F", [["Cargo", 1800], ["Ammo", 0], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 3413.35], ["Troops", 0]], "ALL", "WEST", "M"],
    ["Prowler (HMG)", "B_T_LSV_01_armed_F", [["Cargo", 1800], ["Ammo", 0], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 3413.35], ["Troops", 0]], "ALL", "WEST", "M"],
    ["Prowler (AT)", "B_T_LSV_01_AT_F", [["Cargo", 1800], ["Ammo", 0], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 3413.35], ["Troops", 0]], "ALL", "WEST", "M"],
    ["Hunter", "B_T_MRAP_01_F", [["Cargo", 2000], ["Ammo", 0], ["Fuel", 26], ["Medical", 0], ["Repair", 0], ["Vehicle", 8306.63], ["Troops", 3]], "ALL", "WEST", "M"],

    // --- LOGISTICS TRUCKS (SB / MSR) ---
    ["HEMTT", "B_Truck_01_mover_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 28], ["Medical", 0], ["Repair", 0], ["Vehicle", 10842.8], ["Troops", 1]], "SB", "WEST", "M"],
    ["HEMTT Transport", "B_Truck_01_transport_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 28], ["Medical", 0], ["Repair", 0], ["Vehicle", 10942.9], ["Troops", 15]], "ALL", "WEST", "M"],
    ["HEMTT Transport (Covered)", "B_Truck_01_covered_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 28], ["Medical", 0], ["Repair", 0], ["Vehicle", 11026.2], ["Troops", 15]], "ALL", "WEST", "M"],
    ["HEMTT Flatbed", "B_Truck_01_flatbed_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 28], ["Medical", 0], ["Repair", 0], ["Vehicle", 11739], ["Troops", 1]], "SB", "WEST", "M"],
    ["HEMTT Cargo", "B_Truck_01_cargo_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 28], ["Medical", 0], ["Repair", 0], ["Vehicle", 11786.7], ["Troops", 1]], "ALL", "WEST", "M"],
    ["HEMTT Ammo", "B_Truck_01_ammo_F", [["Cargo", 3000], ["Ammo", 1000000000000], ["Fuel", 28], ["Medical", 0], ["Repair", 0], ["Vehicle", 12407.2], ["Troops", 1]], "SB", "WEST", "M"],
    ["HEMTT Box", "B_Truck_01_box_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 28], ["Medical", 0], ["Repair", 0], ["Vehicle", 11692.9], ["Troops", 1]], "SB", "WEST", "M"],
    ["HEMTT Fuel", "B_Truck_01_fuel_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 1000000000000], ["Medical", 0], ["Repair", 0], ["Vehicle", 13181], ["Troops", 1]], "SB", "WEST", "M"],
    ["HEMTT Medical", "B_Truck_01_medical_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 28], ["Medical", 1], ["Repair", 0], ["Vehicle", 11026.2], ["Troops", 16]], "SB", "WEST", "M"],
    ["HEMTT Repair", "B_Truck_01_Repair_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 28], ["Medical", 0], ["Repair", 1000000000000], ["Vehicle", 11692.9], ["Troops", 1]], "SB", "WEST", "M"],
    ["HEMTT", "B_T_Truck_01_mover_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 28], ["Medical", 0], ["Repair", 0], ["Vehicle", 10842.8], ["Troops", 1]], "SB", "WEST", "M"],
    ["HEMTT Transport", "B_T_Truck_01_transport_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 28], ["Medical", 0], ["Repair", 0], ["Vehicle", 10942.9], ["Troops", 15]], "ALL", "WEST", "M"],
    ["HEMTT Transport (Covered)", "B_T_Truck_01_covered_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 28], ["Medical", 0], ["Repair", 0], ["Vehicle", 11026.2], ["Troops", 15]], "ALL", "WEST", "M"],
    ["HEMTT Flatbed", "B_T_Truck_01_flatbed_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 28], ["Medical", 0], ["Repair", 0], ["Vehicle", 11739], ["Troops", 1]], "SB", "WEST", "M"],
    ["HEMTT Cargo", "B_T_Truck_01_cargo_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 28], ["Medical", 0], ["Repair", 0], ["Vehicle", 11786.7], ["Troops", 1]], "ALL", "WEST", "M"],
    ["HEMTT Ammo", "B_T_Truck_01_ammo_F", [["Cargo", 3000], ["Ammo", 1000000000000], ["Fuel", 28], ["Medical", 0], ["Repair", 0], ["Vehicle", 12407.2], ["Troops", 1]], "SB", "WEST", "M"],
    ["HEMTT Box", "B_T_Truck_01_box_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 28], ["Medical", 0], ["Repair", 0], ["Vehicle", 11692.9], ["Troops", 1]], "SB", "WEST", "M"],
    ["HEMTT Fuel", "B_T_Truck_01_fuel_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 1000000000000], ["Medical", 0], ["Repair", 0], ["Vehicle", 13181], ["Troops", 1]], "SB", "WEST", "M"],
    ["HEMTT Medical", "B_T_Truck_01_medical_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 28], ["Medical", 1], ["Repair", 0], ["Vehicle", 11026.2], ["Troops", 16]], "SB", "WEST", "M"],
    ["HEMTT Repair", "B_T_Truck_01_Repair_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 28], ["Medical", 0], ["Repair", 1000000000000], ["Vehicle", 11692.9], ["Troops", 1]], "SB", "WEST", "M"],

    // --- ARMORED RECON & OVERWATCH (SB / ALL) ---
    ["Hunter HMG", "B_MRAP_01_hmg_F", [["Cargo", 2000], ["Ammo", 0], ["Fuel", 26], ["Medical", 0], ["Repair", 0], ["Vehicle", 8389.04], ["Troops", 2]], "ALL", "WEST", "M"],
    ["Hunter GMG", "B_MRAP_01_gmg_F", [["Cargo", 2000], ["Ammo", 0], ["Fuel", 26], ["Medical", 0], ["Repair", 0], ["Vehicle", 8389.04], ["Troops", 2]], "ALL", "WEST", "M"],
    ["AFV-4 Gorgon", "B_APC_Wheeled_03_cannon_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 24], ["Medical", 0], ["Repair", 0], ["Vehicle", 21700], ["Troops", 8]], "SB", "WEST", "M"],
    ["AMV-7 Marshall", "B_APC_Wheeled_01_cannon_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 24], ["Medical", 0], ["Repair", 0], ["Vehicle", 23299.8], ["Troops", 8]], "SB", "WEST", "M"],
    ["Rhino MGS", "B_AFV_Wheeled_01_cannon_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 24], ["Medical", 0], ["Repair", 0], ["Vehicle", 23900.1], ["Troops", 0]], "SB", "WEST", "M"],
    ["Rhino MGS UP", "B_AFV_Wheeled_01_up_cannon_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 24], ["Medical", 0], ["Repair", 0], ["Vehicle", 24200], ["Troops", 0]], "SB", "WEST", "M"],
    ["Hunter HMG", "B_T_MRAP_01_hmg_F", [["Cargo", 2000], ["Ammo", 0], ["Fuel", 26], ["Medical", 0], ["Repair", 0], ["Vehicle", 8389.04], ["Troops", 2]], "ALL", "WEST", "M"],
    ["Hunter GMG", "B_T_MRAP_01_gmg_F", [["Cargo", 2000], ["Ammo", 0], ["Fuel", 26], ["Medical", 0], ["Repair", 0], ["Vehicle", 8389.04], ["Troops", 2]], "ALL", "WEST", "M"],
    ["AMV-7 Marshall", "B_T_APC_Wheeled_01_cannon_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 24], ["Medical", 0], ["Repair", 0], ["Vehicle", 23299.8], ["Troops", 8]], "SB", "WEST", "M"],
    ["Rhino MGS", "B_T_AFV_Wheeled_01_cannon_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 24], ["Medical", 0], ["Repair", 0], ["Vehicle", 23900.1], ["Troops", 0]], "SB", "WEST", "M"],
    ["Rhino MGS UP", "B_T_AFV_Wheeled_01_up_cannon_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 24], ["Medical", 0], ["Repair", 0], ["Vehicle", 24200], ["Troops", 0]], "SB", "WEST", "M"],

    // --- HEAVY ARMOR & MECHANIZED (SB) ---
    ["IFV-6c Panther", "B_APC_Tracked_01_rcws_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 18], ["Medical", 0], ["Repair", 0], ["Vehicle", 62385], ["Troops", 8]], "SB", "WEST", "M"],
    ["CRV-6e Bobcat", "B_APC_Tracked_01_CRV_F", [["Cargo", 3000], ["Ammo", 1000000000000], ["Fuel", 1000000000000], ["Medical", 0], ["Repair", 1000000000000], ["Vehicle", 65255.9], ["Troops", 0]], "SB", "WEST", "M"],
    ["IFV-6a Cheetah", "B_APC_Tracked_01_AA_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 18], ["Medical", 0], ["Repair", 0], ["Vehicle", 63585.1], ["Troops", 0]], "SB", "WEST", "M"],
    ["M2A1 Slammer", "B_MBT_01_cannon_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 65047.5], ["Troops", 6]], "SB", "WEST", "M"],
    ["M2A4 Slammer UP", "B_MBT_01_TUSK_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 70000], ["Troops", 6]], "SB", "WEST", "M"],
    ["M4 Scorcher", "B_MBT_01_arty_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 65348.6], ["Troops", 0]], "SB", "WEST", "M"],
    ["M5 Sandstorm MLRS", "B_MBT_01_mlrs_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 67663.5], ["Troops", 0]], "SB", "WEST", "M"],
    ["IFV-6c Panther", "B_T_APC_Tracked_01_rcws_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 18], ["Medical", 0], ["Repair", 0], ["Vehicle", 62385], ["Troops", 8]], "SB", "WEST", "M"],
    ["CRV-6e Bobcat", "B_T_APC_Tracked_01_CRV_F", [["Cargo", 3000], ["Ammo", 1000000000000], ["Fuel", 1000000000000], ["Medical", 0], ["Repair", 1000000000000], ["Vehicle", 65255.9], ["Troops", 0]], "SB", "WEST", "M"],
    ["IFV-6a Cheetah", "B_T_APC_Tracked_01_AA_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 18], ["Medical", 0], ["Repair", 0], ["Vehicle", 63585.1], ["Troops", 0]], "SB", "WEST", "M"],
    ["M2A1 Slammer", "B_T_MBT_01_cannon_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 65047.5], ["Troops", 6]], "SB", "WEST", "M"],
    ["M2A4 Slammer UP", "B_T_MBT_01_TUSK_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 70000], ["Troops", 6]], "SB", "WEST", "M"],
    ["M4 Scorcher", "B_T_MBT_01_arty_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 65348.6], ["Troops", 0]], "SB", "WEST", "M"],
    ["M5 Sandstorm MLRS", "B_T_MBT_01_mlrs_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 20], ["Medical", 0], ["Repair", 0], ["Vehicle", 67663.5], ["Troops", 0]], "SB", "WEST", "M"],

    // --- UNMANNED GROUND VEHICLES (ALL) ---
    ["ED-1D Pelter", "B_UGV_02_Demining_F", [["Cargo", 0], ["Ammo", 0], ["Fuel", 2], ["Medical", 0], ["Repair", 0], ["Vehicle", 255], ["Troops", 0]], "ALL", "WEST", "XS"],
    ["ED-1E Roller", "B_UGV_02_Science_F", [["Cargo", 0], ["Ammo", 0], ["Fuel", 2], ["Medical", 0], ["Repair", 0], ["Vehicle", 255], ["Troops", 0]], "ALL", "WEST", "XS"],
    ["UGV Stomper", "B_UGV_01_F", [["Cargo", 1000], ["Ammo", 0], ["Fuel", 14], ["Medical", 0], ["Repair", 0], ["Vehicle", 4266.54], ["Troops", 0]], "ALL", "WEST", "M"],
    ["UGV Stomper RCWS", "B_UGV_01_rcws_F", [["Cargo", 1000], ["Ammo", 0], ["Fuel", 14], ["Medical", 0], ["Repair", 0], ["Vehicle", 4266.54], ["Troops", 0]], "ALL", "WEST", "M"],
    ["UGV Stomper", "B_T_UGV_01_olive_F", [["Cargo", 1000], ["Ammo", 0], ["Fuel", 14], ["Medical", 0], ["Repair", 0], ["Vehicle", 4266.54], ["Troops", 0]], "ALL", "WEST", "M"],
    ["UGV Stomper RCWS", "B_T_UGV_01_rcws_olive_F", [["Cargo", 1000], ["Ammo", 0], ["Fuel", 14], ["Medical", 0], ["Repair", 0], ["Vehicle", 4266.54], ["Troops", 0]], "ALL", "WEST", "M"],

    // --- UNMANNED AERIAL VEHICLES (ALL / SB) ---
    ["AR-2 Darter", "B_UAV_01_F", [["Cargo", 999], ["Ammo", 0], ["Fuel", 100], ["Medical", 0], ["Repair", 0], ["Vehicle", 170.667], ["Troops", 0]], "ALL", "WEST", "XS"],
    ["AL-6 Pelican", "B_UAV_06_F", [["Cargo", 120], ["Ammo", 0], ["Fuel", 100], ["Medical", 0], ["Repair", 0], ["Vehicle", 251.286], ["Troops", 0]], "ALL", "WEST", "XS"],
    ["AL-6 Pelican (Medical)", "B_UAV_06_medical_F", [["Cargo", 120], ["Ammo", 0], ["Fuel", 100], ["Medical", 1], ["Repair", 0], ["Vehicle", 251.286], ["Troops", 0]], "ALL", "WEST", "XS"],
    ["MQ-4A Greyhawk", "B_UAV_02_dynamicLoadout_F", [["Cargo", 250], ["Ammo", 0], ["Fuel", 1000], ["Medical", 0], ["Repair", 0], ["Vehicle", 3000], ["Troops", 0]], "SB", "WEST", "M"],
    ["UCAV Sentinel", "B_UAV_05_F", [["Cargo", 999], ["Ammo", 0], ["Fuel", 1000], ["Medical", 0], ["Repair", 0], ["Vehicle", 11450], ["Troops", 0]], "SB", "WEST", "XL"],
    ["MQ-12 Falcon", "B_T_UAV_03_dynamicLoadout_F", [["Cargo", 999], ["Ammo", 0], ["Fuel", 100], ["Medical", 0], ["Repair", 0], ["Vehicle", 5154.97], ["Troops", 0]], "SB", "WEST", "OPEN"],

    // --- ROTARY WING / HELICOPTERS (SB) ---
    ["MH-9 Hummingbird", "B_Heli_Light_01_F", [["Cargo", 1000], ["Ammo", 0], ["Fuel", 242], ["Medical", 0], ["Repair", 0], ["Vehicle", 500], ["Troops", 2]], "SB", "WEST", "OPEN"],
    ["AH-9 Pawnee", "B_Heli_Light_01_dynamicLoadout_F", [["Cargo", 1000], ["Ammo", 0], ["Fuel", 242], ["Medical", 0], ["Repair", 0], ["Vehicle", 500], ["Troops", 0]], "SB", "WEST", "OPEN"],
    ["AH-99 Blackfoot", "B_Heli_Attack_01_dynamicLoadout_F", [["Cargo", 999], ["Ammo", 0], ["Fuel", 500], ["Medical", 0], ["Repair", 0], ["Vehicle", 10056.3], ["Troops", 0]], "SB", "WEST", "OPEN"],
    ["AH-99 Blackfoot (Stub Wings)", "B_Heli_Attack_01_pylons_dynamicLoadout_F", [["Cargo", 999], ["Ammo", 0], ["Fuel", 500], ["Medical", 0], ["Repair", 0], ["Vehicle", 10056.3], ["Troops", 0]], "SB", "WEST", "OPEN"],
    ["UH-80 Ghost Hawk", "B_Heli_Transport_01_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 1360], ["Medical", 0], ["Repair", 0], ["Vehicle", 4000], ["Troops", 8]], "SB", "WEST", "OPEN"],
    ["UH-80 Ghost Hawk (Stub Wings)", "B_Heli_Transport_01_pylons_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 1360], ["Medical", 0], ["Repair", 0], ["Vehicle", 4000], ["Troops", 8]], "SB", "WEST", "OPEN"],
    ["CH-67 Huron (Unarmed)", "B_Heli_Transport_03_unarmed_F", [["Cargo", 6000], ["Ammo", 0], ["Fuel", 1360], ["Medical", 0], ["Repair", 0], ["Vehicle", 12000], ["Troops", 14]], "SB", "WEST", "OPEN"],
    ["CH-67 Huron", "B_Heli_Transport_03_F", [["Cargo", 6000], ["Ammo", 0], ["Fuel", 1360], ["Medical", 0], ["Repair", 0], ["Vehicle", 12000], ["Troops", 14]], "SB", "WEST", "OPEN"],
    ["UH-80 Ghost Hawk (Sand)", "B_CTRG_Heli_Transport_01_sand_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 1360], ["Medical", 0], ["Repair", 0], ["Vehicle", 4000], ["Troops", 8]], "SB", "WEST", "OPEN"],
    ["UH-80 Ghost Hawk (Tropic)", "B_CTRG_Heli_Transport_01_tropic_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 1360], ["Medical", 0], ["Repair", 0], ["Vehicle", 4000], ["Troops", 8]], "SB", "WEST", "OPEN"],

    // --- FIXED WING & VTOL (SB) ---
    ["V-44 X Blackfish (Infantry Transport)", "B_T_VTOL_01_infantry_F", [["Cargo", 12000], ["Ammo", 0], ["Fuel", 1000], ["Medical", 0], ["Repair", 0], ["Vehicle", 47709.8], ["Troops", 30]], "SB", "WEST", "OPEN"],
    ["V-44 X Blackfish (Vehicle Transport)", "B_T_VTOL_01_vehicle_F", [["Cargo", 12000], ["Ammo", 0], ["Fuel", 1000], ["Medical", 0], ["Repair", 0], ["Vehicle", 47709.8], ["Troops", 0]], "SB", "WEST", "OPEN"],
    ["V-44 X Blackfish (Armed)", "B_T_VTOL_01_armed_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 1000], ["Medical", 0], ["Repair", 0], ["Vehicle", 47759.8], ["Troops", 0]], "SB", "WEST", "OPEN"],
    ["A-164 Wipeout (CAS)", "B_Plane_CAS_01_dynamicLoadout_F", [["Cargo", 500], ["Ammo", 0], ["Fuel", 1000], ["Medical", 0], ["Repair", 0], ["Vehicle", 19500], ["Troops", 0]], "SB", "WEST", "L"],
    ["F/A-181 Black Wasp II", "B_Plane_Fighter_01_F", [["Cargo", 500], ["Ammo", 0], ["Fuel", 1550], ["Medical", 0], ["Repair", 0], ["Vehicle", 11000], ["Troops", 0]], "SB", "WEST", "L"],
    ["F/A-181 Black Wasp II (Stealth)", "B_Plane_Fighter_01_Stealth_F", [["Cargo", 500], ["Ammo", 0], ["Fuel", 1550], ["Medical", 0], ["Repair", 0], ["Vehicle", 11000], ["Troops", 0]], "SB", "WEST", "L"],

    // --- NAVAL / BOATS (ALL) ---
    ["Rescue Boat", "B_Lifeboat", [["Cargo", 500], ["Ammo", 0], ["Fuel", 12], ["Medical", 0], ["Repair", 0], ["Vehicle", 565], ["Troops", 0]], "ALL", "WEST", "M"],
    ["Assault Boat", "B_Boat_Transport_01_F", [["Cargo", 500], ["Ammo", 0], ["Fuel", 12], ["Medical", 0], ["Repair", 0], ["Vehicle", 565], ["Troops", 0]], "ALL", "WEST", "M"],
    ["Speedboat Minigun", "B_Boat_Armed_01_minigun_F", [["Cargo", 500], ["Ammo", 0], ["Fuel", 12], ["Medical", 0], ["Repair", 0], ["Vehicle", 9002.62], ["Troops", 8]], "ALL", "WEST", "M"],
    ["SDV", "B_SDV_01_F", [["Cargo", 500], ["Ammo", 0], ["Fuel", 120], ["Medical", 0], ["Repair", 0], ["Vehicle", 2600], ["Troops", 2]], "ALL", "WEST", "M"],
    ["Rescue Boat", "B_T_Lifeboat", [["Cargo", 500], ["Ammo", 0], ["Fuel", 12], ["Medical", 0], ["Repair", 0], ["Vehicle", 565], ["Troops", 0]], "ALL", "WEST", "M"],
    ["Assault Boat", "B_T_Boat_Transport_01_F", [["Cargo", 500], ["Ammo", 0], ["Fuel", 12], ["Medical", 0], ["Repair", 0], ["Vehicle", 565], ["Troops", 0]], "ALL", "WEST", "M"],
    ["Speedboat Minigun", "B_T_Boat_Armed_01_minigun_F", [["Cargo", 500], ["Ammo", 0], ["Fuel", 12], ["Medical", 0], ["Repair", 0], ["Vehicle", 9002.62], ["Troops", 8]], "ALL", "WEST", "M"],

    // --- STATIC WEAPONS & OBJECTS (ALL) ---
    ["Mk30 HMG .50", "B_HMG_01_F", [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 160], ["Troops", 0]], "FOB", "WEST", "XS"],
    ["Mk30 HMG .50 (Raised)", "B_HMG_01_high_F", [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 172.632], ["Troops", 0]], "FOB", "WEST", "XS"],
    ["Mk30A HMG .50", "B_HMG_01_A_F", [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 160], ["Troops", 0]], "FOB", "WEST", "XS"],
    ["Mk32 GMG 20 mm", "B_GMG_01_F", [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 168.171], ["Troops", 0]], "FOB", "WEST", "XS"],
    ["Mk32 GMG 20 mm (Raised)", "B_GMG_01_high_F", [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 161.154], ["Troops", 0]], "FOB", "WEST", "XS"],
    ["Mk32A GMG 20 mm", "B_GMG_01_A_F", [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 168.171], ["Troops", 0]], "FOB", "WEST", "XS"],
    ["Static Titan Launcher (AA) [NATO]", "B_static_AA_F", [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 127.241], ["Troops", 0]], "FOB", "WEST", "XS"],
    ["Static Titan Launcher (AT) [NATO]", "B_static_AT_F", [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 127.167], ["Troops", 0]], "FOB", "WEST", "XS"],
    ["Remote Designator [NATO]", "B_Static_Designator_01_F", [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 100], ["Troops", 0]], "FOB", "WEST", "XS"],
    ["Mk6 Mortar", "B_Mortar_01_F", [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 50], ["Troops", 0]], "FOB", "WEST", "XS"],
    //["AN/MPQ-105 Radar", "B_Radar_System_01_F", [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 23452.9], ["Troops", 0]], "ALL", "WEST", "OPEN"],
    //["MIM-145 Defender", "B_SAM_System_03_F", [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 25484.9], ["Troops", 0]], "ALL", "WEST", "OPEM"],
    ["Static Titan Launcher (AA) [NATO]", "B_T_Static_AA_F", [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 127.241], ["Troops", 0]], "FOB", "WEST", "XS"],
    ["Static Titan Launcher (AT) [NATO]", "B_T_Static_AT_F", [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 127.167], ["Troops", 0]], "FOB", "WEST", "XS"],
    ["Remote Designator [NATO]", "B_W_Static_Designator_01_F", [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 100], ["Troops", 0]], "FOB", "WEST", "XS"],
    ["Mk6 Mortar", "B_T_Mortar_01_F", [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 50], ["Troops", 0]], "FOB", "WEST", "XS"],
    ["Mk30 HMG .50", "B_T_HMG_01_F", [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 160], ["Troops", 0]], "FOB", "WEST", "XS"],
    ["Mk32 GMG 20 mm", "B_T_GMG_01_F", [["Cargo", 0], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 168.171], ["Troops", 0]], "FOB", "WEST", "XS"],

    // --- LOGISTICS SUPPLY CONTAINER OBJECTS (ALL) ---
    ["Explosives [NATO]", "Box_NATO_AmmoOrd_F", [["Cargo", 2000], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 500], ["Troops", 0]], "SB", "WEST", "OPEN"],
    ["Huron Ammo Container", "B_Slingload_01_Ammo_F", [["Cargo", 2000], ["Ammo", 1000000000000], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 8000], ["Troops", 0]], "SB", "WEST", "OPEN"],
    ["Huron Fuel Container", "B_Slingload_01_Fuel_F", [["Cargo", 2000], ["Ammo", 0], ["Fuel", 1000000000000], ["Medical", 0], ["Repair", 0], ["Vehicle", 8500], ["Troops", 0]], "SB", "WEST", "OPEN"],
    ["Huron Medical Container", "B_Slingload_01_Medevac_F", [["Cargo", 2000], ["Ammo", 0], ["Fuel", 0], ["Medical", 1], ["Repair", 0], ["Vehicle", 7000], ["Troops", 0]], "SB", "WEST", "OPEN"],
    ["Huron Repair Container", "B_Slingload_01_Repair_F", [["Cargo", 2000], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 1000000000000], ["Vehicle", 7000], ["Troops", 0]], "SB", "WEST", "OPEN"],
    ["Flexible Fuel Tank (Sand)", "FlexibleTank_01_sand_F", [["Cargo", 999], ["Ammo", 0], ["Fuel", 300], ["Medical", 0], ["Repair", 0], ["Vehicle", 300], ["Troops", 0]], "SB", "WEST", "OPEN"],
    ["Flexible Fuel Tank (Forest)", "FlexibleTank_01_forest_F", [["Cargo", 999], ["Ammo", 0], ["Fuel", 300], ["Medical", 0], ["Repair", 0], ["Vehicle", 300], ["Troops", 0]], "SB", "WEST", "OPEN"],
    ["Vehicle Ammo [NATO]", "Box_NATO_AmmoVeh_F", [["Cargo", 2000], ["Ammo", 30000], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 1500], ["Troops", 0]], "SB", "WEST", "OPEN"],
    ["Huron Cargo Container", "B_Slingload_01_Cargo_F", [["Cargo", 2000], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 7500], ["Troops", 0]], "SB", "WEST", "OPEN"],
    ["Cargo Net [NATO]", "B_CargoNet_01_ammo_F", [["Cargo", 22000], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 1000], ["Troops", 0]], "SB", "WEST", "OPEN"],
    ["Supply Box [NATO]", "B_supplyCrate_F", [["Cargo", 4000], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 500], ["Troops", 0]], "SB", "WEST", "OPEN"],
    ["Basic Ammo [NATO]", "Box_NATO_Ammo_F", [["Cargo", 1000], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 500], ["Troops", 0]], "SB", "WEST", "OPEN"],
    ["Grenades [NATO]", "Box_NATO_Grenades_F", [["Cargo", 500], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 500], ["Troops", 0]], "SB", "WEST", "OPEN"],
    ["Basic Weapons [NATO]", "Box_NATO_Wps_F", [["Cargo", 2000], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 500], ["Troops", 0]], "SB", "WEST", "OPEN"],
    ["Launchers [NATO]", "Box_NATO_WpsLaunch_F", [["Cargo", 2000], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 500], ["Troops", 0]], "SB", "WEST", "OPEN"],
    ["Special Weapons [NATO]", "Box_NATO_WpsSpecial_F", [["Cargo", 3000], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 500], ["Troops", 0]], "SB", "WEST", "OPEN"],
    ["Equipment Box [NATO]", "Box_NATO_Equip_F", [["Cargo", 7000], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 20], ["Troops", 0]], "SB", "WEST", "OPEN"],
    ["Uniforms Box [NATO]", "Box_NATO_Uniforms_F", [["Cargo", 7000], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 20], ["Troops", 0]], "SB", "WEST", "OPEN"],
    ["Support [NATO]", "Box_NATO_Support_F", [["Cargo", 1500], ["Ammo", 0], ["Fuel", 0], ["Medical", 0], ["Repair", 0], ["Vehicle", 500], ["Troops", 0]], "SB", "WEST", "OPEN"]
];

diag_log "QUARTERMASTER DATABASE: spawnableVehicleTemplate.sqf loaded successfully.";