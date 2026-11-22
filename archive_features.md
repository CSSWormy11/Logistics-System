# Archive Features: Historical Implementations & Technical Reference

This document archives sophisticated technical implementations and engine solutions developed during the evolution of the **Arma 3 Logistics & Quartermaster Core Framework (V8)** that have been superseded by higher-performance engine primitives.

---

## 1. Runtime Dynamic Activation of Bohemia Eden Effect Modules (`ModuleSmoke_F`)

### 1.1 Context & Objective
In standard Arma 3 mission design, mission makers deploy smoke grenades in the Eden Editor or run repeating script loops (e.g., spawning physical `SmokeShell` grenades every 50 seconds) to provide visual approach markers for pilots and drivers. This approach consumes significant network bandwidth and scripting overhead.

To resolve this, Section 6.9 explored spawning Bohemia's Eden Editor smoke modules (`ModuleSmoke_F`, `ModuleSmokeBlue_F`, `ModuleSmokeGreen_F`, `ModuleSmokePurple_F`, `ModuleSmokeYellow_F`) dynamically at mission runtime via SQF. When properly initialized, Bohemia's module system generates an infinite, self-repeating smoke plume without requiring periodic script execution loops.

---

### 1.2 The Engine Challenge: Undocumented Module Signatures
Bohemia Interactive architected the `Module_F` framework exclusively for the **Eden 3D Editor GUI** and **Zeus Curator Interface**. The underlying module logic functions (such as `A3\modules_f\Effects\functions\fn_moduleGrenade.sqf`) were never documented or intended for manual runtime instantiation via `createUnit` or `createVehicle`.

Attempting to execute `createUnit` on a module logic without satisfying its exact, undocumented argument layout causes immediate script crashes in the Arma 3 RPT log.

---

### 1.3 Step-by-Step Parameter Resolution & RPT Bug Forensics

Through runtime execution and RPT forensic analysis, the three internal parameter requirements of `fn_moduleGrenade.sqf` were systematically identified and resolved:

#### Crash 1: Undefined `_params`
```text
File A3\modules_f\Effects\functions\fn_moduleGrenade.sqf..., line 3
Error in expression <_params = _this select 1;>
Error Undefined variable in expression: _params
```
* **Cause:** `fn_moduleGrenade.sqf` begins with:
  ```sqf
  private _mode = _this select 0;
  private _params = _this select 1;
  ```
  Calling `[_mod] remoteExec [_fncName, 0, true]` passed an array with only 1 element. Index 1 (`_params`) did not exist.
* **Fix:** Wrapped the call in `["init", [_mod, ...]]`.

---

#### Crash 2: Undefined `_iscuratorplaced`
```text
File A3\modules_f\Effects\functions\fn_moduleGrenade.sqf..., line 61
Error in expression <_isCuratorPlaced = _params select 2;>
Error Undefined variable in expression: _iscuratorplaced
```
* **Cause:** At line 60, Bohemia's function attempts to determine whether Zeus placed the module:
  ```sqf
  private _isCuratorPlaced = _params select 2;
  ```
  Passing `[_mod, []]` provided only 2 items in `_params`. Index 2 was missing.
* **Fix:** Added a boolean `false` as index 2: `[_mod, true, false]`.

---

#### Crash 3: Type Mismatch `Type Array, expected Bool`
```text
File A3\modules_f\Effects\functions\fn_moduleGrenade.sqf..., line 71
Error in expression <if (_activated && !is3DEN) then {>
Error position: <&& !is3DEN) then {>
Error &&: Type Array, expected Bool
```
* **Cause:** Lines 70–71 unpack and evaluate activation:
  ```sqf
  private _activated = _params select 1;
  if (_activated && !is3DEN) then { ... };
  ```
  Passing an empty array `[]` at index 1 of `_params` caused line 71 to evaluate `if ([] && !is3DEN)`. In SQF, boolean operators (`&&`, `||`) require primitive boolean types (`true` or `false`), triggering a fatal engine script abort.
* **Fix:** Explicitly set index 1 of `_params` to `true`:
  ```sqf
  ["init", [_mod, true, false], true] remoteExec [_fncName, 0, true];
  ```

---

### 1.4 Fully Operational Module Activation Code (Reference)

For archival purposes, the complete working implementation that programmatically spawns and activates Bohemia smoke modules at runtime is preserved below:

```sqf
// ============================================================================
// ARCHIVAL REFERENCE: RUNTIME BOHEMIA MODULE SPAWN & ACTIVATION
// ============================================================================

// 1. Module Group Initialization (Logic Side)
private _logicGrp = createGroup [sideLogic, true];

// 2. Module Activation Function
logi_fnc_activateModule = {
    params ["_mod"];
    if (isNull _mod) exitWith {};
    
    // Read the registered module execution function from CfgVehicles
    private _fncName = getText (configFile >> "CfgVehicles" >> typeOf _mod >> "function");
    if (_fncName == "") then { _fncName = "BIS_fnc_moduleGrenade"; };

    // Standard Bohemia Module Parameter Structure:
    // _this select 0: Mode ("init")
    // _this select 1: _params array: [_logic, _isActivated, _isCuratorPlaced]
    // _this select 2: _isActivated (true)
    ["init", [_mod, true, false], true] remoteExec [_fncName, 0, true];
};

// 3. Module Spawning Helper
logi_fnc_createSmokeModule = {
    params ["_class", "_pos", "_colorName", "_ammoClass", "_logicGroup"];
    
    // Spawn the module logic unit
    private _mod = _logicGroup createUnit [_class, _pos, [], 0, "CAN_COLLIDE"];
    if (isNull _mod) then {
        _mod = _logicGroup createUnit ["ModuleSmoke_F", _pos, [], 0, "CAN_COLLIDE"];
    };
    
    // Set internal variables evaluated by fn_moduleGrenade.sqf
    _mod setVariable ["Type", _ammoClass, true];
    _mod setVariable ["type", _ammoClass, true];
    _mod setVariable ["Color", _colorName, true];
    _mod setVariable ["color", _colorName, true];
    _mod setVariable ["Repeat", 1, true];
    _mod setVariable ["repeat", 1, true];
    _mod setVariable ["Timeout", 0, true];
    _mod setVariable ["timeout", 0, true];
    
    // Surface-aware positioning
    if (surfaceIsWater _pos) then {
        _mod setPosASL _pos;
    } else {
        _mod setPosATL _pos;
    };

    // Broadcast module initialization
    [_mod] call logi_fnc_activateModule;
    _mod
};
```

---

### 1.5 Rationale for Transition to `#particlesource`
While the above solution successfully resolves Bohemia's module requirements, the architecture was superseded by **Section 7.6 (Direct Engine Particle Source `#particlesource`)** due to the following strategic advantages:

1. **Direct C++ Execution:** `#particlesource` calls the RV engine's particle emitter directly in C++, completely bypassing SQF script wrappers and Zeus curator event hooks.
2. **Crash Immunity:** Particle sources accept native config classes (e.g., `setParticleClass "SmokeShellBlueEffect"`), requiring no reverse-engineered parameter arrays.
3. **Zero Network Synchronization:** Emitters are spawned locally on each connected client via `createVehicleLocal ["#particlesource", _pos]`, producing zero server-to-client network synchronization overhead.
4. **Clean Lifecycle Cleanup:** Despawning requires a single, atomic `deleteVehicle _ps` call with zero residual sideLogic units or helper entities.
