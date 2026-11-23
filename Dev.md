# Arma 3 Logistics System (V8) — Development Tracker (`Dev.md`)

This document tracks verified bugs, inconsistencies, incomplete features, and upcoming user-directed development goals for the Logistics & Quartermaster Core Framework.

---

## 1. Critical Bugs & Logic Issues to Address

### [x] 1.1 Strategic vs. Tactical Role Parsing in `fn_manageLogisticsMissions.sqf`
- **1. Initial Issue Summary:** `logisticsVehicleRoles.sqf` stores vehicle roles as prioritized arrays of strings (e.g., `["Strategic", "Tactical", "CLT"]`), but `fn_manageLogisticsMissions.sqf` (Lines 139–148) assigned `_assignedRoleOverride = (logisticsVehicleRoles # _roleIdx) # 1;` (which is the array itself) and compared `if (_assignedRoleOverride == "Strategic")`. Comparing an Array to a String in SQF always evaluates to `false`, preventing any vehicle from ever receiving `Logi_Strategic_Task` routing.
- **2. Proposed / Applied Corrections:** Updated `fn_manageLogisticsMissions.sqf` (Lines 139–150) to unwrap the primary role (`# 0`) when the `logisticsVehicleRoles` entry is an array, while preserving fallback support if a string is provided. Mission makers retain full control over the role priority array per vehicle in `logisticsVehicleRoles.sqf`. *(Note: Line 112 still excludes `Air` vehicles via `!(_vehicle isKindOf "Air")`, which may need review if VTOLs/Helicopters should receive Strategic/Tactical tasks prior to GIN/CLT integration.)*
- **3. Status:** **Verified Resolved** (Role array unwrapping and priority matching confirmed functional).

### [ ] 1.2 Vehicle Cap (`QM_CAP`) First-Match Short-Circuit
- **1. Initial Issue Summary:** In `qm_serverFunctions.sqf` (Lines 199–216), `QM_CAP_fnc_checkCurrentActiveCount` and `QM_CAP_fnc_registerNewVehicle` iterated over `QM_CAP_ConfigMatrix` from top to bottom and exited (`exitWith`) on the first parent class where `_classname isKindOf (_x select 0)`. Because `["All", 256]` is the first element in `qm_vehicleCapsTemplate.sqf` (Line 13), every vehicle matched `"All"` immediately and ignored all category and specific vehicle caps below it.
- **2. Proposed / Applied Corrections:** Updated `QM_CAP_ActiveRegistry`, `QM_CAP_fnc_checkCurrentActiveCount`, `QM_CAP_fnc_registerNewVehicle`, and `QM_CAP_fnc_unregisterVehicleAsset` in `qm_serverFunctions.sqf` (Lines 197–274) so that every matching parent class and specific vehicle class in `QM_CAP_ConfigMatrix` is evaluated and tracked simultaneously. Spawning is denied if *any* matching category or specific class cap is full, and destroyed/deleted/salvaged vehicles are removed from all matching cap registries. `qm_vehicleCapsTemplate.sqf` values are left untouched for mission-maker customization.
- **3. Status:** **In Testing** (Corrections applied in `qm_serverFunctions.sqf` — needs in-game verification).

### [x] 1.3 Garage & Facility Discovery: Strict 3D Editor Objects Only
- **1. Initial Issue Summary:** Client UI `c_vehicleTabs.sqf` (Lines 46–53) checked both `allMapMarkers` and `allVariables missionNamespace` (editor-placed objects) when deciding which vehicle tabs/sizes a base supports, whereas server `QM_fnc_processGarageSpawn` in `qm_serverFunctions.sqf` (Line 300) only searched `allMapMarkers`. Additionally, 2D map markers lack 3D elevation (`Z = 0`), causing height/positioning inaccuracies on ship decks and inside hangars.
- **2. Proposed / Applied Corrections:** Transitioned `_Arsenal`/`_Terminal`, `_Spawn`, and `_Garage` locations strictly to 3D Editor Objects (discovered via `missionNamespace` variable names, independent of object classname) while keeping map markers strictly for base identification (`logisticsBases`):
  - Updated `QM_fnc_getLocationsByPrefix` in `init.sqf`, `c_vehicleTabs.sqf`, `QM_fnc_processGarageSpawn` in `qm_serverFunctions.sqf`, `qm_serverGarrisonManager.sqf`, `qm_serverRespawnManager.sqf`, `onPlayerRespawn.sqf`, and `fn_usedCarSalesman.sqf` to use editor-placed 3D objects (`getPosASL` / `getDir`) and removed runtime marker-to-object spawning loops.
  - Added support in `QM_fnc_processGarageSpawn` for both `_HELI` and `_HELICOPTER` garage suffixes, and enabled direct Vehicle-in-Vehicle boat loading (`setVehicleCargo`) when the `<BaseKey>_Garage_Boat_...` object is itself a Boat Rack (or near one).
  - Updated `onPlayerRespawn.sqf` to check within 40m of the `_Spawn` object for nearby Cargo Houses (`Land_Cargo_House_V1_F`, `Land_Cargo_House_V3_F`) and otherwise preserve the exact 3D ASL position of the `_Spawn` object (e.g., `Land_HelipadEmpty_F` on a Carrier/Destroyer deck).
- **3. Status:** **Verified Resolved** (Confirmed in-game; strict 3D editor objects, ASL elevation positioning, Boat Racks, and variable suffix type/size filters verified).

### [ ] 1.4 Dedicated Server Locality in `QM_fnc_serverR4CCreateVehicleCrew`
- **1. Initial Issue Summary:** In `qm_serverFunctions.sqf` (Line 537), `(group _playerUnit) createVehicleCrew _vehicle;` was executed on the server. In Arma 3, the group-targeted `createVehicleCrew` syntax requires the target group to be local to the executing machine; on a dedicated server, a player's group is local to the client.
- **2. Proposed / Applied Corrections:** Updated `QM_fnc_serverR4CCreateVehicleCrew` in `qm_serverFunctions.sqf` (Lines 609–615) to spawn the crew on the server via `createVehicleCrew _vehicle` and then transfer the newly created crew members into `group _playerUnit` using `joinSilent`.
- **3. Status:** **In Testing** (Corrections applied in `qm_serverFunctions.sqf` — needs in-game verification).

### [x] 1.5 Vehicle Salvage System (Redesigned with Dropoff Zone Disembark Confirmation & Cargo Unload Separation)
- **1. Initial Issue Summary:** In `fn_usedCarSalesman.sqf` (Lines 9–17), salvage detection searched within a 14m 3D sphere around `getMarkerPos _baseKey` (the master base marker at `Z=0`) for `["LandVehicle", "Air"]`. Because `getMarkerPos` is at sea level (`Z=0`), elevated decks (e.g., `SB_Carrier` at ~24m ASL or Destroyers) and garage pads located >14m away from the central base marker were completely out of range, and `"Ship"` / boats inside Boat Racks were excluded. In-game testing confirmed that triggering salvage blindly from a terminal crate does not reliably detect unoccupied vehicles on distant pads.
- **2. Proposed / Applied Corrections:**
  - Removed the broken `fn_usedCarSalesman.sqf` scroll-wheel action from base terminals in `qm_clientActionCompiler.sqf`.
  - Implemented **Strict Separation Between Hauled Freight Cargo and Player-Driven Vehicles**:
    1. **Hauled Freight Vehicles (ViV Cargo / Slingload):**
       - When an unload action offloads a vehicle from internal cargo (e.g., a Hunter unloaded from a HEMTT bed or dropped from helicopter slingload) into any base Dropoff Zone, it was never driven by a player (`QM_DrivenByPlayer == false`).
       - It is recognized as freight cargo and **automatically salvaged immediately upon touching the ground** without prompting the player, crediting 100% of resources back to the base ledger.
    2. **Player-Driven Vehicles:**
       - Any vehicle driven into a Dropoff Zone by a player is tagged `QM_DrivenByPlayer = true`.
       - The background dropoff trigger is strictly blocked from auto-despawning driven vehicles.
       - When the player disembarks (`GetOutMan`), the system **ALWAYS prompts the driver for confirmation**: `"Would you like to SALVAGE this [Vehicle Name] and recycle its resources back to [Base Name]? [YES / NO]"`.
       - If confirmed **YES**, the vehicle is despawned, crew safely deleted, 100% of chassis resources credited to base ledgers, and its vehicle cap (`QM_CAP`) unregistered via `QM_fnc_serverVehicleSale`.
       - If declined **NO**, the vehicle remains completely untouched on the pad (`QM_PlayerDeclinedSalvage = true`).
    3. **Ad-Hoc Manual Salvage Action:**
       - Added a context-sensitive look-at `addAction` on the player (`[SALVAGE CONTROL] Recycle Vehicle to Base`) for ad-hoc salvage of unoccupied vehicles parked inside any base dropoff zone.
- **3. Status:** **Verified Resolved** (In Testing).

### [x] 1.6 Multi-Tier Task Visibility, Priority Auto-Assignment & Aircraft Support in `fn_manageLogisticsMissions.sqf`
- **1. Initial Issue Summary:**
  1. Line 112 of `fn_manageLogisticsMissions.sqf` checked `!(_vehicle isKindOf "Air") && getMass _vehicle > 4000`, completely blocking aircraft (such as the Blackfish and Huron) and light vehicles from the task system.
  2. `fn_manageLogisticsMissions.sqf` hardcoded `"SB"` (`LogiScore_SB_*`, `"Pickup_SB"`, `"Dropoff_SB"`) instead of dynamically resolving `SB` and `MSR` bases from `logisticsBases` (e.g., `SB_Carrier`), causing task waypoints to point to `[0,0,0]` and stockpile manifests to read `0` when the Staging Base is named `SB_Carrier`.
  3. `fn_initLogisticsTasks.sqf` (Lines 25–33) stripped only the last underscore token from trigger names, turning numbered triggers like `MSR_pickup_1` into marker `"Pickup_MSR_pickup"` instead of `"Pickup_MSR"`.
  4. `fn_manageLogisticsMissions.sqf` only checked a single role rather than showing all available tasks supported by the vehicle's `logisticsVehicleRoles` array and auto-assigning the highest-priority available task only when the player has no active task (or completes their current task).
- **2. Proposed / Applied Corrections:**
  - Updated `fn_initLogisticsTasks.sqf` so `_pickup` and `_dropoff` triggers strip everything from `"_pickup"` / `"_dropoff"` onward (including numbered suffixes like `_1`) to derive the true parent base key (`MSR`, `SB_Carrier`, `FOB1`, etc.) and create server-authoritative `Pickup_<Base>` and `Dropoff_<Base>` markers.
  - Updated `fn_manageLogisticsMissions.sqf` to dynamically resolve `MSR`, `SB`, and `FOB` bases from `logisticsBases` instead of hardcoding `"SB"`.
  - Updated `fn_manageLogisticsMissions.sqf` so players in any vehicle defined in `logisticsVehicleRoles` (or fallback cargo ground vehicles) can see all available tasks matching any role in their vehicle's `logisticsVehicleRoles` array (`Strategic`, `Tactical`, `CLT`), receive their next task automatically according to the priority order of their vehicle's role array (`#0` $\rightarrow$ `#1` $\rightarrow$ `#2`), and keep their current task sticky until delivery is completed.
  - Fixed native Map UI manual task switching in `fn_manageLogisticsMissions.sqf`: clicking "Assign" in the Arma 3 Map UI updates the native engine `currentTask player` handle (`BIS_fnc_taskReal`) rather than `BIS_fnc_setTask`'s internal variable (`BIS_fnc_taskCurrent`). Previously, `BIS_fnc_taskSetDescription` (every 5s) and `BIS_fnc_taskSetDestination` read the stale `BIS_fnc_setTask` state and forcibly reverted the player back to the default route. The script now reads `currentTask player` directly, synchronizes `BIS_fnc_taskSetState`, and uses `setSimpleTaskDescription` on the real task handle so manual task selection in the Map UI is never overwritten until the selected task's delivery is completed.
- **3. Status:** **Verified Resolved** (Dynamic base resolution, trigger suffix stripping, multi-task priority, and Map UI manual assignment confirmed functional).

### [ ] 1.7 `fn_spawnLoadSupply.sqf` `getPosVisual` (ASL) Bug, Helicopter Slingload Spawning & Legacy Trigger Filenames
- **1. Initial Issue Summary:**
  1. In `mission.sqm`, the `_pickup` and `_dropoff` triggers still called legacy filenames `"SpawnLoadSupply11.sqf"` and `"CargoDelivery3.sqf"` (and `MSR_pickup_1` passed `"MSR_pickup"` instead of `"MSR"` as `_baseMarkerName`), whereas the workspace files are named `fn_spawnLoadSupply.sqf` and `fn_cargoDelivery.sqf`.
  2. Line 74 of `fn_spawnLoadSupply.sqf` placed `if (_availablePoints < _totalCargoPointWeight) exitWith { ... };` inside a nested `if (_availablePoints != -1) then { ... };` block, which only exited the inner `if` scope and still spawned supplies for free when a base's pool was depleted.
  3. Line 121 of `fn_spawnLoadSupply.sqf` used `(getPosVisual _vehicle) # 2` (which is **Height Above Sea Level**, not height above ground/deck) for `_heightAboveSurface`. Any base >30m ASL (or hovering above an Aircraft Carrier at ~24m ASL) hit `_heightAboveSurface > 30` and ran `_vehicle setVehicleCargo _cargoObj` (spawning at `[0,0,0]` for ViV loading), which failed for helicopters carrying slingload containers and left the containers at `[0,0,0]`.
  4. Line 131 (`if (_isHelicopter && _heightAboveSurface >= 1.5)`) only spawned surface containers if the helicopter was hovering; if landed (`< 1.5m`), it fell through to `setVehicleCargo`.
  5. When troops were spawned at Line 79, `fn_spawnLoadSupply.sqf` did not verify that the vehicle was on the ground/deck and stationary before calling `moveInCargo`.
- **2. Proposed / Applied Corrections:**
  - Updated `fn_initLogisticsTasks.sqf` to preserve each trigger's mission-maker `condition` (`triggerStatements select 0`) at mission start while automatically updating legacy `onActivation` script names (`SpawnLoadSupply11.sqf` $\rightarrow$ `fn_spawnLoadSupply.sqf`, `CargoDelivery3.sqf` $\rightarrow$ `fn_cargoDelivery.sqf`).
  - Updated `fn_spawnLoadSupply.sqf` to strip any trailing `"_pickup"` suffix from `_pickupBaseKey`, and fixed the insufficient-supply `exitWith` check at top-level scope so depleted bases properly abort spawning.
  - Replaced `(getPosVisual _vehicle) # 2` with a downward `lineIntersectsSurfaces` raycast directly beneath the vehicle so `_heightAboveSurface` accurately measures height above terrain, carrier deck, or water.
  - Required vehicles picking up **Troops** to be on the ground/deck (`_heightAboveSurface <= 2.5`) and stationary (`abs (speed _vehicle) < 1`) before spawning and moving troops directly into cargo (`moveInCargo`).
  - Updated **Helicopter** cargo handling (`_loadType == "Helicopter"` or `_isHelicopter`) to always stage physical containers on the pickup pad/deck surface (with collision offset per container) for manual slingloading.
  - Preserved `[0, 0, 0]` creation + `_vehicle setVehicleCargo _cargoObj` for **ViV** vehicles (planes at high altitude or stationary ground/naval/VTOL vehicles on the pad), with safe cleanup (`deleteVehicle`) if `setVehicleCargo` returns `false`.
  - Added `LOGI_fnc_handlePickupTrigger` and automatic trigger bounding-box area markers (`Area_<TriggerName>`) in `fn_initLogisticsTasks.sqf`:
    1. Every `_pickup` and `_dropoff` trigger now automatically generates a semi-transparent shaded `RECTANGLE` or `ELLIPSE` marker on the map matching its exact `triggerArea` (`sizeA`, `sizeB`, `angle`), so players can see the exact loading and delivery boundaries on their in-game map.
    2. Multiple pickup triggers for the same base (such as `MSR_pickup_1`, `MSR_pickup_2`, and `MSR_pickup_3`) are grouped together under one shared timer read from `triggerTimeout`. Players receive a live second-by-second on-screen `hintSilent` countdown (`[MSR LOADING ZONE] Loading supplies... Stay inside the marked zone: Xs remaining`), can move freely between overlapping triggers of the same base without resetting the timer, and only reset if they exit all pickup triggers for that base.
- **3. Status:** **In Testing** (Corrections applied in `fn_initLogisticsTasks.sqf` and `fn_spawnLoadSupply.sqf` — needs in-game verification).

### [ ] 1.8 `fn_cargoDelivery.sqf` V8 Template Indexing, `"_dropoff"` Suffix Stripping & Dedicated Server Chat
- **1. Initial Issue Summary:**
  1. Line 36 of `fn_cargoDelivery.sqf` iterated `forEach ((logisticsCargoTemplates # _templateIndex) # 1)`. In V8, index `# 1` of `logisticsCargoTemplates` is a String (`"Ground Vehicle"`, `"Helicopter"`, `"Plane"`), while index `# 2` is the category loadout Array. Calling `forEach` on a String threw a script error whenever a logistics vehicle entered a dropoff zone.
  2. If a dropoff trigger passed `"<Base>_dropoff"` as `_baseKey`, `fn_cargoDelivery.sqf` credited `LogiScore_<Base>_dropoff_<Category>` instead of `LogiScore_<Base>_<Category>`.
  3. `fn_cargoDelivery.sqf` ran on the server and called local `systemChat`, which was invisible to players on a Dedicated Server, and did not guard against overwriting `-1` (infinite) pools or normalize `"Vehicle"` $\rightarrow$ `"Vehicles"`.
- **2. Proposed / Applied Corrections:**
  - Updated `fn_cargoDelivery.sqf` to index `(logisticsCargoTemplates # _templateIndex) # 2` for the category loadout array.
  - Added automatic stripping of any trailing `"_dropoff"` suffix from `_baseKey`.
  - Normalized `"Vehicle"` $\rightarrow$ `"Vehicles"` and added a `_currentScore != -1` guard before adding points to `LogiScore_<BaseKey>_*`.
  - Replaced server-local `systemChat` calls with `remoteExec ["systemChat", _driver]` so the delivering driver always receives arrival and delivery confirmations.
- **3. Status:** **In Testing** (Corrections applied in `fn_cargoDelivery.sqf` — needs in-game verification).

### [ ] 1.9 `"Vehicle"` vs. `"Vehicles"` Resource Pool Name Mismatch & Multi-SB (`SB_Main` / `SB_Carrier`) Support
- **1. Initial Issue Summary:**
  1. `logisticsBaseDefaults.sqf`, `init.sqf`, `spawnableVehicleTemplate.sqf`, `SupplyScores.sqf`, `logisticsCargoTemplates.sqf`, and `fn_manageLogisticsMissions.sqf` all use `"Vehicle"` (singular) as the pool name (`LogiScore_<BaseKey>_Vehicle`), whereas legacy lines in `qm_serverFunctions.sqf` and `qm_clientFunctions.sqf` referenced `LogiScore_<BaseKey>_Vehicles` (plural). When `QM_fnc_normalizePoolName` mapped `"Vehicle"` to `"Vehicles"`, `QM_fnc_processGarageSpawn` checked `LogiScore_SB_Main_Vehicles` (`0` instead of `2,400,000`) and denied spawning the HEMTT Flatbed and HEMTT Cargo with `"Insufficient Vehicles supply points"`.
  2. With multiple Supply Bases (`SB_Carrier` and `SB_Main`), `fn_manageLogisticsMissions.sqf` previously defaulted to `_allSBs # 0` (`SB_Carrier`, which is at sea) for Tactical pickups and Strategic dropoffs even when driving a ground truck at `SB_Main`.
- **2. Proposed / Applied Corrections:**
  - Updated `QM_fnc_normalizePoolName` and `QM_fnc_serverVehicleSale` in `qm_serverFunctions.sqf`, `qm_clientFunctions.sqf` (Line 130), and `fn_cargoDelivery.sqf` (Line 92) so `"Vehicle"` (singular) is the canonical pool name everywhere (`LogiScore_<BaseKey>_Vehicle`). Each Supply Base (`SB_Carrier`, `SB_Main`, etc.) maintains its own independent `2,400,000` Vehicle pool and other resource pools.
  - Kept strict `_Garage` naming conventions in `QM_fnc_processGarageSpawn` (`qm_serverFunctions.sqf`) and `c_vehicleTabs.sqf` so mission makers use `<BaseKey>_Garage` (or `<BaseKey>_Garage_<#>`) for universal pads and `<BaseKey>_Garage_Boat_<#>` for Boat Racks.
  - Updated `fn_manageLogisticsMissions.sqf` so multiple `SB` and `MSR` bases route Tactical pickups to the nearest `SB` (`SB_Main` vs. `SB_Carrier`), filter out ocean-based SBs/FOBs (`surfaceIsWater`) for ground vehicles (and inland SBs/FOBs for naval vessels), and break score ties by selecting the nearest base.
- **3. Status:** **In Testing** (Corrections applied in `qm_serverFunctions.sqf`, `qm_clientFunctions.sqf`, `fn_cargoDelivery.sqf`, `fn_manageLogisticsMissions.sqf`, and `fn_spawnLoadSupply.sqf` — needs in-game verification).

### [x] 1.10 `QM_fnc_getNearbyAmmoSource` Hardcoded to `"SB"` & Missing Infinite-Pool (`-1`) Support
- **1. Initial Issue Summary:** In `qm_clientFunctions.sqf` (Lines 14–62), `QM_fnc_getNearbyAmmoSource` hardcoded `if (_tName find "SB" == 0 && _tName find "_service" != -1)` and `for "_i" from 1 to 20 do { format ["SB_ammo%1", _i] }`, preventing aircraft from opening the Pylon Manager at any `FOB` or `MSR` base (or any base using underscores like `SB_Carrier_ammo_1`). In addition, `QM_fnc_canOpenPylonMenu` checked `(_ammoPool <= 0)` without allowing `-1` (infinite pool).
- **2. Proposed / Applied Corrections:**
  - Updated `QM_fnc_getNearbyAmmoSource` in `qm_clientFunctions.sqf` to dynamically match `<BaseKey>_service` triggers and `<BaseKey>_ammo*` objects (up to index `100`, with or without underscore) for any base in `logisticsBases` (`MSR`, `SB`, or `FOB`).
  - Updated `QM_fnc_canOpenPylonMenu` to treat `_ammoPool == -1` as valid (infinite ammo).
