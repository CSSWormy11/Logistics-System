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
    ["B_T_VTOL_01_vehicle_F", ["Strategic", "Tactical"]],                     // Blackfish (Vehicle Variant) - Heavy Container Capacity
    ["B_T_VTOL_01_infantry_F", ["Strategic", "Tactical"]],                    // Blackfish (Infantry Variant) - High Capacity (32 Troops)

    // =====================================================================
    // STRATEGIC/TACTICAL HAULERS (Bulk Hub Pipelines / Heavy Slingloaders / 16+ Troops / Front-line FOB Supply Lines / Final Mile Assets)
    // =====================================================================
    ["B_Truck_01_flatbed_F", ["Strategic", "Tactical"]],                      // HEMTT Flatbed (Sand) - Heavy Slingload Certified
    ["B_T_Truck_01_flatbed_F", ["Strategic", "Tactical"]],                    // HEMTT Flatbed (Jungle) - Heavy Slingload Certified
    
    ["B_Truck_01_transport_F", ["Strategic", "Tactical"]],                    // HEMTT Transport (Sand) - High Capacity (17 Troops)
    ["B_T_Truck_01_transport_F", ["Strategic", "Tactical"]],                  // HEMTT Transport (Jungle) - High Capacity (17 Troops)
    ["B_Truck_01_covered_F", ["Strategic", "Tactical"]],                      // HEMTT Transport (Covered - Sand) - High Capacity (17 Troops)
    ["B_T_Truck_01_covered_F", ["Strategic", "Tactical"]],                    // HEMTT Transport (Covered - Jungle) - High Capacity (17 Troops)
    
    ["B_Heli_Transport_03_F", ["Strategic", "Tactical"]],                     // Huron (Armed) - Heavy Slingload / 16 Troops
    ["B_Heli_Transport_03_unarmed_F", ["Strategic", "Tactical"]],             // Huron (Unarmed) - Heavy Slingload / 18 Troops
    
    // =====================================================================
    // TACTICAL HAULERS (Front-line FOB Supply Lines / Final Mile Assets)
    // =====================================================================
    ["B_Truck_01_cargo_F", ["Tactical", "Strategic"]],                        // HEMTT Cargo (Sand) - Medium Section Box Freight
    ["B_T_Truck_01_cargo_F", ["Tactical", "Strategic"]],                      // HEMTT Cargo (Jungle) - Medium Section Box Freight
    
    ["B_Heli_Transport_01_F", ["Tactical", "CLT"]],                           // Ghost Hawk - Medium Tactical Insertion Helicopter
    ["B_CTRG_Heli_Transport_01_sand_F", ["Tactical", "CLT"]],                 // Ghost Hawk CTRG (Sand) - Recon Section Transport
    ["B_CTRG_Heli_Transport_01_tropic_F", ["Tactical", "CLT"]],               // Ghost Hawk CTRG (Jungle) - Recon Section Transport
    ["B_Heli_Transport_01_pylons_F", ["Tactical", "CLT"]],                    // Ghost Hawk (Stub Wings) - Fire Support Escort / Lift

    // =====================================================================
    // COMBAT LOGISTICS TRANSPORT (Combat Relief Supply / Under Fire Transport)
    // =====================================================================
    ["B_LSV_01_unarmed_F", ["CLT", "Tactical"]],                              // Prowler (Sand) - Light Assault utility (6 Troops)
    ["B_LSV_01_armed_F", ["CLT"]],                                            // Prowler HMG (Sand) - Crew Combat Patrol (4 Troops)
    ["B_LSV_01_AT_F", ["CLT"]],                                               // Prowler AT (Sand) - Guided Anti-Tank Unit (4 Troops)
    ["B_T_LSV_01_unarmed_F", ["CLT", "Tactical"]],                            // Prowler (Jungle) / CTRG Unarmed - Light Utility (6 Troops)
    ["B_T_LSV_01_armed_F", ["CLT"]],                                          // Prowler HMG (Jungle) - Crew Combat Patrol (4 Troops)
    ["B_T_LSV_01_AT_F", ["CLT"]],                                             // Prowler AT (Jungle) - Guided Anti-Tank Unit (4 Troops)
    
    ["B_MRAP_01_F", ["CLT", "Tactical"]],                                     // Hunter MRAP (Sand) - Light Fireteam Protection (3 Troops)
    ["B_T_MRAP_01_F", ["CLT", "Tactical"]],                                   // Hunter MRAP (Jungle) - Light Fireteam Protection (3 Troops)
    
    ["B_Heli_Light_01_dynamicLoadout_F", ["CLT"]],                            // Pawnee Scout - Light Rapid Drop Crate Supply
    ["B_Heli_Light_01_F", ["CLT", "Tactical"]],                               // Hummingbird - Light Fireteam Inserting / Pod Freight
    
    // ------------------ LOCAL REGIONAL RESISTANCE & GEN FORCES ------------------
    ["B_G_Van_02_vehicle_F", ["Tactical"]],                                   // Van (Cargo - FIA Rebel Variant)
    ["B_GEN_Van_02_vehicle_F", ["Tactical"]],                                 // Van (Cargo - Gendarmerie Security Police)
    ["B_G_Van_02_transport_F", ["Tactical"]],                                 // Van (Transport - FIA Guerrilla Squad)
    ["B_G_Van_01_transport_F", ["Tactical"]],                                 // Truck (FIA Flatbed Troop Assembly)
    ["B_G_Offroad_01_F", ["CLT", "Tactical"]],                                // Offroad (FIA Armed/Unarmed Technical)
    ["B_GEN_Van_02_transport_F", ["Tactical"]],                               // Van (Transport - Gendarmerie Squad Deployment)
    ["B_GEN_Offroad_01_gen_F", ["CLT", "Tactical"]],                          // Offroad (Open Patrol - Gendarmerie)
    ["B_GEN_Offroad_01_comms_F", ["CLT", "Tactical"]],                        // Offroad (Comms Rig - Gendarmerie Command)
    ["B_GEN_Offroad_01_covered_F", ["CLT", "Tactical"]]                       // Offroad (Covered Crew - Gendarmerie)
];