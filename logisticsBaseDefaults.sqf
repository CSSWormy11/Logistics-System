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
// Balances: SB holds exactly 3 maximum heavy HEMTT Cargo trips per pool, rounded up.

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
            ["Cargo", 100000],
            ["Ammo", 300000],
            ["Fuel", 100000],
            ["Medical", 100000],
            ["Repair", 200000],
            ["Vehicle", 2400000],
            ["Troops", 100]
        ]
    ],
    [
        "FOB", 
        [
            ["Cargo", 7000],
            ["Ammo", 5000],
            ["Fuel", 5000],
            ["Medical", 2000],
            ["Repair", 5000],
            ["Vehicle", 36000],
            ["Troops", 10]
        ]
    ]
];