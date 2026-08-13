// ============================================================================
// LOGISTICS SYSTEM: VEHICLE CAPS CONFIGURATION (PART 2)
// File: qm_vehicleCapsTemplate.sqf
// Description: Mission makers define the parent base classes they want limited,
//              along with their maximum allowed active count.
//              Vehicles NOT listed here bypass restrictions entirely (-1/Unlimited).
// Called By: init.sqf (Compiled during server/master initialization)
// ============================================================================

QM_CAP_ConfigMatrix = [
    // ["Parent_Base_Class", Max_Active_Allowed]
    // Overall Vehicles
    ["All", 256],           // All Parent
    ["AllVehicles", 128],           // All Vehicles Parent
    // Overall Air
    ["Plane", 12],           // Plane Parent
    ["VTOL_01_base_F", 3],       // Blackfish Parent;  Catches VTOL Infantry, Cargo, and Armed variants
    ["Plane_Fighter_01_Base_F", 8],           // Blackwasp Parent
    // Overall Ground
    ["LandVehicle", 48],           // Ground Vehicle Parent
    ["Truck_01_viv_base_F", 12],           // HEMTT Parent
    // Overall Armor
    ["Tank_F", 12],           // Tank Platform Parent
    ["B_MBT_01_cannon_F", 4],           // M2A4 Slammer Parent
    ["B_MBT_01_TUSK_F", 4],           // M2A4 Slammer UP
    ["B_MBT_01_cannon_F", 4],           // M2A1 Slammer
    ["AFV_Wheeled_01_base_F", 4],           // Rhino MGS Parent
    ["B_AFV_Wheeled_01_up_cannon_F", 4],           // Rhino MGS UP
    ["B_AFV_Wheeled_01_cannon_F", 4],           // Rhino MGS
    // Overall Strategic
    ["B_T_VTOL_01_infantry_F", 2],       // Catches VTOL Infantry, Cargo, and Armed variants
    ["B_T_VTOL_01_vehicle_F", 2],       // Catches VTOL Infantry, Cargo, and Armed variants
    ["Heli_Transport_03_base_F", 2],           // Catches Huron variants
    ["O_Heli_Transport_04_base_F", 2], // Catches Mi-290 Taru parent base variations
    ["Truck_01_flatbed_base_F", 4],           // HEMTT Flatbed Parent
    ["B_Truck_01_flatbed_F", 4],           // HEMTT Flatbed
    // Overall Tactical
    ["Heli_Transport_01_base_F", 4],           // UH-80 Ghost Hawk Parent
    ["B_Heli_Transport_01_F", 4],           // UH-80 Ghost Hawk
    ["Truck_01_cargo_base_F", 12],           // HEMTT Cargo Parent
    ["B_Truck_01_cargo_F", 12],           // HEMTT Cargo
    ["B_Heli_Light_01_F", 12],           // MH-9 Hummingbird
    // Overall Artillery
    ["B_MBT_01_arty_F", 2],           // M4 Scorcher
    ["B_MBT_01_mlrs_F", 2],           // M5 Sandstorm MLRS
    // Overall Anti-Air
    ["B_APC_Tracked_01_AA_F", 2],           // IFV-6a Cheetah
    // Overall Tactical Service
    ["B_APC_Tracked_01_CRV_F", 2],           // CRV-6e Bobcat
    // Overall IFV/APC
    ["Wheeled_APC_F", 12],           // APC Parent
    ["APC_Wheeled_03_base_F", 3],       // Example: Catches AFV-4 Gorgon family variants
    ["B_APC_Wheeled_01_cannon_F", 2],           // AMV-7 Marshall
    ["APC_Tracked_01_base_F", 2],           // Tracked APC
    ["B_APC_Tracked_01_rcws_F", 2],           // IFV-6c Panther
    // Overall Infantry Armored Transport
    ["Stuff", 12],           // Hunter Parent
    ["Stuff", 4],           // Hunter GMG
    ["Stuff", 4],           // Hunter HMG
    // Overall CAP
    ["B_Plane_Fighter_01_Stealth_F", 2],           // F/A-181 Black Wasp II (Stealth)
    ["B_Plane_Fighter_01_F", 2],           // F/A-181 Black Wasp II
    // Overall CAS
    ["B_T_VTOL_01_armed_F", 1],       // Catches VTOL Infantry, Cargo, and Armed variants
    ["B_Plane_CAS_01_dynamicLoadout_F", 2],           // A-164 Wipeout (CAS)
    // Overall Attack Helicopters
    ["B_Heli_Attack_01_pylons_dynamicLoadout_F", 2],           // AH-99 Blackfoot (Stub Wings)
    ["Heli_Attack_01_base_F", 4],           // AH-99 Blackfoot Parent
    ["B_T_UAV_03_dynamicLoadout_F", 2],           // MQ-12 Falcon
    ["B_Heli_Transport_01_pylons_F", 2],           // UH-80 Ghost Hawk (Stub Wings)
    // Overall Scout Helicopters
    ["B_Heli_Light_01_dynamicLoadout_F", 1],           // AH-9 Pawnee
    ["B_Heli_Attack_01_dynamicLoadout_F", 1]           // AH-99 Blackfoot
];

diag_log "QUARTERMASTER CAPS: Vehicle limits configuration database loaded.";