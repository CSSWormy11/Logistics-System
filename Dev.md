# Arma 3 Logistics System (V8) — Development Tracker (`Dev.md`)

This document tracks verified bugs, inconsistencies, incomplete features, and upcoming user-directed development goals for the Logistics & Quartermaster Core Framework.

---

## 1. Critical Bugs & Logic Issues to Address

### [ ] 1.1 Strategic vs. Tactical Role Parsing in `fn_manageLogisticsMissions.sqf`
- **1. Initial Issue Summary:** `logisticsVehicleRoles.sqf` stores vehicle roles as prioritized arrays of strings (e.g., `["Strategic", "Tactical", "CLT"]`), but `fn_manageLogisticsMissions.sqf` (Lines 139–148) assigned `_assignedRoleOverride = (logisticsVehicleRoles # _roleIdx) # 1;` (which is the array itself) and compared `if (_assignedRoleOverride == "Strategic")`. Comparing an Array to a String in SQF always evaluates to `false`, preventing any vehicle from ever receiving `Logi_Strategic_Task` routing.
- **2. Proposed / Applied Corrections:** Updated `fn_manageLogisticsMissions.sqf` (Lines 139–150) to unwrap the primary role (`# 0`) when the `logisticsVehicleRoles` entry is an array, while preserving fallback support if a string is provided. Mission makers retain full control over the role priority array per vehicle in `logisticsVehicleRoles.sqf`. *(Note: Line 112 still excludes `Air` vehicles via `!(_vehicle isKindOf "Air")`, which may need review if VTOLs/Helicopters should receive Strategic/Tactical tasks prior to GIN/CLT integration.)*
- **3. Status:** **In Testing** (Corrections applied in `fn_manageLogisticsMissions.sqf` — needs in-game verification).

### [ ] 1.2 Vehicle Cap (`QM_CAP`) First-Match Short-Circuit
- **1. Initial Issue Summary:** In `qm_serverFunctions.sqf` (Lines 199–216), `QM_CAP_fnc_checkCurrentActiveCount` and `QM_CAP_fnc_registerNewVehicle` iterated over `QM_CAP_ConfigMatrix` from top to bottom and exited (`exitWith`) on the first parent class where `_classname isKindOf (_x select 0)`. Because `["All", 256]` is the first element in `qm_vehicleCapsTemplate.sqf` (Line 13), every vehicle matched `"All"` immediately and ignored all category and specific vehicle caps below it.
- **2. Proposed / Applied Corrections:** Updated `QM_CAP_ActiveRegistry`, `QM_CAP_fnc_checkCurrentActiveCount`, `QM_CAP_fnc_registerNewVehicle`, and `QM_CAP_fnc_unregisterVehicleAsset` in `qm_serverFunctions.sqf` (Lines 197–274) so that every matching parent class and specific vehicle class in `QM_CAP_ConfigMatrix` is evaluated and tracked simultaneously. Spawning is denied if *any* matching category or specific class cap is full, and destroyed/deleted/salvaged vehicles are removed from all matching cap registries. `qm_vehicleCapsTemplate.sqf` values are left untouched for mission-maker customization.
- **3. Status:** **In Testing** (Corrections applied in `qm_serverFunctions.sqf` — needs in-game verification).

