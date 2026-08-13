// ============================================================================
// LOGISTICS SYSTEM: VEHICLE ROLE ASSIGNMENT DATABASE (PART 1)
// File: logisticsVehicleRoles.sqf
// Description: Defines strategic/tactical classifications for logistics vehicles.
//              Used for base restriction checks and route filtering.
//              *UPDATED*: Roles are now prioritized arrays.
// Called By: init.sqf (Compiled during server/master initialization)
// ============================================================================

// Allowed Roles: 
//   - "Strategic" : Defaults strictly to MSR -> Staging Base bulk supply lines
//   - "Tactical"  : Defaults strictly to Staging Base -> Frontline FOB distribution
//   - "CLT"       : Combat Logistics Transport (Reactive extraction/insertion)

logisticsVehicleRoles = [
    // =====================================================================
    // STRATEGIC HAULERS (Bulk Hub Pipelines / Heavy Slingloaders / 16+ Troops)
    // =====================================================================
    ["B_T_VTOL_01_vehicle_F", ["Strategic", "Tactical", "CLT"]],             // Blackfish (Vehicle Variant) - Heavy Container Capacity
    ["B_T_VTOL_01_infantry_F", ["Strategic", "Tactical", "CLT"]],            // Blackfish (Infantry Variant) - High Capacity (32 Troops)

    // =====================================================================
    // STRATEGIC/TACTICAL HAULERS (Bulk Hub Pipelines / Heavy Slingloaders / 16+ Troops / Front-line FOB Supply Lines / Final Mile Assets)
    // =====================================================================
    ["B_Truck_01_flatbed_F", ["Tactical", "Strategic", "CLT"]],              // HEMTT Flatbed (Sand) - Heavy Slingload Certified
    ["B_T_Truck_01_flatbed_F", ["Tactical", "Strategic", "CLT"]],            // HEMTT Flatbed (Jungle) - Heavy Slingload Certified
    
    ["B_Truck_01_transport_F", ["Tactical", "Strategic", "CLT"]],            // HEMTT Transport (Sand) - High Capacity (17 Troops)
    ["B_T_Truck_01_transport_F", ["Tactical", "Strategic", "CLT"]],          // HEMTT Transport (Jungle) - High Capacity (17 Troops)
    ["B_Truck_01_covered_F", ["Tactical", "Strategic", "CLT"]],              // HEMTT Transport (Covered - Sand) - High Capacity (17 Troops)
    ["B_T_Truck_01_covered_F", ["Tactical", "Strategic", "CLT"]],            // HEMTT Transport (Covered - Jungle) - High Capacity (17 Troops)
    
    ["B_Heli_Transport_03_F", ["Tactical", "Strategic", "CLT"]],             // Huron (Armed) - Heavy Slingload / 16 Troops
    ["B_Heli_Transport_03_unarmed_F", ["Tactical", "Strategic", "CLT"]],     // Huron (Unarmed) - Heavy Slingload / 18 Troops
    
    // =====================================================================
    // TACTICAL HAULERS (Front-line FOB Supply Lines / Final Mile Assets)
    // =====================================================================
    ["B_Truck_01_cargo_F", ["Tactical", "CLT", "Strategic"]],                             // HEMTT Cargo (Sand) - Medium Section Box Freight
    ["B_T_Truck_01_cargo_F", ["Tactical", "CLT", "Strategic"]],                           // HEMTT Cargo (Jungle) - Medium Section Box Freight
    
    ["B_Heli_Transport_01_F", ["Tactical", "CLT", "Strategic"]],                          // Ghost Hawk - Medium Tactical Insertion Helicopter
    ["B_CTRG_Heli_Transport_01_sand_F", ["Tactical", "CLT", "Strategic"]],                // Ghost Hawk CTRG (Sand) - Recon Section Transport
    ["B_CTRG_Heli_Transport_01_tropic_F", ["Tactical", "CLT", "Strategic"]],              // Ghost Hawk CTRG (Jungle) - Recon Section Transport
    ["B_Heli_Transport_01_pylons_F", ["Tactical", "CLT", "Strategic"]],                   // Ghost Hawk (Stub Wings) - Fire Support Escort / Lift

    // =====================================================================
    // COMBAT LOGISTICS TRANSPORT (Combat Relief Supply / Under Fire Transport)
    // =====================================================================
    ["B_LSV_01_unarmed_F", ["CLT", "Tactical", "Strategic"]],                             // Prowler (Sand) - Light Assault utility (6 Troops)
    ["B_LSV_01_armed_F", ["CLT", "Tactical", "Strategic"]],                               // Prowler HMG (Sand) - Crew Combat Patrol (4 Troops)
    ["B_LSV_01_AT_F", ["CLT", "Tactical", "Strategic"]],                                  // Prowler AT (Sand) - Guided Anti-Tank Unit (4 Troops)
    ["B_T_LSV_01_unarmed_F", ["CLT", "Tactical", "Strategic"]],                           // Prowler (Jungle) / CTRG Unarmed - Light Utility (6 Troops)
    ["B_T_LSV_01_armed_F", ["CLT", "Tactical", "Strategic"]],                             // Prowler HMG (Jungle) - Crew Combat Patrol (4 Troops)
    ["B_T_LSV_01_AT_F", ["CLT", "Tactical", "Strategic"]],                                // Prowler AT (Jungle) - Guided Anti-Tank Unit (4 Troops)
    
    ["B_MRAP_01_F", ["CLT", "Tactical", "Strategic"]],                                    // Hunter MRAP (Sand) - Light Fireteam Protection (3 Troops)
    ["B_T_MRAP_01_F", ["CLT", "Tactical", "Strategic"]],                                  // Hunter MRAP (Jungle) - Light Fireteam Protection (3 Troops)
    
    ["B_Heli_Light_01_dynamicLoadout_F", ["CLT", "Tactical", "Strategic"]],               // Pawnee Scout - Light Rapid Drop Crate Supply
    ["B_Heli_Light_01_F", ["CLT", "Tactical", "Strategic"]],                              // Hummingbird - Light Fireteam Inserting / Pod Freight
    
    // ------------------ LOCAL REGIONAL RESISTANCE & GEN FORCES ------------------
    ["B_G_Van_02_vehicle_F", ["Tactical", "CLT", "Strategic"]],                           // Van (Cargo - FIA Rebel Variant)
    ["B_GEN_Van_02_vehicle_F", ["Tactical", "CLT", "Strategic"]],                         // Van (Cargo - Gendarmerie Security Police)
    ["B_G_Van_02_transport_F", ["Tactical", "CLT", "Strategic"]],                         // Van (Transport - FIA Guerrilla Squad)
    ["B_G_Van_01_transport_F", ["Tactical", "CLT", "Strategic"]],                         // Truck (FIA Flatbed Troop Assembly)
    ["B_G_Offroad_01_F", ["CLT", "Tactical", "Strategic"]],                               // Offroad (FIA Armed/Unarmed Technical)
    ["B_GEN_Van_02_transport_F", ["Tactical", "CLT", "Strategic"]],                       // Van (Transport - Gendarmerie Squad Deployment)
    ["B_GEN_Offroad_01_gen_F", ["CLT", "Tactical", "Strategic"]],                         // Offroad (Open Patrol - Gendarmerie)
    ["B_GEN_Offroad_01_comms_F", ["CLT", "Tactical", "Strategic"]],                       // Offroad (Comms Rig - Gendarmerie Command)
    ["B_GEN_Offroad_01_covered_F", ["CLT", "Tactical", "Strategic"]]                      // Offroad (Covered Crew - Gendarmerie)
];