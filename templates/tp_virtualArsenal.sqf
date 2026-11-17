// ============================================================================
// LOGISTICS SYSTEM: VIRTUAL ARSENAL CONFIGURATION MANIFEST
// File: virtualArsenalTemplate.sqf
// Description: Single source of truth for Virtual Arsenal whitelist items.
//              Combines comprehensive asset depth with strict Faction and 
//              Terrain array filtering for dynamic loadouts.
// ============================================================================
// TEMPLATE INDEX MAP
// ============================================================================
//
// [0] Classname (String)
// [1] Default Stock Quantity (Integer)
// [2] Side / Faction (String: "WEST", "EAST", "GUER", "ALL")
// [3] Terrain Compatibility Array (Array of Strings)
//
// ============================================================================

diag_log "QUARTERMASTER DATABASE: virtualArsenalTemplate.sqf initialization started.";

G_Allowed_Weapons = [

    // ========================================================================
    // FACTION: WEST (NATO)
    // ========================================================================
    
    // ------------------------------------------------------------------------
    // ASSAULT RIFLES - MEDITERRANEAN / DESERT
    // ------------------------------------------------------------------------
    ["arifle_MX_F", 30, "WEST", ["Mediterranean", "Desert"]],
    ["arifle_MXC_F", 30, "WEST", ["Mediterranean", "Desert"]],
    ["arifle_MXM_F", 20, "WEST", ["Mediterranean", "Desert"]],
    ["arifle_MX_GL_F", 20, "WEST", ["Mediterranean", "Desert"]],
    ["arifle_MX_SW_F", 15, "WEST", ["Mediterranean", "Desert"]],
    ["arifle_MX_Black_F", 30, "WEST", ["Mediterranean", "Desert"]],
    ["arifle_MXC_Black_F", 30, "WEST", ["Mediterranean", "Desert"]],
    ["arifle_MXM_Black_F", 20, "WEST", ["Mediterranean", "Desert"]],
    ["arifle_MX_GL_Black_F", 20, "WEST", ["Mediterranean", "Desert"]],
    ["arifle_MX_SW_Black_F", 15, "WEST", ["Mediterranean", "Desert"]],
    ["arifle_SPAR_01_blk_F", 30, "WEST", ["Mediterranean", "Desert"]],
    ["arifle_SPAR_01_snd_F", 30, "WEST", ["Mediterranean", "Desert"]],
    ["arifle_SPAR_01_GL_blk_F", 20, "WEST", ["Mediterranean", "Desert"]],
    ["arifle_SPAR_01_GL_snd_F", 20, "WEST", ["Mediterranean", "Desert"]],
    ["arifle_SPAR_02_blk_F", 15, "WEST", ["Mediterranean", "Desert"]],
    ["arifle_SPAR_02_snd_F", 15, "WEST", ["Mediterranean", "Desert"]],
    
    // ------------------------------------------------------------------------
    // ASSAULT RIFLES - WOODLAND / JUNGLE (TROPIC / KHAKI)
    // ------------------------------------------------------------------------
    ["arifle_MX_khk_F", 30, "WEST", ["Woodland", "Jungle"]],
    ["arifle_MXC_khk_F", 30, "WEST", ["Woodland", "Jungle"]],
    ["arifle_MXM_khk_F", 20, "WEST", ["Woodland", "Jungle"]],
    ["arifle_MX_GL_khk_F", 20, "WEST", ["Woodland", "Jungle"]],
    ["arifle_MX_SW_khk_F", 15, "WEST", ["Woodland", "Jungle"]],
    ["arifle_SPAR_01_khk_F", 30, "WEST", ["Woodland", "Jungle"]],
    ["arifle_SPAR_01_GL_khk_F", 20, "WEST", ["Woodland", "Jungle"]],
    ["arifle_SPAR_02_khk_F", 15, "WEST", ["Woodland", "Jungle"]],

    // ------------------------------------------------------------------------
    // MARKSMAN & SNIPER RIFLES - MEDITERRANEAN / DESERT
    // ------------------------------------------------------------------------
    ["srifle_DMR_02_F", 10, "WEST", ["Mediterranean", "Desert"]],
    ["srifle_DMR_02_camo_F", 10, "WEST", ["Mediterranean", "Desert"]],
    ["srifle_DMR_02_sniper_F", 10, "WEST", ["Mediterranean", "Desert"]],
    ["srifle_DMR_03_F", 15, "WEST", ["Mediterranean", "Desert"]],
    ["srifle_DMR_03_tan_F", 15, "WEST", ["Mediterranean", "Desert"]],
    ["srifle_DMR_03_multicam_F", 15, "WEST", ["Mediterranean", "Desert"]],
    ["srifle_EBR_F", 15, "WEST", ["Mediterranean", "Desert"]],
    ["srifle_LRR_F", 5, "WEST", ["Mediterranean", "Desert"]],
    ["srifle_LRR_camo_F", 5, "WEST", ["Mediterranean", "Desert"]],

    // ------------------------------------------------------------------------
    // MARKSMAN & SNIPER RIFLES - WOODLAND / JUNGLE
    // ------------------------------------------------------------------------
    ["srifle_DMR_03_khaki_F", 15, "WEST", ["Woodland", "Jungle"]],
    ["srifle_DMR_03_woodland_F", 15, "WEST", ["Woodland", "Jungle"]],
    ["srifle_LRR_tna_F", 5, "WEST", ["Woodland", "Jungle"]],

    // ------------------------------------------------------------------------
    // MACHINE GUNS & SMGS - ALL TERRAINS
    // ------------------------------------------------------------------------
    ["MMG_02_black_F", 10, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["MMG_02_camo_F", 10, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["MMG_02_sand_F", 10, "WEST", ["Mediterranean", "Desert"]],
    ["SMG_01_F", 20, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["arifle_SDAR_F", 20, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]], // Universal Underwater Rifle

    // ------------------------------------------------------------------------
    // HANDGUNS - ALL TERRAINS
    // ------------------------------------------------------------------------
    ["hgun_P07_F", 30, "WEST", ["Mediterranean", "Desert"]],
    ["hgun_P07_blk_F", 30, "WEST", ["Mediterranean", "Desert"]],
    ["hgun_P07_khk_F", 30, "WEST", ["Woodland", "Jungle"]],
    ["hgun_Pistol_heavy_01_F", 20, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["hgun_Pistol_heavy_01_green_F", 20, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],

    // ------------------------------------------------------------------------
    // LAUNCHERS - MEDITERRANEAN / DESERT
    // ------------------------------------------------------------------------
    ["launch_B_Titan_F", 10, "WEST", ["Mediterranean", "Desert"]],
    ["launch_B_Titan_short_F", 10, "WEST", ["Mediterranean", "Desert"]],
    ["launch_MRAWS_sand_F", 15, "WEST", ["Mediterranean", "Desert"]],
    ["launch_MRAWS_sand_rail_F", 15, "WEST", ["Mediterranean", "Desert"]],

    // ------------------------------------------------------------------------
    // LAUNCHERS - WOODLAND / JUNGLE
    // ------------------------------------------------------------------------
    ["launch_B_Titan_olive_F", 10, "WEST", ["Woodland", "Jungle"]],
    ["launch_B_Titan_tna_F", 10, "WEST", ["Woodland", "Jungle"]],
    ["launch_B_Titan_short_tna_F", 10, "WEST", ["Woodland", "Jungle"]],
    ["launch_MRAWS_green_F", 15, "WEST", ["Woodland", "Jungle"]],
    ["launch_MRAWS_green_rail_F", 15, "WEST", ["Woodland", "Jungle"]],
    ["launch_MRAWS_olive_F", 15, "WEST", ["Woodland", "Jungle"]],
    ["launch_MRAWS_olive_rail_F", 15, "WEST", ["Woodland", "Jungle"]],

    // ------------------------------------------------------------------------
    // LAUNCHERS - UNIVERSAL
    // ------------------------------------------------------------------------
    ["launch_NLAW_F", 20, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],


    // ========================================================================
    // FACTION: EAST (CSAT)
    // ========================================================================
    ["arifle_Katiba_F", 30, "EAST", ["Mediterranean", "Desert"]],
    ["arifle_CTAR_hex_F", 30, "EAST", ["Mediterranean", "Desert"]],
    ["arifle_CTAR_ghex_F", 30, "EAST", ["Woodland", "Jungle"]],
    ["launch_O_Titan_short_F", 10, "EAST", ["Mediterranean", "Desert"]],
    ["launch_RPG32_F", 20, "EAST", ["Mediterranean", "Desert"]],
    ["launch_RPG32_ghex_F", 20, "EAST", ["Woodland", "Jungle"]],


    // ========================================================================
    // FACTION: GUER (INDEPENDENT)
    // ========================================================================
    ["arifle_Mk20_F", 30, "GUER", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["arifle_Mk20_GL_F", 20, "GUER", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["launch_I_Titan_F", 10, "GUER", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["launch_I_Titan_short_F", 10, "GUER", ["Woodland", "Jungle", "Mediterranean", "Desert"]]
];


G_Allowed_Magazines = [
    // ========================================================================
    // CATEGORY: AMMUNITION (ALL AMMO IS UNIVERSAL TERRAIN TO PREVENT ERRORS)
    // ========================================================================
    
    // ------------------------------------------------------------------------
    // WEST AMMUNITION
    // ------------------------------------------------------------------------
    ["30Rnd_65x39_caseless_mag", 200, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["30Rnd_65x39_caseless_mag_Tracer", 200, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["30Rnd_65x39_caseless_black_mag", 200, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["30Rnd_65x39_caseless_khaki_mag", 200, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["100Rnd_65x39_caseless_mag", 100, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["100Rnd_65x39_caseless_black_mag", 100, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["100Rnd_65x39_caseless_khaki_mag", 100, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["30Rnd_556x45_Stanag_red", 200, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["30Rnd_556x45_Stanag_Sand_red", 200, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["150Rnd_556x45_Drum_Mag_F", 50, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["150Rnd_556x45_Drum_Sand_Mag_F", 50, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["150Rnd_556x45_Drum_Green_Mag_F", 50, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["20Rnd_762x51_Mag", 100, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["10Rnd_338_Mag", 100, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["130Rnd_338_Mag", 50, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["7Rnd_408_Mag", 100, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["16Rnd_9x21_Mag", 100, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["30Rnd_45ACP_Mag_SMG_01", 100, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["11Rnd_45ACP_Mag", 100, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["20Rnd_556x45_UW_mag", 100, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]], // SDAR Mag
    ["MRAWS_HEAT_F", 40, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["MRAWS_HE_F", 40, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["NLAW_F", 20, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["Titan_AA", 20, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["Titan_AT", 20, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["Titan_AP", 20, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],

    // ------------------------------------------------------------------------
    // EAST & GUER AMMUNITION
    // ------------------------------------------------------------------------
    ["30Rnd_65x39_caseless_green", 200, "EAST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["30Rnd_580x42_mag_F", 200, "EAST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["20Rnd_650x39_Cased_Mag_F", 100, "EAST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["30Rnd_9x21_Green_Mag", 100, "GUER", ["Woodland", "Jungle", "Mediterranean", "Desert"]],

    // ------------------------------------------------------------------------
    // GRENADES, FLARES & EXPLOSIVES (UNIVERSAL FACTION - "ALL")
    // ------------------------------------------------------------------------
    ["1Rnd_HE_Grenade_shell", 100, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["3Rnd_HE_Grenade_shell", 50, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["1Rnd_Smoke_Grenade_shell", 100, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["1Rnd_SmokeRed_Grenade_shell", 50, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["1Rnd_SmokeGreen_Grenade_shell", 50, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["1Rnd_SmokeBlue_Grenade_shell", 50, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["UGL_FlareWhite_F", 50, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["UGL_FlareRed_F", 50, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["UGL_FlareGreen_F", 50, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["HandGrenade", 150, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["MiniGrenade", 150, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["SmokeShell", 150, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["SmokeShellRed", 50, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["SmokeShellGreen", 50, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["SmokeShellBlue", 50, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["SmokeShellPurple", 50, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["SmokeShellOrange", 50, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["SmokeShellYellow", 50, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["B_IR_Grenade", 50, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["Chemlight_green", 100, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    
    // ------------------------------------------------------------------------
    // MINES & DEMOLITIONS (UNIVERSAL FACTION - "ALL")
    // ------------------------------------------------------------------------
    ["DemoCharge_Remote_Mag", 30, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["SatchelCharge_Remote_Mag", 15, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["ClaymoreDirectionalMine_Remote_Mag", 20, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["SLAMDirectionalMine_Wire_Mag", 20, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["ATMine_Range_Mag", 20, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["APERSMine_Range_Mag", 20, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["APERSBoundingMine_Range_Mag", 20, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["APERSTripMine_Wire_Mag", 20, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["APERSMineDispenser_Mag", 10, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]]
];


G_Allowed_Items = [
    // ========================================================================
    // CATEGORY: UNIFORMS, VESTS & HEADGEAR (WEST)
    // ========================================================================
    
    // ------------------------------------------------------------------------
    // UNIFORMS - MEDITERRANEAN / DESERT
    // ------------------------------------------------------------------------
    ["U_B_CombatUniform_mcam", 50, "WEST", ["Mediterranean", "Desert"]],
    ["U_B_CombatUniform_mcam_tshirt", 50, "WEST", ["Mediterranean", "Desert"]],
    ["U_B_CombatUniform_mcam_vest", 50, "WEST", ["Mediterranean", "Desert"]],
    ["U_B_CTRG_1", 30, "WEST", ["Mediterranean", "Desert"]],
    ["U_B_CTRG_2", 30, "WEST", ["Mediterranean", "Desert"]],
    ["U_B_CTRG_3", 30, "WEST", ["Mediterranean", "Desert"]],
    ["U_B_CTRG_Soldier_Arid_F", 30, "WEST", ["Mediterranean", "Desert"]],
    ["U_B_CTRG_Soldier_2_Arid_F", 30, "WEST", ["Mediterranean", "Desert"]],
    ["U_B_CTRG_Soldier_3_Arid_F", 30, "WEST", ["Mediterranean", "Desert"]],
    ["U_B_FullGhillie_ard", 5, "WEST", ["Mediterranean", "Desert"]],
    ["U_B_FullGhillie_sard", 5, "WEST", ["Mediterranean", "Desert"]],
    ["U_B_GhillieSuit", 10, "WEST", ["Mediterranean", "Desert"]],

    // ------------------------------------------------------------------------
    // UNIFORMS - WOODLAND / JUNGLE
    // ------------------------------------------------------------------------
    ["U_B_T_Soldier_F", 50, "WEST", ["Woodland", "Jungle"]],
    ["U_B_T_Soldier_AR_F", 50, "WEST", ["Woodland", "Jungle"]],
    ["U_B_T_Soldier_SL_F", 50, "WEST", ["Woodland", "Jungle"]],
    ["U_B_CTRG_Soldier_F", 30, "WEST", ["Woodland", "Jungle"]],
    ["U_B_CTRG_Soldier_2_F", 30, "WEST", ["Woodland", "Jungle"]],
    ["U_B_CTRG_Soldier_3_F", 30, "WEST", ["Woodland", "Jungle"]],
    ["U_B_CombatUniform_mcam_wdl_f", 50, "WEST", ["Woodland", "Jungle"]],
    ["U_B_CombatUniform_tshirt_mcam_wdL_f", 50, "WEST", ["Woodland", "Jungle"]],
    ["U_B_CombatUniform_vest_mcam_wdl_f", 50, "WEST", ["Woodland", "Jungle"]],
    ["U_B_FullGhillie_lsh", 5, "WEST", ["Woodland", "Jungle"]],
    ["U_B_T_Sniper_F", 5, "WEST", ["Woodland", "Jungle"]],
    ["U_B_T_FullGhillie_tna_F", 5, "WEST", ["Woodland", "Jungle"]],
    
    // ------------------------------------------------------------------------
    // UNIFORMS - SPECIALTY (ALL TERRAINS)
    // ------------------------------------------------------------------------
    ["U_B_Wetsuit", 10, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["U_B_HeliPilotCoveralls", 10, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["U_B_PilotCoveralls", 10, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["U_B_CBRN_Suit_01_MTP_F", 10, "WEST", ["Mediterranean", "Desert"]],
    ["U_B_CBRN_Suit_01_Tropic_F", 10, "WEST", ["Woodland", "Jungle"]],
    ["U_B_CBRN_Suit_01_Wdl_F", 10, "WEST", ["Woodland", "Jungle"]],

    // ------------------------------------------------------------------------
    // VESTS - MEDITERRANEAN / DESERT
    // ------------------------------------------------------------------------
    ["V_PlateCarrier1_blk", 30, "WEST", ["Mediterranean", "Desert"]],
    ["V_PlateCarrier2_blk", 30, "WEST", ["Mediterranean", "Desert"]],
    ["V_PlateCarrierSpec_blk", 15, "WEST", ["Mediterranean", "Desert"]],
    ["V_PlateCarrierGL_blk", 15, "WEST", ["Mediterranean", "Desert"]],
    ["V_PlateCarrierSpec_mtp", 15, "WEST", ["Mediterranean", "Desert"]],
    ["V_PlateCarrierGL_mtp", 15, "WEST", ["Mediterranean", "Desert"]],
    ["V_PlateCarrierH_CTRG", 20, "WEST", ["Mediterranean", "Desert"]],
    ["V_PlateCarrierL_CTRG", 20, "WEST", ["Mediterranean", "Desert"]],
    ["V_TacVest_blk", 30, "WEST", ["Mediterranean", "Desert"]],
    ["V_TacVest_brn", 30, "WEST", ["Mediterranean", "Desert"]],
    ["V_TacVest_camo", 30, "WEST", ["Mediterranean", "Desert"]],
    ["V_TacVest_khk", 30, "WEST", ["Mediterranean", "Desert"]],

    // ------------------------------------------------------------------------
    // VESTS - WOODLAND / JUNGLE
    // ------------------------------------------------------------------------
    ["V_PlateCarrier1_tna_F", 50, "WEST", ["Woodland", "Jungle"]],
    ["V_PlateCarrier2_tna_F", 50, "WEST", ["Woodland", "Jungle"]],
    ["V_PlateCarrierSpec_tna_F", 15, "WEST", ["Woodland", "Jungle"]],
    ["V_PlateCarrierGL_tna_F", 15, "WEST", ["Woodland", "Jungle"]],
    ["V_PlateCarrier1_wdl", 50, "WEST", ["Woodland", "Jungle"]],
    ["V_PlateCarrier2_wdl", 50, "WEST", ["Woodland", "Jungle"]],
    ["V_PlateCarrierSpec_wdl", 15, "WEST", ["Woodland", "Jungle"]],
    ["V_PlateCarrierGL_wdl", 15, "WEST", ["Woodland", "Jungle"]],
    ["V_TacVest_oli", 30, "WEST", ["Woodland", "Jungle"]],

    // ------------------------------------------------------------------------
    // VESTS - UNIVERSAL (RANGER GREEN / UTILITY)
    // ------------------------------------------------------------------------
    ["V_PlateCarrier1_rgr", 50, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["V_PlateCarrier2_rgr", 50, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["V_PlateCarrierSpec_rgr", 15, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["V_PlateCarrierGL_rgr", 15, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["V_RebreatherB", 10, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["V_LegStrapBag_black_F", 20, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["V_LegStrapBag_coyote_F", 20, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],

    // ------------------------------------------------------------------------
    // HEADGEAR - MEDITERRANEAN / DESERT
    // ------------------------------------------------------------------------
    ["H_HelmetB", 50, "WEST", ["Mediterranean", "Desert"]],
    ["H_HelmetB_camo", 50, "WEST", ["Mediterranean", "Desert"]],
    ["H_HelmetB_desert", 50, "WEST", ["Mediterranean", "Desert"]],
    ["H_HelmetB_sand", 50, "WEST", ["Mediterranean", "Desert"]],
    ["H_HelmetB_light", 30, "WEST", ["Mediterranean", "Desert"]],
    ["H_HelmetB_light_desert", 30, "WEST", ["Mediterranean", "Desert"]],
    ["H_HelmetB_light_sand", 30, "WEST", ["Mediterranean", "Desert"]],
    ["H_HelmetSpecB", 20, "WEST", ["Mediterranean", "Desert"]],
    ["H_HelmetSpecB_sand", 20, "WEST", ["Mediterranean", "Desert"]],
    ["H_HelmetB_black", 30, "WEST", ["Mediterranean", "Desert"]],
    ["H_HelmetSpecB_blk", 20, "WEST", ["Mediterranean", "Desert"]],
    ["H_Booniehat_mcamo", 20, "WEST", ["Mediterranean", "Desert"]],
    ["H_Booniehat_tan", 20, "WEST", ["Mediterranean", "Desert"]],

    // ------------------------------------------------------------------------
    // HEADGEAR - WOODLAND / JUNGLE
    // ------------------------------------------------------------------------
    ["H_HelmetB_tna_F", 50, "WEST", ["Woodland", "Jungle"]],
    ["H_HelmetB_Enh_tna_F", 50, "WEST", ["Woodland", "Jungle"]],
    ["H_HelmetB_Light_tna_F", 30, "WEST", ["Woodland", "Jungle"]],
    ["H_HelmetB_TI_tna_F", 10, "WEST", ["Woodland", "Jungle"]],
    ["H_HelmetB_grass", 50, "WEST", ["Woodland", "Jungle"]],
    ["H_HelmetB_light_grass", 30, "WEST", ["Woodland", "Jungle"]],
    ["H_HelmetB_plain_wdl", 50, "WEST", ["Woodland", "Jungle"]],
    ["H_HelmetSpecB_wdl", 20, "WEST", ["Woodland", "Jungle"]],
    ["H_Booniehat_tna_F", 20, "WEST", ["Woodland", "Jungle"]],
    ["H_Booniehat_wdl", 20, "WEST", ["Woodland", "Jungle"]],
    ["H_Booniehat_oli", 20, "WEST", ["Woodland", "Jungle"]],

    // ------------------------------------------------------------------------
    // HEADGEAR - UNIVERSAL & SPECIALTY
    // ------------------------------------------------------------------------
    ["H_PilotHelmetFighter_B", 10, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["H_PilotHelmetHeli_B", 10, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["H_CrewHelmetHeli_B", 10, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["H_HelmetCrew_B", 10, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["H_Watchcap_blk", 20, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["H_MilCap_mcamo", 20, "WEST", ["Mediterranean", "Desert"]],
    ["H_MilCap_tna_F", 20, "WEST", ["Woodland", "Jungle"]],


    // ========================================================================
    // CATEGORY: OPTICS, ATTACHMENTS & GEAR (UNIVERSAL FACTION - "ALL")
    // ========================================================================
    // Placing these in the "ALL" faction prevents Arsenal lookup bugs if a 
    // player switches uniforms or picks up a weapon dropped by a different side.
    
    // ------------------------------------------------------------------------
    // OPTICS - MEDITERRANEAN / DESERT
    // ------------------------------------------------------------------------
    ["optic_Holosight_arid_F", 30, "ALL", ["Mediterranean", "Desert"]],
    ["optic_Holosight_blk_F", 30, "ALL", ["Mediterranean", "Desert"]],
    ["optic_Holosight_smg_blk_F", 30, "ALL", ["Mediterranean", "Desert"]],
    ["optic_ERCO_blk_F", 20, "ALL", ["Mediterranean", "Desert"]],
    ["optic_ERCO_snd_F", 20, "ALL", ["Mediterranean", "Desert"]],
    ["optic_AMS_snd", 10, "ALL", ["Mediterranean", "Desert"]],

    // ------------------------------------------------------------------------
    // OPTICS - WOODLAND / JUNGLE
    // ------------------------------------------------------------------------
    ["optic_Holosight_khk_F", 30, "ALL", ["Woodland", "Jungle"]],
    ["optic_Holosight_lush_F", 30, "ALL", ["Woodland", "Jungle"]],
    ["optic_Holosight_smg_khk_F", 30, "ALL", ["Woodland", "Jungle"]],
    ["optic_ERCO_khk_F", 20, "ALL", ["Woodland", "Jungle"]],
    ["optic_Hamr_khk_F", 20, "ALL", ["Woodland", "Jungle"]],
    ["optic_AMS_khk", 10, "ALL", ["Woodland", "Jungle"]],
    ["optic_SOS_khk_F", 10, "ALL", ["Woodland", "Jungle"]],
    ["optic_LRPS_tna_F", 10, "ALL", ["Woodland", "Jungle"]],

    // ------------------------------------------------------------------------
    // OPTICS - UNIVERSAL (STANDARD BLACK / DEFAULT)
    // ------------------------------------------------------------------------
    ["optic_Aco", 40, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["optic_Aco_smg", 40, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["optic_Holosight", 40, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["optic_Holosight_smg", 40, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["optic_Hamr", 20, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["optic_MRD", 30, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["optic_MRD_black", 30, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["optic_DMS", 15, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["optic_SOS", 10, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["optic_LRPS", 10, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["optic_AMS", 10, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["optic_NVS", 5, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["optic_tws", 5, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["optic_tws_mg", 5, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],

    // ------------------------------------------------------------------------
    // SUPPRESSORS & MUZZLES (UNIVERSAL COMPATIBILITY)
    // ------------------------------------------------------------------------
    ["muzzle_snds_acp", 20, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["muzzle_snds_L", 20, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["muzzle_snds_M", 20, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["muzzle_snds_m_snd_F", 20, "ALL", ["Mediterranean", "Desert"]],
    ["muzzle_snds_m_khk_F", 20, "ALL", ["Woodland", "Jungle"]],
    ["muzzle_snds_H", 20, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["muzzle_snds_H_snd_F", 20, "ALL", ["Mediterranean", "Desert"]],
    ["muzzle_snds_H_khk_F", 20, "ALL", ["Woodland", "Jungle"]],
    ["muzzle_snds_B", 20, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["muzzle_snds_B_arid_F", 20, "ALL", ["Mediterranean", "Desert"]],
    ["muzzle_snds_B_snd_F", 20, "ALL", ["Mediterranean", "Desert"]],
    ["muzzle_snds_B_lush_F", 20, "ALL", ["Woodland", "Jungle"]],
    ["muzzle_snds_B_khk_F", 20, "ALL", ["Woodland", "Jungle"]],
    ["muzzle_snds_338_black", 10, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["muzzle_snds_338_sand", 10, "ALL", ["Mediterranean", "Desert"]],
    ["muzzle_snds_338_green", 10, "ALL", ["Woodland", "Jungle"]],

    // ------------------------------------------------------------------------
    // POINTERS & BIPODS
    // ------------------------------------------------------------------------
    ["acc_flashlight", 40, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["acc_flashlight_pistol", 40, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["acc_flashlight_smg_01", 40, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["acc_pointer_IR", 40, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["bipod_01_F_blk", 20, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["bipod_01_F_mtp", 20, "ALL", ["Mediterranean", "Desert"]],
    ["bipod_01_F_snd", 20, "ALL", ["Mediterranean", "Desert"]],
    ["bipod_01_F_khk", 20, "ALL", ["Woodland", "Jungle"]],

    // ------------------------------------------------------------------------
    // FACEWEAR & GOGGLES
    // ------------------------------------------------------------------------
    ["G_Combat", 50, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["G_Combat_Goggles_tna_F", 50, "ALL", ["Woodland", "Jungle"]],
    ["G_Lowprofile", 50, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["G_Tactical_Black", 30, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["G_Tactical_Clear", 30, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["G_Balaclava_blk", 20, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["G_Balaclava_oli", 20, "ALL", ["Woodland", "Jungle"]],
    ["G_Balaclava_TI_blk_F", 10, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["G_B_Diving", 10, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["G_AirPurifyingRespirator_01_F", 10, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],

    // ------------------------------------------------------------------------
    // TOOLS, NAV & MEDICAL
    // ------------------------------------------------------------------------
    ["ItemMap", 100, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["ItemCompass", 100, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["ItemWatch", 100, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["ItemRadio", 100, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["ItemGPS", 50, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["B_UavTerminal", 15, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]], // Keep UAV Terminals Faction-Specific
    ["NVGoggles", 50, "ALL", ["Mediterranean", "Desert"]],
    ["NVGoggles_tna_F", 50, "ALL", ["Woodland", "Jungle"]],
    ["NVGogglesB_blk_F", 20, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["Binocular", 50, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["Rangefinder", 20, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["Laserdesignator", 10, "ALL", ["Mediterranean", "Desert"]],
    ["Laserdesignator_01_khk_F", 10, "ALL", ["Woodland", "Jungle"]],
    ["Laserbatteries", 50, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["FirstAidKit", 200, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["Medikit", 20, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["ToolKit", 20, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["MineDetector", 15, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]]
];


G_Allowed_Backpacks = [
    // ========================================================================
    // CATEGORY: BACKPACKS
    // ========================================================================
    
    // ------------------------------------------------------------------------
    // BACKPACKS - MEDITERRANEAN / DESERT
    // ------------------------------------------------------------------------
    ["B_AssaultPack_mcamo", 40, "WEST", ["Mediterranean", "Desert"]],
    ["B_AssaultPack_cbr", 40, "WEST", ["Mediterranean", "Desert"]],
    ["B_Kitbag_mcamo", 30, "WEST", ["Mediterranean", "Desert"]],
    ["B_Kitbag_cbr", 30, "WEST", ["Mediterranean", "Desert"]],
    ["B_Kitbag_tan", 30, "WEST", ["Mediterranean", "Desert"]],
    ["B_TacticalPack_mcamo", 20, "WEST", ["Mediterranean", "Desert"]],
    ["B_Carryall_mcamo", 15, "WEST", ["Mediterranean", "Desert"]],
    ["B_Carryall_cbr", 15, "WEST", ["Mediterranean", "Desert"]],
    ["B_Bergen_mcamo_F", 5, "WEST", ["Mediterranean", "Desert"]],
    ["B_RadioBag_01_mtp_F", 10, "WEST", ["Mediterranean", "Desert"]],

    // ------------------------------------------------------------------------
    // BACKPACKS - WOODLAND / JUNGLE
    // ------------------------------------------------------------------------
    ["B_AssaultPack_tna_F", 40, "WEST", ["Woodland", "Jungle"]],
    ["B_AssaultPack_wdl_F", 40, "WEST", ["Woodland", "Jungle"]],
    ["B_Kitbag_rgr", 30, "WEST", ["Woodland", "Jungle"]], // Ranger Green
    ["B_TacticalPack_oli", 20, "WEST", ["Woodland", "Jungle"]],
    ["B_TacticalPack_rgr", 20, "WEST", ["Woodland", "Jungle"]],
    ["B_Carryall_oli", 15, "WEST", ["Woodland", "Jungle"]],
    ["B_Carryall_green_F", 15, "WEST", ["Woodland", "Jungle"]],
    ["B_Carryall_wdl_F", 15, "WEST", ["Woodland", "Jungle"]],
    ["B_Bergen_tna_F", 5, "WEST", ["Woodland", "Jungle"]],
    ["B_RadioBag_01_tropic_F", 10, "WEST", ["Woodland", "Jungle"]],
    ["B_RadioBag_01_wdl_F", 10, "WEST", ["Woodland", "Jungle"]],

    // ------------------------------------------------------------------------
    // BACKPACKS - UNIVERSAL / BLACK / SPECIALTY
    // ------------------------------------------------------------------------
    ["B_AssaultPack_blk", 40, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["B_TacticalPack_blk", 20, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["B_Carryall_blk", 15, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["B_Parachute", 50, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["B_LegStrapBag_black_F", 20, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["B_LegStrapBag_coyote_F", 20, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["B_LegStrapBag_olive_F", 20, "ALL", ["Woodland", "Jungle", "Mediterranean", "Desert"]],

    // ------------------------------------------------------------------------
    // SUPPORT & STATIC WEAPON BAGS (UNIVERSAL TERRAIN)
    // ------------------------------------------------------------------------
    ["B_UAV_01_backpack_F", 5, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["B_UAV_06_backpack_F", 5, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["B_UAV_06_medical_backpack_F", 5, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["B_UGV_02_Demining_backpack_F", 5, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["B_HMG_01_weapon_F", 5, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["B_HMG_01_support_F", 5, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["B_HMG_01_high_weapon_F", 5, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["B_HMG_01_support_high_F", 5, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["B_GMG_01_weapon_F", 5, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["B_Mortar_01_weapon_F", 5, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["B_Mortar_01_support_F", 5, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["B_AT_01_weapon_F", 5, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]],
    ["B_AA_01_weapon_F", 5, "WEST", ["Woodland", "Jungle", "Mediterranean", "Desert"]]
];