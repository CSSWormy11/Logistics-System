# ARMA 3 MODULAR LOGISTICS & QUARTERMASTER FRAMEWORK (V8)
## Master Setup, Naming Conventions & Template Customization Guide

This document explains how the Logistics & Quartermaster Framework works, how mission makers set up bases using Map Markers, 3D Editor Objects, and Triggers, and how to customize the template files to add modded vehicles, equipment, vehicle caps, and troop/cargo configurations.

---

### 1. CORE CONCEPTS: BASES & NAMING CONVENTIONS

The entire framework revolves around your **BaseKey**. To register a base, place a standard Map Marker (such as an ellipse, rectangle, or icon) in Eden Editor and give it a Variable Name (`markerName`). The marker name **must** contain one of the three base tier designations so the server knows how to initialize its economy and rules:

*   **MSR (Main Supply Route)** — Infinite economy points (`-1`). Functions strictly as a bulk logistics supply origin where logistics transport vehicles (e.g., Blackfish, Huron, landing craft, cargo trucks) pick up bulk supplies (`Huron Cargo Containers`, `Vehicle Ammo`, `Flexible Fuel Tanks`, or `Troops`). Players do **not** spawn personal combat vehicles or infantry squads here.
    *   *Examples:* `MSR`, `MSR_Alpha`, `MSR_1`
*   **SB (Staging Base / Supply Base)** — High finite starting points (`logisticsBaseDefaults.sqf`). Acts as the main logistics and heavy vehicle procurement hub (e.g., Main Airfield or Carrier Strike Group). Receives bulk Strategic deliveries from the MSR and dispatches Tactical deliveries forward to FOBs.
    *   *Examples:* `SB_Main`, `SB_Carrier`, `SB_Charlie`
*   **FOB (Forward Operating Base)** — Lower finite starting points (`logisticsBaseDefaults.sqf`). Frontline infantry and rapid-response bases supplied via Tactical deliveries from SBs.
    *   *Examples:* `FOB1`, `FOB2`, `FOB_Delta`

#### Economy Resource Pools (Per Base)
For every discovered base marker, `init.sqf` initializes 7 network-synchronized variables (`LogiScore_<BaseKey>_<Category>`):
1.  **Cargo** (`LogiScore_<BaseKey>_Cargo`) — General supplies and Virtual Arsenal equipment mass (KG).
2.  **Ammo** (`LogiScore_<BaseKey>_Ammo`) — Vehicle rearming, aircraft pylon ordnance (KG), and vehicle procurement ammo cost.
3.  **Fuel** (`LogiScore_<BaseKey>_Fuel`) — Vehicle refueling (Liters) and vehicle procurement fuel cost.
4.  **Medical** (`LogiScore_<BaseKey>_Medical`) — Medical supply score.
5.  **Repair** (`LogiScore_<BaseKey>_Repair`) — Vehicle repair operations and procurement repair cost.
6.  **Vehicles** (`LogiScore_<BaseKey>_Vehicles`) — Chassis mass cost (KG) when procuring vehicles in the Motorpool.
7.  **Troops** (`LogiScore_<BaseKey>_Troops`) — Manpower pool used for player respawns, AI squad recruitment, and R4-C vehicle crew generation.

#### Facility Naming Format
Every piece of infrastructure belonging to a base uses the `BaseKey` as its prefix, followed by an underscore, the facility suffix, and an optional index or type/size tag:
*   **Format:** `<BaseKey>_<FacilityType>_<OptionalSpecifiers>_<OptionalNumber>`
*   **Examples:** `SB_Carrier_Arsenal_1`, `SB_Carrier_Garage_Plane_XL_1`, `FOB1_Spawn_1`, `FOB1_pickup`, `FOB1_dropoff`, `FOB1_service`

---

### 2. INFRASTRUCTURE BUILDER: BASE MARKERS vs. 3D FACILITY OBJECTS

