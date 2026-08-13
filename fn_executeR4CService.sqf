// ============================================================================
// LOGISTICS SYSTEM: VEHICLE INTERACTION CLIENT (PART 3A)
// File: fn_executeR4CService.sqf
// Description: Virtual Service Pad Integration Module. Executes on the 
//              Client-Side Local Machine (Trigger-driven driver interface).
//              Evaluates vehicle state and requests server processing.
// Called By: Editor Trigger (On Activation)
// ============================================================================

params [ 
    ["_trigger", objNull, [objNull]], 
    ["_veh", objNull, [objNull]], 
    ["_delay", 3, [3]] 
];

if (isNull _trigger || isNull _veh || !alive _veh) exitWith {};
if (driver _veh != player) exitWith {};

private _triggerName = vehicleVarName _trigger;
private _baseKey = _triggerName;
private _idx = _baseKey find "_service";
if (_idx != -1) then { _baseKey = _baseKey select [0, _idx]; };

private _vehType = getText(configFile >> "CfgVehicles" >> typeOf _veh >> "DisplayName");
_veh sideChat format ["R4-C SYSTEMS: Establishing connection link to %1 Base Ledger. Analyzing %2 profile...", _baseKey, _vehType];
sleep _delay;

// --- DIAGNOSTIC TRACKING VARIABLES ---
private _startDamage = damage _veh;
private _startFuel = fuel _veh;
private _startMissingAmmo = false;

// --- RPT LOGGING: Pre-Service State ---
diag_log format ["[PART 3A VIRTUAL PAD SCAN] Vehicle: %1 | Base: %2", _vehType, _baseKey];
diag_log format ["    >> Pre-Service State -> Damage: %1 | Fuel: %2", _startDamage, _startFuel];

// --- LANE 1: REARM ---
{
    _x params ["_magClass", "_turretPath", "_ammoCount"];
    private _maxCount = getNumber (configFile >> "CfgMagazines" >> _magClass >> "count");
    if (_ammoCount < _maxCount) then { _startMissingAmmo = true; };
} forEach (magazinesAllTurrets _veh);

if (_startMissingAmmo) then {
    diag_log "    >> Action: REARM Triggered.";
    _veh sideChat "Rearming dynamic weapons array and turret pods...";
    [_baseKey, _veh, player, "REARM", 150] remoteExecCall ["QM_fnc_serverProcessR4C", 2];
    sleep _delay;
    _veh sideChat "Rearm cycle finalized.";
} else { 
    diag_log "    >> Action: REARM Skipped (Already Full).";
    _veh sideChat "Munitions inventory checks out optimal (100% Full)."; 
};
sleep 1;

// --- LANE 2: REPAIR ---
if (_startDamage > 0.01) then {
    diag_log format ["    >> Action: REPAIR Triggered. (Damage: %1)", _startDamage];
    _veh sideChat format ["Damage detected at %1%2. Deploying welding arrays...", round(_startDamage * 100), "%"];
    private _repairCost = ceil (_startDamage * 2000); // 2000 points for a 100% repair
    [_baseKey, _veh, player, "REPAIR", _repairCost] remoteExecCall ["QM_fnc_serverProcessR4C", 2];
    sleep _delay;
    _veh sideChat "Structural composition fully restored.";
} else { 
    diag_log "    >> Action: REPAIR Skipped (No Damage).";
    _veh sideChat "Chassis structural integrity verified nominal (0% Damage)."; 
};
sleep 1;

// --- LANE 3: RECREW ---
private _emptyCrew = count (fullCrew [_veh, "", true] select {(_x select 1) in ["driver", "commander", "gunner", "turret"] && isNull (_x select 0)});
if (_emptyCrew > 0) then {
    diag_log format ["    >> Action: RECREW Triggered (%1 missing).", _emptyCrew];
    _veh sideChat format ["Warning: %1 vacant operator slots found. Routing mobilization drafts...", _emptyCrew];
    [_baseKey, _veh, player, _emptyCrew, _emptyCrew] remoteExecCall ["QM_fnc_serverR4CCreateVehicleCrew", 2];
    sleep 2.0;
} else { 
    diag_log "    >> Action: RECREW Skipped (Fully Crewed).";
    _veh sideChat "Operating crew contingent certified full."; 
};
sleep 1;

// --- LANE 4: REFUEL ---
private _missingFuel = 1 - _startFuel;
if (_missingFuel > 0.01) then {
    diag_log format ["    >> Action: REFUEL Triggered. (Missing: %1)", _missingFuel];
    _veh sideChat format ["Fuel levels at %1%2. Engaging liquid propellant transfer valves...", round(_startFuel * 100), "%"];
    private _fuelCost = ceil (_missingFuel * 100);
    [_baseKey, _veh, player, "REFUEL", _fuelCost] remoteExecCall ["QM_fnc_serverProcessR4C", 2];
    sleep 1.5;
    _veh sideChat "Fuel tanks capped to capacity.";
} else {
    diag_log "    >> Action: REFUEL Skipped (Tanks Full).";
    _veh sideChat "Fuel reserves at absolute capacity.";
};

_veh sideChat "R4-C SERVICE TRACK RELEASES: Clear the virtual pad zone bounds.";