- **3. Status:** **Verified Resolved** (Confirmed working in-game by user testing).

### [x] 1.11 `fn_pylonManager.sqf` Infinite-Pool (`-1`) Block & Turret / Network `setPylonLoadout`
- **1. Initial Issue Summary:**
  1. In `fn_pylonManager.sqf` (Lines 271–278), when a base had infinite ammo (`_currentPool == -1`), `_netCost > _currentPool` evaluated to `true` for any positive weight increase (blocking pylon equipping at infinite bases), and refunding ordnance overwrote `-1` with `-1 - _netCost`.
  2. Line 282 hardcoded `_veh setPylonLoadout [_pylonIndex, _newMag, true, []]`, which stripped gunner turret ownership (`[0]`) by forcing pilot control (`[]`) and only executed locally without `remoteExec` network synchronization.
- **2. Proposed / Applied Corrections:**
  - Updated `fn_pylonManager.sqf` (Lines 269–299) to bypass pool deduction/refund when `_currentPool == -1`.
  - Preserved each pylon's existing turret path (`_turretPath` from `getAllPylonsInfo _veh`) when calling `setPylonLoadout`, and executed `setPylonLoadout` and `setAmmoOnPylon` across the network via `remoteExec`.
- **3. Status:** **Verified Resolved** (Confirmed working in-game by user testing; adding interactive Pilot vs. Gunner turret control toggle is tracked in Section 4.8).

### [ ] 1.12 `qm_supplyPhysicalController.sqf` Infinite-Pool (`-1`) Zeroing & Case Sensitivity
- **1. Initial Issue Summary:**
  1. In `qm_supplyPhysicalController.sqf` (Lines 35–42), `<BaseKey>_fuel`, `_ammo`, and `_repair` variable names were searched case-sensitively (`find`).
  2. Line 77 checked `if (_currentMasterPool <= 0)` without exempting `-1` (infinite supply), causing the script to zero out the physical Fuel/Ammo/Repair cargo of containers at `MSR` bases (`setFuelCargo 0`, `setAmmoCargo 0`, `setRepairCargo 0`), and Line 145 overwrote `-1` when deducting points.
  3. Line 93 only scanned `["LandVehicle", "Air"]` within 20m, excluding `"Ship"` assets.
- **2. Proposed / Applied Corrections:**
  - Updated `qm_supplyPhysicalController.sqf` to match `_fuel`, `_ammo`, and `_repair` container names case-insensitively (`toLowerANSI`).
  - Added explicit handling for `_currentMasterPool == -1` so infinite bases keep their containers topped up and never overwrite `-1` when servicing nearby vehicles.
  - Added `"Ship"` to the 20m `nearEntities` vehicle scan.
- **3. Status:** **In Testing** (User confirmed passive physical supply containers resupply vehicles properly in-game; base point deduction verification still in testing).

### [ ] 1.13 `fn_executeR4CService.sqf` & `_service` Trigger Filtering (`_x isKindOf "Air"` / `thisList select 0`)
- **1. Initial Issue Summary:**
  1. In `fn_executeR4CService.sqf` (Lines 44–92), each R4-C service lane (`REARM`, `REPAIR`, `RECREW`, `REFUEL`) called `QM_fnc_serverProcessR4C` / `QM_fnc_serverR4CCreateVehicleCrew`, slept for `_delay`, and then unconditionally printed `"Rearm cycle finalized."`, `"Structural composition fully restored."`, or `"Fuel tanks capped to capacity."` via `_veh sideChat`—even when the base had `0` points and the server denied the service.
  2. In `mission.sqm` (`SB_Main_service_1`, `SB_Carrier_service`, `FOB_Destroyer_086_service`, `FOB_Destroyer_011_service`), the trigger `condition` checked `((_x isKindOf "Air"))`, which completely blocked ground vehicles (`LandVehicle`, such as the Prowler) and boats (`Ship`) from ever triggering the service pad at `SB_Main_service_1` for refueling, repairing, rearming, or recrewing.
  3. In addition, the `_service` triggers passed `(thisList select 0)` to `fn_executeR4CService.sqf`; if `thisList select 0` was not `vehicle player`, `if (driver _veh != player) exitWith {};` immediately exited.
- **2. Proposed / Applied Corrections:**
  - Updated `fn_executeR4CService.sqf` to strip `"_service"` case-insensitively and check `LogiScore_<BaseKey>_<Pool>` (`== -1` or `>= _cost`) in each lane so it only reports completion when the base actually has the required supplies, and reports an abort message via `sideChat` when supplies are insufficient.
  - Updated `fn_initLogisticsTasks.sqf` (Lines 166–171) to automatically initialize all `<Base>_service*` triggers at mission start so they accept `LandVehicle`, `Air`, and `Ship`, pass `vehicle player` directly to `fn_executeR4CService.sqf`, and draw yellow map markers and bounding boxes (`Service_<Base>` and `Area_<TriggerName>`) on the in-game map.
- **3. Status:** **In Testing** (Corrections applied in `fn_executeR4CService.sqf` and `fn_initLogisticsTasks.sqf` — needs in-game verification with a Prowler/ground vehicle and aircraft).

### [x] 1.14 MSR (Main Supply Route) Architectural Role & Infinite Supply Ingress Pipeline
- **1. Initial Issue Summary:**
  1. In `fn_spawnLoadSupply.sqf` (Lines 91–97), `_availablePoints != -1 && _availablePoints < _totalCargoPointWeight` checked whether base storage had sufficient points before spawning. When loading at an MSR hub, if `LogiScore_MSR_<category>` was not found in `missionNamespace` (e.g. if no map marker was named `"MSR"` or before network sync), `getVariable` returned `0` (`0 != -1`), which evaluated as depleted and aborted with `"WARNING: Stores low on <category> at MSR."`.
  2. Because of this top-level script exit, `fn_spawnLoadSupply.sqf` aborted before reaching the cargo spawning code, completely preventing cargo from spawning or loading into the transport vehicle.
  3. In `init.sqf` (Lines 121–152), `logisticsBases` and `LogiScore_<base>_*` were only initialized from markers in `allMapMarkers`. If mission makers placed MSR pickup triggers (`MSR_pickup_1`..`5`) without a dedicated marker named `"MSR"`, `"MSR"` was omitted from `logisticsBases` and its infinite (`-1`) pool values were never initialized.
  4. Architectural Scope Clarification: MSR was previously at risk of being treated as a standard operating base with player respawns, arsenals, vehicle factories, and service pads, and an artificial `b_installation` marker was being spawned on map init.
- **2. Proposed / Applied Corrections:**
  - **Off-Map Supply Pipeline Role:** MSR is strictly an off-map / boundary supply ingress corridor solely for generating and hauling supplies forward (Cargo crates, Vehicle Ammo crates, Fuel bladders, Repair containers, Troop reinforcement AI squads):
    - **No Player Respawn:** MSR is strictly excluded from `qm_clientRespawnManager.sqf` and `onPlayerRespawn.sqf`. Players cannot spawn or respawn at MSR.
    - **No Vehicle Procurement / Garage:** MSR does not host a vehicle procurement terminal or garage pads for player use.
    - **No R4-C Vehicle Service:** MSR does not provide vehicle rearming, repair, refueling, or AI recrewing (`fn_executeR4CService.sqf`, `qm_clientFunctions.sqf`, and `qm_serverFunctions.sqf` strictly guard against MSR).
    - **No Terminals or Arsenals:** MSR is excluded from physical terminal/arsenal loops in `qm_serverGarrisonManager.sqf`.
    - **Map Representation:** Removed artificial `b_installation` map marker creation in `init.sqf`. MSR's pickup corridors/pads are represented exclusively by their functional `mil_pickup` markers without misleading base labels.
  - **Troop Reinforcement Transportation:** When Troop supplies are loaded at MSR (`_supplyType == "Troops"`), AI troops board the transport vehicle, the player hauls them to a rear Staging Base (SB) or forward base (FOB) dropoff pad, and upon dropoff, those troops are inducted into that receiving base's troop pool.
  - **Infinite Pool Safeguards:** Preserved infinite (`-1`) pool ledgers for MSR in `init.sqf` and `fn_spawnLoadSupply.sqf`, with native Vehicle-in-Vehicle (`setVehicleCargo`) loading.
- **3. Status:** **Verified Resolved** (Architecture aligned with off-map ingress role; respawn, garage, service, and marker exclusions implemented).

### [x] 1.15 Dropoff Pad Cargo Offload Unconditionally Deleting Pre-Placed Base Arsenals & Infrastructure
- **1. Initial Issue Summary:**
  - In `fn_cargoDelivery.sqf` (Line 105), `deleteVehicle _object;` was executed unconditionally inside the nearby objects scan loop, outside the `if (_scoreIndex != -1)` validation block.
  - As a result, when a player delivered cargo to a dropoff pad, any `ReammoBox_F`, `AllVehicles`, `ThingX`, `Air`, or `Strategic` entity located within the trigger radius—including editor-placed Arsenals (`VirtualReammoBox_camonet_F`, e.g. `FOB_AgiaMarinaBase_Arsenal`), base Terminals, and Ammo Caches—was permanently deleted from the world.
  - This occurred because `SB_Main_dropoff_1` had a large 533-meter trigger radius and `FOB_AgiaMarinaBase_dropoff` spanned 41 meters, sweeping editor objects into the deletion list.
- **2. Proposed / Applied Corrections:**
  - In `fn_cargoDelivery.sqf`, added strict base infrastructure protection checking `vehicleVarName`, `QM_Crate_OwningBase`, `QM_TerminalUnifiedActionsActive`, `QM_Global_Terminals`, and `bis_fnc_arsenal_action` (protecting all `Arsenal`, `Terminal`, `Service`, `_Ammo`, `_Fuel`, `_Repair`, `_Spawn`, and `_Garage` objects).
  - Restricted cargo scanning strictly to `_object inArea _triggerArea` (or within 15 meters of pad center) rather than unbounded bounding-box radii.
  - Moved `deleteVehicle _object;` strictly inside `if (_scoreIndex != -1)` so objects are only deleted if they are verified logistics supply items credited to the base economy pool.
  - In `fn_spawnLoadSupply.sqf`, explicitly tagged all dynamically spawned logistics cargo and slingload pods with `_cargoObj setVariable ["isLogisticsCargo", true, true];`.
- **3. Status:** **Verified Resolved** (In Testing).

### [x] 1.16 Immediate Cargo Offload Processing & Anti-Collision Engine
- **1. Initial Issue Summary:**
  - In `fn_cargoDelivery.sqf`, the offload scanning loop blocked processing whenever internal vehicle cargo (`getVehicleCargo`) or slingloads (`getSlingLoad`) were still present (`if (count _allInternalCargo > 0 || _hasSlingLoadAttached) then { sleep 1; } else { ... };`).
  - As a result, when a player unloaded multiple cargo crates from a transport truck onto a dropoff pad, previous code waited until the truck was completely empty before scanning, crediting, or deleting any crates.
  - Newly offloaded crates collided with resting crates on the pad within the same bounding zone, triggering Arma 3 physics engine impact damage that caused crates to violently explode, destroy supplies, and fail delivery credit.
- **2. Proposed / Applied Corrections:**
  - Removed the blocking cargo check gate in `fn_cargoDelivery.sqf`. The trigger area now performs continuous real-time scanning across every tick.
  - As soon as each individual supply crate touches the dropoff pad tarmac, it is immediately validated against `supplyScores`, credited directly to the receiving base's resource caches, and deleted on the spot (`deleteVehicle _object`).
  - Completely eliminates crate-on-crate physics collisions and damage on the dropoff tarmac.
  - Final delivery receipt messaging, driver notification, and truck load unmarking (`logistics_is_loaded = false`, `logistics_intended_fob = ""`) trigger cleanly once the vehicle has completely emptied all internal and slingload cargo and at least one delivery was recorded.
- **3. Status:** **Verified Resolved** (In Testing).

---

## 2. Economy, Filtering & Configuration Inconsistencies

### [x] 2.1 Base Restriction Tier Discrepancy (`c_vehicleTabs.sqf` vs. `fn_recruiter_list.sqf`)
- **1. Initial Issue Summary:**
  - In `fn_recruiter_list.sqf` (Line 67), `"FOB"`-tier units were allowed at both `FOB` and `SB` bases (`_isFOB || _isSB`), allowing frontline-only `"FOB"` infantry to be spawned at rear `"SB"` hubs.
  - Neither `fn_recruiter_list.sqf` nor `c_vehicleTabs.sqf` supported `"BOTH"` or an array of allowed base types/names (e.g., `["SB", "FOB"]`).
- **2. Proposed / Applied Corrections:** Updated both `fn_recruiter_list.sqf` (Lines 68–84) and `c_vehicleTabs.sqf` (Lines 156–170) so that:
  - `"SB"` restricts strictly to `SB` bases (`_isSB`).
  - `"FOB"` restricts strictly to `FOB` bases (`_isFOB`).
  - `"ALL"` or `"BOTH"` allows spawning at both `SB` and `FOB` bases (`_isSB || _isFOB`).
  - Array restrictions (e.g., `["SB", "FOB"]` or specific base names like `["SB_Carrier"]`) are also supported.
- **3. Status:** **Verified Resolved** (In Testing).

### [x] 2.2 Case Sensitivity in Infantry & Vehicle Template Filtering
- **1. Initial Issue Summary:** In `fn_recruiter_list.sqf` (Lines 62–64), `_faction`, `_terrainArray`, and `_systemsArray` were compared without `toUpper` normalization, and in `c_vehicleTabs.sqf` (Line 150), `_systemsArray` was compared without `toUpper`.
- **2. Proposed / Applied Corrections:** Normalized `_faction`, `_terrainArray`, `_systemsArray`, and `_restrictionType` in both `fn_recruiter_list.sqf` and `c_vehicleTabs.sqf` using `toUpper` so mission-maker case differences never break filtering.
- **3. Status:** **Verified Resolved** (In Testing).

### [x] 2.3 `B_supplyCrate_F` Cost / Score Values in Templates
- **1. Initial Issue Summary:** `B_supplyCrate_F` is set to `4,000` Cargo points in `spawnableVehicleTemplate.sqf` (Line 195) and `7,000` Cargo points in `SupplyScores.sqf` (Line 15).
- **2. Proposed / Applied Corrections:** None required — template values were intentionally configured by the author and are designed to be mission-maker customizable.
- **3. Status:** **Verified Resolved / By Design** (Template files left untouched per design specification).