*   **Map Markers are used ONLY to identify Bases (`logisticsBases`):**
    *   Place a 2D map marker in Eden Editor named with `"MSR"`, `"SB"`, or `"FOB"` (e.g., `MSR`, `SB_Carrier`, `FOB1`) to register the base and its economy pools.
*   **3D Editor Objects are used strictly for all base facilities (`_Arsenal`, `_Spawn`, `_Garage`, `_fuel`/`_ammo`/`_repair`):**
    *   Instead of placing map markers for spawn pads or arsenals, mission makers place **physical 3D objects** in Eden Editor and assign them the appropriate **Variable Name**.
    *   **Variable Name Drives the Logic (Not Object Classname):** The scripts determine what a facility does strictly from its variable name (`<BaseKey>_Garage_...`, `<BaseKey>_Arsenal_...`, `<BaseKey>_Spawn_...`), not from the 3D object's classname.
    *   **Exact 3D Positioning (`getPosASL` & `getDir`):** Because every facility is a 3D object, spawned vehicles, aircraft, boats, and troops inherit the exact 3D Above-Sea-Level (`ASL`) elevation and heading of the object—making Carrier flight decks, Destroyer pads, hangars, and uneven terrain 100% accurate without height guesswork.
    *   **Recommended 3D Objects to Place in Eden Editor:**
        *   **Terminals / Virtual Arsenal (`<BaseKey>_Arsenal_#`):** Ammo Cache (`VirtualReammoBox_camonet_F`) or Laptop/Terminal prop.
        *   **Aircraft & Ground Vehicle Garages (`<BaseKey>_Garage_...`):** Invisible Helipad (`Land_HelipadEmpty_F`).
        *   **Boat Garages (`<BaseKey>_Garage_Boat_...`):** Destroyer Boat Rack (`Land_Destroyer_01_Boat_Rack_01_F`) for Vehicle-in-Vehicle rack deployment, or Invisible Helipad (`Land_HelipadEmpty_F`) at water level.
        *   **Troop & Player Respawn Points (`<BaseKey>_Spawn_#`):** Invisible Helipad (`Land_HelipadEmpty_F`) or Cargo House (`Land_Cargo_House_V1_F` / `Land_Cargo_House_V3_F`).

---

### 3. FACILITY REFERENCE: 3D OBJECTS & TRIGGERS

#### A. Quartermaster Terminals & Virtual Arsenal (`_Arsenal` / `_Terminal`)
*   **Naming:** `<BaseKey>_Arsenal_<#>` or `<BaseKey>_Terminal_<#>` (3D Object Variable Name, e.g., `SB_Carrier_Arsenal_1`, `FOB1_Arsenal_1` on a `VirtualReammoBox_camonet_F`).
*   **Function:** Initializes the Quartermaster interaction crate. Players use the scroll-wheel actions on this crate to open:
    1.  **Quartermaster Control Hub (`c_unifiedMenu.sqf`)** — Recruit AI Infantry (`Barracks`) or switch to the `Motorpool`.
    2.  **Virtual Arsenal (`qm_clientActionCompiler.sqf` & `fn_equipmentTrader.sqf`)** — Filtered by player faction and map biome (`virtualArsenalTemplate.sqf`). When closing the Arsenal, the net weight change (`loadAbs` delta in KG) is billed to or refunded into `LogiScore_<BaseKey>_Cargo`. If the base lacks sufficient Cargo points, the player's prior loadout is restored.
    3.  **Procure New Vehicle (`fn_newCarDealership.sqf`)** — Opens the Motorpool dialog directly.
    4.  **Salvage / Scrap Nearby Vehicle (`fn_usedCarSalesman.sqf`)** — *(Note: Currently undergoing redesign per `Dev.md` Section 4.5 to provide a dedicated Salvage Selection Menu / direct look-at action).*

