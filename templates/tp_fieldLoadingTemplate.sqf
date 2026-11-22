// ============================================================================
// LOGISTICS SYSTEM: VEHICLE FIELD-LOADING CAPABILITY MATRIX
// File: logisticsFieldLoadingTemplate.sqf
// Description: Defines vehicle self-loading material handling equipment
//              (cranes, container winches, tailgate hoists) available in
//              austere field environments (non-loading zones).
//
// Capability Model:
// 1. Designated Base Loading Zones (Pickup Pads):
//    - Base infrastructure (forklifts, gantry cranes, ground depot crews) is present.
//    - ANY vehicle can load ANY cargo it physically fits into its cargo bay.
// 2. The Field (Austere Non-Loading Zones):
//    - ["ALL"]:
//      Vehicle is equipped with an onboard material-handling hydraulic crane
//      (e.g., RHS M1084, Russian KamAZ Crane, MTVR Crane). Can self-load ANY
//      cargo it physically fits anywhere in the field.
//    - ["Huron_Containers"]:
//      Vehicle possesses a specialized container winch / tilt-bed
//      (e.g., HEMTT Flatbed). Authorized to self-load 20ft Huron containers
//      in the field, but CANNOT self-load cargo nets, ammo boxes, or pallets.
//    - [] (Empty / Unlisted - e.g., HEMTT Cargo, Blackfish, Huron ViV, Vans, LSVs):
//      Vehicle has no self-loading equipment. In the field, it can ONLY load
//      human-liftable items:
//        * Tier 1 (<= 120 lbs): 1 player can load anywhere.
//        * Tier 2 (121 - 250 lbs): Requires at least 2 players within 12m (team-lift).
//        * Tier 3 (> 250 lbs): Prohibited in the field! Requires a Base Loading Zone.
//
// Customization & Overrides:
// - A vehicle can be granted custom capabilities via object variable:
//     _vehicle setVariable ["QM_FieldLoadingCapacity", ["ALL"], true];
// ============================================================================

logisticsFieldLoadingTemplate = [
    // ========================================================================
    // VANILLA NATO / BLUFOR
    // ========================================================================
    // HEMTT Flatbeds (Equipped with container winch/tilt-bed: Huron containers only)
    ["B_Truck_01_flatbed_F", ["Huron_Containers"]],
    ["B_T_Truck_01_flatbed_F", ["Huron_Containers"]],

    // Standard Vanilla Transports without cranes (Field loading restricted to human weight tiers)
    ["B_Truck_01_cargo_F", []],
    ["B_T_Truck_01_cargo_F", []],
    ["B_Truck_01_transport_F", []],
    ["B_T_Truck_01_transport_F", []],
    ["B_Truck_01_covered_F", []],
    ["B_T_Truck_01_covered_F", []],
    ["B_T_VTOL_01_vehicle_F", []],
    ["B_T_VTOL_01_infantry_F", []],
    ["B_Heli_Transport_03_unarmed_F", []],
    ["B_Heli_Transport_03_F", []],

    // ========================================================================
    // RHS: USAF (FMTV M1084 Material Handling Crane Trucks)
    // ========================================================================
    ["rhsusf_M1084A1R_SOV_M2_D", ["ALL"]],
    ["rhsusf_M1084A1P2_B_M2_WD_fmtv_usarmy", ["ALL"]],
    ["rhsusf_M1084A1P2_B_M2_d_fmtv_usarmy", ["ALL"]],
    ["rhsusf_M1084A1P2_WD_fmtv_usarmy", ["ALL"]],
    ["rhsusf_M1084A1P2_d_fmtv_usarmy", ["ALL"]],
    ["rhsusf_M1084A1P2_B_WD_fmtv_usarmy", ["ALL"]],
    ["rhsusf_M1084A1P2_B_d_fmtv_usarmy", ["ALL"]],

    // Standard RHS Trucks without cranes (Field loading restricted to human weight tiers)
    ["rhsusf_M1078A1P2_WD_fmtv_usarmy", []],
    ["rhsusf_M1078A1P2_d_fmtv_usarmy", []],
    ["rhsusf_M1078A1P2_B_WD_fmtv_usarmy", []],
    ["rhsusf_M1078A1P2_B_d_fmtv_usarmy", []],

    // ========================================================================
    // RHS: AFRF (Russian KamAZ / Ural Crane Trucks)
    // ========================================================================
    ["rhs_kamaz5350_crane_msv", ["ALL"]],
    ["rhs_kamaz5350_crane_vmf", ["ALL"]],
    ["rhs_kamaz5350_crane_vdv", ["ALL"]],
    ["rhs_kamaz5350_crane_vv", ["ALL"]],
    ["RHS_Ural_Crane_Base", ["ALL"]],
    ["rhs_kamaz5350_crane_base", ["ALL"]],

    // Russian Flatbeds
    ["rhs_kamaz5350_flatbed_msv", ["Huron_Containers"]],
    ["rhs_kamaz5350_flatbed_vmf", ["Huron_Containers"]],
    ["rhs_kamaz5350_flatbed_vdv", ["Huron_Containers"]],
    ["rhs_kamaz5350_flatbed_vv", ["Huron_Containers"]]
];