### [x] 2.4 Service Truck & Huron Container `1,000,000` Cost Entries vs. `10,000,000` Script Filter
- **1. Initial Issue Summary:** `c_vehicleTabs.sqf` (Line 205) and `qm_serverFunctions.sqf` (Lines 54, 256, 337) filtered out pool costs `>= 10000000` (10M), while `spawnableVehicleTemplate.sqf` (Lines 52–67, 89, 184–188) has `1000000` (1M — representing bulk/infinite `transportAmmo`/`transportFuel`/`transportRepair` config values) on HEMTT service trucks, Bobcats, and Huron containers. Because `1,000,000 < 10,000,000`, the scripts billed 1,000,000 Ammo/Fuel/Repair/Cargo points when spawning those assets (which exceeded an SB's starting 100k–300k pools).
- **2. Proposed / Applied Corrections:** Kept `spawnableVehicleTemplate.sqf` untouched and updated the cost filter threshold in `c_vehicleTabs.sqf` (Line 212) and `qm_serverFunctions.sqf` (`QM_fnc_serverVehicleSale` and `QM_fnc_processGarageSpawn`) from `< 10000000` to `< 1000000` so `1000000` config-capacity values are excluded while normal chassis/fuel/cargo costs are billed and refunded normally.
- **3. Status:** **Verified Resolved** (In Testing).

---

## 3. Incomplete Features & Legacy/Redundant Files

### [x] 3.1 Unwired Pylon Dialog Controls (`QM_PylonDialog` UI Polish)
- **1. Initial Issue Summary:** In `qm_pylonMenu.hpp` (Lines 124–156), UI controls for Internal Weapon Systems (`GunHeader` 8300, `GunSlider` 8301, `GunSliderText` 8302) and Livery/Camo (`CamoDropdown` 8400) existed in the dialog definition, but had no logic or event handlers bound to them, cluttering the UI.
- **2. Proposed / Applied Corrections:** Polished the Pylon dialog by hiding controls 8300, 8301, 8302, and 8400 (`show = 0` in `qm_pylonMenu.hpp` and `ctrlShow false` in `fn_pylonManager.sqf`). Future feature requests for internal gun ammo belt scaling and aircraft livery/camo selection are tracked under **Section 4.8**.
- **3. Status:** **Verified Resolved** (Unimplemented controls hidden; feature requests deferred to Section 4.8).

### [x] 3.2 Infantry Recruitment UI Polish (Squad Quick-Draft vs. Individual Specialists)
- **1. Initial Issue Summary:** In `qm_quartermasterUI.hpp` (Lines 40, 49), Column 2 of `CfgControlHubMenu` was previously titled `"AUTONOMOUS LOGISTICS GROUPS [SERVER]"` / `"MOBILIZE INDEPENDENT UNIT"`, which created confusion because `QM_fnc_serverCreateLocalGroup` in `qm_serverFunctions.sqf` (Lines 136–191) attaches the spawned AI group directly to `group _playerUnit` (the player's personal squad), behaving as a quick-draft squad composition rather than an autonomous/independent entity.
- **2. Proposed / Applied Corrections:**
  - Polished `qm_quartermasterUI.hpp`:
    - Updated Column 1 Header to `"INDIVIDUAL SPECIALIST RECRUITS"` and button to `"DRAFT RECRUIT TO YOUR SQUAD"`.
    - Updated Column 2 Header to `"SQUAD TEMPLATES [QUICK DRAFT]"` and button to `"DRAFT SQUAD TEMPLATE TO YOUR SQUAD"`.
  - Added a dedicated low-priority feature request to **Section 4.9** for a potential future 3rd column or autonomous AI module that answers to the player through High Command (`setCommander` / `BIS_fnc_HCSetGroupSelection`).
- **3. Status:** **Verified Resolved** (UI headers and labels aligned with squad integration).

### [x] 3.3 External Modular Systems (Combat Tasking System / GIN / Zeus / WorldAI)
- **1. Initial Issue Summary:** Several scripts are referenced via `fileExists` or UI `action` strings that are external to this repository:
  - Tactical Command Center / GIN (`tsk_serverGIN.sqf`, `tsk_clientMapIntel.sqf`, `tsk_clientTaskMaster.sqf`)
  - Zeus Master Admin Tablet (`fn_adminTabletLoad.sqf`, `fn_adminTabletExecute.sqf`)
  - WorldAI Spawner: Referenced by `"WorldAI"` tags and multi-vehicle convoy blueprints in `spawnableInfantryTemplate.sqf` and `spawnableVehicleTemplate.sqf`.
- **2. Proposed / Applied Corrections:** Documented that these references belong to the separate **Combat Tasking System** within the larger modular dynamic mission architecture. All hooks in `init.sqf` are safely guarded with `fileExists` checks so the Logistics System functions seamlessly as a standalone core or alongside the combat systems without modification or errors.
- **3. Status:** **Verified Resolved / By Design** (External modular hooks confirmed and left untouched).

### [x] 3.4 Redundant / Superseded Workspace Files & Code Blocks
- **1. Initial Issue Summary:**
  - `qm_openPylonMenu.sqf` — Contained `.hpp` C++ dialog classes inside a `.sqf` file; unused.
  - `c_vehicleExecute.sqf` — Duplicate of `fn_newCarDealership.sqf`; unused by `qm_quartermasterUI.hpp`.
  - `c_unifiedMenu.sqf` — Legacy terminal entry script; superseded by `qm_clientActionCompiler.sqf`.
  - `QM_fnc_initVirtualArsenal` in `fn_equipmentTrader.sqf` (Lines 14–84) — Uncalled function (superseded by inline Arsenal logic in `qm_clientActionCompiler.sqf`).
  - `QM_fnc_clientRegisterTraderActions` in `qm_clientActionCompiler.sqf` (Line 15) and `qm_clientFunctions.sqf` (Line 101) — Empty no-op stub.
  - Duplicate `_GARAGE` marker hiding loop in `init.sqf` (Lines 113–115 and 129–131).
- **2. Proposed / Applied Corrections:**
  - Moved `qm_openPylonMenu.sqf`, `c_vehicleExecute.sqf`, and `c_unifiedMenu.sqf` into an `archive/` folder.
  - Removed dead `QM_fnc_initVirtualArsenal` function block from `fn_equipmentTrader.sqf`.
  - Removed no-op stub `QM_fnc_clientRegisterTraderActions` from `qm_clientActionCompiler.sqf` and its caller in `qm_clientFunctions.sqf`.
  - Removed the duplicate `_GARAGE` marker hiding loop in `init.sqf`.
- **3. Status:** **Verified Resolved** (Files archived and code cleaned up).

### 3.5 Base Supply Manifest Map Entry Displays Scientific Notation (`1.6e+06`) & Unformatted Numbers

- **1. Initial Issue Summary:**
  - On the map diary screen under **"Base Supply Manifest"** (`BasesManifestTab`), base resource pools with 1,000,000+ points (such as Staging Base Cargo and Vehicle pools at 1,600,000) reverted to raw engine scientific notation (`1.6e+06`).
  - Numbers lacked thousands comma separators and value range context, making it difficult to gauge high-tier economy totals at a glance.
  - The map ledger thread in `qm_clientFunctions.sqf` was passing raw scalars into `format` strings without formatting, and `logi_fnc_formatPoints` in `fn_manageLogisticsMissions.sqf` lacked full scientific notation expansion and range scale descriptors for very large numbers.
- **2. Proposed / Applied Corrections:**
  - Standardized `logi_fnc_formatPoints` across `qm_clientFunctions.sqf` and `fn_manageLogisticsMissions.sqf` to dynamically expand all positive and negative scientific notation floats up to 100+ Trillion (`1e+014`) into full-length integer strings.
  - Added thousands comma formatting (`1,600,000`).
  - Added dynamic value range scale tags off to the side: `(Thousands)`, `(Millions)`, `(Billions)`, `(Trillions)`, `(Quadrillions)`, `(Quintillions)` (leaving sub-1000 numbers unadorned for clarity).
  - Preserved `"UNLIMITED"` for infinite pools (`-1` at MSR hubs).
  - Updated `qm_clientFunctions.sqf` map diary ledger to route all 7 supply categories through `logi_fnc_formatPoints` and format base titles cleanly (e.g., `SB Main`, `FOB CampMaxwell`).
  - Updated `fn_recruiter_list.sqf` title card to format base manpower totals with the same standard.
- **3. Status:** **Verified Resolved** (In Testing).

---

## 4. Logistics Framework V8 — Current Development Goals

These are the current development goals for Logistics Framework V8. They should be treated as an ongoing development checklist that remains active throughout the project.

**Important development priorities:**
- These goals are intended to be worked on after and/or alongside resolving existing coding bugs, logic errors, and other issues discovered during development.
- Do not treat these goals as a requirement to stop current debugging or bug-fixing work.
- When resolving bugs or making changes to existing systems, consider whether the work overlaps with or contributes to any of these goals.
- Track the completion of each goal and its subtasks.
- Update this checklist as work progresses. Mark completed items accordingly.
- Do not consider a goal complete until its associated subtasks have been addressed.
- Preserve the existing framework architecture and conventions unless a change is necessary to accomplish a goal.

---

### 4.1 Standalone Loading Mechanic & Field Capability Registry (Implemented — In Testing)

Develop a standalone loading mechanic that distinguishes between loading zones and non-loading zones, regulating Vehicle-in-Vehicle (ViV) loading based on cargo mass, crew complement, and vehicle material-handling equipment (`fn_standaloneLoadingMechanic.sqf` and `logisticsFieldLoadingTemplate.sqf`):

- [x] **Implement loading zones (`QM_fnc_isInsideLoadingZone`):**
  - [x] Allow anything a vehicle is capable of carrying (Huron containers, cargo nets, vehicle ammo, supply boxes) to be loaded freely within designated Base Loading Zones (`_isPickup` triggers) thanks to base infrastructure (forklifts, overhead cranes, depot crews).
- [x] **Implement Field-Loading Capability Registry (`logisticsFieldLoadingTemplate.sqf`):**
  - [x] **Onboard Crane Vehicles (`["ALL"]`):** Vehicles equipped with heavy hydraulic material-handling cranes (e.g. RHS M1084 FMTV series, Russian KamAZ 5350 Crane variants, Ural Cranes) are authorized to field-load *any* cargo they physically fit into their bays anywhere in the field.
  - [x] **Container Winch Vehicles (`["Huron_Containers"]`):** The HEMTT Flatbed (`B_Truck_01_flatbed_F` / `B_T_Truck_01_flatbed_F`) is equipped with an onboard container winch/tilt-bed and is authorized to field-load 20ft Huron Containers (`B_Slingload_01_*_F`) anywhere. It *cannot* field-load cargo nets or vehicle ammo boxes in the field without being inside a Base Loading Zone.
  - [x] **Unassisted Standard Haulers (`[]`):** Vehicles without self-loading equipment (HEMTT Cargo, Blackfish, Huron ViV, Vans, LSVs) are restricted to human-liftable weight tiers when in the field.
  - [x] **Object Variable Override:** Supported via `_vehicle setVariable ["QM_FieldLoadingCapacity", ["ALL"], true]` for easy Eden editor / script-driven assignment without editing templates.
- [x] **Implement non-loading zones (Austere Field Loading):**
  - [x] Restrict unassisted field loading according to item mass:
    - [x] **Tier 1 (<= 120 lbs):** Single player can load into any compatible vehicle anywhere.
    - [x] **Tier 2 (121 - 250 lbs):** Requires at least TWO players nearby (within 12m) to team-lift into a vehicle; rejected and unloaded back onto the ground if fewer than two players are present.
    - [x] **Tier 3 (> 250 lbs):** Prohibited in the field! Must be loaded inside a designated Base Loading Zone (or requires a vehicle equipped with an onboard crane).
  - [x] **Interactive Field Actions:**
    - [x] `[FLATBED WINCH] Load Nearby Huron Container` added to Flatbeds (cyan).
    - [x] `[FIELD CRANE] Hoist Nearby Cargo` added to crane-equipped trucks (orange).
    - [x] Short-circuit distance evaluation (`player distance _target < 10`) eliminates unnecessary per-frame entity scans for optimized client performance.
- [x] **Engine Event Handler & Multiplayer Authority:**
  - [x] Switched ViV event interceptor to native `CargoLoaded` / `CargoUnloaded` engine event handlers.
  - [x] Authoritative validation runs strictly on `isServer`, preventing MP race conditions, multiple unloads, and duplicate network chat broadcasts.
  - [x] Reset `logistics_is_loaded` and `logistics_loaded_type` dynamically on `CargoUnloaded` when bay is emptied.
- [x] **Slingload Helicopter Exclusion:**
  - [x] Standard external helicopter slingloading is unaffected; restrictions apply strictly to internal Vehicle-in-Vehicle (ViV) transport.

### 4.2 Respawn System Updates & Per-Player FOB Cooldowns (Implemented — In Testing)

Update the respawn system to account for troop supply availability and individual player respawn restrictions at forward bases (`qm_clientRespawnManager.sqf`, `onPlayerRespawn.sqf`, `init.sqf`):

- [x] **Integrate troop supply availability into respawn location selection:**
  - [x] Only display bases with available troop supply points (`LogiScore_<Base>_Troops > 0` or `-1` infinite) in the respawn selection list.
  - [x] Bases with depleted troop pools (`0`) are dynamically purged from players' respawn menus until reinforcements are delivered.
- [x] **Implement per-player, per-base FOB cooldown timers:**
  - [x] **Per-Player Client Isolation:** Delegated respawn registration from side-wide `west` to per-player targeting (`[player, _entity, _name] call BIS_fnc_addRespawnPosition`), ensuring that a cooldown on one player never locks out or interferes with other players.
  - [x] **Forward Operating Base (FOB) Cooldown:** When a player respawns at a FOB, a tactical cooldown timer (`QM_Respawn_FOBCooldown`, default 120s / 2 minutes, configurable in `init.sqf`) is applied strictly for that player and that FOB via a persistent client session map (`QM_Local_FOBCooldowns`).
  - [x] **Supply Base (SB) Cooldown Exemption & MSR Ingress Separation:** Rear-echelon Supply Bases (`SB_Main`, `SB_Carrier`) have **zero** cooldown. A player killed in action can always redeploy immediately to a Supply Base (subject only to the standard engine 10-second death delay `respawnDelay`). MSR is strictly an off-map supply ingress pipeline and is completely excluded from player respawning.
  - [x] Dynamic auto-restoration: If a player sits in the respawn menu, the FOB dynamically re-appears as an available spawn point the exact second their cooldown timer expires.
- [x] **Support realistic gameplay pacing & anti-exploit security:**
  - [x] Eliminates the "revolving door" exploit where killed players repeatedly respawn at the exact same forward FOB within seconds to rush enemy sniper or ambush positions.
  - [x] Encourages medical revives, base defense, intelligence sharing, and logistics supply runs (flying or driving reinforcements forward from rear SBs).

### [x] 4.3 Vehicle Spawning System Updates (Verified Resolved)

Improve vehicle spawning accuracy and transition toward physical objects as spawn-point references instead of relying on markers.

- [x] Improve spawn positioning and height accuracy. *(Verified Resolved)*
  - [x] Prevent objects from spawning above their intended positions. *(Uses exact 3D `getPosASL` of editor-placed pad object)*
  - [x] Prevent objects from spawning below their intended positions. *(Uses exact 3D `getPosASL` of editor-placed pad object)*
  - [x] Ensure objects spawn exactly where intended. *(Uses exact 3D `getPosASL` and `getDir` of editor-placed pad object)*
- [x] Transition from markers to physical objects as spawn-point references. *(Verified Resolved — `_Arsenal`/`_Terminal`, `_Spawn`, and `_Garage` now strictly use editor-placed 3D objects via variable name; markers are reserved for base identification)*
- [x] Develop spawn-point object compatibility. *(Verified Resolved)*
  - [x] Determine which objects permit which vehicle types to spawn. *(Determined strictly by the object's variable name suffix: `_GROUND`, `_HELI`/`_HELICOPTER`, `_PLANE`, `_AIR`, `_BOAT`, or universal, plus `XXS`..`XL` upper-limit sizing)*
  - [x] Determine how each object positions the vehicles it spawns.
  - [x] Support boat racks for compatible boats.
    - [x] Position boats using the vehicle-in-vehicle cargo position. *(`_padObj setVehicleCargo _veh` when the garage object is a Boat Rack or near one)*
    - [x] Prevent incompatible vehicle types, such as helicopters, from spawning at boat racks. *(Enforced by `_BOAT` vs. `_HELI`/`_PLANE`/`_GROUND` variable naming)*
  - [x] Support invisible helipads for helicopters.
    - [x] Position helicopters on top of the invisible helipad, similar to the existing marker-based positioning behavior. *(`_veh setPosASL (getPosASL _padObj)`)*
    - [x] Prevent incompatible vehicle types from spawning at designated objects. *(Enforced by variable name type and size specifiers)*

### 4.4 Modded Vehicle and Equipment Handling (Universal Mod & CDLC Compatibility)

Update the existing template-based architecture to support comprehensive master templates for vehicles, infantry, weapons, equipment, magazines, and items that automatically adapt to loaded mods and CDLCs, ensuring mission makers can maintain a single template file that functions across any terrain, modset, or DLC configuration:

- [ ] **Universal Multi-Mod / CDLC Master Template Architecture:**
  - [ ] Allow mission makers to define a unified master template file containing vehicles (`spawnableVehicleTemplate.sqf`), infantry (`fn_recruiter_list.sqf`), cargo (`logisticsCargoTemplates.sqf`), weapons, magazines, and equipment across Vanilla, CDLCs (Western Sahara, Spearhead 1944, S.O.G. Prairie Fire, CSLA, Global Mobilization), and popular community mods (RHS, CUP, 3CB, etc.).
  - [ ] Ensure the framework gracefully parses templates without generating engine config errors, missing-asset warnings, or script halts when optional mods/CDLCs are not active.
- [ ] **Class Existence Validation Engine (`isClass` Config Verification):**
  - [ ] Implement robust config verification across all UI builders and spawner loops, mirroring the graceful `fileExists` pattern used for mission scripts:
    - [ ] **Vehicles, Drones & Statics:** `isClass (configFile >> "CfgVehicles" >> _classname)` in `c_vehicleTabs.sqf` and Motorpool UI.
    - [ ] **Infantry Specialists & Squads:** `isClass (configFile >> "CfgVehicles" >> _classname)` in `fn_recruiter_list.sqf` and Recruiter UI.
    - [ ] **Weapons & Attachments:** `isClass (configFile >> "CfgWeapons" >> _classname)` in Virtual Arsenal and loadout handlers.
    - [ ] **Equipment, Vests, Uniforms & Headgear:** `isClass (configFile >> "CfgWeapons" >> _classname) || isClass (configFile >> "CfgGlasses" >> _classname)`.
    - [ ] **Magazines & Ordnance:** `isClass (configFile >> "CfgMagazines" >> _classname)`.
  - [ ] Automatically suppress and hide any entry from menus if its class does not exist in the active engine session.
- [ ] **Vehicle & Equipment Spawner Safety:**
  - [ ] Prevent unverified or missing classnames from reaching `createVehicle`, `createUnit`, `addWeapon`, or `setPylonLoadout`.
- [ ] **Content Set & Era Filtering Toggles (Phase 2):**
  - [ ] Provide mission-maker configuration toggles to enable or restrict specific eras and content packs (e.g. `QM_AllowedEras = ["WW2", "VIETNAM", "COLD_WAR", "MODERN", "2035"]` or `QM_DisableVanilla2035 = true;`).
  - [ ] Ensure historical or thematic missions (such as World War II or Vietnam) can suppress vanilla 2035 assets (preventing futuristic aircraft like the Black Wasp II or stealth drones from appearing alongside period-accurate assets) even when running on the vanilla engine.

### 4.5 Vehicle Salvage System Redesign (Low Priority — Combined Bug 1.5 Fix & Feature Update)

Replace the current blind radius-based salvage check (`fn_usedCarSalesman.sqf`) with a dedicated, reliable Salvage system at bases.

- [ ] Support Laptop / Terminal Objects (`_Terminal` / `_Arsenal`) placed at vehicle spawn locations or base hubs.
- [ ] **Option A — Salvage Menu UI (Reusing Motorpool Dialog):**
  - [ ] Open a Salvage menu via `addAction` that reuses the Motorpool UI layout (`CfgVehicleProcureMenu`) and tabs (`Wheeled`, `Tracked`, `Helis`, `Planes`, `Boats`, `Drones`, `Supplies`).
  - [ ] List all unoccupied, salvageable vehicles (any vehicle present in `G_Procureable_Vehicles`) currently located at the base (near any base marker, 3D facility/spawn object, or dropoff zone).
  - [ ] Display live vehicle status/stats in the UI (e.g., Health / Damage %, Fuel remaining %, Ammo remaining %) and scale or display the corresponding resource refund.
  - [ ] Allow the player to select the exact vehicle from the list and confirm despawning/salvaging it.
- [ ] **Option B — Direct Look-At (`cursorObject`) Salvage Action:**
  - [ ] When a player is at a base and walks up to / looks directly at an unoccupied spawnable vehicle, provide a context-sensitive `addAction` on the vehicle (or player) to salvage that specific vehicle.
- [x] **Option C (Implemented — In Testing) — Dropoff Zone Vehicle Salvage with Disembark Confirmation Prompt:**
  - [x] Eliminated the broken scroll-wheel terminal `addAction` (`fn_usedCarSalesman.sqf`) from base terminals.
  - [x] Designated the existing base **Dropoff Zone** as the universal vehicle return location.
  - [x] When an unoccupied vehicle is parked inside the dropoff zone and the crew disembarks, `GetOutMan` prompts the last player to exit with an interactive `BIS_fnc_guiMessage` confirmation: `"Would you like to SALVAGE this [Vehicle Name] and recycle its resources back to [Base Name]? [YES / NO]"`.
  - [x] If confirmed YES: despawns vehicle, refunds chassis/cargo points to base pool, and unregisters its vehicle cap (`QM_CAP`) via `QM_fnc_serverVehicleSale`. If NO: leaves vehicle untouched.
  - [x] Registered direct look-at `addAction` on the player (`[SALVAGE CONTROL] Recycle Vehicle to Base`) for ad-hoc salvage of unoccupied vehicles inside any base dropoff pad.

### 4.6 Contested Bases (`Contested_*`) Conquest Mechanics & Modular Integration
- **1. Architectural Scope & Folder Isolation:**
  - Contested Bases represent dynamic frontline territory control (Battlefield Conquest game mode), which is an independent tactical system that *interfaces* with logistics.
  - To prevent coupling or regressions in core logistics, all Conquest scripts, triggers, and daemons will reside in their own dedicated directory: `conquest/` (prefixed with `conq_*`).
  - **Zero-Dependency Guard:** If a mission maker does not place any `Contested_*` markers or triggers on the map, the conquest module idles or exits immediately with zero CPU overhead. If present, it binds dynamically to the logistics framework.

- **2. Capture Mechanics & Faction State Handover:**
  - **Dominance Radius Watchdog (`conq_captureDaemon.sqf`):** Monitors physical presence inside the base capture zone. When opposing forces attain numerical dominance, capture progress shifts toward Neutral ($0\%$), then climbs toward $100\%$ enemy control.
  - **Visual & Tactical Handover:**
    - Updates map marker icon and color dynamically (`b_installation` / `ColorWEST` $\leftrightarrow$ `o_installation` / `ColorEAST` $\leftrightarrow$ `n_installation` / `ColorCivilian`).
    - Flips physical flag pole texture to match active faction.
  - **Infrastructure Gating:**
    - Quartermaster Terminals and Virtual Arsenals check player side (`side player == _baseControllingSide`); enemy players are locked out.
    - R4-C Service Pads only refuel, rearm, and repair vehicles belonging to the controlling faction.
    - Base Respawn Manager (`qm_serverRespawnManager.sqf`) unregisters the respawn position from the losing faction and binds it to the capturing faction.

- **3. Supply Handover Model (Plunder / Spoils of War):**
  - **Zero Starting Supplies:** Contested bases initialize with **$0$ supplies across all pools** (`Cargo: 0, Ammo: 0, Fuel: 0, Medical: 0, Repair: 0, Vehicle: 0, Troops: 0`). Everything must be physically delivered or captured.
  - **The Plunder Rule:** The capturing faction inherits whatever remaining ledger points exist in the base at the exact instant the capture is finalized.
  - **Live Resupply During Contested State:** Logistics pilots and drivers are authorized to deliver supplies to a contested base up until the exact moment ownership flips. If the base trades hands while supplies are on the ground or in transit, the newly capturing side reaps the benefits.
  - **Stockpile Volatility:** High supply stockpiles raise the strategic stakes of holding or losing a contested outpost—stocking 50,000 Ammo or Vehicle Material means an enemy capturing the base can immediately procure heavy armor and ordnance from your former garages.

- **4. Contested Base Infrastructure Restoration:**
  - Upon successful capture, all base infrastructure (terminals, arsenals, helipads, garages) is claimed by the new faction. Intact facilities become immediately operational.
  - Destroyed infrastructure adheres to the 1-hour supply reconstruction rules detailed in Section 6.4.

- **5. Faction Permanence vs. Dynamic Contested Bases:**
  - **`CON` are the ONLY bases that can trade sides:** Contested sectors represent dynamic tactical frontline objectives that can flip control between factions during gameplay.
  - **All other base types maintain side permanence:** Standard bases (`MSR`, `CS`, `AOR`, `SB`, `CVN`, `LHA`, `LPD`, `LST`, `DDG`, `DD`, `FFG`/`FG`, `FOB`) remain permanently aligned with their original starting faction. Enemy forces cannot capture or flip them.
  - **Starvation / Supply Depletion Behavior:** If a permanent base runs out of supplies (or its infrastructure is destroyed), it becomes dormant/inactive—players lose the ability to spawn vehicles, rearm, or use it as an operational staging point. However, ownership does not flip; as soon as friendly logistics units resupply the base, it becomes fully active and operational again.

- [ ] Transition `Contested_*` facility markers (`_Arsenal`, `_Garage`, `_Spawn`, `_Service`) to 3D editor objects in `mission.sqm`.
- [ ] Build isolated `conquest/conq_captureDaemon.sqf` with dominance radius math and faction state synchronization.
- [ ] Implement Plunder ledger transfer and terminal/respawn handover callbacks.

### 4.7 Route-Tiered & Difficulty-Scaled Cargo Templates (`Strategic` / `Tactical` / `CLT`)

Expand `logisticsCargoTemplates.sqf` (and update `fn_spawnLoadSupply.sqf`, `fn_cargoDelivery.sqf`, and `fn_manageLogisticsMissions.sqf`) so each supply category within a vehicle's template contains nested sub-arrays keyed by route (`"Strategic"`, `"Tactical"`, `"CLT"`).

- [ ] **Nested Route-Tiered Array Schema for `logisticsCargoTemplates.sqf`:**
  ```sqf
  [
      "B_Truck_01_flatbed_F",
      [
          ["Cargo", [
              ["Strategic", ["B_Slingload_01_Cargo_F"]],
              ["Tactical",  ["B_CargoNet_01_ammo_F", "B_CargoNet_01_ammo_F", "B_CargoNet_01_ammo_F"]],
              ["CLT",       ["B_supplyCrate_F", "B_supplyCrate_F", "B_supplyCrate_F", "B_supplyCrate_F", "B_supplyCrate_F"]]
          ]],
          ...
      ]
  ]
  ```
  - [ ] **Strategic Route (`MSR` $\rightarrow$ `SB`):** Uses the `"Strategic"` sub-array (e.g., Huron Containers `B_Slingload_01_*_F` for Strategic haulers, or 3× Cargo Nets for Tactical haulers like the HEMTT Cargo whose max capacity is its Tactical load).
  - [ ] **Tactical Route (`SB` $\rightarrow$ `FOB`):** Uses the `"Tactical"` sub-array (e.g., Cargo Nets `B_CargoNet_01_ammo_F`, Vehicle Ammo Crates, Fuel Bladders—such as 6× Cargo Nets for a Blackfish, 3× Cargo Nets for a HEMTT Flatbed/Cargo, or 1× Cargo Net for a Huron/Ghost Hawk).
  - [ ] **Combat Logistics Transport (`CLT`):** Uses the `"CLT"` sub-array (e.g., Supply Boxes `B_supplyCrate_F`—such as 12× on a Blackfish, 5× on a Flatbed, 4× on a HEMTT Cargo, or 1× slingloaded on a Huron/Ghost Hawk/Little Bird).
- [x] **Update Parser Logic (`fn_spawnLoadSupply.sqf`, `fn_cargoDelivery.sqf`, `fn_manageLogisticsMissions.sqf`):** *(In Testing)*
  - [x] Detect whether a category's item list is a nested route array (`[["Strategic", [...]], ["Tactical", [...]], ["CLT", [...]]]`) or a legacy flat array (`["Class1", ...]`) for backwards compatibility.
  - [x] Select the sub-array matching the player's currently assigned task (`Logi_Strategic_Task` $\rightarrow$ `"Strategic"`, `Logi_Tactical_Task` $\rightarrow$ `"Tactical"`, `Logi_CLT_Task` $\rightarrow$ `"CLT"`).
- [ ] **In-Game Capacity Testing & Template Population:**
  - [ ] Test each vehicle's physical ViV / slingload capacity for Strategic, Tactical, and CLT container types and populate `logisticsCargoTemplates.sqf` with the tested counts.

### 4.8 Pylon Manager: Pilot vs. Gunner Weapon Control Toggle & Aircraft Customization

Enhance the Aircraft Pylon Manager (`fn_pylonManager.sqf` / `qm_pylonMenu.hpp`, IDD `9600`) so pilots can reassign weapon control between Pilot (Driver) and Gunner (Co-Pilot/Turret) and customize aircraft liveries/components.

- [ ] **Pilot vs. Gunner (Turret) Pylon Control Toggle (Higher Priority):**
  - [ ] Allow players to toggle each pylon's controller between **Pilot (`[]`)** and **Gunner / Co-Pilot (`[0]`)** inside the Pylon Manager UI (both when equipping new ordnance and on already-equipped pylons).
  - [ ] Synchronize the selected turret path (`[]` vs. `[0]`) across all clients via `setPylonLoadout [_pylonIndex, _magClass, true, _selectedTurretPath]` so pilots flying solo can take control of weapons or hand weapon control over when picking up a co-pilot/gunner.
- [ ] **Internal Weapon Systems Scaling (Low Priority Future Feature):**
  - [ ] Wire `GunSlider` / `GunSliderText` (IDC `8300`, `8301`, `8302`) in `qm_pylonMenu.hpp` / `fn_pylonManager.sqf` to allow scaling internal cannon/gun ammunition reserves and deduct or refund base Ammo points accordingly.
- [ ] **Aircraft Camo Schemes & Component Options (Low Priority Future Feature):**
  - [ ] Wire `CamoDropdown` (IDC `8400`) in `qm_pylonMenu.hpp` / `fn_pylonManager.sqf` to read `CfgVehicles >> _vehClass >> TextureSources` and apply the selected camouflage skin globally via `BIS_fnc_initVehicle`.
  - [ ] Support optional aircraft component/animation toggles (`AnimationSources`) if applicable.

### 4.9 High Command Autonomous Groups Integration (Low Priority Future Feature)

Provide an option in the Recruitment / Mobilization interface (or a 3rd UI column) to mobilize independent AI squads that do not join the player's direct personal squad, but are instead assigned to the player via Arma 3's High Command system.

- [ ] Create independent groups on the server with autonomous AI leaders.
- [ ] Bind spawned groups to the player using `player hcSetGroup [_group]` / `setCommander`.
- [ ] Deduct base `Troops` and `Cargo` supply points identically to squad templates.

### 4.10 Task & Journal Navigation: 3-Tier Sub-Task Hierarchy, Grid Coordinates & Manifest Status (Verified Complete)

Enhance the Logistics Mission Routing Engine (`fn_manageLogisticsMissions.sqf`) so transport routes feature a structured parent/sub-task hierarchy (`BIS_fnc_setTask`) communicating base names, 6-digit military map grid coordinates (`mapGridPosition`), and live cargo manifest status in the map diary journal:

> [!NOTE]
> Per design review, real-time on-screen HUD overlays are explicitly rejected in favor of native Arma 3 Map and Journal diary immersion. As long as the player's journal displays the pickup base name, 6-digit grid, manifest item, and dropoff base name with 6-digit grid, and the trigger zones are visually marked on the map, navigation is complete and realistic without screen clutter.

- [x] **Parent Task Hierarchy (`[SubTaskID, ParentTaskID]`):**
  - [x] **Sub-Task 1: Pickup Supplies** — Assigned at route start; waypoint targets the center of the compatible pickup trigger with base name and 6-digit grid. Marked `SUCCEEDED` upon loading completion.
  - [x] **Sub-Task 2: Cargo Manifest & Securing** — Shows assigned cargo category (e.g. `Ammo`, `Fuel`, `Medical`, `Cargo`). Marked `SUCCEEDED` once loaded and secured. Resets/fails if cargo is dropped or lost early before reaching the delivery zone.
  - [x] **Sub-Task 3: Deliver Supplies** — Transitions to `ASSIGNED` upon loading completion; waypoint targets the center of the dropoff zone at the destination base with 6-digit grid. Marked `SUCCEEDED` upon dropoff delivery.
  - [x] **Parent Route Task** — Completes once all 3 sub-tasks succeed, cycling the player to their next prioritized route assignment.
- [x] **Trigger Condition-Driven Compatibility:**
  - [x] Evaluate the player's vehicle against the trigger's Eden Editor condition (`LogiTriggerCond`), distinguishing between plane corridors (`_x isKindOf "Plane"`), low/slow helicopter zones (`_x isKindOf "Helicopter"`), and open/unrestricted stationary pads.
- [x] **Multiplayer Locality:**
  - [x] Ensure all tasks, sub-tasks, and HUD waypoints are player-local (`player` target in `BIS_fnc_setTask`) so multiple players flying or driving simultaneously never interfere with each other's navigation or progress.
- [x] **Clean Map Marker Styling & De-Cluttering:**
  - [x] Master base markers (`SB_Main`, `FOB_*`, `MSR`) remain visible on the map and display their clean human-readable name (`Main Supply Base`, `Agia Marina Base`, `MSR Supply Hub`).
  - [x] All text labels are removed (`setMarkerText ""`) from individual Pickup (`mil_pickup` Blue), Dropoff (`mil_end` Green), and Service (`b_maint` Yellow) pad icons, preventing the distracting "wall-of-text" across the map when zoomed out.
  - [x] Every individual numbered trigger pad (e.g. `MSR_pickup_1` through `5`) receives its own clean icon and transparent boundary box on the map.
- [x] **Spotlight Contextual Map Marker Hierarchy (Option 3):**
  - [x] **Infantry on Foot:** Combat players on foot have all logistics pad icons (`Pickup_*`, `Dropoff_*`, `Service_*`) and area trigger boundaries (`Area_*`) completely hidden locally (`setMarkerAlphaLocal 0`), maintaining an uncluttered tactical map.
  - [x] **Any Player in a Vehicle (Combat Aircraft, Tanks, APCs, Boats, Transports):**
    - **Service Markers (`Service_*` & `Area_*_service*`):** Always visible at `0.50` (`setMarkerAlphaLocal 0.50` for icons, `0.20` for trigger area boundaries) so pilots and vehicle crews always know where base R4-C repair/rearm/refuel stations are.
    - **Dynamic Service Distress Spotlight:** If the vehicle receives >25% overall or subsystem damage, falls below 50% fuel, or exhausts >50% ammo, service markers dynamically spotlight to full brightness (`setMarkerAlphaLocal 1.0` for icons, `0.45` for trigger area boundaries).
    - **Cargo Pads for Combat Vehicles:** Pickup and Dropoff pads remain hidden (`setMarkerAlphaLocal 0`) for non-logistics combat assets, preventing cargo clutter.
  - [x] **Logistics Overview Mode:** Drivers mounting an authorized logistics vehicle without an active locked route see all logistics pad icons at `1.0` and area boundaries at `0.25` for global situational awareness.
  - [x] **Active Route Spotlight Mode:**
    - **Active Route Pads (Assigned Origin Pickup & Destination Dropoff):** Spotlighted at full brightness (`setMarkerAlphaLocal 1.0` for icons, `0.45` for trigger area boundaries).
    - **Secondary / Alternative Pads (All other bases):** Dimmed subtly to 25% opacity (`setMarkerAlphaLocal 0.25` for icons, `0.10` for trigger area boundaries). Provides clear operational priority while allowing immediate visibility of alternate or emergency divert dropoff bases.
  - [x] **Zero Network Overhead & Safe Position Queries:** Implemented purely client-side via `setMarkerAlphaLocal` with default global server alpha `0`. Marker coordinates remain intact for distance calculations, HUD waypoints, and journal manifests.


### 4.11 Ground Vehicle Road Driving Distance vs. Air Flight Routing

Enhance the Logistics Mission Routing Engine (`fn_manageLogisticsMissions.sqf`) to evaluate actual road network driving distance for land vehicles and straight-line flight distance for aircraft, preventing illogical ground vehicle assignments (e.g. routing trucks to geographically close but road-isolated bases like Camp Tempest):

- [x] **Road Driving vs. Flight Distance Function (`logi_fnc_getRouteDistance`):**
  - [x] Aircraft (`Air`) evaluate straight-line 2D/3D Euclidean distance between origin and destination pads.
  - [x] Ground vehicles (`LandVehicle`) check a precomputed road-network driving distance matrix on Stratis (`SB_Main` to `FOB_AgiaMarinaBase`: 1,050m, `CampRogain`: 3,200m, `CampMaxwell`: 4,100m, `Mike26`: 4,600m, `Kamino`: 5,300m, `CampTempest`: 7,200m).
  - [x] Dynamic fallback calculation using a 1.4x road winding factor for unmapped base pairs or custom maps.
- [x] **Origin-Based Distance Sorting:**
  - [x] Base candidate sorting calculates route travel distance from the origin supply base (`_primarySB` / `_primaryMSR`) rather than the truck's momentary coordinate on the runway, eliminating mid-transit route recalculation artifacts.
- [x] **In-Transit Route Destination Locking:**
  - [x] Once loaded (`_isLoaded == true`), the assigned intended base (`logistics_intended_fob`) is locked and preserved throughout the entire transit leg, preventing destination flipping until the cargo has been safely offloaded and credited at the delivery pad.

### 4.12 Universal Dropoff Processing, Field Salvage & Ad-Hoc Supply Returns

Enhance the logistics economy and dropoff engine to universally accept and credit supplies at any dropoff zone, regardless of active mission tasking, vehicle type, or original cargo origin:

- [x] **Missionless & Ad-Hoc Dropoff Acceptance:**
  - [x] Decouple `fn_cargoDelivery.sqf` from strict vehicle variable gates (`logistics_loaded_type != ""`) and trigger filter restrictions (`typeOf _x in allowedLogisticsVehicles`).
  - [x] Any valid supply object matching `supplyScores` placed or dropped on a dropoff pad will be validated, credited to the receiving base's resource caches, and deleted immediately from the tarmac.
- [x] **Strict Safeguard: Supply Crates vs. Drivable Vehicles:**
  - [x] Enforce a strict distinction between detached cargo objects (crates, nets, bladders, pods) and drivable vehicles (`LandVehicle`, `Air`, `Ship`).
  - [x] Drivable transport or combat vehicles driven into or passing through dropoff zones will NEVER be automatically deleted, reclaimed, or consumed by the delivery loop.
  - [x] Vehicle despawning/salvaging is strictly gated behind an explicit player confirmation flow (see Option C in Section 4.5 and Section 5.2).
- [x] **Field Salvage & Re-Delivery of Lost/Abandoned Cargo:**
  - [x] Crates dropped along roads, at combat sites, or recovered from destroyed logistics convoys remain persistent in the world and can be recovered via ViV, slingload, or transport vehicles and delivered to any friendly dropoff pad for credit.
- [x] **Dynamic Alternate-Base Delivery Recognition in Task Engine:**
  - [x] Update `fn_manageLogisticsMissions.sqf` load state transition logic so delivering cargo to any friendly dropoff pad (even if different from `logistics_intended_fob`) credits the run as a successful delivery rather than failing the task with an out-of-zone detachment alert (`[DETACHED / LOST]`).
- [x] **Combat Logistics Supply Return Loop:**
  - [x] Allow players to retrieve unused or surplus combat supplies from the field and deliver them back to rear Supply Bases or forward FOBs. Physical separation between pickup and dropoff pads ensures supplies returned to their origin base increase that base's stockpiles without triggering infinite spawn-despawn loops.

---

## 5. Architectural Explorations, Considerations & Revamping Concepts (Optional Alternatives)

This section documents alternative design paradigms, prospective refactors, and conceptual revamps that may be considered as substitutes or evolutions to existing processes. These concepts are exploratory: they allow comparing trade-offs between static templating and procedural automation before committing to major architectural shifts.

### 5.1 Dynamic Config Introspection & Auto-Discovery vs. Static Vehicle Templates

Investigate replacing manually curated, static template files (`spawnableVehicleTemplate.sqf`, `logisticsCargoTemplates.sqf`) with runtime engine config introspection (`"configFile >> 'CfgVehicles'"`), dynamically discovering vehicles, equipment, and compatibility without requiring exhaustive classname maintenance or `isClass` checks:

- [ ] **Procedural Asset Auto-Discovery:**
  - Query active engine configs directly at mission startup to identify all accessible assets matching target criteria:
    - Faction/Side filtering (e.g. `getNumber (_cfg >> "side") == 1` for BLUFOR).
    - Scope validation (`getNumber (_cfg >> "scope") == 2` for playable/curator-accessible entities).
    - Category classification (`_class isKindOf "Helicopter"`, `"Plane"`, `"Tank"`, `"Car"`, `"Ship"`).
  - Automatically captures all active vehicles across Vanilla, CDLCs (Spearhead 1944, Western Sahara, S.O.G. Prairie Fire), and third-party mods (RHS, CUP, 3CB) without needing manual template entries.
- [ ] **Automated Vehicle Stat & Capacity Extraction:**
  - Extract physical and logistical statistics directly from config properties:
    - **Crew & Turret Complement:** Query `hasDriver`, `hasGunner`, `hasCommander`, and `_cfg >> "Turrets"` to dynamically determine crew seating.
    - **Passenger Capacity:** Query `getNumber (_cfg >> "transportSoldier")` and calculate available cargo / FFV seats automatically.
    - **Slingload Limits:** Query `getNumber (_cfg >> "slingLoadMaxCargoMass")` to determine exact lift capacity.
- [ ] **Dynamic Cargo & Slingload Matching:**
  - Retrieve the mass of supply crates, vehicles, and pods (`getNumber (configFile >> "CfgVehicles" >> _cargoClass >> "mass")`).
  - Procedurally match any slingloadable asset beneath the helicopter's `slingLoadMaxCargoMass`, eliminating hardcoded per-helicopter slingload cargo tables.
- [ ] **Simplified Role-Archetype Population Templates:**
  - Rather than hardcoding full unit lists per vehicle, mission makers provide a lightweight archetype mapping:
    - *Pilot / Driver archetype*, *Gunner archetype*, *Commander archetype*, *Passenger squad pool*.
  - Spawner loops dynamically read vehicle capacity from config and fill seats sequentially until full.
- [ ] **Technical Scope & Known Boundaries:**
  - **Vehicle-in-Vehicle (ViV) Limitations:** While slingload mass and passenger seating are exposed cleanly in config, ViV internal dimensions, proxy clearance, and `cargoDoors` collision geometry are notoriously complex in engine configs. A hybrid model (procedural discovery for slingloading/passengers/motorpools, paired with a lightweight curated template for ViV cargo) may represent the ideal balance.
  - **Relationship to Section 4.4:** Section 4.4 remains the concrete near-term implementation path (curated master templates with `isClass` safety checks); this concept serves as the long-term procedural alternative under evaluation.

### 5.2 Dropoff Zone Vehicle Salvage & Disembark Confirmation System (Alternative to Terminal Salvage)

Investigate moving vehicle despawning and salvaging entirely out of terminal scroll-wheel actions and into the physical base **Dropoff Zone**, utilizing an interactive confirmation prompt when players disembark to ensure safe, foolproof vehicle reclamation:

- [x] **Unified Vehicle Return Location (Dropoff Zone):**
  - Rather than requiring players to navigate to a specific terminal/laptop crate or attempting to scan large radii across multiple garage pads (which previously failed to reliably locate vehicles), designated base Dropoff Zones act as universal vehicle return points.
  - Players simply drive, land, or dock any vehicle they wish to return inside the base's dropoff pad.
- [x] **Accidental Deletion & Drive-Through Safeguard:**
  - Transport trucks, combat vehicles, tanks, and helicopters driving through or stopping in dropoff zones to deliver cargo will **never** be automatically deleted or reclaimed.
  - Automatic detection and deletion is strictly confined to detached cargo objects (crates, nets, bladders, pods). Drivable vehicles are completely immune from automatic tarmac clearing.
- [x] **Interactive Disembark Confirmation Flow:**
  - When a player drives or flies a vehicle into a dropoff pad, stops the engine, and disembarks:
    - The system checks if all player crew members have exited (`count (crew _veh select {isPlayer _x}) == 0`).
    - If unoccupied by players, the last disembarking player is presented with a context-sensitive confirmation prompt (e.g. dynamic on-screen prompt, custom action, or dialog):
      `"Would you like to salvage [Vehicle Display Name] for [X] points? [YES / NO]"`
    - **Confirmed (YES):** The vehicle is despawned, remaining AI crew members safely deleted, calculated resource refund credited to the base ledger, and vehicle cap (`QM_CAP`) unregistered.
    - **Declined (NO / Ignored):** The vehicle remains intact, allowing players to leave parked vehicles at the pad without fear of accidental reclamation.
- [x] **Deprecation of Broken Scroll-Wheel Action:**
  - Fully removes the legacy, unreliable `fn_usedCarSalesman.sqf` addAction from terminals, cleaning up the player scroll-wheel menu and resolving Section 1.5.

### [x] 5.3 Selective Supply Loading Architecture: Interactive Supply Manifest Dialog (Option B Implemented — In Testing)

Explore solutions to prevent non-cargo scene objects and ambient base clutter (such as road cones `RoadCone_F`, barrier tape, floodlights, toolboxes, or furniture placed by mission makers inside a Base Loading Zone) from being inadvertently loaded into transport vehicles (e.g., HEMTTs, cargo vans, Blackfish), while providing fine-grained player control over cargo loading order:

- [x] **Core Problem & Accidental Clutter Ingestion:**
  - In crowded supply depot environments, proximity-based or native ViV loading can inadvertently grab non-logistics props placed for visual detailing (e.g., traffic cones demarcating runways, barricades, decorative crates) and load them into cargo bays.
  - When multiple supply items sit on the same loading pad, players currently lack a deterministic mechanism to choose *which* crate or container is loaded first into their vehicle.
- [x] **Architectural Implementation: Option B (Interactive Dual-Column Supply Manifest Dialog):**
  - **Context-Sensitive Interaction:** Added `[CARGO MANIFEST] Selective Supply Loading` action to all cargo-capable vehicles in `fn_standaloneLoadingMechanic.sqf` (accessible whether dismounted within 10m or seated inside vehicle).
  - **Dual-Column Manifest Dialog (`CfgCargoManifestMenu` in `qm_manifestMenu.hpp`):**
    - **Header & Status Bar:** Displays target vehicle display name, active location environment (`[BASE LOADING ZONE]` vs. `[FIELD ZONE - CAPABILITY RULES ACTIVE]`), and current bay occupancy.
    - **Left Column (Available Ground Supplies):** Scans within 25m of the vehicle, displaying item display name, category tag (`[Cargo]`, `[Ammo]`, `[Fuel]`, `[Repair]`, `[Medical]`), mass in lbs, distance, and real-time fit status (`[FITS]` green vs. `[BAY FULL]` / `[CANNOT FIT]` red).
    - **Right Column (Current Vehicle Cargo Bay):** Displays all items currently secured inside the vehicle's cargo bay.
    - **Action Controls:**
      - **[LOAD SELECTED INTO VEHICLE]** (`fn_manifestLoadExecute.sqf`): Validates physical fit and capability rules (field crane / winch / mass tiers), loads item via native `setVehicleCargo`, updates tracking variables (`logistics_is_loaded`, `logistics_loaded_type`), and dynamically refreshes the manifest.
      - **[UNLOAD SELECTED TO GROUND]** (`fn_manifestUnloadExecute.sqf`): Offloads selected item from cargo bay to the ground behind the vehicle and dynamically refreshes both columns.
      - **[REFRESH MANIFEST]** (`fn_manifestMenuPopulate.sqf`): Re-scans perimeter and updates dialog in real time.
- [x] **Ambient Prop & Scene Clutter Filtering Safeguard:**
  - Implemented strict filtering in `fn_manifestMenuPopulate.sqf`:
    - Filters out common scene props (`RoadCone_F`, `Sign_F`, `TargetBase`, `Land_BarGate_F`, helipads, tools, and clutter props).
    - Filters out editor-placed base facilities (`_Arsenal`, `_Terminal`, `_Spawn`, `_Garage`, `_Service`) and items with `QM_TerminalUnifiedActionsActive` or `QM_Crate_OwningBase`.
    - Filters out crewed vehicles, attached objects, and cargo already loaded into other vehicles.
    - Only permits verified supply assets matching `supplyScores`, tagged with `isLogisticsCargo == true`, or valid logistics containers (`Slingload_01_Base_F`, `ReammoBox_F`, cargo vehicles).
- [x] **Field-Loading Capability Integration & Third-Party Mod Interoperability:**
  - Enforces `logisticsFieldLoadingTemplate.sqf` capability registry rules when outside base loading zones:
    - Vehicles with onboard cranes (`["ALL"]`) can load any cargo that physically fits.
    - Vehicles with container winches (`["Huron_Containers"]`, e.g. HEMTT Flatbed) can load Huron containers only.
    - Standard haulers enforce mass tiers ($\le 120$ lbs 1-man, $121-250$ lbs 2-man lift, $> 250$ lbs prohibited in field).
  - Uses native engine ViV calls (`setVehicleCargo`, `canVehicleCargo`) and standard vehicle actions, operating harmoniously alongside ACE3, Boxloader, or Drongo's DYEL without conflicts.
  - Resolved RPT script error on startup by replacing non-existent command check with native Bohemia `CfgVehicles >> VehicleTransport >> Carrier` config verification, separated server-authoritative event handlers from client `addAction` attachments, and added client proximity daemon / `GetInMan` hooks so all vehicles reliably receive the interactive actions.

### [x] 5.4 Decoupling Native Engine / Third-Party Mod Loading from Custom Manifest Restrictions & Passive Handler Architecture (Verified Resolved)

Ensure that custom field loading restrictions (mass limits, onboard cranes, container winches, 2-player team lifts, loading zone requirements) apply **strictly and exclusively** when players use the custom interactive Cargo Manifest dialog (`fn_manifestLoadExecute.sqf` / `qm_manifestMenu.hpp`), guaranteeing zero interference with native Arma 3 engine mechanics or external mods:

- [x] **Core Architectural Rule & Decoupling:**
  - Field loading capability restrictions (weight limits, winches, cranes, team lifts) belong **strictly inside `fn_manifestLoadExecute.sqf`**.
  - **Native Engine Loading (Zero Restrictions):** Native Arma 3 engine loading (the built-in ViV `Load in vehicle cargo` scroll-wheel action) operates 100% unrestricted across all vehicles, boat racks, and assets.
  - **Third-Party Mod Interoperability (Zero Interference):** Third-party cargo and logistics systems (Drongo's DYEL, Boxloader, ACE3 Cargo) operate completely unhindered without ejection or validation overrides from our framework.
  - **System-Automated Loading (Instant & Unrestricted):** System spawning routines (spawning boats into Destroyer Boat Racks via `qm_serverFunctions.sqf`, garage motorpool spawns, and logistics trigger spawns via `fn_spawnLoadSupply.sqf`) load immediately into vehicles without zone or weight restrictions.
- [x] **Removal of Force-Ejection from `CargoLoaded` Event Handler:**
  - The Bohemia engine `CargoLoaded` event handler in `fn_standaloneLoadingMechanic.sqf` has been converted to a strictly passive synchronization listener.
  - It **never** validates, blocks, or force-ejects cargo (`objNull setVehicleCargo _c`).
  - Its exclusive responsibility is maintaining state variables:
    ```sqf
    _parentVehicle setVariable ["logistics_is_loaded", true, true];
    private _cargoType = [_cargoVehicle] call QM_fnc_getCargoCategory;
    _parentVehicle setVariable ["logistics_loaded_type", _cargoType, true];
    ```
- [x] **`QM_fnc_validateVehicleCargoLoad` Converted to Non-Ejecting Auditor:**
  - Removed all asynchronous force-ejection spawn blocks (`sleep 0.1; objNull setVehicleCargo _c`).
  - Function now returns informational status `[_isAuthorized, _reason]` without disturbing loaded cargo.
- [x] **Comprehensive Base Loading Zone Recognition (`QM_fnc_isInsideLoadingZone`):**
  - Upgraded `QM_fnc_isInsideLoadingZone` in `fn_standaloneLoadingMechanic.sqf` to evaluate all base infrastructure:
    1. Pickup triggers (`LogiPickupTriggers_*`).
    2. Dropoff triggers (`LogiDropoffTriggers_*`).
    3. Proximity to any base 3D facility object (`_Arsenal`, `_Terminal`, `_Garage`, `_Spawn`) within 75 meters.
    4. Proximity to Naval Capital Ships (`Land_Destroyer_01_base_F`, `Land_Carrier_01_base_F`) within 90 meters.
    5. Proximity to master base markers (`logisticsBases`) within 250 meters.
  - Players using the Cargo Manifest dialog anywhere at a base or on a naval vessel are correctly identified as being in a Base Loading Zone.

### [x] 5.5 Vehicle Procurement Costing: Empty Vehicle Troops & Cargo Deduction Elimination (Phase 1 Implemented & Verified)

Refine Motorpool vehicle procurement costing so that purchasing empty, unoccupied vehicles does not penalize base personnel or cargo stockpiles:

- [x] **Elimination of Troop Deductions for Empty Vehicles:**
  - Vehicles spawned from the motorpool (`QM_fnc_processGarageSpawn`) are unoccupied, player-driven transports.
  - While template entries in `spawnableVehicleTemplate.sqf` track passenger capacity or crew figures for external AI systems (`["Troops", 1]`), motorpool procurement now treats troop costs as `0` for empty player vehicles.
  - Drivable vehicles will never be blocked by insufficient troop points, and base troop pools (`LogiScore_*_Troops`) remain 100% untouched upon vehicle delivery.
- [x] **Elimination of Phantom Cargo Deductions for Empty Vehicles:**
  - Vehicles spawn with empty cargo bays and only default factory glovebox inventory (e.g. 2 first aid kits).
  - Theoretical cargo capacities in `spawnableVehicleTemplate.sqf` (e.g. `["Cargo", 3000]`) are no longer billed during empty chassis procurement.
  - Dedicated logistics supply objects (cargo nets, fuel bladders, ammo crates under the Supply tab) continue to deduct their respective cargo/resource costs normally.
- [x] **UI Cost Label Synchronization (`c_vehicleTabs.sqf`):**
  - Updated the Motorpool listbox formatter to ignore `Trp` and `Crg` tags for drivable empty vehicles, displaying only real billing requirements (e.g. `[10942 Veh | 28 Fuel] - HEMTT Transport`).
- [x] **100% Symmetrical Salvage & Early Destruction Refunds:**
  - Vehicles track their exact effective procurement cost in `QM_Spawn_CostArray`.
  - Salvaging via Dropoff Zones or early destruction refunds the exact effective resources paid, preserving closed-economy balance without phantom troop or cargo credits.
- [ ] **Phase 2 (Optional Future Proposal): Dynamic Config-Driven Chassis, Fuel & Ordnance Costing:**
  - Dynamic derivation of chassis cost from physical mass (`getMass`), fuel from tank capacity (`fuelCapacity`), and armament from turret/pylon magazines.

### [x] 5.6 Universal Base Supply Ledger for All Players (Map Diary & Informational Tasks) (Verified Resolved)

Ensure all players—including combat infantry, tank crews, snipers, attack pilots, and commanders—can view the real-time supply inventory (Cargo, Ammo, Fuel, Medical, Repair, Vehicle, Troops) of every base across Stratis directly from their map screen, without being assigned logistics delivery waypoints or tasking:

- [x] **Root Cause of Restricted Visibility:**
  - Base stockpile inventories were previously only exposed through the task descriptions of `Logi_Strategic_Task` and `Logi_Tactical_Task` (`fn_manageLogisticsMissions.sqf`).
  - Because these tasks were exclusively assigned to players actively seated in the driver seat of an authorized logistics vehicle (`_isLogisticsDriver`), all other players (and logistics drivers on foot) had those tasks deleted, leaving them unable to inspect base supplies on the map.
  - The client Diary subject `BasesManifestTab` in `qm_clientFunctions.sqf` was executed during early init before `player` was non-null, lacked respawn lifecycle restoration, and had no single-page theater overview.
- [x] **Dual-Channel Map Access (Diary & Tasks):**
  - **1. Map Diary Subject (`BasesManifestTab` / "Base Supply Manifest"):**
    - Features a primary **"0. Theater Overview (All Bases)"** record summarizing all Staging Bases (SBs), Forward Operating Bases (FOBs), and Main Supply Route (MSR) hubs in a unified, color-coded status table.
    - Features individual base records for detailed inspection of specific base stockpiles.
  - **2. Global Read-Only Informational Task (`Logi_Base_Ledger_Task`):**
    - Created with title `"Base Supply Ledger [Theater Overview]"`.
    - Configured with `destination: objNull`, `priority: -1`, and `showNotification: false`.
    - Appears in the map's Tasks list for quick reference without creating 3D HUD waypoint arrows, map waypoint markers, or overriding active combat routes.
- [x] **Persistent Lifecycle Daemon Across Respawns:**
  - Implemented client daemon in `qm_clientFunctions.sqf` that monitors player lifecycle and automatically re-initializes both the Diary subject and Informational Task whenever the player respawns or changes units.
  - Live background updater refreshes values every 4 seconds from `missionNamespace` variables (`LogiScore_*`).

### 5.7 [PROPOSAL] Modular Workspace Directory Restructuring & Standardized File Prefix Migration (`logistics/`, `templates/`, `tp_*`)

Organize the root mission workspace into clean, modular subdirectories (`templates/` and `logistics/`), introduce standardized system prefixes (`tp_*`, `logi_*`, `qm_*`), and update all file paths, includes, and GUI script references across the codebase:

- [ ] **Core Architectural Motivation:**
  - As Framework V8 expanded to over 35 scripts, housing all template configurations, UI dialogs, server functions, and logistics mechanics in the flat mission root makes file discovery, version control, and modular packaging difficult.
  - Establishing clear directory boundaries separates **static mission configuration data** (`templates/`) from **runtime operational engines** (`logistics/`), keeping the mission root pristine (`init.sqf`, `description.ext`, `defines.hpp`, `mission.sqm`, docs).
  - External modules (such as Combat Tasking / Intel `tsk_*`) will remain untouched in the root for now, deferred for dedicated refactoring when addressing those systems.

- [ ] **Standardized Prefixing Taxonomy & Template Naming Decision:**
  - **The Design Question: `tp_*` (Type-Based) vs. System-Specific (`qm_*` / `logi_*`):**
    - *Consideration:* Should templates be named after the subsystem that primarily uses them (e.g. `qm_vehicleCapsTemplate.sqf`, `logi_cargoTemplates.sqf`), or should all templates share a uniform `tp_` prefix?
    - *Evaluation:* In Framework V8, templates act as **shared global data matrices** rather than private subsystem scripts:
      - `spawnableVehicleTemplate.sqf` feeds the Quartermaster motorpool (`c_vehicleTabs.sqf`, `fn_newCarDealership.sqf`), the WorldAI spawner, the Dropoff Zone salvage system, and base service facilities.
      - `SupplyScores.sqf` feeds the Base Ledger economy, the physical supply spawner, the cargo delivery offloader, the recruiter, and the Cargo Manifest dialog.
      - `logisticsCargoTemplates.sqf` feeds the dynamic tasking engine, pickup triggers, dropoff offloaders, and manifest menus.
    - *Architectural Recommendation (Adopt `tp_*`):* 
      - Tagging shared data files with `qm_` or `logi_` is misleading, as developers might assume a `qm_` template is only used by the Quartermaster.
      - Standardizing all files in `templates/` with the **`tp_`** prefix creates a clean, predictable rule: **"Any file beginning with `tp_` inside `templates/` is a system-agnostic configuration blueprint."**
  - **Subsystem Prefix Breakdown:**
    - **`tp_*` (Templates & Blueprints):** All configuration matrices, base defaults, vehicle roles, scoring tables, and spawn templates housed in `templates/` (`tp_spawnableVehicles.sqf`, `tp_cargoTemplates.sqf`, `tp_supplyScores.sqf`, etc.).
    - **`logi_*` (Logistics Engine & Cargo Operations):** Routing, manifest inspection, loading/unloading mechanics, delivery validation, and depot triggers housed in `logistics/`.
    - **`qm_*` (Quartermaster Base Services & UI):** Motorpool dealership, recruiter, equipment trader, R4-C vehicle servicing, and pylon management housed in `logistics/`.
    - **`tsk_*` (Tactical Command & Intel):** Preserved as-is for future modularization.

- [x] **Technical Guide: How Bohemia Engine Pathing & Subfolder Referencing Works:**
  - **1. Relative SQF Script Paths:**
    - In Arma 3, script commands (`execVM`, `preprocessFileLineNumbers`, `compileScript`, `fileExists`) resolve paths **relative to the root of the active mission folder**.
    - When a file moves to a subfolder, prefixing the subfolder name with a backslash or forward slash directs the engine into that directory:
      - *Root:* `call compile preprocessFileLineNumbers "logisticsCargoTemplates.sqf";`
      - *Subfolder:* `call compile preprocessFileLineNumbers "templates\tp_cargoTemplates.sqf";`
      - *Execution:* `[_veh, _base] execVM "logistics\logi_spawnLoadSupply.sqf";`
  - **2. Preprocessor Includes in `description.ext`:**
    - Dialog resource files moved to `logistics/` are included via relative path:
      - `#include "logistics\qm_quartermasterUI.hpp"`
      - `#include "logistics\qm_manifestMenu.hpp"`
      - `#include "logistics\qm_pylonMenu.hpp"`
  - **3. Dialog Action Strings inside `.hpp` Files:**
    - Button `action` and `onLoad` strings inside UI dialog definitions must reference the new subfolder path:
      - `action = "[] execVM 'logistics\qm_newCarDealership.sqf';";`
      - `action = "[] execVM 'logistics\qm_manifestLoadExecute.sqf';";`
  - **4. Eden Editor Triggers & Runtime Hot-Patching Protection:**
    - Because `fn_initLogisticsTasks.sqf` (becoming `logi_initTasks.sqf`) dynamically scans all Eden triggers and rewrites trigger statements (`setTriggerStatements`) in memory at mission start, **mission makers do NOT need to manually edit `mission.sqm` in Eden Editor**.
    - Updating the runtime string generator inside `logi_initTasks.sqf` automatically routes all physical trigger pads on Stratis to the new `logistics/` directory with zero manual Eden Editor intervention.

- [x] **Exhaustive File-by-File Migration Mapping:**

| Current Root Filename | Target Subdirectory & Proposed Name | System Classification | Primary Referencing Scripts |
| :--- | :--- | :--- | :--- |
| **`logisticsBaseDefaults.sqf`** | `templates\tp_baseDefaults.sqf` | Template (Base Stockpiles) | `init.sqf` |
| **`logisticsCargoTemplates.sqf`** | `templates\tp_cargoTemplates.sqf` | Template (Vehicle Cargo Lists) | `init.sqf`, `logi_manageMissions.sqf`, `logi_spawnLoadSupply.sqf`, `logi_cargoDelivery.sqf` |
| **`logisticsFieldLoadingTemplate.sqf`** | `templates\tp_fieldLoadingTemplate.sqf` | Template (Field Capability Rules) | `init.sqf`, `logi_standaloneLoading.sqf`, `qm_manifestLoadExecute.sqf` |
| **`logisticsVehicleRoles.sqf`** | `templates\tp_vehicleRoles.sqf` | Template (Strategic/Tactical/CLT) | `init.sqf`, `logi_manageMissions.sqf` |
| **`qm_vehicleCapsTemplate.sqf`** | `templates\tp_vehicleCaps.sqf` | Template (Active Vehicle Limits) | `init.sqf`, `qm_serverFunctions.sqf` |
| **`spawnableInfantryTemplate.sqf`** | `templates\tp_spawnableInfantry.sqf` | Template (Recruiter Blueprints) | `init.sqf`, `qm_recruiterList.sqf` |
| **`spawnableVehicleTemplate.sqf`** | `templates\tp_spawnableVehicles.sqf` | Template (Motorpool Blueprints) | `init.sqf`, `qm_vehicleTabs.sqf`, `qm_newCarDealership.sqf`, `qm_serverFunctions.sqf` |
| **`SupplyScores.sqf`** | `templates\tp_supplyScores.sqf` | Template (Asset Point Weights) | `init.sqf`, `logi_manageMissions.sqf`, `logi_spawnLoadSupply.sqf`, `logi_cargoDelivery.sqf`, `qm_manifestMenuPopulate.sqf` |
| **`virtualArsenalTemplate.sqf`** | `templates\tp_virtualArsenal.sqf` | Template (Whitelisted Armaments) | `init.sqf`, `qm_serverFunctions.sqf` |
| **`fn_initLogisticsTasks.sqf`** | `logistics\logi_initTasks.sqf` | Logistics Core (Triggers & Alpha) | `init.sqf` |
| **`fn_manageLogisticsMissions.sqf`** | `logistics\logi_manageMissions.sqf` | Logistics Core (Dynamic Tasking) | `init.sqf` |
| **`fn_spawnLoadSupply.sqf`** | `logistics\logi_spawnLoadSupply.sqf` | Logistics Core (Supply Spawner) | `init.sqf`, `logi_initTasks.sqf` |
| **`fn_cargoDelivery.sqf`** | `logistics\logi_cargoDelivery.sqf` | Logistics Core (Dropoff Offloader) | `logi_initTasks.sqf` |
| **`fn_standaloneLoadingMechanic.sqf`**| `logistics\logi_standaloneLoading.sqf` | Logistics Core (ViV Daemons) | `init.sqf` |
| **`fn_startupMarkerDiagnostics.sqf`** | `logistics\logi_markerDiagnostics.sqf` | Diagnostics (Map Audit) | `init.sqf` |
| **`qm_manifestMenu.hpp`** | `logistics\qm_manifestMenu.hpp` | Cargo Manifest GUI (IDD 5500) | `description.ext` |
| **`fn_manifestMenuOpen.sqf`** | `logistics\qm_manifestMenuOpen.sqf` | Cargo Manifest Dialog Launcher | `logi_standaloneLoading.sqf` |
| **`fn_manifestMenuPopulate.sqf`** | `logistics\qm_manifestMenuPopulate.sqf` | Cargo Manifest Perimeter Scanner | `qm_manifestMenu.hpp`, `qm_manifestLoadExecute.sqf`, `qm_manifestUnloadExecute.sqf` |
| **`fn_manifestLoadExecute.sqf`** | `logistics\qm_manifestLoadExecute.sqf` | Cargo Manifest Load Action | `qm_manifestMenu.hpp` |
| **`fn_manifestUnloadExecute.sqf`** | `logistics\qm_manifestUnloadExecute.sqf` | Cargo Manifest Unload Action | `qm_manifestMenu.hpp` |
| **`qm_quartermasterUI.hpp`** | `logistics\qm_quartermasterUI.hpp` | Quartermaster Master GUI | `description.ext` |
| **`c_vehicleTabs.sqf`** | `logistics\qm_vehicleTabs.sqf` | Motorpool UI Category Filter | `qm_quartermasterUI.hpp` |
| **`fn_newCarDealership.sqf`** | `logistics\qm_newCarDealership.sqf` | Motorpool Purchase Dispatcher | `qm_quartermasterUI.hpp` |
| **`fn_recruiter.sqf`** | `logistics\qm_recruiter.sqf` | Barracks Recruit Dispatcher | `qm_quartermasterUI.hpp` |
| **`fn_recruiter_list.sqf`** | `logistics\qm_recruiterList.sqf` | Barracks UI Populator | `qm_quartermasterUI.hpp` |
| **`fn_equipmentTrader.sqf`** | `logistics\qm_equipmentTrader.sqf` | Equipment Trader Client UI | `init.sqf` |
| **`fn_usedCarSalesman.sqf`** | `logistics\qm_usedCarSalesman.sqf` | Legacy Salvage Client Action | `init.sqf` |
| **`fn_executeR4CService.sqf`** | `logistics\qm_executeR4CService.sqf` | R4-C Base Service Handler | `logi_initTasks.sqf` |
| **`qm_pylonMenu.hpp`** | `logistics\qm_pylonMenu.hpp` | Pylon GUI Resource | `description.ext` |
| **`fn_pylonManager.sqf`** | `logistics\qm_pylonManager.sqf` | Pylon Manager Engine | `init.sqf`, `qm_clientFunctions.sqf` |
| **`qm_clientFunctions.sqf`** | `logistics\qm_clientFunctions.sqf` | Client Framework Library | `init.sqf` |
| **`qm_serverFunctions.sqf`** | `logistics\qm_serverFunctions.sqf` | Server Framework Library | `init.sqf` |
| **`qm_clientActionCompiler.sqf`** | `logistics\qm_clientActionCompiler.sqf` | Terminal Action Compiler | `init.sqf` |
| **`qm_supplyPhysicalController.sqf`** | `logistics\qm_supplyPhysicalController.sqf`| Base Crate Physical Spawner | `init.sqf` |
| **`qm_serverGarrisonManager.sqf`** | `logistics\qm_serverGarrisonManager.sqf` | Server Garrison Controller | `init.sqf` |
| **`qm_serverRespawnManager.sqf`** | `logistics\qm_serverRespawnManager.sqf` | Server Respawn Manager | `init.sqf` |
| **`qm_clientRespawnManager.sqf`** | `logistics\qm_clientRespawnManager.sqf` | Client Respawn UI Manager | `init.sqf` |

- [x] **Execution & Phased Implementation Strategy:**
  - **Phase 1: Directory Setup & Git-Tracking Relocation:**
    - Execute `git mv` operations to move files into `templates/` and `logistics/` with new standardized prefixes, retaining 100% of Git commit history and blame data.
  - **Phase 2: Master Entrypoint Path Remapping:**
    - Update `init.sqf` to compile from `templates\tp_*.sqf` and execute from `logistics\*.sqf`.
    - Update `description.ext` `#include` statements to reference `logistics\*.hpp`.
  - **Phase 3: Internal Inter-Script & Dialog Action Remapping:**
    - Update all UI `.hpp` `action` and `onLoad` strings.
    - Update internal script calls (`execVM`, `preprocessFileLineNumbers`).
    - Update `logi_initTasks.sqf` dynamic trigger statement injection.
  - **Phase 4: Comprehensive Verification:**
    - Run `check_brackets.ps1` across all relocated files.
    - Validate that `mission.sqm` remains completely unstaged and untouched.

---

### [x] 5.8 Dropoff Zone Delivered Vehicle Auto-Despawn & Selective Disembark Salvage
- **1. Initial Issue Summary:**
  - When vehicles were delivered to a base Dropoff Zone via helicopter slingload or transport vehicle cargo bay (Vehicle-in-Vehicle / ViV), the dropoff zone engine ignored them because drivable vehicles (`LandVehicle`, `Air`, `Ship`) were globally excluded from the cargo offload scanner (`!_isDrivableVehicle`).
  - As a result, delivered vehicles sat permanently on the tarmac without despawning or crediting points, forcing solo pilots and drivers to land, exit their vehicles, walk across the tarmac, manually salvage each delivered vehicle (risking accidentally recycling their own transport), and embark again every run.
  - Furthermore, disembark salvage prompts could trigger on any disembark rather than being strictly reserved for vehicles driven by players.
- **2. Root Cause Analysis:**
  - In `logistics\logi_cargoDelivery.sqf`, line 94 checked `if (!_isDrivableVehicle && ...)` before running point evaluation and `deleteVehicle`. All drivable vehicles were skipped to prevent deleting active player transport trucks/helis.
  - In `logistics\qm_serverFunctions.sqf`, `QM_fnc_serverVehicleSale` required `!isNull _playerUnit` (`if (_baseKey == "" || isNull _vehicle || isNull _playerUnit) exitWith {}`), causing automated/remote salvage calls without an on-foot player to fail silently.
  - In `logistics\qm_clientFunctions.sqf`, `GetOutMan` fired without checking if the vehicle was delivered via slingload/ViV, and didn't re-initialize on player respawn.
- **3. Applied Fixes & Architectural Improvements:**
  - **Automated Delivered Vehicle Processing (`logi_cargoDelivery.sqf`):**
    - Scans for delivered vehicles (`_isDeliveredVehicle`) satisfying: inside dropoff zone, not base infrastructure, no human crew, not currently attached as ViV or slingload (`isNull (ropeAttachedTo _object)`), resting on ground (`abs (speed _object) < 3`, `getPosATL # 2 < 2.5`), not declined by player, and tagged via slingload (`QM_WasSlingLoaded`), ViV cargo (`QM_UnloadedFromViV`), logistics cargo (`isLogisticsCargo`), or un-driven.
    - Proactively tags active helicopter slingloads hovering in or above the dropoff zone.
    - Calls `QM_fnc_serverVehicleSale` to credit the base ledger, unregister vehicle asset caps, delete the vehicle, and broadcast delivery receipts (`[LOGISTICS RECEIPT]: %1 recycled...`) to the delivery pilot and server chat.
  - **Slingload & ViV Lifecycle Tracking (`logi_standaloneLoading.sqf` & `qm_manifestUnloadExecute.sqf`):**
    - Added `RopeAttach` and `RopeBreak` event handlers to track slingloaded assets (`QM_WasSlingLoaded`, `QM_DroppedFromSling`, `QM_SlingCarrier`).
    - Added ViV unload tracking in `CargoUnloaded` and `qm_manifestUnloadExecute.sqf` (`QM_UnloadedFromViV`, `QM_CarrierVehicle`).
    - Added pre-tagging in `logi_spawnLoadSupply.sqf` for all logistics-spawned vehicles and pods.
  - **Strictly Scoped Disembark Salvage Prompt (`qm_clientFunctions.sqf`):**
    - Added `GetInMan` to record `QM_DrivenByPlayer = true` when entering as driver.
    - In `GetOutMan`, explicitly exits immediately if the vehicle was delivered via slingload, ViV, or logistics cargo, or was not driven by players.
    - Prompts only the last player disembarking a vehicle they were actively driving into the dropoff zone. If declined, sets `QM_PlayerDeclinedSalvage = true` so the vehicle remains safely parked.
    - Preserves the direct look-at `[SALVAGE CONTROL] Recycle Vehicle to Base` context action on `cursorObject` for all players.
    - Attached a `Respawn` event handler hook so salvage listeners persist across all player respawns.
  - **Universal Server Vehicle Sale (`qm_serverFunctions.sqf`):**
    - Allowed `_playerUnit` to be `objNull` for automated deliveries, falling back to global chat receipts.
    - Added `supplyScores` lookup fallback so all logistics and template vehicles receive accurate point credits.
- **4. Verification:**
  - Bracket balance verified across all 40 `.sqf` and `.hpp` files (`Curly: 0, Round: 0, Square: 0`).
  - `mission.sqm` remained completely untouched.

---

## 6. Quality of Life (QoL) Improvements & Special Infrastructure Proposals

### [x] 6.1 Destroyer Flight Deck Naval Aviation (Ghost Hawk & Light Heli Spawns at Naval FOBs)
- **1. Context & User Requirement:**
  - Destroyers (e.g., `FOB_Destroyer_086`, `FOB_Destroyer_011`, transitioning to US Navy hull codes like `FOB_DDG_086`, `FOB_DDG_011`) feature an aft helicopter flight deck and hangar bay.
  - Operationally, Destroyers should deploy Medium and Light maritime helicopters that realistically fit their flight deck and hangar footprint:
    - **Authorized Assets:** `UH-80 Ghost Hawk` (standard, stub-wing armed, sand, and tropic variants), `MH-9 Hummingbird` (`B_Heli_Light_01_F`), and `AH-9 Pawnee` (`B_Heli_Light_01_dynamicLoadout_F`).
    - **Strictly Prohibited Assets:** Heavy-lift helicopters such as `CH-67 Huron` (`B_Heli_Transport_03_F`, `B_Heli_Transport_03_unarmed_F`), Super/King Stallions, or large transport aircraft, which physically exceed destroyer deck dimensions and should only be operated from large amphibious assault ships (LHAs) or fleet aircraft carriers (`SB_Carrier`).
  - **The Dilemma & Mission Maker Architecture:** Destroyers are classified as **FOBs** (`FOB_DDG_*` / `FOB_Destroyer_*`). Previously, all Western helicopters in `templates\tp_spawnableVehicles.sqf` were locked to `"SB"` (Supply Base only). The mission maker established that the **naming convention on the physical pad** (`_helicopter` vs. `_ground`) should be the authoritative gatekeeper, while the template grants explicit `["SB", "FOB"]` base tier access to the light/medium maritime helicopter airframes (or `["SB"]` for heavy-lift and attack airframes).

- **2. Implemented Architecture (Template Whitelist + Pad-Level Gatekeeper):**
  - **Pillar A: Template Authorization in `templates/tp_spawnableVehicles.sqf`:**
    - The restriction column for light/medium maritime helicopters was updated to the explicit array format `["SB", "FOB"]`:
      - `MH-9 Hummingbird` $\rightarrow$ `["SB", "FOB"]`
      - `AH-9 Pawnee` $\rightarrow$ `["SB", "FOB"]`
      - `UH-80 Ghost Hawk` (all 4 variants: Standard, Stub Wings, Sand, Tropic) $\rightarrow$ `["SB", "FOB"]`
    - Heavy-lift rotary (`CH-67 Huron`) and heavy attack (`AH-99 Blackfoot`), as well as fixed-wing strike fighters (`A-164 Wipeout`, `F/A-181 Black Wasp II`), remain strictly locked to `["SB"]`. They can never spawn at Destroyers or FOBs.
  - **Pillar B: Pad-Level Naming Convention Gatekeeper:**
    - **Land FOBs (Helicopter Blocked):** Mission makers name garage pads with the `_ground` token (e.g. `Garage_Ground_100`, `Garage_Ground_120`, `Garage_Ground_150`). In `qm_vehicleTabs.sqf`, `_maxHeliSize` remains `-1`, so helicopters are completely hidden from the requisition menu. In `qm_serverFunctions.sqf`, `QM_fnc_processGarageSpawn` strictly rejects helicopter spawns on `_ground` pads.
    - **Destroyers (Naval Aviation Flight Decks):** The aft helipads are named with the `_helicopter` token (e.g. `Garage_Helicopter_60`, `Garage_Helicopter_50`). In `qm_vehicleTabs.sqf`, `_maxHeliSize` evaluates to `6` (`OPEN`), making Ghost Hawks, Hummingbirds, and Pawnees available for deployment directly onto the destroyer's flight deck.

- **3. Status:** **Verified Resolved & Implemented** via `templates/tp_spawnableVehicles.sqf`, `logistics/qm_vehicleTabs.sqf`, and `logistics/qm_serverFunctions.sqf`.

---

### [ ] 6.2 Standardized US Navy Hull Classification Architecture (DD, DDG, CVN, LHA/LHD Base Echelons)
- **1. Context & Standardized Naval Taxonomy:**
  - Real-world United States Navy hull classification codes use standard two- or three-letter designations followed by hull numbers, rather than arbitrary text:
    - **`DD`**: Destroyer (General / Gun Destroyer)
    - **`DDG`**: Guided-Missile Destroyer (e.g., *Arleigh Burke*-class / USS *Liberty* `Land_Destroyer_01_base_F`)
    - **`CVN`**: Aircraft Carrier, Nuclear-powered (e.g., *Nimitz* / *Gerald R. Ford*-class / USS *Freedom* `Land_Carrier_01_base_F`)
    - **`LHA` / `LHD`**: Landing Helicopter Assault / Dock (Amphibious Assault Capital Ships, e.g., *America* / *Wasp*-class)
    - **`LPD`**: Amphibious Transport Dock (e.g., *San Antonio*-class)
    - **`LSD`**: Dock Landing Ship (e.g., *Whidbey Island* / *Harpers Ferry*-class)
  - **Immediate Mission Maker Implementation (Safe & Non-Breaking):**
    - Mission maker is updating Eden Editor base marker names to incorporate standard hull codes while retaining the `FOB_` prefix:
      - e.g., `FOB_Destroyer_086` $\rightarrow$ `FOB_DDG_086`
      - e.g., `FOB_Destroyer_011` $\rightarrow$ `FOB_DDG_011`
    - Because the string `"FOB"` remains present at the start of the identifier, all current engine scripts (`init.sqf`, `qm_vehicleTabs.sqf`, `logi_initTasks.sqf`, ledger displays) continue running seamlessly without breaking or requiring immediate code alterations.

- **2. Strategic Value of Hull-Code Base Echelons (Future Implementation Roadmap):**
  - Moving to recognized hull classification codes allows the logistics framework to establish distinct, authentic operational profiles across two key pillars:
  
  - **Pillar A: Tailored Starting Supply Ledgers (`tp_baseDefaults.sqf`):**
    | Naval Hull Tier | Operational Role | Recommended Ledger Profile |
    | :--- | :--- | :--- |
    | **`CVN`** (Fleet Carrier) | Strategic Maritime Base | **Massive Aviation Reserves:** Maximum Fuel & Ammo for fixed-wing strike fighters, large Vehicle Material pool for carrier deck tractors and aircraft, high Troop capacity (hundreds of naval aviators & sailors). Unlimited or semi-infinite. |
    | **`LHA` / `LHD`** (Amphibious Assault) | Expeditionary Task Force Hub | **Marine Expeditionary Stores:** High rotary-wing & STOVL Fuel/Ammo, elevated Troop reserves for embarked Marine rifle platoons, dedicated Vehicle Material for amphibious armor (AAVs) and transport helis. |
    | **`DDG` / `DD`** (Guided Destroyer) | Escort & Surface Combatant | **Specialized Escort Stores:** Tailored guided-missile Munitions, precision Repair components, moderate aviation Fuel calibrated for 1–2 embarked maritime helicopters, ~30–50 personnel, dedicated boat reserves for RHIBs. |
    | **`LPD` / `LSD`** (Dock Ships) | Amphibious Connector | **Connector Stores:** Specialized Cargo & Vehicle pools for LCAC hovercraft, utility landing craft (LCU), and combat engineering equipment. |
    | **`FOB`** (Land Outpost) | Forward Ground Base | Standard ground-combat stockpile (10% of SB baseline). |
    | **`SB`** (Main Depot) | Strategic Mainland Depot | Baseline continental supply depot. |

  - **Pillar B: Granular Vehicle Spawn Whitelists (`tp_spawnableVehicles.sqf`):**
    - Vehicle templates can list allowed hull types in their restriction array (e.g., `["CVN"]`, `["LHA", "CVN"]`, `["DDG", "LHA", "CVN"]`, `["SB"]`, `["FOB"]`):
      - **`CVN` Exclusives:** Fixed-wing carrier-capable strike jets (`F/A-18`, `F-35C`), carrier AEW airborne early warning, heavy logistics transports.
      - **`LHA` / `LHD` Assets:** STOVL strike aircraft (`F-35B`, `AV-8B Harrier`), tiltrotors (`V-22 Osprey`, `Blackfish`), heavy-lift rotary (`CH-67 Huron`, `Super Stallion`), attack & utility helicopters (`AH-1Z Viper`, `UH-1Y Venom`, `UH-80 Ghost Hawk`), and amphibious surface craft.
      - **`DDG` / `DD` Assets:** Flight-deck-rated maritime helicopters only (`UH-80 Ghost Hawk` standard & stub wings, `MH-9 Hummingbird`, `AH-9 Pawnee`), alongside deployed RHIBs / speedboats (`B_Boat_Transport_01_F`, `B_Boat_Armed_01_minigun_F`). Fixed-wing jets and heavy-lift helicopters are strictly excluded.

- **3. Status:** **Logged as Strategic Architectural Proposal** (Pre-staged for future implementation as mission maker updates base names in Eden Editor).

- **4. First-Class Base Types & Standardized Naming Convention:**
  - Rather than fuzzy equivalence matching, the framework recognizes distinct, first-class base types defined directly in `templates/tp_baseDefaults.sqf`:
    - **`MSR`**: Mainland Supply Route (Infinite pipeline, no garrison/repair)
    - **`CS`**: Cargo Ship (Offshore naval equivalent of MSR, infinite pipeline)
    - **`AOR`**: Auxiliary Replenishment Oiler (Offshore fleet replenishment ship, infinite pipeline)
    - **`SB`**: Mainland Strategic Supply Base (Depot reserves)
    - **`CVN`**: Nuclear Aircraft Carrier (Fleet Hub reserves)
    - **`LHA`**: Amphibious Assault Capital Ship (Peral's mod expeditionary stores)
    - **`LPD`**: Amphibious Transport Dock (Expeditionary Force staging base)
    - **`LST`**: Landing Ship, Tank (Peral's mod amphibious vehicle & armor staging base)
    - **`FOB`**: Forward Operating Base (Land outpost stores)
    - **`DDG`**: Guided-Missile Destroyer (Surface escort & light aviation)
    - **`DD`**: Gun Destroyer (Surface escort)
    - **`FFG` / `FG`**: Guided-Missile Frigate (Surface escort, e.g. HAFM Barbaros/Hydra)
    - **`CON`**: Contested Base Sector (Frontline capture sector, $0$ starting supplies)
  - **The Three Functional Shipping / Receiving Echelons:**
    - **Echelon 1: MSR — Shipping Only (Infinite Pipeline Source):**
      - Bases: `MSR`, `CS`, `AOR`.
      - Role: External acquisition corridors into the AO with infinite (`-1`) reserves.
      - Behavior: Logistics assets only pick up supplies here to haul forward; no base dropoffs, garrisons, or vehicle procurement are performed here.
    - **Echelon 2: Supply Base (SB) — Shipping and Receiving (Central Staging & Distribution):**
      - Bases: `SB`, `CVN`, `LHA`, `LPD`, `LST`.
      - Role: Consolidation hubs with large starting stockpiles.
      - Behavior: Receives bulk supplies from MSR pipeline runs, stores and organizes material, and distributes cargo to forward tactical bases. Supports vehicle manufacturing/garages and maintenance.
    - **Echelon 3: FOB — Receiving Only (Forward Operational Support):**
      - Bases: `FOB`, `DDG`, `DD`, `FFG` / `FG`, `CON`.
      - Role: Forward frontline installations with tailored, localized combat stockpiles.
      - Behavior: Receives supplies from Supply Bases to maintain frontline combat units (rearming aircraft/tanks, fueling, field surgery, vehicle repair, and local respawn points).
  - **Syntax & Display Name Parsing:**
    - The first segment before the first underscore designates the **Base Type** (e.g. `CVN`, `DDG`, `LPD`, `LST`, `FOB`, `CON`).
    - The segment after the first underscore defines the **Specific Base Name** (e.g. `11`, `86`, `Beachhead_Alpha`, `Liberty`, `Washington`, `Abdera`).
    - **Additional underscores denote spaces** in the display name (e.g., `FOB_Camp_Maxwell` $\rightarrow$ `"Camp Maxwell"`, `FOB_Beachhead_Alpha` $\rightarrow$ `"Beachhead Alpha"`).
  - **Ship-to-Shore Expeditionary Logistics Architecture:**
    - **Pipeline Source:** Offshore replenishment oiler (`AOR`) or container ship (`CS`) provides bulk replenishment.
    - **Offshore Staging Bases:** Capital and amphibious vessels (`CVN`, `LHA`, `LPD`, `LST`) operate as `STRATEGIC` bases offshore.
    - **Drivable Connectors:** Pilotable landing craft such as the **LCC-1** (Expeditionary Force) or hovercraft register in `allowedLogisticsVehicles` via `tp_cargoTemplates.sqf`.
    - **Tactical Delivery:** The LCC-1 loads supplies or vehicles at the ship's sea pad/ramp, sails across the water, and offloads at the shoreline `FOB_Beachhead` or `CON_Beachhead` dropoff zone. Mission routing dynamically selects water routes when the player pilots a naval vessel.
  - Mission makers can define any new base type simply by adding a row to `tp_baseDefaults.sqf`—all discovery, ledger allocation, and role handling adapt automatically without touching code.

---

### [x] 6.3 Map Marker True-North Normalization & Scope Boundaries
- **1. Context & Eden Editor Observations:**
  - When mission makers place or duplicate markers in the Eden Editor, slight inadvertent rotations often leave markers with non-zero angles (e.g., $14.7^\circ$, $282.4^\circ$, $0.25^\circ$). This causes base installation icons (NATO symbols, flags, HQ icons) to appear tilted or crooked on the player map and GPS.
  - The mission maker recently audited `mission.sqm` and manually zeroed all base marker angles (`SB_Main`, `FOB_AgiaMarinaBase`, `FOB_CampMaxwell`, `FOB_CampRogain`, `FOB_Kamino`, `FOB_Mike26`, `FOB_CampTempest`, `Contested_Stadium`). In Eden Editor SQM format, $0^\circ$ (True North) is represented by omitting the `angle` property entirely.
  - Additionally, a new virtual arsenal cache (`SB_Main_Arsenal_6`, `VirtualReammoBox_camonet_F`) was placed at Main Supply Base.

- **2. Framework Codebase Audit (Marker Directionality):**
  - **Comprehensive Verification:** A deep audit of all framework modules (`logistics\*.sqf`, `templates\*.sqf`, `init.sqf`) confirmed that **not a single script relies on marker direction (`markerDir`) for vehicle, infantry, or asset orientation**.
  - All directional spawning is 100% handled by 3D world entities:
    - Garages, Helipads, Boat Racks, and Ammo Caches: `_spawnDir = getDir _padObj;`
    - Infantry/Barracks recruitment: `_spawnDir = getDir _padObj;`
  - The only script call to `setMarkerDir` in the entire project is in `logi_initTasks.sqf` (Line 244), where the dynamically generated visual bounding box (`Area_%1`) for rectangular triggers is rotated to match the physical trigger footprint (`(triggerArea _trigger) params [..., "_angle", ...];`).

- **3. Normalization Scope & Applied Implementation:**
  - In `init.sqf` (Lines 250 & 272), base marker orientation is explicitly normalized to True North:
    ```sqf
    {
        private _baseName = _x;
        if (getMarkerColor _baseName != "") then {
            _baseName setMarkerDir 0; // Enforce true North orientation (upright NATO symbol)
            _baseName setMarkerAlpha 1;
        };
    } forEach logisticsBases;
    ```
  - This ensures all base HQ icons display upright and professional on all client map displays, regardless of whether a mission maker accidentally rotated a marker in Eden Editor, while preserving 100% of custom tactical mission graphics (arrows, zones).

- **4. Status:** **Verified Resolved & Non-Issue (Architecturally Superseded by Section 6.8)**:
  - **Transition to 3D Game Logics:** Under Section 6.8, base discovery and facility linking have fully transitioned from 2D Eden map markers to **3D Game Logic / Anchor entities** (`SideBLUFOR_F`, `Logic`, `EmptyDetector`).
  - **Automated Script Synthesis:** The framework synthesizes missing base map markers dynamically at runtime, where `createMarker` inherently defaults to `0°` (True North).
  - **Zero Mission Impact:** Combined with the mission maker's manual zeroing in `mission.sqm` and 3D Game Logic anchors, marker angle drift is completely eliminated as an operational concern.

---

### [x] 6.4 Base Supply Depletion Gating & 1-Hour Infrastructure Reconstruction Timer
- **1. Context & Architectural Requirement:**
  - In a realistic logistics economy, depleted base supply pools must have tangible operational consequences on available combat power.
  - Base facility objects (arsenals, terminals, garages, service pads, medical facilities) are vulnerable to player ordnance, artillery, and airstrikes. When destroyed, they should not automatically pop back into existence, nor should they remain permanently broken for the rest of a multi-day campaign.

- **2. Supply Depletion Gating (Arsenals, Motorpools, & Medical) - IMPLEMENTED in V8:**
  - **Virtual Arsenal Lockdown (`qm_clientActionCompiler.sqf`):**
    - [x] If a base's `Cargo` and `Ammo` supply pools are both depleted ($\le 0$), the Virtual Arsenal clears all virtual gear (`removeVirtualWeaponCargo`, etc.), displaying an empty armory locker with system notification:
      `"LOGISTICS ALERT: %1 armory depleted (0 Cargo / 0 Ammo). Deliver supply crates to restore weapons and gear."`
  - **Garage Motorpool Gating (`qm_serverFunctions.sqf`):**
    - [x] In `QM_fnc_processGarageSpawn`, the server pre-validates base resources against `_costArray` before attempting deployment.
    - [x] If the base lacks required `Vehicle`, `Fuel`, or `Ammo` points, deployment is aborted with client notification (`"MECHANIC: Deployment rejected. Insufficient base resources: %1"`), eliminating the zero-point spawn exploit.
  - **Medical Supply Integration (`qm_supplyPhysicalController.sqf` & `qm_clientActionCompiler.sqf`):**
    - [x] Added `_medical` recognition. Any physical base object named `<BaseKey>_medical` (or numbered, such as the Huron Medical Container or medical pod) links dynamically to the base's `Medical` ledger.
    - [x] Engine Container Interaction (No AOE): Rather than an automatic proximity aura, players physically walk up to the medical container and receive field treatment. The amount healed is deducted from the base's `Medical` ledger points. Drains and denies treatment when points hit $0$. (AOE healing remains reserved for custom trigger areas placed by mission makers).
  - **R4-C Pad Gating (`qm_serverFunctions.sqf` & `qm_executeR4CService.sqf`):**
    - If a base has $0$ `Fuel`, R4-C service pads cannot refuel vehicles.
    - If a base has $0$ `Ammo`, R4-C service pads cannot rearm vehicle pylons or turrets.
    - If a base has $0$ `Repair`, R4-C service pads cannot repair hull or engine damage.

- **3. Base Infrastructure Blueprint Logging & Manual Reconstruction Action:**
  - **Mission Start 3D Blueprint Logging:**
    - At mission start, the server logs every physical facility object (`_Arsenal`, `_Terminal`, `_Garage`, `_Service`, `_Helipad`, `_Medical`, `_Fuel`, `_Ammo`):
      `[varName, baseKey, classname, posASL, vectorDirAndUp, supplyType, supplyCost]`.
    - Retains original variable names and exact orientations for 100% fidelity.
  - **Destruction Tracking & 1-Hour Delay:**
    - When an object is killed/destroyed, the server records its destruction timestamp.
  - **Manual Player Reconstruction Action:**
    - Instead of magical automatic respawning, a player must manually request reconstruction at the base Quartermaster terminal/flag:
      `"[ENGINEERING] Reconstruct Base Facility: %1 (Cost: %2 %3)"`
    - **Visibility Condition 1:** At least **1 hour (3600 seconds)** has passed since destruction. The action does not appear until the hour has fully elapsed.
    - **Visibility Condition 2:** The base has sufficient points of that specific supply type (e.g. required Vehicle/Repair points) to fund the rebuild.
    - When executed: points are deducted from the ledger, the destroyed wreck is cleaned up, a fresh entity is created at the logged position/vectors, assigned the original variable name, and actions/listeners are re-initialized.
  - **Contested Base Integration:**
    - Surviving intact facilities flip immediately to the capturing faction.
    - Destroyed facilities continue their 1-hour rebuild timer under the new owners, who can fund and reconstruct them once the timer elapses.

- **4. Status:** **Core Gating Implemented** (Manual rebuild action staged for infrastructure manager).

---

### [ ] 6.5 Direct MSR-to-FOB Resupply Route Proposal (Under Consideration)
- **1. Concept Description:**
  - Evaluates an alternative logistical pipeline where heavy-lift airframes (`CH-67 Huron`, `V-44X Blackfish`) or heavy logistics convoys (`HEMTT Flatbed`) can load supplies at an MSR hub or offshore Cargo Ship (`CS`) and transport them directly to a frontline FOB, bypassing the intermediate Staging Base (`SB`).
- **2. Trade-Off Analysis:**
  - *Pros:* Simulates direct strategic airlift from theater entry points straight into besieged outposts or remote island FOBs.
  - *Cons / Risks:* Bypasses the rear-line Staging Base entirely, disincentivizing players from defending and stocking mainland supply depots.
- **3. Status:** **Logged as Exploratory Proposal** (Retained for community feedback; deferred while standard MSR $\rightarrow$ SB $\rightarrow$ FOB pipelines are finalized).

---

### [ ] 6.6 Open / Infiltratable Virtual Arsenal Across Factions (Proposal Under Consideration)
- **1. Context & Operational Concept:**
  - In tactical combat, an enemy operative who successfully infiltrates an opposing base or contested outpost without being detected may realistically raid the armory for enemy weapons, ammunition, or uniform gear.
  - Evaluates removing faction side lockouts strictly from the **Virtual Arsenal / Ammo Caches** at all bases (including contested bases), allowing enemy players who sneak into proximity to open the armory.
- **2. Strict Functional Boundaries:**
  - **Arsenals:** Infiltrators can access gear, subject to base supply availability (wiped if base has $0$ supplies).
  - **Vehicles & Garages:** Remain **strictly locked** to the controlling faction. Enemy players cannot requisition vehicles from enemy garages.
  - **R4-C Service Pads:** Remain **strictly locked** to the controlling faction. Enemy vehicles cannot receive maintenance or rearming on opposing service pads.
- **3. Status:** **Logged for Discussion & Design Alignment** (Awaiting final operational rule consensus before implementing).

---

### [ ] 6.7 Unified Dual-Purpose (Pickup & Dropoff) Pads & Naval Lateral Transfers
- **1. Context & The Physical Footprint Dilemma:**
  - On large mainland supply depots or land bases, mission makers have ample geographic space to place separate pickup (`<BaseKey>_pickup`) and dropoff (`<BaseKey>_dropoff`) triggers across distinct logistics yards.
  - On naval surface combatants (such as Destroyers `FOB_DDG_086` / `DDG_Liberty`), physical deck space is strictly constrained: there is only **one** aft helicopter flight deck.
  - Mission makers currently must either squeeze two overlapping triggers onto the same physical pad or choose one over the other. Placing a single, dual-purpose pad that dynamically senses whether an inbound aircraft is arriving to *deliver* supplies or arriving to *load* supplies solves this physical space limitation.

- **2. Dual-Purpose Pad Engine Concept (Context-Sensitive Detection):**
  - **Single Physical Pad Identifier:** e.g., `<BaseKey>_pad` or `<BaseKey>_logi_pad` (or overlapping pickup/dropoff on the same footprint).
  - **Dynamic Inbound State Evaluation:**
    - **Inbound with Cargo (Dropoff Mode):** If an aircraft enters the pad carrying cargo (ViV cargo loaded, slingload attached via ropes, or cargo objects dropped onto the deck), the pad behaves as a **Dropoff Pad**: automatically receiving, inventorying, and despawning the delivered cargo, and crediting the base's ledger (`QM_fnc_serverVehicleSale` / `logi_cargoDelivery.sqf`).
    - **Inbound Empty (Pickup Mode):** If an empty aircraft lands on the pad, the pad behaves as a **Pickup Pad**: presenting the pilot with the cargo loading/spawning menu to load supplies from that base's ledger into the vehicle.
  - **Conflict Prevention:** By evaluating `count (getVehicleCargo _veh) > 0` or `!isNull (ropeAttachedTo _veh)` vs an empty cargo hold, a single physical pad seamlessly alternates roles without script conflicts or double-processing.

- **3. Operational Flow: Multi-Tier Lateral Transfers vs. Simple Core Pipelines:**
  - **The Three-Tier Core Structure Remains Clean & Simple:**
    - **Level 1 (Pipeline Hubs):** `MSR` & `CS` (Infinite reserves).
    - **Level 2 (Strategic Staging Bases):** `SB`, `CVN`, `LHA` (Massive rear-line stockpiles).
    - **Level 3 (Tactical Outposts & Contested Fronts):** `FOB`, `DDG`, `DD`, `CON` (Frontline operational ledgers).
    - **Core Automated Mission Types:** Kept deliberately clean, robust, and two-tiered:
      1. *Strategic Runs:* `MSR` $\rightarrow$ `SB` (Heavy bulk containers & flatbeds).
      2. *Tactical Runs:* `SB` $\rightarrow$ `FOB` / `CON` (Medium/light logistics, nets, boxes).
  - **Lateral & Forward-Staging Deliveries (Player-Directed):**
    - Complex multi-hop supply lines (e.g., Heavy `CH-67 Huron` ferries supplies from `CVN_Freedom` to `DDG_Liberty`, and then a Medium `UH-80 Ghost Hawk` or boat based on the Destroyer moves smaller tactical batches to a contested beachhead `CON_Stadium`):
    - Rather than over-complicating the automated task generator with dynamic three-way routing algorithms, **lateral transfers are player-directed**:
      - A player simply ignores automated task waypoints, flies to the Destroyer, drops supplies to credit the Destroyer's ledger, and another pilot spawns supplies from the Destroyer to ferry forward.
      - The framework's dropoff triggers, salvage systems, and physical ledgers already naturally support this sandbox freedom!

- **4. Status:** **Logged as Section 6 Optional Alternative** (Architecture fully evaluated; core routing kept simple and robust while dual-purpose pad logic is preserved for future naval flight deck optimization).

---

### [x] 6.8 Eden Editor Entity Synchronization & Proximity-Based Infrastructure Discovery (Alternatives to Strict Variable Naming)
- **1. Context & The 2D Marker Sync Limitation:**
  - In the Arma 3 Eden Editor, map markers are 2D mission metadata (`dataType="Marker"`), not 3D simulation entities.
  - The engine's connection pipeline physically forbids dragging a synchronization wire (`Right Click -> Connect -> Sync To`) between 3D world objects/triggers and 2D map markers.
  - Currently, all base infrastructure (arsenals, terminals, spawn pads, garages, service pads, medical facilities) is discovered strictly through variable naming conventions: `<BaseKey>_<TypeSuffix>_#` (e.g. `SB_Main_Arsenal_1`, `SB_Main_Garage_Air_1`).
  - Mission makers seeking a more visual, drag-and-drop workflow desire an alternative where infrastructure can be grouped with a base via Eden connections or proximity without typing repetitive variable names.

- **2. Implemented Hybrid Discovery Architecture (All 3 Options Fully Operational):**
  - **Option 1 (2D Map Marker with Full Variable Names):**
    - The existing system: A 2D marker defines the base (`SB_Main`, `FOB_AgiaMarinaBase`).
    - Facilities use explicit full names (`SB_Main_Arsenal_1`, `SB_Main_Garage_Air_1`, `SB_Main_pickup_1`).
  - **Option 2 (3D Base Anchor Object / Flagpole Establishing Base without Markers):**
    - A 3D object (Flag Pole `Flag_NATO_F`, Game Logic, or HQ building) with a base variable name (e.g. `SB_Main`, `FOB_Beachhead`, `CON_Stadium`) automatically registers in `logisticsBases` even if NO 2D map marker exists!
    - The framework auto-creates a True-North 2D map marker at the object's coordinates (`createMarker [_objVar, getPos _x]`), ensuring map clicking, HUD ledgers, and diary manifests work seamlessly with zero manual marker placement.
  - **Option 3 (Eden Editor Drag-and-Drop Synchronization with Suffix / Role Names):**
    - The mission maker places a **Game Logic** (`Systems (F5) -> Logic Entities -> Game Logic`) or **Trigger** named with the base key (e.g. `SB_Main` or `FOB_Camp_Tempest`).
    - > [!IMPORTANT]
      > **Arma 3 Engine Rule (`synchronizedObjects`):** The Bohemia engine's `synchronizedObjects` command **ONLY** returns linked objects when called on a **Game Logic**, **Module**, **Trigger**, or **AI Unit**. Calling `synchronizedObjects` on a static prop / empty object (such as `FlagPole_F` or `PortableFlagPole_01_F`) **always returns `[]`** at runtime, even though Eden Editor allows drawing sync lines to it. Therefore, use a **Game Logic** (placed right at/under your flagpole if desired) as the sync hub.
    - The mission maker draws standard Eden sync lines (`Right Click -> Connect -> Sync To`) from the Game Logic directly to child objects and triggers.
    - **Multiplayer Locality Safety:** Because `synchronizedObjects` on a server-owned Game Logic only evaluates locally on the server, `init.sqf` caches and broadcasts `QM_SyncedObjects` (`publicVariable` / object variable) at `time > 0`, and all subsystems read it via `QM_fnc_getSyncedObjects`.
    - **Eden Variable Naming Rule:** In Arma 3 Eden Editor, variable names define global variables in `missionNamespace`. Variable names **CANNOT start with an underscore** (`_`), as leading underscores are reserved for local script scope. Additionally, variable names must be globally unique across the mission.
    - Synced child objects ONLY require role names (with optional numbering/sizes):
      - `Garage_Ground_1`, `Garage_Air_L_1`, `Garage_Boat_1` $\rightarrow$ Garages & Assembly Pads
      - `Spawn_1`, `Spawn_2` $\rightarrow$ Troop & Vehicle Spawns
      - `Pickup_1`, `Pickup_2` $\rightarrow$ Supply Pickup Triggers
      - `Dropoff_1`, `Dropoff_2` $\rightarrow$ Supply Delivery Dropoff Triggers
      - `Service_1`, `Service_2` $\rightarrow$ R4-C Service Pads
      - `Arsenal_1`, `Terminal_1` $\rightarrow$ Quartermaster Terminals & Virtual Arsenals
      - `Medical_1`, `Medical_2` $\rightarrow$ Medical Containers (Huron Pods / Clinics)
      - `Fuel_1`, `Ammo_1`, `Repair_1` $\rightarrow$ Passive physical logistics caches
    - The framework automatically ties them to the master base's identity via `synchronizedObjects _baseObj`.

- **3. Status:** **Verified Resolved & Implemented** across `init.sqf`, `qm_serverFunctions.sqf`, `qm_vehicleTabs.sqf`, `logi_initTasks.sqf`, and `qm_supplyPhysicalController.sqf`.

---

### [x] 6.9 Dynamic Ground Visual Markers & Color-Coding (Chemlights, Helipad Lights & Particle-Free Visual Cues)

> [!NOTE]
> **Operational Scope & Performance Goal:** Replace manual, continuous Eden smoke grenades (which produce heavy particle plumes that severely degrade rendering FPS) with an automated, lightweight, day/night-adaptive visual cue system.

- **1. Strategic Motivation & Mission-Maker Workflow:**
  - Mission makers currently place physical smoke grenades in the Eden Editor and script them to continuously emit smoke so arriving pilots and drivers can visually identify logistics pads and service areas from distance.
  - Continuous volumetric smoke particles place a heavy burden on the engine's particle rendering pipeline, especially around major bases with multiple pads.
  - At night, smoke plumes become invisible in pitch black, while active chemlights or portable lights are required to guide drivers and pilots onto pads.

- **2. Standardized Color Mapping & Tactical Symbology:**
  - **Service Areas (Repair, Refuel, Rearm):**
    - **Color:** `Yellow` (Universal maintenance / caution).
    - **Day Smoke:** `SmokeShellYellow`.
    - **Outer Edges & Corners:** `Land_runway_edgelight_yellow_F` / `Land_Flush_Light_yellow_F`.
    - **Centerline (Night):** `Chemlight_yellow` + `PortableHelipadLight_01_yellow_F` (or `_constant`).
  - **Dropoff Zones (Offloading / Delivering Supply):**
    - **Color:** `Green` (Matches BLUFOR standard tactical field marker: ground squads deploy green smoke/chemlights to designate friendly drop zones & LZs).
    - **Day Smoke:** `SmokeShellGreen`.
    - **Outer Edges & Corners:** `Land_Flush_Light_green_F` / `Land_runway_edgelight` (Green / High-candela).
    - **Centerline (Night):** `Chemlight_green` + `PortableHelipadLight_01_green_F` (or `_constant`).
  - **Pickup Zones (Loading Supply / Warehouse Pads):**
    - **Color:** `Purple` (Distinct, high-contrast, zero confusion with hostile red or dropoff green).
    - **Day Smoke:** `SmokeShellPurple` (100% native in vanilla Arma 3).
    - **Outer Edges & Corners:** `Land_runway_edgelight_blue_F` / `Land_runway_edgelight` (Blue/Purple spectrum).
    - **Centerline (Night):** `Chemlight_blue` / `Chemlight_purple` + `PortableHelipadLight_01_blue_F` / `Land_PortableHelipadLight_01_F`.
  - **Vehicle Spawn Pads & Helipads (Motorpool / Factory Delivery):**
    - **Color:** `Blue` (BLUFOR vehicle procurement & spawn safety: warns ground personnel and drivers to keep the pad clear to avoid vehicle crushing/collision during spawning).
    - **Day Smoke:** `SmokeShellBlue` (`ModuleSmokeBlue_F`).
    - **Night Lighting:** `PortableHelipadLight_01_blue_F` (or `_constant`) + `Chemlight_blue`.

- **3. Dimensional Hierarchy & Multi-Tier Lighting Architecture:**
  - **Visual Tier 1: Outer Edges & Corners (Runway / Flush Lights - 2,000m+ Range):**
    - Utilizes airport runway edge lights (`Land_runway_edgelight*`, `Land_Flush_Light_*`) placed at the 4 corners and spaced every $100\text{ m}$ down the long flanks.
    - Extended billboard optical glow LODs allow approaching pilots to identify zone boundaries from miles out.
  - **Visual Tier 2: Centerline Approach Alignment (Helipad Lights - 400m–600m Range):**
    - Placed along the major axis centerline every $100\text{ m}$ (with a 25m–50m buffer from the zone edges).
    - Dynamic class selection: uses non-blinking `_constant` variants if 3den Enhanced / CBA is present, falling back dynamically via `isClass` to vanilla `_F` without breaking pure vanilla environments.
  - **Visual Tier 3: Ground Touchdown & Taxiing (Chemlights - 50m Range):**
    - Paired with centerline lights to provide soft, glare-free deck illumination as the aircraft flares for touchdown or trucks reverse into loading bays.
  - **Visual Tier 4: Daytime Centerline Smoke (Particle Overdraw Optimization):**
    - Placed strictly down the centerline every $200\text{ m}$ (Small pads: exactly 1 single center smoke).
    - Zero perimeter smoke ensures pristine frame rates with zero GPU fill-rate particle bottlenecks.

- **4. Dimensional Layout Rules:**
  - **Small Pads ($\le 100\text{ m}$):**
    - **Day:** 1 single center smoke (`SmokeShell*`). Zero perimeter smoke.
    - **Night:** 1 Chemlight + 1 Helipad Light in the center; 4 Runway / Flush lights at the outer corners.
  - **Large Corridors & Airfields ($> 100\text{ m}$):**
    - Derived dynamically from `triggerArea`: detects Major Axis (Length) and Minor Axis (Width) at any orientation `_angle`.
    - **Minor Axis (Width):** Marked only at the corners; zero interior width clutter.
    - **Major Axis Centerline:** Center-originating, expanding symmetrically every $100\text{ m}$ (Night) or $200\text{ m}$ (Day Smoke), with a 25m–50m end-buffer.
    - **Major Axis Flanks:** Night runway lights every $100\text{ m}$ from the corners inward; zero daytime smoke.

- **5. Day / Night State Machine & Mod Compatibility:**
  - Environmental monitor evaluates `sunOrMoon` (or sunrise/sunset times).
  - Automatically toggles objects at dawn and dusk.
  - Dynamic `isClass` checking supports both pure vanilla servers and modded (3den Enhanced) environments seamlessly.

- **6. Status:** **Verified Resolved & Implemented** via `logistics/logi_groundVisuals.sqf`, `logistics/logi_initTasks.sqf`, and `init.sqf`.

---

## 7. Major Feature Requests & System Overhauls

### [ ] 7.1 Multi-Side (PvP / TvT / Multi-Faction) Logistics Engine
- **1. Strategic Context & Competitive Logistics:**
  - Modern conflict scenarios (PvP, TvT, or multi-faction PvE where BLUFOR, OPFOR, and Independent compete for dominance) require logistics networks that operate symmetrically and securely without cross-faction leakage.
  - Logistics players become high-value strategic targets: ambushing an enemy ammo convoy or intercepting a fuel tanker directly starves opposing combat forces of vehicle deployments and ordnance.

- **2. Architecture & Data Model:**
  - **Established Eden Anchor & Side-Ownership Standard (Side Logics vs. `LocationArea_F`):**
    - **Permanent Side-Locked Bases (`MSR`, `SB`, `FOB`, Naval):** Use Bohemia's native Side Logic entities (`Systems (F5) -> Logic Entities -> Sides`) as the master base anchor and synchronization hub:
      - `SideBLUFOR_F` $\rightarrow$ `WEST` (Blue map marker; locked to BLUFOR; ignored by Bohemia `Spawn AI: Sector Tactic`).
      - `SideOPFOR_F` $\rightarrow$ `EAST` (Red map marker; locked to OPFOR; ignored by Bohemia `Spawn AI: Sector Tactic`).
      - `SideResistance_F` $\rightarrow$ `INDEPENDENT` (Green map marker; locked to Independent; ignored by Bohemia `Spawn AI: Sector Tactic`).
    - **Contested / Capturable Bases (`CON_*`):** Use **`LocationArea_F`** (`Systems (F5) -> Logic Entities -> Locations -> Area`) as the master base anchor, synced both to Logistics V8 infrastructure and to Bohemia's native `ModuleSector_F` + capture Trigger + `Spawn AI: Sector Tactic` so AI actively attack and capture `CON` sectors while leaving rear `MSR`/`SB`/`FOB` hubs untouched.
    - **Fallback & Legacy Compatibility:** Optional side prefixes (`BLU_`, `OPF_`, `IND_`) may be supported as a fallback for 2D-marker-only missions; unspecified legacy markers/logics default to `WEST`.
    - **Unbounded Synced Child Numbering:** Because synced objects are discovered directly via `QM_fnc_getSyncedObjects` (not bounded `1..100` loops), arbitrarily high unique Eden variable numbers (`Arsenal_500`, `Garage_Ground_500`, `dropoff_500`) are natively supported alongside legacy `<BaseKey>_<Suffix>_#` naming.
  - **Side-Scoped Base Ledgers:**
    - Ledger variables expand from global base keys to side-scoped keys where applicable: `LogiScore_<BaseKey>_<Category>` or `LogiScore_<BaseKey>_<Side>_<Category>`.
  - **Faction-Gated Visibility & Fog of War:**
    - The Base Supply Ledger HUD and Map Diary only display stockpile levels for bases belonging to the player's own faction (or captured `CON` sectors under friendly control).
    - Enemy base stockpiles remain concealed unless revealed through battlefield intelligence, recon UAV flyovers, or captured documents.
  - **Independent Supply Corridors (MSRs):**
    - Distinct pipeline routes for each faction:
      - BLUFOR: `MSR_WEST_1` / `CS_WEST_Carrier`
      - OPFOR: `MSR_EAST_1` / `CS_EAST_Freighter`
      - INDEPENDENT: `MSR_GUER_1`
    - Task generation strictly assigns supply acquisition tasks from friendly MSRs to friendly Supply Bases.
  - **Inter-Faction Cargo Interception & Supply Hijacking:**
    - Players can capture enemy logistics vehicles carrying cargo.
    - Delivering captured enemy crates to a friendly dropoff pad credits the cargo points directly to the friendly base's ledger, depriving the enemy of resources while bolstering friendly supplies.

- **3. Status:** **Logged as Section 7 Major Feature Proposal**.

---

### [ ] 7.2 Civilian Logistics Framework (Commercial, Industrial & Resource Network)

> [!NOTE]
> **Scope & Architectural Boundary:** Civilian Logistics is a subsystem of the broader Logistics framework within the Dynamic Mission System (DMS). It operates alongside Military Logistics but addresses a distinct economic and material-distribution purpose. This documentation preserves established design intentions and catalogs open design questions; it does **not** represent finalized or actively implemented code.

- **1. Core Purpose & Distinction from Military Logistics:**
  - **Military Logistics:** Primarily handles the movement of military supplies (`Cargo`, `Ammo`, `Fuel`, `Medical`, `Repair`, `Vehicle`, `Troops`) between MSR supply pipelines, rear Staging Bases, and forward operating bases (FOBs). Supplies are delivered into base inventory pools to sustain authorized military units and combat readiness.
  - **Civilian Logistics:** Handles a broader civilian economic, industrial, and material-distribution network. It supports the extraction, transportation, storage, processing, commercial distribution, purchasing, and consumption of civilian goods, raw materials, and finished assets.
  - **Not a Simple Military Sub-Category:** Civilian Logistics cannot simply force all materials into the existing seven military supply categories; it operates as an independent resource and distribution framework.

- **2. Civilian Resource Classifications (Beyond the Seven Military Pools):**
  - **Minimum Resource Types Identified:**
    - `Fuel` (Civilian/Commercial power, heating, transport)
    - `Repair Materials` (Civilian maintenance, construction, toolsets)
    - `Cargo` (General commercial freight, boxed goods, retail merchandise)
    - `Water` (Potable municipal water, agricultural supply, drought relief)
    - `Wood` (Harvested timber, lumber, construction materials)
    - `Coal` (Energy production, smelting fuel, industrial heating)
    - `Iron Ore` (Mined mineral resources, raw manufacturing feedstock)
  - **Industrial & Commercial Movement:** Resources such as water, wood, coal, and iron ore represent materials that flow through extraction, refinement, manufacturing, distribution, and consumption pipelines.
  - **Dedicated Classification:** A distinct civilian resource classification schema is necessary rather than forcing civilian goods into military ledgers.

- **3. Civilian Shops vs. Military Arsenals (Strict System Separation):**
  - **Isolated User Roles & Facilities:**
    - Civilian players interface exclusively with **Civilian Shops**.
    - Military players interface exclusively with **Military Arsenal Facilities** (`VirtualReammoBox_*`, Quartermaster Terminals).
    - **No Cross-Access:** Civilian shops maintain completely independent inventories from military armories; there is no automatic cross-access or bleed-over between systems.
  - **Network-Linked Stock & Real Availability:**
    - Civilian shops are not static, bottomless inventories.
    - Shop stock connects dynamically to the wider civilian supply network: availability of retail goods, tools, and consumables reflects physical deliveries made to that shop or commercial district.
  - **Previously Discussed Commercial Mechanics:** Discussions have explored shop inventory tracking, stock limits, goods valuation/pricing, retail purchasing, and civilian consumption (exact technical integration remains an open design decision).

- **4. Civilian Infrastructure & Proposed Supply Flow:**
  - **Proposed Facility Archetypes:**
    - **Mines / Extraction Sites:** Primary sources providing raw, extracted resources (iron ore, coal, stone).
    - **Industrial Sites / Factories:** Facilities that receive raw materials and process/manufacture refined goods or construction supplies.
    - **Warehouses / Depots:** Regional storage hubs that consolidate, hold, and distribute bulk resources.
    - **Ports & Railheads:** Major commercial transit hubs serving as maritime/intermodal transportation gateways.
    - **Commercial Shops / Retail Markets:** Urban and rural storefronts that maintain consumer inventory and vend goods to civilians.
  - **Proposed Supply Flow Model (Unfinalized Proposal):**
    ```mermaid
    flowchart LR
        Sources["Resource Sources<br/>(Mines, Forests, Wells)"] --> Trans1["Transportation<br/>(Trucks, Freighters)"]
        Trans1 --> Storage["Storage Hubs<br/>(Warehouses, Ports)"]
        Storage --> Processing["Processing Facilities<br/>(Factories, Mills, Refineries)"]
        Processing --> Distribution["Commercial Distribution<br/>(Wholesale Depots)"]
        Distribution --> Shops["Commercial Shops<br/>(Storefronts, Markets)"]
        Shops --> Consumption["Civilian Consumption<br/>(Local Populations, Players)"]
    ```
    *(Note: This represents a conceptual operational model from discussions, NOT a finalized engineering commitment. Facility types and production relationships remain subject to evaluation.)*

- **5. Comparative Framework: Military vs. Civilian Logistics:**
  | Dimension | Military Logistics (Logistics V8 Core) | Civilian Logistics (Proposed Framework) |
  | :--- | :--- | :--- |
  | **Primary Purpose** | Sustaining combat readiness & operational persistence | Economic distribution, commerce, industrial processing |
  | **Resource Types** | 7 Pools: Cargo, Ammo, Fuel, Medical, Repair, Vehicle, Troops | Broad spectrum: Fuel, Repair, Cargo, Water, Wood, Coal, Iron Ore, finished goods |
  | **Primary Nodes** | MSR Pipelines, Staging Bases (`SB`, `CVN`, `LHA`, `LPD`), `FOB`s | Mines, Factories, Warehouses, Ports, Commercial Shops |
  | **User Interaction** | Quartermaster Terminals, Garages, Virtual Arsenals, R4-C Pads | Commercial Shops, Vendor Kiosks, Industrial Loading Bays |
  | **Access Control** | Faction-gated (BLUFOR, OPFOR, INDEP), side permanence | Open civilian commerce, regional consumer markets |
  | **Inventory Dynamics** | Point ledgers deducted by vehicle deployment & loadouts | Physical cargo, raw material processing, retail stock & purchasing |

  > [!IMPORTANT]
  > **Shared vs. Independent Infrastructure:** While both systems may share transportation mechanics (e.g. flatbed trucks, cargo loading triggers, ViV integration, dropoff/pickup routines), their resource classifications, inventory data stores, and user interfaces must remain strictly isolated. The precise degree of shared code vs independent modules remains an open architectural decision.

- **6. Clear Boundary: Civilian Logistics vs. DMS Humanitarian Operational Framework:**
  - **Civilian Logistics Network:** The persistent underlying economic, resource, and commercial distribution network (moving wood/coal, stocking shops, warehouse inventories).
  - **Humanitarian Operational Framework:** Independent tactical mission tasking within DMS, including:
    - Search and Rescue (SAR)
    - Civilian Medical Evacuations (MEDEVAC)
    - Disaster response (wildfire suppression, flood relief)
    - IDAP humanitarian aid drops and refugee camp logistics
    - Critical municipal infrastructure repair (power restoration, water decontamination)
  - **Conceptual Separation:** A humanitarian relief task (e.g., delivering medical supplies to an IDAP clinic) may utilize logistics transport vehicles, but it represents an *operational activity*, not a permanent modification to commercial shop retail ledgers. Civilian Logistics and Humanitarian Operations belong to distinct functional domains within DMS.

- **7. Catalog of Outstanding Design Questions:**
  The following design questions must be formally resolved through future design discussions prior to any implementation:

  - **A. Resource Classification & Taxonomy:**
    - What complete list of civilian resource types will be supported?
    - How will resources be categorized across Raw Materials, Processed Goods, Finished Commercial Products, and Consumables?
    - How should civilian resources be valued, measured, and represented (unit counts, volumetric mass, point equivalents, or physical cargo objects)?

  - **B. Resource Production & Industrial Processing:**
    - How are raw resources extracted (passive background yield, interactive mining, player labor, or external delivery)?
    - Do industrial processing plants convert raw inputs into finished outputs (e.g. Iron Ore + Coal $\rightarrow$ Steel $\rightarrow$ Repair Parts)?
    - Are production rates static, dynamic, or tied to available input stockpiles?

  - **C. Transportation & Storage Architecture:**
    - How are civilian resources physically transported across the map (standard cargo crates, loose bulk materials, tankers, flatbeds)?
    - Do regional warehouses maintain discrete, persistent per-building inventories?
    - How are civilian transportation assets classified, and can they safely leverage existing Logistics V8 vehicle loading routines?

  - **D. Shops & Commercial Distribution:**
    - How do commercial storefronts receive inventory (scheduled warehouse deliveries, merchant player runs, or baseline restock timers)?
    - How are retail purchase prices calculated (fixed pricing vs dynamic supply-and-demand valuation)?
    - Does customer purchasing directly consume physical shop inventory, causing storefronts to run out of stock?

  - **E. Economy, Currency & Facility Ownership:**
    - Does Civilian Logistics utilize an explicit currency / financial ledger, or does it operate on barter, resource allocation, and trade credits?
    - Who owns civilian infrastructure (neutral civilian population, private commercial entities, municipal governments)?
    - Can civilian facilities be bought, leased, or captured by players or factions?

  - **F. Persistence & DMS System Integration:**
    - Which civilian inventories require server-side persistence across sessions or mission restarts?
    - How does civilian inventory data interface with the central Logistics framework without degrading performance?
    - How does the civilian logistics framework gracefully handle scenarios where civilian operational modules (e.g. IDAP missions, SAR) are disabled?

- **8. Status & Roadmap Classification:**
  - **Established Design Intentions:** Complete separation from military arsenals; support for raw industrial resources (wood, coal, iron ore, water); independent commercial shop network; strict decoupling from humanitarian operational missions.
  - **Unfinalized Concepts:** Extraction-to-consumption supply chain flow; shop stock valuation models; shared vehicle loading mechanics.
  - **Current Status:** **Documented as Design Foundation (Section 7.2)**. No SQF implementation or code modifications authorized until design questions are fully aligned.

---

### [ ] 7.3 Mechanized Combat Logistics & High Command Dismount Squads (IFVs, APCs & Armed Transports)

> [!NOTE]
> **Operational Scope & Architectural Boundary:** This proposal establishes the design foundation for separating **Combat Crew** (gunners, commanders, drivers who stay in the vehicle) from **Dismount Infantry / High Command Squads** (fireteams transported into the combat zone who disembark to fight on foot) when operating armored fighting vehicles (IFVs, APCs, MRAPs, and armed helicopters).

- **1. Strategic Problem & Core Motivation:**
  - Players operating mechanized assets (e.g., AMV-7 Marshall, AFV-4 Gorgon, BTR-K Kamysh, Hunter HMG) frequently require two distinct groups of personnel:
    1. **Vehicle Crew:** Specialists tasked with operating internal weapons systems (cannon, coaxial MG, ATGM launcher, commander optics). These units must remain inside the vehicle during engagements.
    2. **Dismount Troops / Infantry Fireteam:** Riflemen, autoriflemen, and AT specialists transported in the passenger bay who must deploy onto the battlefield upon reaching the objective.
  - Currently, when AI units are boarded into a player's vehicle as logistics cargo, they are not part of the player's direct group and cannot be ordered out via standard squad commands (1–9 menu).
  - Conversely, if all units are automatically added to the player's personal squad, the player's command bar becomes cluttered, and the system cannot distinguish between dedicated vehicle gunners versus passengers intended to disembark.

- **2. Proposed High Command & Sub-Group Architecture:**
  - **Vehicle Crew vs. Dismount Squad Separation:**
    - **Vehicle Crew Sub-Group:** Manned via R4C crew deployment or recruitment. Remains assigned to vehicle operational turrets under the player's direct vehicle command.
    - **High Command Dismount Squad:** Transported troops are placed into an independent AI squad bound to the player's **High Command interface (`Ctrl + Space`)**.
  - **High Command Control:**
    - The player commander can assign waypoints, fire orders, or bounding maneuvers to the dismounted squad directly from the tactical map or High Command interface without micromanaging individual soldiers.
  - **Dismount / Mount Action Triggers:**
    - Mechanized commanders receive dedicated action menu items:
      - `[HIGH COMMAND] Dismount Passenger Squad` $\rightarrow$ Orders passenger fireteam to exit vehicle and establish 360-degree perimeter security.
      - `[HIGH COMMAND] Mount Passenger Squad` $\rightarrow$ Orders dismounted fireteam to re-board cargo seats.

- **3. Vehicle Classification & Role Redefinition:**
  - Re-evaluate vehicle roster definitions between **Combat Logistics** (IFVs, armed APCs with crew + dismount capacity) and **Pure Freight Logistics** (unarmed trucks, flatbeds, cargo vans, heavy haulers).
  - Vehicle procurement menus will reflect whether a vehicle supports automated cargo freight, troop cargo transport, or mechanized crew/dismount configurations.

- **4. Status:** **Logged as Section 7 Major Feature Proposal (Design Phase)**.

---

### [x] 7.4 Frontline Contested Sector Separation & Combat Logistics Routing (`Logi_CLT_Task`)

> [!NOTE]
> **Operational Scope & Role Boundary:** Implemented strict operational isolation between **Rear-Line Tactical Outposts (`FOB_*` $\rightarrow$ `TACTICAL`)** and **Frontline Contested Sectors (`CON_*` $\rightarrow$ `CLT`)**. Unarmed logistics haulers (HEMTT cargo/flatbeds, utility vans) are strictly restricted to strategic/tactical routes and are never routed into contested combat zones.

- **1. Strategic Problem & Root Cause Analysis:**
  - **The Symptom:** When players boarded tactical logistics trucks at `SB_Main`, the automated task manager (`logi_manageMissions.sqf`) consistently generated delivery tasks directing them to `CON_Spartan`—the furthest base from the airfield on Stratis.
  - **The Root Cause:** In `templates/tp_baseDefaults.sqf`, the default configuration for `CON` sectors mistakenly specified `["Role", "TACTICAL"]`. Because `CON_Spartan` initializes with $0$ starting supplies across all resource pools (unlike standard FOBs with 10,000–30,000 points), the task assignment algorithm's lowest-score sort (`_candidateFOBs sort by lowest score`) always prioritized `CON_Spartan` above all established FOBs.
  - **Engine ViV Event Handler Bug:** In `logi_spawnLoadSupply.sqf`, the auto-salvage hook subscribed to `"VehicleCargoUnloaded"`, which produced a foreign enum RPT error (`Unknown enum value: "VehicleCargoUnloaded"`). The Bohemia engine event handler name is `"CargoUnloaded"`.

- **2. Applied Architecture Corrections:**
  - **Contested Base Reclassification (`CON` $\rightarrow$ `CLT`):**
    - Updated `templates/tp_baseDefaults.sqf` to classify `CON` sectors strictly as `["Role", "CLT"]`.
    - Updated `init.sqf` (`logi_fnc_getBaseRole`) so any base with the `CON_` prefix defaults to `"CLT"`.
  - **Vehicle Role Partitioning (`tp_vehicleRoles.sqf`):**
    - Removed `"CLT"` from rear-echelon unarmed trucks (HEMTT flatbeds, transports, covered trucks, cargo box trucks, and utility vans). These assets strictly support `Strategic` and `Tactical` routes.
    - Reserved `"CLT"` for combat-rated, armed, or high-survivability transport platforms (Prowler armed/AT, Hunter MRAP, Ghost Hawk, Hummingbird, Pawnee Scout, armed technicals).
  - **Dynamic Combat Logistics Task Generation (`Logi_CLT_Task`):**
    - Implemented `Logi_CLT_Task` creation in `createClientLogiTasks` and sticky task management in `logi_manageMissions.sqf`.
    - `Logi_Tactical_Task` now filters candidate destination bases strictly by `getBaseRole == "TACTICAL"` (`FOB_*`, naval DDGs), completely preventing tactical haulers from being routed into contested sectors.
    - `Logi_CLT_Task` routes candidate destinations strictly from `_allCONs` (`getBaseRole in ["CLT", "COMBAT", "CONTESTED"]`).
    - Added real-time Live Resource HUD Manifest tracking for contested sectors with dedicated red section formatting (`#ff4444`).
  - **Event Handler Typo Correction:**
    - Corrected `"VehicleCargoUnloaded"` to `"CargoUnloaded"` in `logi_spawnLoadSupply.sqf`, resolving the RPT error during freight loading/unloading.

- **3. Status:** **Completed & Verified (Production V8)**.

---

### [ ] 7.5 Dynamic Cross-Tier Resupply & Mid-Transit Route Swapping (Strategic / Tactical / CLT)

> [!NOTE]
> **Operational Scope & Architectural Boundary:** This proposal establishes the design foundation for **Cross-Tier Resupply & Dynamic Mid-Transit Cargo Rerouting**. It explores allowing players who load supplies under one tier (e.g., Strategic bulk containers) to dynamically deliver or reroute them to lower-tier or contested sectors (e.g., Tactical FOBs or Contested bases), with intelligent task navigation adapting to the physically loaded cargo.

- **1. Strategic Motivation & Operational Flexibility:**
  - Logistics operators frequently face changing battlefield conditions where supplies loaded at a rear Staging Base or MSR need to be diverted to an outpost under heavy contact.
  - For example, a heavy lift helicopter pilot (CH-67 Huron or Blackfish) might load a strategic ammunition container intended for a Staging Base, but a squad pinned down at `CON_Spartan` or `FOB_CampMaxwell` urgently needs that ammunition.
  - Players should have the operational freedom to deliver any valid logistics cargo to any friendly or contested dropoff pad, with the receiving base crediting the full value of the resources.

- **2. Current V8 Capabilities vs. Proposed Overhaul:**
  - **What Current V8 Handles Today:**
    - **Physical Delivery Freedom:** Any cargo offloaded in *any* base dropoff zone is accepted and credited 100% to that base ledger via `logi_cargoDelivery.sqf`. The system never rejects supplies.
    - **Reroute Detection:** If a player delivers to an alternate base than the one originally designated by their task, the mission manager recognizes the delivery, marks the task completed, and notifies the player: `[LOGISTICS ENGINE]: Tactical Route rerouted to FOB Mike 26 and completed successfully!`.
    - **Role Priority & Manual Overrides:** All vehicles retain their full prioritized role array (e.g. `["Strategic", "Tactical", "CLT"]`). The vehicle auto-assigns `#0` by default, but the player can manually click "Assign" on any other route in their map task list. Once that run completes, auto-assignment seamlessly returns them to their primary vehicle role.
    - **Task-Adaptive Cargo Spawning:** [logi_spawnLoadSupply.sqf](file:///C:/Users/JSHer/OneDrive/Documents/Arma%203/missions/Mine/Testing/Logistics/Logistics%20System/logistics/logi_spawnLoadSupply.sqf#L44-L58) dynamically checks the player's current active task and sub-task to spawn the appropriate cargo tier (`Strategic` vs. `Tactical` vs. `CLT`).
  - **Proposed Future Enhancements (Section 7.5):**
    - **Intelligent Mid-Transit Rerouting:** If a player has already loaded cargo under a Strategic run and manually switches their active map task to `Tactical Route` or `Combat Logistics Route` while en route:
      - The task engine will inspect the *currently loaded* cargo object in the vehicle.
      - It will query all candidate destination bases (`FOBs` or `CONs`) to find which outpost has the *lowest stockpile of that specific loaded resource* (e.g. lowest Ammo).
      - It will dynamically reroute the 3D delivery waypoint to that base on the fly, eliminating the need for manual off-grid navigation.

- **3. Status:** **Documented as Design Foundation (Section 7.5)**.

### [x] 7.6 Direct Engine Particle Source (`#particlesource`) Overhaul for Dynamic Ground Visuals

> [!NOTE]
> **Operational Scope & Architectural Boundary:** This proposal establishes the technical specification for transitioning the dynamic ground visual markers (Section 6.9) from Bohemia's editor/curator module framework (`ModuleSmoke_F` / `fn_moduleGrenade.sqf`) to native client-side `#particlesource` engine emitters. This architecture provides 100% immunity to internal module parameter deprecation, zero network sync overhead, and instant script-driven lifecycle cleanup.

- **1. Strategic Context & Technical Rationale:**
  - In Bohemia Interactive's module architecture, `ModuleSmoke_F`, `ModuleSmokeBlue_F`, and related visual helpers were originally authored specifically for the 3D Eden Editor GUI and Zeus curator interface via `fn_moduleGrenade.sqf`.
  - Spawning and activating Bohemia Eden modules programmatically at runtime via SQF requires satisfying complex private argument structures (`_params = [_logic, _isActivated, _isCuratorPlaced]`), which are undocumented and sensitive to engine updates or execution environments.
  - In contrast, Arma 3's real-time engine exposes native C++ particle generation directly via the `createVehicleLocal ["#particlesource", ...]` primitive, which attaches pure volumetric rendering directly to coordinates or memory points without any SQF wrapper functions, curator event listeners, or module logic overhead.

- **2. Comparative Architectural Breakdown:**
  | Dimension | Bohemia Module Framework (`ModuleSmoke_F`) | Native Engine Particle Source (`#particlesource`) |
  | :--- | :--- | :--- |
  | **Invocation Mechanism** | `createVehicle` $\rightarrow$ `remoteExec ["fn_moduleGrenade", 0]` | Local C++ primitive: `createVehicleLocal ["#particlesource", _pos]` |
  | **Script Overhead** | High (triggers Bohemia SQF event loops, curator listeners) | Zero (handled 100% inside RV engine particle pipeline) |
  | **Network Bandwidth** | JIP broadcasts, logic object synchronizations | Zero (purely client-side rendering via `createVehicleLocal`) |
  | **Parameter Sensitivity** | Prone to `Type Array, expected Bool` or undefined `_params` | Zero parameters beyond class string; 100% crash immune |
  | **Lifecycle & Deletion** | Complex module logic hierarchy | Instant, atomic cleanup via `deleteVehicle _ps` |
  | **Visual Fidelity** | Standard smoke plume | Identical standard smoke plume (`setParticleClass`) |

- **3. Proposed Implementation Architecture:**
  - **Color & Particle Class Mapping:**
    - **Service Areas (Yellow):** `_ps setParticleClass "SmokeShellYellowEffect"`
    - **Dropoff Zones (Green):** `_ps setParticleClass "SmokeShellGreenEffect"`
    - **Pickup Zones (Purple):** `_ps setParticleClass "SmokeShellPurpleEffect"`
    - **Vehicle Spawn Pads & Helipads (Blue):** `_ps setParticleClass "SmokeShellBlueEffect"`
  - **Client-Side Emitter Generation Helper:**
    ```sqf
    // logistics/logi_groundVisuals.sqf overhaul function
    logi_fnc_createSmokeEmitter = {
        params ["_pos", "_particleClass"];
        private _ps = "#particlesource" createVehicleLocal _pos;
        _ps setParticleClass _particleClass;
        _ps setPosATL _pos;
        _ps
    };
    ```
  - **Day / Night State Transition Lifecycle:**
    - **Permanent Fixtures:** Runway edge lights (`Land_runway_edgelight_yellow_F`, `Land_runway_edgelight_blue_F`) remain permanent fixtures on the terrain with `switchLight "AUTO"`, requiring no despawn or recreation.
    - **Day State:** Server broadcasts or local clients evaluate `sunOrMoon > 0.1` and instantiate local `#particlesource` emitters along pad centerlines and helipad warning locations. Centerline chemlights and helipad lights are deleted.
    - **Night State:** Local `#particlesource` emitters are immediately deleted via `deleteVehicle`. Centerline helipad lights and chemlights are spawned.

- **4. Migration Trigger & Current Status:**
  - **Current Status:** **Implemented & Fully Operational (Section 7.6)**. All legacy Bohemia `ModuleSmoke_F` and `fn_moduleGrenade.sqf` logic removed from `logistics/logi_groundVisuals.sqf` in favor of native `#particlesource` emitters. Historical module activation solution archived in `archive_features.md`. Multiple drop-off zone resolution across bases fully enabled.

---

**Ongoing Development Tracking**

Maintain this checklist as part of the V8 development process. These goals are not necessarily sequential and may be addressed independently as opportunities arise during debugging, refactoring, and feature development.

When work on any goal begins, track its progress and associated subtasks. Do not remove unfinished goals simply because other development work takes priority.

The objective is to progressively bring these features into Logistics Framework V8 while maintaining the stability and functionality of the existing framework.