#### B. Infantry & Player Respawn Points (`_Spawn`)
*   **Naming:** `<BaseKey>_Spawn_<#>` (3D Object Variable Name, e.g., `SB_Carrier_Spawn_1`, `FOB1_Spawn_1` on a `Land_HelipadEmpty_F`).
*   **Function:**
    *   **Player Respawns (`qm_serverRespawnManager.sqf` & `onPlayerRespawn.sqf`):** Registers native Arma 3 respawn positions directly onto the 3D `_Spawn` object while `LogiScore_<BaseKey>_Troops >= 1` (or infinite `-1`). Deducts 1 Troop point per respawn. Upon respawn, if a Barracks/Cargo House (`Land_Cargo_House_V1_F` or `Land_Cargo_House_V3_F`) is within 40m of the `_Spawn` object, the player is placed safely inside a building position; otherwise, the player remains at the exact 3D ASL position of the `_Spawn` object (e.g., on the Carrier or Destroyer deck).
    *   **AI Recruitment (`fn_recruiter.sqf` & `qm_serverFunctions.sqf`):** Spawns individual AI soldiers or full pre-built squads at the nearest `<BaseKey>_Spawn` 3D object's exact `getPosASL` and `getDir`, deducts the troop cost from `LogiScore_<BaseKey>_Troops`, and joins them into the player's group.

#### C. Motorpool Garage Pads (`_Garage`)
*   **Naming:** `<BaseKey>_Garage_<OptionalType>_<OptionalMaxSize>_<Optional#>` (3D Object Variable Name).
    *   *Examples:* `SB_Carrier_Garage_Plane_XL_1`, `SB_Carrier_Garage_Heli_L_2`, `SB_Carrier_Garage_Boat_S_1`, `FOB1_Garage_Ground_XL_1`, `FOB1_Garage_1`
*   **Boat Rack Support:** Give a Boat Rack (`Land_Destroyer_01_Boat_Rack_01_F`) the variable name `<BaseKey>_Garage_Boat_<Size>_<#>` (or place a Boat Rack within 20m of the boat garage object). When a player spawns a `Ship`, the server checks `canVehicleCargo` and loads the boat directly into the Boat Rack via `setVehicleCargo`.
*   **Valid Type Specifiers:**
    *   `_GROUND` — Ground vehicles (`Car`, `Tank`, `Wheeled_APC_F`, `Tracked_APC_F`, Supply crates/containers).
    *   `_HELI` or `_HELICOPTER` — Helicopters (`Helicopter`).
    *   `_PLANE` — Fixed-wing aircraft & VTOLs (`Plane`).
    *   `_AIR` — Accepts **both** Helicopters and Planes (`Helicopter` + `Plane`).
    *   `_BOAT` — Naval craft (`Ship`).
    *   *(Omitted / Universal)* — A 3D object named `<BaseKey>_Garage_1` (with no type specifier) accepts **all** vehicle types.
*   **Valid Size Specifiers (Upper-Limit Capacity):**
    *   Sizes from smallest to largest: `XXS` (1) $\rightarrow$ `XS` (2) $\rightarrow$ `S` (3) $\rightarrow$ `M` (4) $\rightarrow$ `L` (5) $\rightarrow$ `XL` (6) $\rightarrow$ `OPEN` (7, default if omitted).
    *   **Size acts as a MAXIMUM limit:** An `_XL` pad can spawn `XXS`, `XS`, `S`, `M`, `L`, and `XL` vehicles, whereas an `_S` pad can only spawn `XXS`, `XS`, and `S` vehicles.
*   **String-Subtraction Safety:** Both the client UI (`c_vehicleTabs.sqf`) and server spawner (`QM_fnc_processGarageSpawn`) strip `<BaseKey>_GARAGE` from the front of the object's variable name before checking type/size tokens, so base names like `SB_Carrier` never falsely trigger on `"CAR"`.