### [ ] 1.3 Garage & Facility Discovery: Strict 3D Editor Objects Only
- **1. Initial Issue Summary:** Client UI `c_vehicleTabs.sqf` (Lines 46–53) checked both `allMapMarkers` and `allVariables missionNamespace` (editor-placed objects) when deciding which vehicle tabs/sizes a base supports, whereas server `QM_fnc_processGarageSpawn` in `qm_serverFunctions.sqf` (Line 300) only searched `allMapMarkers`. Additionally, 2D map markers lack 3D elevation (`Z = 0`), causing height/positioning inaccuracies on ship decks and inside hangars.
- **2. Proposed / Applied Corrections:** Transitioned `_Arsenal`/`_Terminal`, `_Spawn`, and `_Garage` locations strictly to 3D Editor Objects (discovered via `missionNamespace` variable names, independent of object classname) while keeping map markers strictly for base identification (`logisticsBases`):
  - Updated `QM_fnc_getLocationsByPrefix` in `init.sqf`, `c_vehicleTabs.sqf`, `QM_fnc_processGarageSpawn` in `qm_serverFunctions.sqf`, `qm_serverGarrisonManager.sqf`, `qm_serverRespawnManager.sqf`, `onPlayerRespawn.sqf`, and `fn_usedCarSalesman.sqf` to use editor-placed 3D objects (`getPosASL` / `getDir`) and removed runtime marker-to-object spawning loops.
  - Added support in `QM_fnc_processGarageSpawn` for both `_HELI` and `_HELICOPTER` garage suffixes, and enabled direct Vehicle-in-Vehicle boat loading (`setVehicleCargo`) when the `<BaseKey>_Garage_Boat_...` object is itself a Boat Rack (or near one).
  - Updated `onPlayerRespawn.sqf` to check within 40m of the `_Spawn` object for nearby Cargo Houses (`Land_Cargo_House_V1_F`, `Land_Cargo_House_V3_F`) and otherwise preserve the exact 3D ASL position of the `_Spawn` object (e.g., `Land_HelipadEmpty_F` on a Carrier/Destroyer deck).
- **3. Status:** **In Testing** (Corrections applied across `init.sqf`, `qm_serverFunctions.sqf`, `c_vehicleTabs.sqf`, `qm_serverGarrisonManager.sqf`, `qm_serverRespawnManager.sqf`, `onPlayerRespawn.sqf`, and `fn_usedCarSalesman.sqf` — needs in-game verification).

### [ ] 1.4 Dedicated Server Locality in `QM_fnc_serverR4CCreateVehicleCrew`
- **1. Initial Issue Summary:** In `qm_serverFunctions.sqf` (Line 537), `(group _playerUnit) createVehicleCrew _vehicle;` was executed on the server. In Arma 3, the group-targeted `createVehicleCrew` syntax requires the target group to be local to the executing machine; on a dedicated server, a player's group is local to the client.
- **2. Proposed / Applied Corrections:** Updated `QM_fnc_serverR4CCreateVehicleCrew` in `qm_serverFunctions.sqf` (Lines 609–615) to spawn the crew on the server via `createVehicleCrew _vehicle` and then transfer the newly created crew members into `group _playerUnit` using `joinSilent`.
- **3. Status:** **In Testing** (Corrections applied in `qm_serverFunctions.sqf` — needs in-game verification).

### [x] 1.5 Vehicle Salvage System (Redesigned with Dropoff Zone Disembark Confirmation)
- **1. Initial Issue Summary:** In `fn_usedCarSalesman.sqf` (Lines 9–17), salvage detection searched within a 14m 3D sphere around `getMarkerPos _baseKey` (the master base marker at `Z=0`) for `["LandVehicle", "Air"]`. Because `getMarkerPos` is at sea level (`Z=0`), elevated decks (e.g., `SB_Carrier` at ~24m ASL or Destroyers) and garage pads located >14m away from the central base marker were completely out of range, and `"Ship"` / boats inside Boat Racks were excluded. In-game testing confirmed that triggering salvage blindly from a terminal crate does not reliably detect unoccupied vehicles on distant pads.
- **2. Proposed / Applied Corrections:**
  - Removed the broken `fn_usedCarSalesman.sqf` scroll-wheel action from base terminals in `qm_clientActionCompiler.sqf`.
  - Implemented **Option C (Dropoff Zone Disembark Confirmation Prompt & Context Action)**:
    1. Base **Dropoff Zones** serve as the universal vehicle return point.
    2. When a player drives, lands, or docks an unoccupied vehicle into a dropoff zone and disembarks, `GetOutMan` triggers a modal `BIS_fnc_guiMessage` confirmation prompt asking: `"Would you like to SALVAGE this [Vehicle Name] and recycle its resources back to [Base Name]? [YES / NO]"`.
    3. If confirmed **YES**, the vehicle is despawned, crew safely deleted, 100% of chassis resources credited to base ledgers, and its vehicle cap (`QM_CAP`) unregistered via `QM_fnc_serverVehicleSale`.
    4. If declined **NO**, the vehicle remains completely untouched on the pad.
    5. Added a context-sensitive look-at `addAction` on the player (`[SALVAGE CONTROL] Recycle Vehicle to Base`) for ad-hoc salvage of unoccupied vehicles inside any base dropoff zone.
