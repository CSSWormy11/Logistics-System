# Master System Architecture Blueprint (Version 8)
## Comprehensive Custom Variable, Formula & Function Audit

---

## 1. Global Variables, Network Ledgers & Core Formulas

### 1.1 Master Base & Economy Variables

*   **`logisticsBases`** *(Array of Strings)*
    *   **Declared & Populated:** [`init.sqf`](file:///C:/Users/JSHer/OneDrive/Documents/Arma%203/missions/Mine/Testing/Logistics/Logistics%20System/init.sqf) (Server) $\rightarrow$ Broadcast via `publicVariable "logisticsBases"`.
    *   **Format:** All map markers containing `"MSR"`, `"SB"`, or `"FOB"` (e.g., `["MSR", "SB_Carrier", "FOB1", "FOB2"]`).
    *   **Read By:** `fn_initLogisticsTasks.sqf`, `fn_manageLogisticsMissions.sqf`, `qm_serverGarrisonManager.sqf`, `qm_serverRespawnManager.sqf`, `qm_supplyPhysicalController.sqf`, `onPlayerRespawn.sqf`, `qm_clientFunctions.sqf`, `qm_serverFunctions.sqf`.

*   **`LogiScore_<BaseKey>_<Category>`** *(Number)*
    *   **Declared & Initialized:** [`init.sqf`](file:///C:/Users/JSHer/OneDrive/Documents/Arma%203/missions/Mine/Testing/Logistics/Logistics%20System/init.sqf) (Server) using defaults from [`logisticsBaseDefaults.sqf`](file:///C:/Users/JSHer/OneDrive/Documents/Arma%203/missions/Mine/Testing/Logistics/Logistics%20System/logisticsBaseDefaults.sqf) $\rightarrow$ Broadcast via `publicVariable`.
    *   **Categories:** `Cargo`, `Ammo`, `Fuel`, `Medical`, `Repair`, `Vehicle`, `Troops`.
    *   **Special Value:** `-1` indicates an infinite resource pool (used for `MSR` bases).
    *   **Modified By:**
        *   `fn_spawnLoadSupply.sqf` — Server deducts points on supply pickup.
        *   `fn_cargoDelivery.sqf` — Server credits points on cargo delivery.
        *   `QM_fnc_processInventoryTransaction` (`qm_serverFunctions.sqf`) — Server deducts/refunds `Cargo` mass delta from Virtual Arsenal / Crate transactions.
        *   `QM_fnc_processGarageSpawn` (`qm_serverFunctions.sqf`) — Server deducts multi-pool costs (`< 1,000,000`) on vehicle spawn.
        *   `QM_fnc_serverVehicleSale` (`qm_serverFunctions.sqf`) — Server refunds multi-pool costs (`< 1,000,000`) on vehicle salvage.
        *   `QM_fnc_serverCreateLocalUnit` / `QM_fnc_serverCreateLocalGroup` (`qm_serverFunctions.sqf`) — Server deducts `Troops` on AI recruitment.
        *   `QM_fnc_deductRespawnTroop` (`qm_serverFunctions.sqf`) — Server deducts `1` Troop on player respawn.
        *   `QM_fnc_serverProcessR4C` / `QM_fnc_serverR4CCreateVehicleCrew` (`qm_serverFunctions.sqf`) — Server deducts `Repair`, `Fuel`, `Ammo`, or `Troops` on R4-C service.
        *   `qm_supplyPhysicalController.sqf` — Server deducts `Repair`, `Fuel`, or `Ammo` during passive proximity servicing.
        *   `fn_pylonManager.sqf` — Client/Server deducts or refunds `Ammo` KG delta on aircraft pylon changes.

*   **`QM_Global_Terminals`** *(Array of Objects)*
    *   **Declared & Populated:** [`qm_serverGarrisonManager.sqf`](file:///C:/Users/JSHer/OneDrive/Documents/Arma%203/missions/Mine/Testing/Logistics/Logistics%20System/qm_serverGarrisonManager.sqf) (Server) $\rightarrow$ Broadcast via `publicVariable "QM_Global_Terminals"`.
    *   **Read By:** `qm_clientFunctions.sqf` (`Anonymous_ActionMenu_Watchdog`), `fn_equipmentTrader.sqf` (Virtual Arsenal Watchdog & Auto-Rearm Monitor), `fn_usedCarSalesman.sqf`.

*   **`QM_Current_Terminal_Base`** *(String — Player Object Variable)*
    *   **Set By:** `c_unifiedMenu.sqf`, `qm_clientActionCompiler.sqf` (`player setVariable ["QM_Current_Terminal_Base", _baseKey]`).
    *   **Read By:** `fn_recruiter_list.sqf`, `fn_recruiter.sqf`, `fn_newCarDealership.sqf`, `c_vehicleTabs.sqf`, `c_vehicleExecute.sqf`, `fn_usedCarSalesman.sqf`.

*   **`QM_Current_Terminal_Box`** *(Object — Player Object Variable)*
    *   **Set By:** `c_unifiedMenu.sqf`, `qm_clientActionCompiler.sqf` (`player setVariable ["QM_Current_Terminal_Box", _target]`).
    *   **Read By:** `fn_usedCarSalesman.sqf`.

*   **`allowedLogisticsVehicles`** *(Array of Strings)*
    *   **Declared & Populated:** `init.sqf` (Extracted from index `0` of `logisticsCargoTemplates`).
    *   **Read By:** External GIN / Task scripts and logistics checks.

*   **`QM_CAP_ActiveRegistry`** *(Array of `[FamilyString, [VehicleObjects]]`)*
    *   **Declared & Populated:** `qm_serverFunctions.sqf` (Initialized from `QM_CAP_ConfigMatrix` in `qm_vehicleCapsTemplate.sqf`).
    *   **Modified & Read By:** `QM_CAP_fnc_checkCurrentActiveCount`, `QM_CAP_fnc_registerNewVehicle`, `QM_CAP_fnc_unregisterVehicleAsset`.

---

### 1.2 Core System Formulas

*   **Virtual Arsenal & Crate Mass Delta Formula (`fn_equipmentTrader.sqf` & `qm_serverFunctions.sqf`):**
    *   `_massDelta = (loadAbs player) - _startingMass;`
    *   `_kgCost = round (_massDelta * 0.1);` *(1 Arma mass unit $\approx$ 0.1 KG; billed/refunded against `LogiScore_<BaseKey>_Cargo`)*.
*   **R4-C Service Cost Formulas (`fn_executeR4CService.sqf` & `qm_supplyPhysicalController.sqf`):**
    *   **Repair Cost:** `round ((damage _veh) * (getMass _veh) * 0.1)` $\rightarrow$ Billed to `LogiScore_<BaseKey>_Repair`.
    *   **Fuel Cost:** `round ((1 - (fuel _veh)) * _fuelCapacity)` $\rightarrow$ Billed to `LogiScore_<BaseKey>_Fuel`.
    *   **Ammo Cost:** `round ((1 - _ammoRatio) * (getMass _veh) * 0.05)` $\rightarrow$ Billed to `LogiScore_<BaseKey>_Ammo`.
    *   **Recrew Cost:** `1` Troop per empty non-cargo turret/driver seat $\rightarrow$ Billed to `LogiScore_<BaseKey>_Troops`.
*   **Aircraft Pylon Weight Cost Formula (`fn_pylonManager.sqf`):**
    *   `_netCost = _newWeight - _oldWeight;` *(Using `QM_Pylon_WeightDict` KG lookup or `CfgMagazines` `mass * 0.1` fallback)* $\rightarrow$ Billed/refunded against `LogiScore_<BaseKey>_Ammo`.
*   **Surface Elevation Raycast Formula (`fn_spawnLoadSupply.sqf`):**
    *   `lineIntersectsSurfaces [_startPosASL, _endPosASL, _ignoreObj1, _ignoreObj2, true, 1, "GEOM", "NONE"]`
    *   Used directly beneath vehicles to compute true `_heightAboveSurface` rather than sea-level ASL altitude, and at pickup markers to snap staged helicopter slingload containers onto Carrier/Destroyer flight decks.

---

## 2. File-by-File Architecture & Function Reference

### File: `init.sqf`
*   **Role:** Master Bootloader, Terrain Classifier, Base Economy Initializer, and Script Launcher.
*   **Scripts Compiled / Executed (Dependencies):**
    *   `logisticsCargoTemplates.sqf`, `SupplyScores.sqf`, `logisticsBaseDefaults.sqf`, `virtualArsenalTemplate.sqf`, `spawnableInfantryTemplate.sqf`, `spawnableVehicleTemplate.sqf`, `qm_vehicleCapsTemplate.sqf`, `logisticsVehicleRoles.sqf`
    *   `fn_initLogisticsTasks.sqf`, `fn_manageLogisticsMissions.sqf`, `fn_startupMarkerDiagnostics.sqf`
    *   **Server:** `qm_serverFunctions.sqf`, `qm_supplyPhysicalController.sqf`, `qm_serverGarrisonManager.sqf`, `qm_serverRespawnManager.sqf`, `tsk_serverGIN.sqf`
    *   **Client:** `qm_clientFunctions.sqf`, `fn_pylonManager.sqf`, `qm_clientActionCompiler.sqf`, `fn_equipmentTrader.sqf`, `tsk_clientMapIntel.sqf`, `tsk_clientTaskMaster.sqf`
*   **Functions & Logic Blocks:**
    *   `fn_G_getTerrain`: Classifies `worldName` into `"Desert"`, `"Woodland"`, `"Mediterranean"`, or `"Jungle"`.
    *   `QM_fnc_getLocationsByPrefix`: Scans `missionNamespace` strictly for editor-placed 3D objects matching `<BaseKey>_<typeSuffix>` (un-numbered or numbered `1..100`) and returns `[[Object, PosASL, Dir, "OBJECT", Name], ...]`.
    *   `Initialization_Root_Scope`: Builds `allowedLogisticsVehicles`, discovers all `MSR`/`SB`/`FOB` markers into `logisticsBases`, initializes `LogiScore_<BaseKey>_<Category>` network variables from `logisticsBaseDefaults`, and launches server/client subsystems.

---

### File: `qm_serverFunctions.sqf`
*   **Role:** Server-Side Quartermaster Function Library. Compiled once on the server by `init.sqf`. Handles multi-tier vehicle cap enforcement, 3D garage spawning, vehicle salvage refunds, AI unit/group recruitment, R4-C servicing, and respawn troop deductions.
*   **Functions Declared:**
    *   `QM_fnc_normalizePoolName`:
        *   *Parameters:* `[_poolName]`
        *   *Purpose:* Normalizes resource pool names (`"Vehicle"` / `"Vehicles"` $\rightarrow$ `"Vehicle"`, `"Troop"` / `"Troops"` $\rightarrow$ `"Troops"`) to canonical `LogiScore_<BaseKey>_<Pool>` names (`"Cargo"`, `"Ammo"`, `"Fuel"`, `"Medical"`, `"Repair"`, `"Vehicle"`, `"Troops"`).
    *   `QM_fnc_deductRespawnTroop`:
        *   *Parameters:* `[_baseKey]` (Called via `remoteExec` from `onPlayerRespawn.sqf`)
        *   *Purpose:* Deducts `1` Troop from `LogiScore_<BaseKey>_Troops` when a player respawns at a base.
    *   `QM_fnc_processInventoryTransaction`:
        *   *Parameters:* `[_baseKey, _massDelta, _playerUnit, _loadoutBackup]` (Called via `remoteExec` from `fn_equipmentTrader.sqf`)
        *   *Purpose:* Deducts or refunds Virtual Arsenal / Crate equipment mass delta against `LogiScore_<BaseKey>_Cargo`. Reverts player loadout via `setUnitLoadout` if the base cannot afford the withdrawal.
    *   `QM_fnc_serverVehicleSale`:
        *   *Parameters:* `[_baseKey, _vehicle, _playerUnit]` (Called via `remoteExec` from `fn_usedCarSalesman.sqf`)
        *   *Purpose:* Looks up the vehicle's blueprint in `G_Procureable_Vehicles`, refunds all valid cost pools (`< 1,000,000`) back to `LogiScore_<BaseKey>_*`, unregisters the vehicle from `QM_CAP_ActiveRegistry` via `QM_CAP_fnc_unregisterVehicleAsset`, deletes any AI/UAV crew via `deleteVehicleCrew`, and deletes the vehicle.
    *   `QM_fnc_serverCreateLocalUnit`:
        *   *Parameters:* `[_baseKey, _classname, _playerUnit, _costArray, _name]` (Called via `remoteExec` from `fn_recruiter.sqf`)
        *   *Purpose:* Verifies and deducts `LogiScore_<BaseKey>_Troops`, finds the nearest `<BaseKey>_Spawn` 3D object via `QM_fnc_getLocationsByPrefix`, spawns the AI unit at the object's exact `getPosASL` and `getDir`, and joins it into `group _playerUnit`.
    *   `QM_fnc_serverCreateLocalGroup`:
        *   *Parameters:* `[_baseKey, _unitArray, _playerUnit, _costArray, _name]` (Called via `remoteExec` from `fn_recruiter.sqf`)
        *   *Purpose:* Spawns a full squad array at the nearest `<BaseKey>_Spawn` 3D object's exact `getPosASL` and `getDir`, deducts total troop cost, and joins all spawned units into `group _playerUnit`.
    *   `QM_CAP_fnc_checkCurrentActiveCount`:
        *   *Parameters:* `[_classname]`
        *   *Purpose:* Multi-tier vehicle cap validator. Evaluates **every** entry in `QM_CAP_ConfigMatrix` where `_classname isKindOf (_x select 0)`, prunes dead/null vehicles from `QM_CAP_ActiveRegistry`, and returns `[false, _curCount, _limit, _family]` if *any* matching parent category or specific class cap is full (or `[true, _curCount, _limit, _family]` if allowed).
    *   `QM_CAP_fnc_registerNewVehicle`:
        *   *Parameters:* `[_obj, _class]`
        *   *Purpose:* Registers a newly spawned vehicle into **all** matching parent and specific class buckets in `QM_CAP_ActiveRegistry` and attaches `Killed` and `Deleted` event handlers to automatically unregister it.
    *   `QM_CAP_fnc_unregisterVehicleAsset`:
        *   *Parameters:* `[_obj]`
        *   *Purpose:* Removes a destroyed, deleted, or salvaged vehicle from all matching buckets in `QM_CAP_ActiveRegistry`.
    *   `QM_fnc_processGarageSpawn`:
        *   *Parameters:* `[_baseKey, _classname, _clientPlayer, _costArray, _vehSize]` (Called via `remoteExec` from `fn_newCarDealership.sqf` / `c_vehicleExecute.sqf`)
        *   *Purpose:* Validates multi-tier vehicle caps (`QM_CAP_fnc_checkCurrentActiveCount`) and base resource pools (`< 1,000,000`); scans `missionNamespace` strictly for editor-placed `<BaseKey>_Garage*` 3D objects matching the vehicle's type (`_GROUND`, `_HELI`/`_HELICOPTER`, `_PLANE`, `_AIR`, `_BOAT`, or universal) and upper-limit size (`XXS`..`XL`..`OPEN`); checks for pad/rack obstructions; deducts resource costs; spawns the vehicle (loading Ships directly into the `<BaseKey>_Garage_Boat*` Boat Rack object or nearby Boat Rack via `setVehicleCargo` if compatible, or placing at the 3D pad object's exact `getPosASL` and `getDir`); creates UAV crew if autonomous; and registers the vehicle with `QM_CAP_fnc_registerNewVehicle`.
    *   `QM_fnc_serverProcessR4C`:
        *   *Parameters:* `[_baseKey, _vehicle, _playerUnit, _serviceType, _calculatedCost]` (Called via `remoteExec` from `fn_executeR4CService.sqf`)
        *   *Purpose:* Deducts `Repair`, `Fuel`, or `Ammo` points from the base and executes `setDamage 0`, `setFuel 1`, or `setVehicleAmmoDef 1` on the vehicle.
    *   `QM_fnc_serverR4CCreateVehicleCrew`:
        *   *Parameters:* `[_baseKey, _vehicle, _playerUnit, _missingSeatCount, _totalCost]` (Called via `remoteExec` from `fn_executeR4CService.sqf`)
        *   *Purpose:* Deducts `Troops` from the base, spawns missing vehicle crew on the server via `createVehicleCrew _vehicle`, and transfers the new crew units into `group _playerUnit` via `joinSilent` (ensuring Dedicated Server locality compatibility).

---

### File: `qm_clientFunctions.sqf`
*   **Role:** Client-Side Quartermaster Watchdogs, Diary Ledger Refresher, and Pylon Menu Helpers.
*   **Functions & Threads Declared:**
    *   `QM_fnc_getNearbyAmmoSource`: Checks within 40m of the player's vehicle for a `<BaseKey>_service` trigger or `<BaseKey>_ammo*` object and returns the matching `BaseKey`.
    *   `QM_fnc_canOpenPylonMenu`: Returns `true` if the player is in an aircraft (`"Air"`) within range of an ammo source.
    *   `QM_fnc_addPylonAction`: Binds the `"Configure Aircraft Pylons"` scroll-wheel action to the player.
    *   `Anonymous_ActionMenu_Watchdog`: Monitors `QM_Global_Terminals` and binds Quartermaster scroll-wheel actions to newly discovered terminal crates via `QM_fnc_clientRegisterTraderActions`, `QM_fnc_clientRegisterFlagActions`, and `QM_fnc_clientRegisterBarracksActions`.
    *   `Anonymous_DiaryLedger_Refresher`: Updates the player's Map Briefing Diary (`"Logistics Stockpile Ledger"`) every 5 seconds with live resource pool values for all bases.

---

### File: `qm_clientActionCompiler.sqf`
*   **Role:** Terminal Scroll-Wheel Action Compiler & Virtual Arsenal Whitelist Enforcer.
*   **Functions Declared:**
    *   `QM_fnc_clientRegisterTraderActions`: Placeholder hook for trader actions.
    *   `QM_fnc_clientRegisterFlagActions`: Registers `"Salvage / Scrap Nearby Vehicle"` on terminal crates, setting `QM_Current_Terminal_Base` and `QM_Current_Terminal_Box` on the player and executing `fn_usedCarSalesman.sqf`.
    *   `QM_fnc_clientRegisterBarracksActions`: Registers `"Open Quartermaster Control Hub"` (`CfgControlHubMenu`), `"Open Virtual Arsenal"` (purges `"%ALL"`, filters `G_Allowed_Weapons` / `Magazines` / `Items` / `Backpacks` by player side and terrain biome via `fn_G_getTerrain`, records starting `loadAbs` mass, and hooks `ContainerClosed` to `QM_fnc_traderOnContainerClosed`), and `"Procure New Vehicle"` (`CfgVehicleProcureMenu`).

---

### File: `fn_initLogisticsTasks.sqf`
*   **Role:** Server-Side Logistics Trigger Normalizer & Waypoint Marker Generator.
*   **Variables:** `_allMissionTriggers`, `_trigger`, `_triggerName`, `_tNameLower`, `_isPickup`, `_isDropoff`, `_stmts`, `_cond`, `_act`, `_deact`, `_idx`, `_parentBase`, `_displayName`, `_prefix`, `_expectedMarkerID`, `_marker`.
*   **Logic:**
    1.  Scans all mission triggers (`allMissionObjects "EmptyDetector"`).
    2.  Extracts `_parentBase` by taking the substring before `"_pickup"` or `"_dropoff"` (so numbered triggers like `MSR_pickup_1` or `SB_Carrier_pickup_1` cleanly resolve to `"MSR"` and `"SB_Carrier"`).
    3.  Preserves the mission maker's custom trigger `condition` (`_stmts select 0`) while upgrading any legacy `"SpawnLoadSupply11.sqf"` or `"CargoDelivery3.sqf"` script calls in `onActivation` (`_stmts select 1`) to `"fn_spawnLoadSupply.sqf"` and `"fn_cargoDelivery.sqf"` once at startup.
    4.  Generates server-authoritative `"Pickup_<BaseKey>"` and `"Dropoff_<BaseKey>"` markers at the trigger positions for task waypoints.

---

### File: `fn_manageLogisticsMissions.sqf`
*   **Role:** Client-Side Logistics Task Manager & Live Stockpile HUD.
*   **Functions & Threads:**
    *   `logi_fnc_formatPoints`: Formats numeric stockpile scores with thousand-separators (or `"Infinite Supply"` for `-1`).
    *   `createClientLogiTasks`: Creates/maintains client tasks `Logi_Strategic_Task` (`MSR` $\rightarrow$ `SB`) and `Logi_Tactical_Task` (`SB` $\rightarrow$ `FOB`).
    *   `Live_Resource_HUD_Thread`: Continuously updates the task descriptions of `Logi_Strategic_Task` and `Logi_Tactical_Task` with live stockpile manifests for all SBs and FOBs discovered in `logisticsBases`.
    *   `Dynamic_Assignment_Engine_Thread`:
        *   Evaluates whether the player is driving/piloting a logistics vehicle (matching `logisticsVehicleRoles` or `logisticsCargoTemplates`).
        *   Reads the vehicle's ordered role array from `logisticsVehicleRoles` (e.g., `["Strategic", "Tactical", "CLT"]` or `["CLT", "Tactical", "Strategic"]`).
        *   Dynamically resolves `MSR`, `SB` (e.g., `SB_Carrier`), and `FOB` base keys from `logisticsBases`.
        *   Displays all tasks whose role is included in the vehicle's role array (`Strategic`, `Tactical`, `CLT`) and hides unsupported tasks.
        *   Keeps the player's current task **sticky** while active (`_stickyRole`), respecting manual task selection in the map UI, and only auto-assigns a new task when the player has no active task or completes their delivery—selecting the highest-priority available role according to the vehicle's role array order (`#0` $\rightarrow$ `#1` $\rightarrow$ `#2`).

---

### File: `fn_spawnLoadSupply.sqf`
*   **Role:** Server-Side Supply Spawning, Troop Boarding & Cargo Loading Engine.
*   **Called By:** `<BaseKey>_pickup` triggers (`[_x, "<BaseKey>"] execVM "fn_spawnLoadSupply.sqf"`).
*   **Variables:** `_vehicle`, `_pickupBaseKey`, `_vehType`, `_templateIndex`, `_allVehicleSupplies`, `_loadType`, `_supplyType`, `_availCategories`, `_cargoList`, `_totalCargoPointWeight`, `_availablePoints`, `_targetDeliveryBase`, `_deliveryMarker`, `_deliveryPos`, `_vehPosASL`, `_surfaceIntersects`, `_heightAboveSurface`, `_isPlane`, `_isHelicopter`, `_grp`, `_unit`, `_cargoObj`, `_offsetPos`, `_loaded`.
*   **Logic:**
    1.  Strips any trailing `"_pickup"` suffix from `_pickupBaseKey` (e.g., `"MSR_pickup"` $\rightarrow$ `"MSR"`).
    2.  Looks up the vehicle in `logisticsCargoTemplates` (`_loadType = _allVehicleSupplies # 1`, `_availCategories = _allVehicleSupplies # 2`).
    3.  Determines the needed supply category (`_supplyType`) from the vehicle's current task or most depleted destination pool.
    4.  Calculates `_totalCargoPointWeight` from `SupplyScores` and verifies `LogiScore_<BaseKey>_<Category>` has sufficient points (aborting at top-level scope if depleted).
    5.  Computes true `_heightAboveSurface` using a downward `lineIntersectsSurfaces` raycast directly beneath the vehicle (preventing high ASL terrain or Carrier decks from being misidentified as high-altitude flight).
    6.  **Troops (`_supplyType == "Troops"`):** Requires `_heightAboveSurface <= 2.5` and `abs (speed _vehicle) < 1`. Deducts points, spawns the infantry group, moves them directly into the vehicle via `moveInCargo`, and spawns the `Independent_Infantry_Tracking_Loop` to credit the destination base upon arrival and disembarkation.
    7.  **Helicopter Cargo (`_loadType == "Helicopter"` or `_isHelicopter`):** Deducts points and spawns the physical supply container(s) on the pickup marker/deck surface (with a 6m offset per container) for manual slingloading.
    8.  **ViV Cargo (Ground / Naval / VTOL / Plane):** Requires stationary surface contact (`_heightAboveSurface <= 2.5 && abs (speed _vehicle) < 1`) or a fixed-wing `"Plane"` at `> 30m` above surface. Deducts points, spawns cargo at `[0, 0, 0]`, loads it via `_vehicle setVehicleCargo _cargoObj`, and deletes `_cargoObj` if `setVehicleCargo` returns `false`.

---

### File: `fn_cargoDelivery.sqf`
*   **Role:** Server-Side Cargo Offload & Destination Base Economy Crediting Loop.
*   **Called By:** `<BaseKey>_dropoff` triggers (`[thisTrigger, "<BaseKey>"] execVM "fn_cargoDelivery.sqf"`).
*   **Logic:**
    *   Monitors logistics vehicles entering the dropoff trigger area.
    *   When internal ViV cargo is unloaded or a slingloaded container is detached inside the dropoff radius, matches the unloaded object against `SupplyScores`, deletes the physical container, credits `LogiScore_<BaseKey>_<Category>` (plus linked secondary pools), and marks `_vehicle setVariable ["currentLoadedMenu", "none", true]`.

---

### Files: `c_vehicleTabs.sqf`, `fn_newCarDealership.sqf` & `c_vehicleExecute.sqf`
*   **Role:** Motorpool Procurement UI Controller (`CfgVehicleProcureMenu`).
*   **Logic:**
    *   `c_vehicleTabs.sqf`: Scans `missionNamespace` strictly for editor-placed `<BaseKey>_Garage*` 3D objects using string-length subtraction. Computes maximum supported pad sizes (`_maxGroundSize`, `_maxHeliSize`, `_maxPlaneSize`, `_maxBoatSize`). Filters `G_Procureable_Vehicles` case-insensitively by system tag (`"LOGISTICS"`), player faction, terrain biome (`fn_G_getTerrain`), base restriction (`"SB"`, `"FOB"`, `"ALL"`/`"BOTH"`, or Array; restricting `MSR` strictly to the Supplies tab), and pad size capacity. Formats multi-resource costs (`< 1,000,000`) into the UI listbox.
    *   `fn_newCarDealership.sqf` / `c_vehicleExecute.sqf`: Reads the selected vehicle blueprint and invokes `QM_fnc_processGarageSpawn` on the server via `remoteExec`.

---

### File: `fn_usedCarSalesman.sqf`
*   **Role:** Client-Side Vehicle Salvage & Refund Scanner *(Scheduled for Redesign in `Dev.md` Section 4.5)*.
*   **Called By:** Scroll-wheel action on Terminal crate (`qm_clientActionCompiler.sqf`).
*   **Variables:** `_baseKey`, `_terminalBox`, `_searchCenters`, `_prefixUpper`, `_candidates`, `_near`, `_racks`, `_sorted`, `_targetScrapVehicle`.

---

### Files: `fn_recruiter_list.sqf`, `fn_recruiter.sqf` & `c_unifiedMenu.sqf`
*   **Role:** Garrison Barracks Infantry Recruitment UI (`CfgControlHubMenu`).
*   **Logic:**
    *   `fn_recruiter_list.sqf`: Filters `G_Individual_Blueprints` and `G_Group_Blueprints` case-insensitively by faction, terrain biome (`fn_G_getTerrain`), system tag, and base restriction (`"SB"`, `"FOB"`, `"ALL"`/`"BOTH"`, or Array), and displays live `LogiScore_<BaseKey>_Troops` in the header.
    *   `fn_recruiter.sqf`: Dispatches the selected individual unit or squad blueprint to `QM_fnc_serverCreateLocalUnit` or `QM_fnc_serverCreateLocalGroup` via `remoteExec`.

---

### Files: `fn_executeR4CService.sqf` & `qm_supplyPhysicalController.sqf`
*   **Role:** Active (Scroll-Wheel Trigger) and Passive (20m Container Watchdog) Vehicle Servicing (R4-C).
*   **Logic:**
    *   `fn_executeR4CService.sqf`: Calculates Repair, Refuel, Rearm, or Recrew costs for the player's vehicle inside a `<BaseKey>_service` trigger and calls `QM_fnc_serverProcessR4C` or `QM_fnc_serverR4CCreateVehicleCrew` on the server.
    *   `qm_supplyPhysicalController.sqf`: Server loop scanning within 20m of `<BaseKey>_fuel*`, `<BaseKey>_ammo*`, and `<BaseKey>_repair*` objects, billing resource deltas back to the base ledger and zeroing container cargo capacity if the base pool reaches `0`.

---

### Files: `fn_pylonManager.sqf`, `qm_openPylonMenu.sqf` & `qm_pylonMenu.hpp`
*   **Role:** Dynamic Aircraft Hardpoint & Ordnance Manager (`QM_PylonDialog`).
*   **Logic:**
    *   Queries compatible magazines per pylon, categorizes weapons (`A2A`, `A2G`, `PODS`, `OTHER`), calculates net weight changes in KG via `QM_fnc_getWeaponWeight`, deducts/refunds `LogiScore_<BaseKey>_Ammo`, and applies `setPylonLoadout`, `setAmmoOnPylon`, and turret control.

---

### Files: `qm_serverGarrisonManager.sqf`, `qm_serverRespawnManager.sqf` & `onPlayerRespawn.sqf`
*   **Role:** Server 3D Facility Initializer & Manpower-Linked Respawn System.
*   **Logic:**
    *   `qm_serverGarrisonManager.sqf`: Discovers editor-placed `<BaseKey>_Terminal` / `<BaseKey>_Arsenal` 3D objects, populates physical crate inventories using the 4-index `virtualArsenalTemplate.sqf` filtered by faction and biome, attaches `ContainerOpened`/`ContainerClosed` mass accounting handlers, and broadcasts `QM_Global_Terminals`.
    *   `qm_serverRespawnManager.sqf`: Monitors `LogiScore_<BaseKey>_Troops` and dynamically adds/removes native engine respawn points (`BIS_fnc_addRespawnPosition` / `BIS_fnc_removeRespawnPosition`) directly onto editor-placed `<BaseKey>_Spawn` 3D objects.
    *   `onPlayerRespawn.sqf`: Checks within 40m of the `_Spawn` object for nearby Cargo Houses (`Land_Cargo_House_V1_F`, `Land_Cargo_House_V3_F`) to place the player indoors if present, otherwise preserves the exact 3D ASL position of the `_Spawn` object, and triggers `QM_fnc_deductRespawnTroop` on the server.
