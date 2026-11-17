// ============================================================================
// LOGISTICS SYSTEM: BASE DEFAULTS CONFIGURATION (PART 1)
// File: tp_baseDefaults.sqf
// Description: Defines the starting economy limits, operational roles, and
//              supply pool configurations for all first-class base types.
//              MSR & CS (Cargo Ships) hubs have infinite (-1) resources.
//              SB, CVN, LHA, FOB, DDG, DD have tailored starting pools.
//              CON (Contested Bases) initialize with 0 across all pools.
// Called By: init.sqf (Compiled during server/master initialization)
// ============================================================================

// Format: [BaseType, [[Property/Category, Value], ...]]
// Note: -1 denotes unlimited reserves (Pipeline Hub)
// Roles: "STRATEGIC" (Rear Staging Depots / Fleet Capital Ships)
//        "TACTICAL"  (Frontline Outposts / Littoral Escorts / Contested Sectors)
//        "MSR"       (Infinite Supply Pipeline Corridors)

logisticsBaseDefaults = [
    // ------------------------------------------------------------------------
    // PIPELINE SOURCES (Infinite Reserves, No Garrison/Repair Facilities)
    // ------------------------------------------------------------------------
    [
        "MSR", 
        [
            ["Role", "MSR"],
            ["Cargo", -1], ["Ammo", -1], ["Fuel", -1], ["Medical", -1], 
            ["Repair", -1], ["Vehicle", -1], ["Troops", -1]
        ]
    ],
    [
        "CS", // Cargo Ship (Offshore Maritime Pipeline Hub)
        [
            ["Role", "MSR"],
            ["Cargo", -1], ["Ammo", -1], ["Fuel", -1], ["Medical", -1], 
            ["Repair", -1], ["Vehicle", -1], ["Troops", -1]
        ]
    ],

    // ------------------------------------------------------------------------
    // STRATEGIC REAR BASES (Primary Distribution Depots & Fleet Capital Ships)
    // ------------------------------------------------------------------------
    [
        "SB", // Mainland Strategic Supply Base
        [
            ["Role", "STRATEGIC"],
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
        "CVN", // Nuclear Aircraft Carrier (Fleet Hub)
        [
            ["Role", "STRATEGIC"],
            ["Cargo", 300000],
            ["Ammo", 400000],
            ["Fuel", 300000],
            ["Medical", 100000],
            ["Repair", 200000],
            ["Vehicle", 1600000],
            ["Troops", 400]
        ]
    ],
    [
        "LHA", // Amphibious Assault Capital Ship
        [
            ["Role", "STRATEGIC"],
            ["Cargo", 150000],
            ["Ammo", 150000],
            ["Fuel", 100000],
            ["Medical", 50000],
            ["Repair", 100000],
            ["Vehicle", 800000],
            ["Troops", 200]
        ]
    ],

    // ------------------------------------------------------------------------
    // TACTICAL FORWARD BASES (Frontline Outposts & Surface Combatants)
    // ------------------------------------------------------------------------
    [
        "FOB", // Forward Operating Base (Land Outpost)
        [
            ["Role", "TACTICAL"],
            ["Cargo", 30000],
            ["Ammo", 30000],
            ["Fuel", 10000],
            ["Medical", 10000],
            ["Repair", 20000],
            ["Vehicle", 160000],
            ["Troops", 40]
        ]
    ],
    [
        "DDG", // Guided-Missile Destroyer (Surface Escort & Light Aviation)
        [
            ["Role", "TACTICAL"],
            ["Cargo", 15000],
            ["Ammo", 25000],
            ["Fuel", 15000],
            ["Medical", 5000],
            ["Repair", 15000],
            ["Vehicle", 50000],
            ["Troops", 20]
        ]
    ],
    [
        "DD", // Gun Destroyer (Surface Escort)
        [
            ["Role", "TACTICAL"],
            ["Cargo", 15000],
            ["Ammo", 20000],
            ["Fuel", 15000],
            ["Medical", 5000],
            ["Repair", 15000],
            ["Vehicle", 50000],
            ["Troops", 20]
        ]
    ],

    // ------------------------------------------------------------------------
    // CONTESTED BASES (Frontline Sectors, 0 Starting Supplies, 100% Deliver/Capture)
    // Mission makers can freely adjust starting supply values here.
    // ------------------------------------------------------------------------
    [
        "CON", // Contested Base Sector (Default: 0 across all pools)
        [
            ["Role", "TACTICAL"],
            ["Cargo", 0],
            ["Ammo", 0],
            ["Fuel", 0],
            ["Medical", 0],
            ["Repair", 0],
            ["Vehicle", 0],
            ["Troops", 0]
        ]
    ],
    [
        "CONTESTED", // Alias for Contested Bases (Default: 0 across all pools)
        [
            ["Role", "TACTICAL"],
            ["Cargo", 0],
            ["Ammo", 0],
            ["Fuel", 0],
            ["Medical", 0],
            ["Repair", 0],
            ["Vehicle", 0],
            ["Troops", 0]
        ]
    ]
];