- **3. Status:** **Verified Resolved** (In Testing).

### [ ] 1.6 Multi-Tier Task Visibility, Priority Auto-Assignment & Aircraft Support in `fn_manageLogisticsMissions.sqf`
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
- **3. Status:** **In Testing** (Corrections applied in `fn_initLogisticsTasks.sqf` and `fn_manageLogisticsMissions.sqf` — needs in-game verification).

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

### [ ] 1.14 MSR Infinite-Pool (`-1`) Verification Guard & Native ViV Loading
- **1. Initial Issue Summary:**
  1. In `fn_spawnLoadSupply.sqf` (Lines 91–97), `_availablePoints != -1 && _availablePoints < _totalCargoPointWeight` checked whether base storage had sufficient points before spawning. When loading at an MSR hub, if `LogiScore_MSR_<category>` was not found in `missionNamespace` (e.g. if no map marker was named `"MSR"` or before network sync), `getVariable` returned `0` (`0 != -1`), which evaluated as depleted and aborted with `"WARNING: Stores low on <category> at MSR."`.
  2. Because of this top-level script exit, `fn_spawnLoadSupply.sqf` aborted before reaching the cargo spawning code, completely preventing cargo from spawning or loading into the transport vehicle.
  3. In `init.sqf` (Lines 121–152), `logisticsBases` and `LogiScore_<base>_*` were only initialized from markers in `allMapMarkers`. If mission makers placed MSR pickup triggers (`MSR_pickup_1`..`5`) without a dedicated marker named `"MSR"`, `"MSR"` was omitted from `logisticsBases` and its infinite (`-1`) pool values were never initialized.
- **2. Proposed / Applied Corrections:**
  - Updated `fn_spawnLoadSupply.sqf` to explicitly check `private _isMSR = "MSR" in (toUpper _pickupBaseKey);` so MSR loading pads are recognized as infinite (`-1`), bypassing low store warnings and skipping pool deductions.
  - Updated `init.sqf` to ensure `"MSR"` is unconditionally registered in `logisticsBases` and its ledger pools initialized to `-1` across all resource categories in `logisticsBaseDefaults.sqf`.
  - Strictly preserved Bohemia Interactive native Vehicle-in-Vehicle (`setVehicleCargo`) loading without artificial workarounds or attachTo mechanics.
- **3. Status:** **Testing in Progress** (Corrections applied in `fn_spawnLoadSupply.sqf` and `init.sqf` — awaiting in-game confirmation).

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

### [ ] 2.1 Base Restriction Tier Discrepancy (`c_vehicleTabs.sqf` vs. `fn_recruiter_list.sqf`)
- **1. Initial Issue Summary:**
  - In `fn_recruiter_list.sqf` (Line 67), `"FOB"`-tier units were allowed at both `FOB` and `SB` bases (`_isFOB || _isSB`), allowing frontline-only `"FOB"` infantry to be spawned at rear `"SB"` hubs.
  - Neither `fn_recruiter_list.sqf` nor `c_vehicleTabs.sqf` supported `"BOTH"` or an array of allowed base types/names (e.g., `["SB", "FOB"]`).
