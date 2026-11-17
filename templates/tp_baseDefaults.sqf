// ============================================================================
// LOGISTICS SYSTEM: BASE DEFAULTS CONFIGURATION (PART 1)
// File: logisticsBaseDefaults.sqf
// Description: Defines the starting economy limits for different base types.
//              MSR (Main Supply Route) hubs have infinite (-1) resources.
//              SB (Supply Bases) and FOBs have finite starting pools.
// Called By: init.sqf (Compiled during server/master initialization)
// ============================================================================

// Format: [BaseType, [[Category, DefaultValue], ...]]
// Note: -1 denotes unlimited reserves (MSR Hub)
// Balances:
//   - SB: Baseline values calibrated for full fleet + 400 troops.
//         If only 1 SB exists on the map, init.sqf doubles its values automatically.
//   - FOB: Set at 10% of the baseline SB values (can be adjusted independently).

logisticsBaseDefaults = [
    [
        "MSR", 
        [
            ["Cargo", -1], ["Ammo", -1], ["Fuel", -1], ["Medical", -1], 
            ["Repair", -1], ["Vehicle", -1], ["Troops", -1]
        ]
    ],
    [
        "SB", 
        [
            ["Cargo", 300000],
            ["Ammo", 300000],
            ["Fuel", 100000],
            ["Medical", 100000],
            ["Repair", 200000],
            ["Vehicle", 1600000],
            ["Troops", 400]
        ]
    ],
    [
        "FOB", 
        [
            ["Cargo", 30000],
            ["Ammo", 30000],
            ["Fuel", 10000],
            ["Medical", 10000],
            ["Repair", 20000],
            ["Vehicle", 160000],
            ["Troops", 40]
        ]
    ]
];