#### D. Vehicle Servicing (R4-C) & Aircraft Pylon Manager (`_service`, `_fuel`, `_ammo`, `_repair`)
Handles **Repair, Refuel, Rearm, and Recrew (R4-C)** plus dynamic **Aircraft Pylon Loadouts**:
1.  **Service Pad Triggers (`<BaseKey>_service`):**
    *   Place a Trigger named `<BaseKey>_service` (or `<BaseKey>_service_1`).
    *   Provides scroll-wheel actions (`fn_executeR4CService.sqf`) to the vehicle driver to **Repair**, **Refuel**, **Rearm**, or **Recrew** (spawns missing AI turret/crew members on the server and joins them to the player's group, billing `LogiScore_<BaseKey>_Troops`).
2.  **Physical Service Containers (`qm_supplyPhysicalController.sqf`):**
    *   Place physical objects named `<BaseKey>_fuel_<#>`, `<BaseKey>_ammo_<#>`, or `<BaseKey>_repair_<#>`.
    *   The server watchdog monitors vehicles within 20m and bills `LogiScore_<BaseKey>_Fuel`, `Ammo`, or `Repair` dynamically as the vehicle is serviced, disabling the container's native cargo capacity if the base's pool hits `0`.
3.  **Aircraft Pylon Manager (`fn_pylonManager.sqf` & `qm_openPylonMenu.sqf`):**
    *   Available when a player is inside an aircraft within 40m of either a `<BaseKey>_service` trigger or a `<BaseKey>_ammo_<#>` object.
    *   Allows customizing each hardpoint's weapon/magazine, turret control (Pilot vs. Gunner), ammo count slider, and aircraft livery. Calculates the net ordnance weight difference in KG and bills/refunds `LogiScore_<BaseKey>_Ammo`.

#### E. Logistics Transport Triggers (`_pickup` & `_dropoff`)
Handles bulk supply spawning, loading, and base delivery (`fn_initLogisticsTasks.sqf`, `fn_manageLogisticsMissions.sqf`, `fn_spawnLoadSupply.sqf`, `fn_cargoDelivery.sqf`).

1.  **Pickup Triggers (`<BaseKey>_pickup` or `<BaseKey>_pickup_<#>`):**
    *   *Examples:* `MSR_pickup_1`, `SB_Carrier_pickup_1`, `FOB1_pickup`
    *   **Trigger Condition:** Configurable by the mission maker in Eden Editor to control which vehicles/altitudes activate the zone (e.g., `this && {(vehicle _x) isKindOf "LandVehicle" || (vehicle _x) isKindOf "Air" || (vehicle _x) isKindOf "Ship"} count thisList > 0`).
    *   **Trigger On Activation:**
        ```sqf
        { if (isServer && (_x isKindOf "AllVehicles")) then { [_x, "MSR"] execVM "fn_spawnLoadSupply.sqf"; }; } forEach thisList;
        ```
        *(Note: `fn_initLogisticsTasks.sqf` preserves your custom Trigger Condition at mission start while automatically upgrading any legacy `"SpawnLoadSupply11.sqf"` calls to `"fn_spawnLoadSupply.sqf"`, and `fn_spawnLoadSupply.sqf` automatically strips any trailing `"_pickup"` suffix from the base key).*
    *   **How Pickup Works (`fn_spawnLoadSupply.sqf`):**
        *   Reads the vehicle's current task destination (or lowest-supplied base) to determine which supply category (`Cargo`, `Ammo`, `Fuel`, `Medical`, `Repair`, `Vehicles`, or `Troops`) is needed most.
        *   Looks up the vehicle's loadout for that category in `logisticsCargoTemplates.sqf` and calculates total point cost via `SupplyScores.sqf`.
        *   Verifies the source base has enough points (and exits cleanly if depleted), then deducts the points from the source base.
        *   **Troops:** Requires the vehicle to be on the ground/deck (`_heightAboveSurface <= 2.5m`) and stationary (`speed < 1`). Spawns the infantry group and moves them directly into the vehicle (`moveInCargo`).
        *   **Helicopter Cargo (`"Helicopter"` in `logisticsCargoTemplates.sqf`):** Spawns the physical container(s) on the pickup marker/deck surface (with a 6m offset per container if spawning multiple) so the helicopter pilot can manually slingload them.
        *   **Vehicle-in-Vehicle (ViV) Cargo (Ground Trucks, Naval Craft, VTOLs, Planes):** Spawns the supply object(s) at `[0, 0, 0]` and loads them directly into the vehicle's ViV cargo bay via `_vehicle setVehicleCargo _cargoObj` (requiring ground/naval/VTOL vehicles to be stationary on the surface, or fixed-wing `"Plane"` assets to be either stationary on the surface or flying `> 30m` above the surface). If `setVehicleCargo` returns `false`, the temporary object at `[0, 0, 0]` is immediately deleted so objects never pile up at `[0, 0, 0]`.

2.  **Dropoff Triggers (`<BaseKey>_dropoff` or `<BaseKey>_dropoff_<#>`):**
    *   *Examples:* `SB_Carrier_dropoff_1`, `FOB1_dropoff`, `FOB2_dropoff`
    *   **Trigger On Activation:**
        ```sqf
        [thisTrigger, "FOB1"] execVM "fn_cargoDelivery.sqf";
        ```
    *   **How Dropoff Works (`fn_cargoDelivery.sqf`):**
        *   Monitors logistics vehicles inside the trigger area. Once cargo is unloaded (via ViV unload or helicopter slingload release), it matches the dropped object classnames against `SupplyScores.sqf`, deletes the physical cargo containers, and credits the points into `LogiScore_<BaseKey>_<Category>` (plus any dual-credit categories such as `Cargo` $\rightarrow$ `Medical` & `Repair`, or `Ammo` $\rightarrow$ `Vehicles`).
        *   For **Troops**, an autonomous tracking thread monitors the transported infantry group and credits `LogiScore_<BaseKey>_Troops` (and deletes the temporary transport group) once the vehicle arrives within 50m of the destination marker and the troops disembark.

---

### 4. LOGISTICS TASK SYSTEM & ROLE PRIORITY (`logisticsVehicleRoles.sqf`)

When a player enters the driver/pilot seat of a logistics vehicle, `fn_manageLogisticsMissions.sqf` manages their logistics tasks and live stockpile manifest HUD:

*   **Three Task Levels:**
    1.  **`"Strategic"` (`Logi_Strategic_Task`):** Bulk resupply runs from an **MSR** to an **SB** (active whenever an SB's supply pool drops below its starting default).
    2.  **`"Tactical"` (`Logi_Tactical_Task`):** Resupply runs from an **SB** to the most depleted **FOB** (active whenever any FOB's supply pool drops below its starting default).
    3.  **`"CLT"` (`Combat Logistics Task`):** Frontline delivery tasks generated via the Global Intelligence Network (GIN).
*   **Multi-Role Visibility:** A player in a logistics vehicle will see **all** currently available tasks that match **any** role included in their vehicle's `logisticsVehicleRoles` array.
*   **Priority Auto-Assignment:** When the player has no active task (or just completed a delivery), the system checks their vehicle's role array **in order from left to right (`#0` $\rightarrow$ `#1` $\rightarrow$ `#2`)** and automatically assigns the first task level that currently has an available mission.
    *   *Example 1:* `["Strategic", "Tactical", "CLT"]` (e.g., Blackfish or HEMTT Flatbed on Livonia) auto-assigns **Strategic** first; if all SBs are full, it auto-assigns **Tactical**; if all FOBs are full, it falls back to **CLT**.
    *   *Example 2:* `["Tactical", "CLT", "Strategic"]` (e.g., HEMTT Cargo on Livonia) auto-assigns **Tactical** first, while still letting the driver see Strategic and CLT tasks on the map.
    *   *Example 3:* `["CLT", "Tactical", "Strategic"]` (e.g., transport helicopters) auto-assigns **CLT** first, then **Tactical**, then **Strategic**.
*   **Sticky Current Task:** Once a player has an active task (either automatically assigned or manually selected in the map Task UI), newly available higher-priority tasks will **not** overwrite their active task until they finish delivering their current load.

---

### 5. CUSTOMIZING THE TEMPLATE FILES (ADDING MODS, VEHICLES & TROOPS)

All mission-maker configuration lives in the 8 template `.sqf` files. You never need to edit core system scripts to add modded vehicles, custom factions, or new cargo configurations.

#### 5.1 `logisticsBaseDefaults.sqf` — Base Starting Supply Pools
Defines the starting point values for `"MSR"` (`-1` = infinite), `"SB"`, and `"FOB"` across the 7 resource categories:
```sqf
[
    "SB",
    [
        ["Cargo",    100000],
        ["Ammo",     300000],
        ["Fuel",     100000],
        ["Medical",  100000],
        ["Repair",   100000],
        ["Vehicles", 300000],
        ["Troops",   200]
    ]
]
```

#### 5.2 `logisticsVehicleRoles.sqf` — Logistics Vehicle Role Priority
Maps each logistics transport vehicle classname to an ordered array of allowed task tiers (`"Strategic"`, `"Tactical"`, `"CLT"`):
```sqf
["B_T_VTOL_01_vehicle_F", ["Strategic", "Tactical", "CLT"]],
["B_Truck_01_flatbed_F",  ["Strategic", "Tactical", "CLT"]],
["B_Heli_Transport_03_F", ["Strategic", "Tactical", "CLT"]],
["B_Truck_01_cargo_F",    ["Tactical", "CLT", "Strategic"]]
```
*   **Standard Classification Thresholds:**
    *   **`"Strategic"` (`["Strategic", "Tactical", "CLT"]`):** Heavy bulk haulers capable of transporting **Huron Containers (`B_Slingload_01_*_F`)** **OR** **16+ Troops** (2+ full squads). Includes all **Blackfish** variants, all **Huron** variants, and all **HEMTT** logistics variants **except** the HEMTT Cargo (`Flatbed`, `Transport`, `Covered`).
    *   **`"Tactical"` (`["Tactical", "CLT", "Strategic"]`):** Medium distribution haulers carrying palletized **Cargo Nets (`B_CargoNet_01_ammo_F`) / Vehicle Ammo Crates / Fuel Bladders** **OR** **8–15 Troops** (1 squad). Includes **HEMTT Cargo**, **Ghost Hawk** variants, and **Cargo/Transport Vans**.
    *   **`"CLT"` (`["CLT", "Tactical", "Strategic"]`):** Light combat logistics transports carrying **single Supply Crates (`B_supplyCrate_F`)** **OR** **$\le 7$ Troops** (fireteam). Includes **Prowlers**, **Hunters**, **Offroads**, **Hummingbird**, and **Pawnee**.
*   **To add a modded logistics truck, ship, or helicopter:** Add its CfgVehicles classname and list the task tiers it is allowed to perform in the exact priority order you want it to auto-assign tasks.

#### 5.3 `logisticsCargoTemplates.sqf` — Vehicle Cargo Loadouts per Supply Category
Defines what physical cargo objects (or troop classnames) spawn when a logistics vehicle enters a `_pickup` trigger, and how they are loaded:
```sqf
[
    "B_Truck_01_flatbed_F",
    "Ground Vehicle", // Load Type: "Ground Vehicle", "Plane", or "Helicopter"
    [
        ["Cargo",    ["B_Slingload_01_Cargo_F"]],
        ["Ammo",     ["B_Slingload_01_Ammo_F"]],
        ["Fuel",     ["B_Slingload_01_Fuel_F"]],
        ["Medical",  ["B_Slingload_01_Medevac_F"]],
        ["Repair",   ["B_Slingload_01_Repair_F"]],
        ["Vehicles", ["B_Slingload_01_Ammo_F"]],
        ["Troops",   []]
    ]
]
```
*   **Load Type (`Index 1`):**
    *   `"Ground Vehicle"` or `"Plane"` — Uses Vehicle-in-Vehicle (`setVehicleCargo`) for physical supply containers, and `moveInCargo` for `"Troops"`.
    *   `"Helicopter"` — Spawns physical supply containers on the pickup pad/deck surface so the helicopter can manually slingload them, and uses `moveInCargo` when landed for `"Troops"`.
*   **Multiple Containers:** If an array lists multiple classnames (e.g., `["Box_NATO_AmmoVeh_F", "Box_NATO_AmmoVeh_F"]`), all listed items are spawned and loaded together.

#### 5.4 `SupplyScores.sqf` — Resource Values of Delivered Cargo & Troops
Defines the category and point value awarded when an object or soldier is loaded/delivered:
```sqf
// [Classname, Category, PointValue]
["B_Slingload_01_Cargo_F", "Cargo", 12000],
["Box_NATO_AmmoVeh_F",     "Ammo",  1600],
["B_Soldier_F",            "Troops", 1]
```
*   **Important:** Every cargo container or soldier classname used in `logisticsCargoTemplates.sqf` **must** have an entry in `SupplyScores.sqf` so `fn_spawnLoadSupply.sqf` and `fn_cargoDelivery.sqf` know its point value.

#### 5.5 `spawnableVehicleTemplate.sqf` — Motorpool Procurement Catalog
Controls every vehicle, aircraft, boat, drone, and supply crate available in the Motorpool UI (`G_Procureable_Vehicles`). Each entry follows a 7-index format:
```sqf
// [0: DisplayName, 1: [Classname], 2: CostArray, 3: BaseRestriction, 4: Faction, 5: [TerrainBiomes], 6: [SystemsArray], 7: SizeCategory]
["M2A4 Slammer UP", ["B_MBT_01_TUSK_F"], [["Vehicles", 71369], ["Fuel", 1800], ["Ammo", 5522]], "SB", "BLU_F", ["Woodland", "Desert", "Tropical", "Winter"], ["Logistics"], "L"]
```
*   **Index 0 (`DisplayName`):** Name shown in the Motorpool list.
*   **Index 1 (`[Classname]`):** Single-element array containing the vehicle's `CfgVehicles` classname.
*   **Index 2 (`CostArray`):** Array of `[PoolName, Amount]` pairs deducted when spawning and refunded when salvaging (`"Vehicles"`, `"Fuel"`, `"Ammo"`, `"Repair"`, `"Cargo"`, `"Medical"`, `"Troops"`). *(Values `>= 1,000,000` are treated as config-capacity placeholders and ignored during billing/refunds).*
*   **Index 3 (`BaseRestriction`):** Controls which base tiers can spawn this vehicle:
    *   `"SB"` — Only spawnable at Staging Bases (`SB`).
    *   `"FOB"` — Only spawnable at Forward Operating Bases (`FOB`).
    *   `"ALL"` or `"BOTH"` — Spawnable at both `SB` and `FOB` bases.
    *   `["SB", "FOB"]` (Array) — You can also pass an array of allowed base tiers or specific base names.
    *   *(Note: At an `MSR`, the Motorpool UI automatically restricts tabs strictly to the `Supplies` tab).*
*   **Index 4 (`Faction`):** Faction lock (`"BLU_F"`, `"OPF_F"`, `"IND_F"`, or `"ALL"`). Case-insensitive.
*   **Index 5 (`TerrainBiomes`):** Array of map biomes where this variant appears (`"Desert"`, `"Woodland"`, `"Tropical"`, `"Winter"`, or `"All"`). Determined automatically by `fn_G_getTerrain` in `init.sqf`.
*   **Index 6 (`SystemsArray`):** System tag filter (e.g., `["Logistics"]`). Case-insensitive.
*   **Index 7 (`SizeCategory`):** Required pad size (`"XXS"`, `"XS"`, `"S"`, `"M"`, `"L"`, `"XL"`).

#### 5.6 `qm_vehicleCapsTemplate.sqf` — Multi-Tier Active Vehicle Caps (`QM_CAP_ConfigMatrix`)
Controls the maximum number of active vehicles allowed in the field simultaneously across both **broad parent classes** and **specific vehicle classnames**:
```sqf
QM_CAP_ConfigMatrix = [
    ["All", 256],
    ["Tank", 12],
    ["B_MBT_01_TUSK_F", 4],
    ["Plane", 4],
    ["Helicopter", 8]
];
```
*   **How Multi-Tier Caps Work:**
    *   When a player attempts to spawn a vehicle, the server checks **every** entry in `QM_CAP_ConfigMatrix` where `_classname isKindOf _capClass`.
    *   If a parent category (e.g., `["Tank", 12]`) is set to `12` and a specific tank (`["B_MBT_01_TUSK_F", 4]`) is set to `4`, players can field up to **12 tanks total** of any type, but at most **4 Slammer UP** tanks at once.
    *   Likewise, if 10 other tanks are already active in the field, players can only spawn **2** more tanks of *any* type until existing tanks are destroyed or salvaged.
    *   When a vehicle is destroyed, deleted, or salvaged via `fn_usedCarSalesman.sqf`, it is automatically removed from all matching cap registries.

#### 5.7 `spawnableInfantryTemplate.sqf` — Barracks Individual & Squad Blueprints
Defines `G_Individual_Blueprints` (7-index) and `G_Group_Blueprints` (7-index) for the Barracks recruitment menu:
```sqf
// Individual Unit: [0: Name, 1: Classname, 2: TroopCost, 3: BaseRestriction, 4: Faction, 5: [TerrainBiomes], 6: [SystemsArray]]
["Rifleman (AT)", "B_soldier_LAT_F", 1, "FOB", "BLU_F", ["Desert", "Woodland"], ["Logistics"]]

// Squad Group: [0: GroupName, 1: [ClassnameArray], 2: TotalTroopCost, 3: BaseRestriction, 4: Faction, 5: [TerrainBiomes], 6: [SystemsArray]]
["Rifle Squad", ["B_Soldier_SL_F", "B_Soldier_F", "B_soldier_AR_F", "B_soldier_LAT_F"], 4, "ALL", "BLU_F", ["Desert", "Woodland"], ["Logistics"]]
```
*   Supports `"SB"`, `"FOB"`, `"ALL"` / `"BOTH"`, or an Array of base tiers/names for `BaseRestriction` (Index 3).

#### 5.8 `virtualArsenalTemplate.sqf` — Virtual Arsenal & Physical Crate Whitelist
Defines 4 global arrays (`G_Allowed_Weapons`, `G_Allowed_Magazines`, `G_Allowed_Items`, `G_Allowed_Backpacks`) using a 4-index structure:
```sqf
// [0: Classname, 1: DefaultPhysicalCrateQty, 2: Faction, 3: [TerrainBiomes]]
["arifle_MX_F", 10, "BLU_F", ["Desert"]],
["arifle_MX_Black_F", 10, "BLU_F", ["Woodland", "Tropical", "Winter"]]
```
*   **To add modded weapons/gear:** Add the item's classname, physical stock count, faction (`"BLU_F"`, `"OPF_F"`, `"IND_F"`, or `"ALL"`), and allowed terrain biomes (`"Desert"`, `"Woodland"`, `"Tropical"`, `"Winter"`, or `"All"`).