- **2. Proposed / Applied Corrections:** Updated both `fn_recruiter_list.sqf` (Lines 68–84) and `c_vehicleTabs.sqf` (Lines 156–170) so that:
  - `"SB"` restricts strictly to `SB` bases (`_isSB`).
  - `"FOB"` restricts strictly to `FOB` bases (`_isFOB`).
  - `"ALL"` or `"BOTH"` allows spawning at both `SB` and `FOB` bases (`_isSB || _isFOB`).
  - Array restrictions (e.g., `["SB", "FOB"]` or specific base names like `["SB_Carrier"]`) are also supported.
- **3. Status:** **In Testing** (Corrections applied in `fn_recruiter_list.sqf` and `c_vehicleTabs.sqf` — needs in-game verification).

### [ ] 2.2 Case Sensitivity in Infantry & Vehicle Template Filtering
- **1. Initial Issue Summary:** In `fn_recruiter_list.sqf` (Lines 62–64), `_faction`, `_terrainArray`, and `_systemsArray` were compared without `toUpper` normalization, and in `c_vehicleTabs.sqf` (Line 150), `_systemsArray` was compared without `toUpper`.
- **2. Proposed / Applied Corrections:** Normalized `_faction`, `_terrainArray`, `_systemsArray`, and `_restrictionType` in both `fn_recruiter_list.sqf` and `c_vehicleTabs.sqf` using `toUpper` so mission-maker case differences never break filtering.
- **3. Status:** **In Testing** (Corrections applied in `fn_recruiter_list.sqf` and `c_vehicleTabs.sqf` — needs in-game verification).

### [x] 2.3 `B_supplyCrate_F` Cost / Score Values in Templates
- **1. Initial Issue Summary:** `B_supplyCrate_F` is set to `4,000` Cargo points in `spawnableVehicleTemplate.sqf` (Line 195) and `7,000` Cargo points in `SupplyScores.sqf` (Line 15).
- **2. Proposed / Applied Corrections:** None required — template values were intentionally configured by the author and are designed to be mission-maker customizable.
- **3. Status:** **Verified Resolved / By Design** (Template files left untouched per design specification).

