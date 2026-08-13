// ============================================================================
// LOGISTICS SYSTEM: INFANTRY & SQUAD CONFIGURATION MANIFEST
// File: spawnableInfantryTemplate.sqf
// Description: Single source of truth for all spawnable infantry units and groups.
//              Used by Quartermaster recruitment and World AI spawner systems.
// ============================================================================
// TEMPLATE INDEX MAP
// ============================================================================
//
// [0] Display Name
// [1] Classname Array
// [2] Resource Cost Array
// [3] Base Restriction
// [4] Side / Faction
// [5] Terrain Compatibility Array
// [6] Allowed Systems Array
//
// ============================================================================

G_Procureable_Infantry = [

    // ========================================================================
    // FACTION: BLUFOR (WEST / NATO)
    // ========================================================================

    // ------------------------------------------------------------------------
    // CLASSIFICATION: ANTI-AIR SPECIALISTS
    // ------------------------------------------------------------------------
    ["NATO AA Specialist", ["B_soldier_AA_F"], [["Troops", 1], ["Cargo", 350]], "FOB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],

    // ------------------------------------------------------------------------
    // CLASSIFICATION: ANTI-TANK SPECIALISTS
    // ------------------------------------------------------------------------
    ["NATO AT Specialist (Light)", ["B_soldier_LAT_F"], [["Troops", 1], ["Cargo", 300]], "FOB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["NATO AT Specialist (MAAWS)", ["B_soldier_LAT2_F"], [["Troops", 1], ["Cargo", 350]], "FOB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["NATO AT Specialist (Heavy)", ["B_soldier_AT_F"], [["Troops", 1], ["Cargo", 400]], "FOB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["NATO Recon AT", ["B_recon_LAT_F"], [["Troops", 1], ["Cargo", 350]], "FOB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["NATO Patrol AT", ["B_Patrol_Soldier_AT_F"], [["Troops", 1], ["Cargo", 350]], "FOB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],

    // ------------------------------------------------------------------------
    // CLASSIFICATION: STANDARD INFANTRY
    // ------------------------------------------------------------------------
    ["NATO Rifleman", ["B_Soldier_F"], [["Troops", 1], ["Cargo", 200]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["NATO Rifleman (Lite)", ["B_Soldier_lite_F"], [["Troops", 1], ["Cargo", 150]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["NATO Grenadier", ["B_Soldier_GL_F"], [["Troops", 1], ["Cargo", 250]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["NATO Auto-Rifleman", ["B_soldier_AR_F"], [["Troops", 1], ["Cargo", 250]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["NATO Heavy Gunner", ["B_HeavyGunner_F"], [["Troops", 1], ["Cargo", 300]], "FOB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["NATO Patrol Auto-Rifleman", ["B_Patrol_Soldier_AR_F"], [["Troops", 1], ["Cargo", 250]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["NATO Patrol Machine Gunner", ["B_Patrol_Soldier_MG_F"], [["Troops", 1], ["Cargo", 300]], "FOB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["NATO Patrol Heavy Gunner", ["B_Patrol_HeavyGunner_F"], [["Troops", 1], ["Cargo", 300]], "FOB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],

    // ------------------------------------------------------------------------
    // CLASSIFICATION: RECON, SNIPERS & MARKSMEN
    // ------------------------------------------------------------------------
    ["NATO Spotter", ["B_spotter_F"], [["Troops", 1], ["Cargo", 250]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["NATO Sniper", ["B_sniper_F"], [["Troops", 1], ["Cargo", 350]], "FOB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["NATO Sniper (Arid Ghillie)", ["B_ghillie_ard_F"], [["Troops", 1], ["Cargo", 350]], "FOB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["NATO Sniper (Semi-Arid Ghillie)", ["B_ghillie_sard_F"], [["Troops", 1], ["Cargo", 350]], "FOB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["NATO Recon Scout", ["B_recon_F"], [["Troops", 1], ["Cargo", 250]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["NATO Recon Marksman", ["B_recon_M_F"], [["Troops", 1], ["Cargo", 300]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["NATO Marksman", ["B_soldier_M_F"], [["Troops", 1], ["Cargo", 300]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["NATO Sharpshooter", ["B_Sharpshooter_F"], [["Troops", 1], ["Cargo", 300]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["NATO Recon Sharpshooter", ["B_Recon_Sharpshooter_F"], [["Troops", 1], ["Cargo", 350]], "FOB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["NATO Patrol Marksman", ["B_Patrol_Soldier_M_F"], [["Troops", 1], ["Cargo", 300]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],

    // ------------------------------------------------------------------------
    // CLASSIFICATION: COMMAND & CONTROL
    // ------------------------------------------------------------------------
    // Note: Restricted exclusively to Quartermaster (Player Recruitment)
    ["NATO Officer", ["B_officer_F"], [["Troops", 1], ["Cargo", 150]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster"]],
    ["NATO Squad Leader", ["B_Soldier_SL_F"], [["Troops", 1], ["Cargo", 200]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster"]],
    ["NATO Team Leader", ["B_Soldier_TL_F"], [["Troops", 1], ["Cargo", 200]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster"]],

    // ------------------------------------------------------------------------
    // CLASSIFICATION: MEDICAL PERSONNEL
    // ------------------------------------------------------------------------
    ["NATO Combat Life Saver", ["B_medic_F"], [["Troops", 1], ["Cargo", 250]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster"]],

    // ------------------------------------------------------------------------
    // CLASSIFICATION: ENGINEERING & REPAIR
    // ------------------------------------------------------------------------
    ["NATO Engineer", ["B_engineer_F"], [["Troops", 1], ["Cargo", 300]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster"]],
    ["NATO Repair Specialist", ["B_soldier_repair_F"], [["Troops", 1], ["Cargo", 300]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster"]],

    // ------------------------------------------------------------------------
    // CLASSIFICATION: DRONE OPERATIONS
    // ------------------------------------------------------------------------
    ["NATO UAV Operator", ["B_soldier_UAV_F"], [["Troops", 1], ["Cargo", 250]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster"]],

    // ------------------------------------------------------------------------
    // CLASSIFICATION: VEHICLE & AIR CREWS
    // ------------------------------------------------------------------------
    ["NATO Crewman", ["B_crew_F"], [["Troops", 1], ["Cargo", 150]], "ALL", "WEST", ["Mediterranean", "Desert"], ["Quartermaster"]],
    ["NATO Helicopter Pilot", ["B_Helipilot_F"], [["Troops", 1], ["Cargo", 100]], "SB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster"]],
    ["NATO Fighter Pilot", ["B_Pilot_F"], [["Troops", 1], ["Cargo", 100]], "SB", "WEST", ["Mediterranean", "Desert"], ["Quartermaster"]],

    // ------------------------------------------------------------------------
    // PRE-COMPOSED SQUADS (WORLD AI & QM COMPATIBLE)
    // ------------------------------------------------------------------------
    [
        "NATO Fireteam (4-Man)", 
        ["B_Soldier_TL_F", "B_soldier_AR_F", "B_Soldier_F", "B_soldier_LAT_F"], 
        [["Troops", 4], ["Cargo", 1050]], 
        "FOB", 
        "WEST",
        ["Mediterranean", "Desert"],
        ["Quartermaster", "WorldAI"]
    ],
    [
        "NATO Rifle Squad (8-Man)", 
        ["B_Soldier_SL_F", "B_medic_F", "B_Soldier_TL_F", "B_soldier_AR_F", "B_Soldier_F", "B_soldier_LAT_F", "B_Soldier_F", "B_Soldier_F"], 
        [["Troops", 8], ["Cargo", 2100]], 
        "SB", 
        "WEST",
        ["Mediterranean", "Desert"],
        ["Quartermaster", "WorldAI"]
    ],


    // ========================================================================
    // FACTION: OPFOR (EAST / CSAT)
    // ========================================================================

    // ------------------------------------------------------------------------
    // CLASSIFICATION: ANTI-AIR SPECIALISTS
    // ------------------------------------------------------------------------
    ["CSAT AA Specialist", ["O_Soldier_AA_F"], [["Troops", 1], ["Cargo", 350]], "FOB", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    
    // ------------------------------------------------------------------------
    // CLASSIFICATION: ANTI-TANK SPECIALISTS
    // ------------------------------------------------------------------------
    ["CSAT AT Specialist (Light)", ["O_Soldier_LAT_F"], [["Troops", 1], ["Cargo", 300]], "FOB", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["CSAT AT Specialist (Heavy)", ["O_Soldier_HAT_F"], [["Troops", 1], ["Cargo", 400]], "FOB", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["CSAT AT Specialist", ["O_Soldier_AT_F"], [["Troops", 1], ["Cargo", 350]], "FOB", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["CSAT Recon AT", ["O_recon_LAT_F"], [["Troops", 1], ["Cargo", 350]], "FOB", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["Viper AT Specialist (Hex)", ["O_V_Soldier_LAT_hex_F"], [["Troops", 1], ["Cargo", 400]], "FOB", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],

    // ------------------------------------------------------------------------
    // CLASSIFICATION: STANDARD INFANTRY
    // ------------------------------------------------------------------------
    ["CSAT Rifleman", ["O_Soldier_F"], [["Troops", 1], ["Cargo", 200]], "ALL", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["CSAT Rifleman (Lite)", ["O_Soldier_lite_F"], [["Troops", 1], ["Cargo", 150]], "ALL", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["CSAT Grenadier", ["O_Soldier_GL_F"], [["Troops", 1], ["Cargo", 250]], "ALL", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["CSAT Auto-Rifleman", ["O_Soldier_AR_F"], [["Troops", 1], ["Cargo", 250]], "ALL", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["CSAT Heavy Gunner", ["O_HeavyGunner_F"], [["Troops", 1], ["Cargo", 300]], "FOB", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["Viper Rifleman (Hex)", ["O_V_Soldier_hex_F"], [["Troops", 1], ["Cargo", 250]], "ALL", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],

    // ------------------------------------------------------------------------
    // CLASSIFICATION: RECON, SNIPERS & MARKSMEN
    // ------------------------------------------------------------------------
    ["CSAT Spotter", ["O_spotter_F"], [["Troops", 1], ["Cargo", 250]], "ALL", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["CSAT Sniper", ["O_sniper_F"], [["Troops", 1], ["Cargo", 350]], "FOB", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["CSAT Sniper (Arid Ghillie)", ["O_ghillie_ard_F"], [["Troops", 1], ["Cargo", 350]], "FOB", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["CSAT Sniper (Semi-Arid Ghillie)", ["O_ghillie_sard_F"], [["Troops", 1], ["Cargo", 350]], "FOB", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["CSAT Recon Scout", ["O_recon_F"], [["Troops", 1], ["Cargo", 250]], "ALL", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["CSAT Pathfinder", ["O_Pathfinder_F"], [["Troops", 1], ["Cargo", 300]], "ALL", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["CSAT Recon Marksman", ["O_recon_M_F"], [["Troops", 1], ["Cargo", 300]], "ALL", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["CSAT Marksman", ["O_soldier_M_F"], [["Troops", 1], ["Cargo", 300]], "ALL", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["CSAT Sharpshooter", ["O_Sharpshooter_F"], [["Troops", 1], ["Cargo", 300]], "ALL", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],
    ["Viper Marksman (Hex)", ["O_V_Soldier_M_hex_F"], [["Troops", 1], ["Cargo", 350]], "FOB", "EAST", ["Mediterranean", "Desert"], ["Quartermaster", "WorldAI"]],

    // ------------------------------------------------------------------------
    // CLASSIFICATION: COMMAND & CONTROL
    // ------------------------------------------------------------------------
    ["CSAT Officer", ["O_officer_F"], [["Troops", 1], ["Cargo", 150]], "ALL", "EAST", ["Mediterranean", "Desert"], ["Quartermaster"]],
    ["CSAT Squad Leader", ["O_Soldier_SL_F"], [["Troops", 1], ["Cargo", 200]], "ALL", "EAST", ["Mediterranean", "Desert"], ["Quartermaster"]],
    ["CSAT Team Leader", ["O_Soldier_TL_F"], [["Troops", 1], ["Cargo", 200]], "ALL", "EAST", ["Mediterranean", "Desert"], ["Quartermaster"]],

    // ------------------------------------------------------------------------
    // CLASSIFICATION: MEDICAL PERSONNEL
    // ------------------------------------------------------------------------
    ["CSAT Combat Life Saver", ["O_medic_F"], [["Troops", 1], ["Cargo", 250]], "ALL", "EAST", ["Mediterranean", "Desert"], ["Quartermaster"]],

    // ------------------------------------------------------------------------
    // CLASSIFICATION: ENGINEERING & REPAIR
    // ------------------------------------------------------------------------
    ["CSAT Engineer", ["O_engineer_F"], [["Troops", 1], ["Cargo", 300]], "ALL", "EAST", ["Mediterranean", "Desert"], ["Quartermaster"]],
    ["CSAT Repair Specialist", ["O_soldier_repair_F"], [["Troops", 1], ["Cargo", 300]], "ALL", "EAST", ["Mediterranean", "Desert"], ["Quartermaster"]],

    // ------------------------------------------------------------------------
    // CLASSIFICATION: DRONE OPERATIONS
    // ------------------------------------------------------------------------
    ["CSAT UAV Operator", ["O_soldier_UAV_F"], [["Troops", 1], ["Cargo", 250]], "ALL", "EAST", ["Mediterranean", "Desert"], ["Quartermaster"]],

    // ------------------------------------------------------------------------
    // CLASSIFICATION: VEHICLE & AIR CREWS
    // ------------------------------------------------------------------------
    ["CSAT Crewman", ["O_crew_F"], [["Troops", 1], ["Cargo", 150]], "ALL", "EAST", ["Mediterranean", "Desert"], ["Quartermaster"]],
    ["CSAT Helicopter Pilot", ["O_helipilot_F"], [["Troops", 1], ["Cargo", 100]], "SB", "EAST", ["Mediterranean", "Desert"], ["Quartermaster"]],
    ["CSAT Fighter Pilot", ["O_Pilot_F"], [["Troops", 1], ["Cargo", 100]], "SB", "EAST", ["Mediterranean", "Desert"], ["Quartermaster"]],

    // ------------------------------------------------------------------------
    // PRE-COMPOSED SQUADS (WORLD AI & QM COMPATIBLE)
    // ------------------------------------------------------------------------
    [
        "CSAT Fireteam (4-Man)", 
        ["O_Soldier_TL_F", "O_soldier_AR_F", "O_Soldier_F", "O_soldier_LAT_F"], 
        [["Troops", 4], ["Cargo", 1050]], 
        "FOB", 
        "EAST",
        ["Mediterranean", "Desert"],
        ["WorldAI"] // Explicitly World AI only based on previous templates
    ],


    // ========================================================================
    // FACTION: INDEPENDENT (GUER / AAF)
    // ========================================================================

    // ------------------------------------------------------------------------
    // CLASSIFICATION: ANTI-AIR SPECIALISTS
    // ------------------------------------------------------------------------
    ["AAF AA Specialist", ["I_Soldier_AA_F"], [["Troops", 1], ["Cargo", 350]], "FOB", "GUER", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster", "WorldAI"]],

    // ------------------------------------------------------------------------
    // CLASSIFICATION: ANTI-TANK SPECIALISTS
    // ------------------------------------------------------------------------
    ["AAF AT Specialist (Light)", ["I_Soldier_LAT_F"], [["Troops", 1], ["Cargo", 300]], "FOB", "GUER", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster", "WorldAI"]],
    ["AAF AT Specialist (MAAWS)", ["I_Soldier_LAT2_F"], [["Troops", 1], ["Cargo", 350]], "FOB", "GUER", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster", "WorldAI"]],
    ["AAF AT Specialist", ["I_Soldier_AT_F"], [["Troops", 1], ["Cargo", 350]], "FOB", "GUER", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster", "WorldAI"]],

    // ------------------------------------------------------------------------
    // CLASSIFICATION: STANDARD INFANTRY
    // ------------------------------------------------------------------------
    ["AAF Rifleman", ["I_soldier_F"], [["Troops", 1], ["Cargo", 200]], "ALL", "GUER", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster", "WorldAI"]],
    ["AAF Rifleman (Lite)", ["I_Soldier_lite_F"], [["Troops", 1], ["Cargo", 150]], "ALL", "GUER", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster", "WorldAI"]],
    ["AAF Grenadier", ["I_Soldier_GL_F"], [["Troops", 1], ["Cargo", 250]], "ALL", "GUER", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster", "WorldAI"]],
    ["AAF Auto-Rifleman", ["I_Soldier_AR_F"], [["Troops", 1], ["Cargo", 250]], "ALL", "GUER", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster", "WorldAI"]],

    // ------------------------------------------------------------------------
    // CLASSIFICATION: RECON, SNIPERS & MARKSMEN
    // ------------------------------------------------------------------------
    ["AAF Spotter", ["I_Spotter_F"], [["Troops", 1], ["Cargo", 250]], "ALL", "GUER", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster", "WorldAI"]],
    ["AAF Sniper", ["I_Sniper_F"], [["Troops", 1], ["Cargo", 350]], "FOB", "GUER", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster", "WorldAI"]],
    ["AAF Sniper (Arid Ghillie)", ["I_ghillie_ard_F"], [["Troops", 1], ["Cargo", 350]], "FOB", "GUER", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster", "WorldAI"]],
    ["AAF Sniper (Semi-Arid Ghillie)", ["I_ghillie_sard_F"], [["Troops", 1], ["Cargo", 350]], "FOB", "GUER", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster", "WorldAI"]],
    ["AAF Marksman", ["I_Soldier_M_F"], [["Troops", 1], ["Cargo", 300]], "ALL", "GUER", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster", "WorldAI"]],

    // ------------------------------------------------------------------------
    // CLASSIFICATION: COMMAND & CONTROL
    // ------------------------------------------------------------------------
    ["AAF Officer", ["I_officer_F"], [["Troops", 1], ["Cargo", 150]], "ALL", "GUER", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster"]],
    ["AAF Squad Leader", ["I_Soldier_SL_F"], [["Troops", 1], ["Cargo", 200]], "ALL", "GUER", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster"]],
    ["AAF Team Leader", ["I_Soldier_TL_F"], [["Troops", 1], ["Cargo", 200]], "ALL", "GUER", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster"]],

    // ------------------------------------------------------------------------
    // CLASSIFICATION: MEDICAL PERSONNEL
    // ------------------------------------------------------------------------
    ["AAF Combat Life Saver", ["I_medic_F"], [["Troops", 1], ["Cargo", 250]], "ALL", "GUER", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster"]],

    // ------------------------------------------------------------------------
    // CLASSIFICATION: ENGINEERING & REPAIR
    // ------------------------------------------------------------------------
    ["AAF Engineer", ["I_engineer_F"], [["Troops", 1], ["Cargo", 300]], "ALL", "GUER", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster"]],
    ["AAF Repair Specialist", ["I_soldier_repair_F"], [["Troops", 1], ["Cargo", 300]], "ALL", "GUER", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster"]],

    // ------------------------------------------------------------------------
    // CLASSIFICATION: DRONE OPERATIONS
    // ------------------------------------------------------------------------
    ["AAF UAV Operator", ["I_soldier_UAV_F"], [["Troops", 1], ["Cargo", 250]], "ALL", "GUER", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster"]],

    // ------------------------------------------------------------------------
    // CLASSIFICATION: VEHICLE & AIR CREWS
    // ------------------------------------------------------------------------
    ["AAF Crewman", ["I_crew_F"], [["Troops", 1], ["Cargo", 150]], "ALL", "GUER", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster"]],
    ["AAF Helicopter Pilot", ["I_helipilot_F"], [["Troops", 1], ["Cargo", 100]], "SB", "GUER", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster"]],
    ["AAF Fighter Pilot", ["I_pilot_F"], [["Troops", 1], ["Cargo", 100]], "SB", "GUER", ["Mediterranean", "Desert", "Woodland", "Jungle"], ["Quartermaster"]],

    // ------------------------------------------------------------------------
    // PRE-COMPOSED SQUADS (WORLD AI & QM COMPATIBLE)
    // ------------------------------------------------------------------------
    [
        "AAF Patrol (4-Man)", 
        ["I_Soldier_TL_F", "I_soldier_AR_F", "I_Soldier_F", "I_Soldier_F"], 
        [["Troops", 4], ["Cargo", 1000]], 
        "FOB", 
        "GUER",
        ["Woodland", "Jungle", "Mediterranean", "Desert"],
        ["Quartermaster", "WorldAI"]
    ]
];