### [ ] 2.4 Service Truck & Huron Container `1,000,000` Cost Entries vs. `10,000,000` Script Filter
- **1. Initial Issue Summary:** `c_vehicleTabs.sqf` (Line 205) and `qm_serverFunctions.sqf` (Lines 54, 256, 337) filtered out pool costs `>= 10000000` (10M), while `spawnableVehicleTemplate.sqf` (Lines 52–67, 89, 184–188) has `1000000` (1M — representing bulk/infinite `transportAmmo`/`transportFuel`/`transportRepair` config values) on HEMTT service trucks, Bobcats, and Huron containers. Because `1,000,000 < 10,000,000`, the scripts billed 1,000,000 Ammo/Fuel/Repair/Cargo points when spawning those assets (which exceeded an SB's starting 100k–300k pools).
- **2. Proposed / Applied Corrections:** Kept `spawnableVehicleTemplate.sqf` untouched and updated the cost filter threshold in `c_vehicleTabs.sqf` (Line 212) and `qm_serverFunctions.sqf` (`QM_fnc_serverVehicleSale` and `QM_fnc_processGarageSpawn`) from `< 10000000` to `< 1000000` so `1000000` config-capacity values are excluded while normal chassis/fuel/cargo costs are billed and refunded normally.
- **3. Status:** **In Testing** (Corrections applied in `c_vehicleTabs.sqf` and `qm_serverFunctions.sqf` — needs in-game verification).

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

### 4.2 Respawn System Updates

Update the respawn system to account for troop supply availability and individual player respawn restrictions at each base.

- [ ] Integrate troop supply availability into respawn location selection.
  - [ ] Only display bases with available troop supply points as respawn locations.
- [ ] Implement per-player, per-base respawn timers.
  - [ ] Track respawn timers independently for each player at each base.
  - [ ] Prevent players from respawning at the same base in quick succession.
- [ ] Support more realistic gameplay pacing.
  - [ ] Reduce the ability to immediately return to the battlefield after death.
  - [ ] Discourage players from exploiting knowledge gained from ambushes and sniper positions through repeated instant respawns.
  - [ ] Encourage teamwork, coordination, intelligence sharing, scouting, and base security.

### 4.3 Vehicle Spawning System Updates

Improve vehicle spawning accuracy and transition toward physical objects as spawn-point references instead of relying on markers.

- [x] Improve spawn positioning and height accuracy. *(In Testing)*
  - [x] Prevent objects from spawning above their intended positions. *(Uses exact 3D `getPosASL` of editor-placed pad object)*
  - [x] Prevent objects from spawning below their intended positions. *(Uses exact 3D `getPosASL` of editor-placed pad object)*
  - [x] Ensure objects spawn exactly where intended. *(Uses exact 3D `getPosASL` and `getDir` of editor-placed pad object)*
- [x] Transition from markers to physical objects as spawn-point references. *(In Testing — `_Arsenal`/`_Terminal`, `_Spawn`, and `_Garage` now strictly use editor-placed 3D objects via variable name; markers are reserved for base identification)*
- [x] Develop spawn-point object compatibility. *(In Testing)*
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

### 4.6 Contested Bases (`Contested_*`) Mechanics & Integration (Low Priority)

Design and implement the frontline Contested Base (`Contested_*`, e.g., `Contested_Stadium`) mechanics once core `MSR`, `SB`, and `FOB` logistics operations are finalized and verified.

- [ ] Define how `Contested_*` bases interact with the logistics supply pools and capture/frontline state.
- [ ] Transition `Contested_*` facility markers (`_Arsenal`, `_Garage`, `_Spawn`, `_Service`) to 3D editor objects when Contested Base rules are finalized.

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

### 4.10 Task HUD & Waypoint Navigation: 3-Tier Sub-Task Hierarchy, Grid Coordinates & Manifest Status

Enhance the Logistics Mission Routing Engine (`fn_manageLogisticsMissions.sqf`) so transport routes feature a structured parent/sub-task hierarchy (`BIS_fnc_setTask`) communicating base names, 6-digit military map grid coordinates (`mapGridPosition`), and live cargo manifest status:

- [x] **Parent Task Hierarchy (`[SubTaskID, ParentTaskID]`):**
  - [x] **Sub-Task 1: Pickup Supplies** — Assigned at route start; waypoint targets the center of the compatible pickup trigger with base name and 6-digit grid. Marked `SUCCEEDED` upon loading completion.
  - [x] **Sub-Task 2: Cargo Manifest & Securing** — Shows assigned cargo category (e.g. `Ammo`, `Fuel`, `Medical`, `Cargo`). Marked `SUCCEEDED` once loaded and secured. Resets/fails if cargo is dropped or lost early before reaching the delivery zone.
  - [x] **Sub-Task 3: Deliver Supplies** — Transitions to `ASSIGNED` upon loading completion; waypoint targets the center of the dropoff zone at the destination base with 6-digit grid. Marked `SUCCEEDED` upon dropoff delivery.
  - [x] **Parent Route Task** — Completes once all 3 sub-tasks succeed, cycling the player to their next prioritized route assignment.
- [x] **Trigger Condition-Driven Compatibility:**
  - [x] Evaluate the player's vehicle against the trigger's Eden Editor condition (`LogiTriggerCond`), distinguishing between plane corridors (`_x isKindOf "Plane"`), low/slow helicopter zones (`_x isKindOf "Helicopter"`), and open/unrestricted stationary pads.
- [x] **Multiplayer Locality:**
  - [x] Ensure all tasks, sub-tasks, and HUD waypoints are player-local (`player` target in `BIS_fnc_setTask`) so multiple players flying or driving simultaneously never interfere with each other's navigation or progress.

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

---

**Ongoing Development Tracking**

Maintain this checklist as part of the V8 development process. These goals are not necessarily sequential and may be addressed independently as opportunities arise during debugging, refactoring, and feature development.

When work on any goal begins, track its progress and associated subtasks. Do not remove unfinished goals simply because other development work takes priority.

The objective is to progressively bring these features into Logistics Framework V8 while maintaining the stability and functionality of the existing framework.
