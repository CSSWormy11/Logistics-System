// ============================================================================
// LOGISTICS SYSTEM: CLIENT FUNCTIONS & DAEMONS
// File: qm_clientFunctions.sqf
// Description: Central repository for all client-side UI threads, action menus,
//              and local helper functions. Executed dynamically via init.sqf.
// ============================================================================

if (!hasInterface) exitWith {};

// ---------------------------------------------------------------------------
// 1. CLIENT HELPER FUNCTIONS
// ---------------------------------------------------------------------------

QM_fnc_getNearbyAmmoSource = {
    params ["_veh"];
    if (isNull _veh) exitWith {""};
    private _foundBase = "";

    private _triggers = allMissionObjects "EmptyDetector";
    {
        private _tName = vehicleVarName _x;
        if (["_service", _tName] call BIS_fnc_inString) then {
            if (_veh inArea _x || _veh distance2D _x < 40) then {
                private _idx = _tName find "_service";
                private _potBase = _tName select [0, _idx];
                if (["SB", _potBase] call BIS_fnc_inString) then { _foundBase = _potBase; };
            };
        };
        if (_foundBase != "") exitWith {};
    } forEach _triggers;

    if (_foundBase != "") exitWith { _foundBase };

    private _nearEnts = nearestObjects [_veh, ["AllVehicles","ReammoBox_F","ThingX","Building"], 40];
    {
        private _varName = vehicleVarName _x;
        if (["_ammo", _varName] call BIS_fnc_inString) then {
            private _idx = _varName find "_ammo";
            private _potBase = _varName select [0, _idx];
            if (["SB", _potBase] call BIS_fnc_inString) then { _foundBase = _potBase; };
        };
        if (_foundBase != "") exitWith {};
    } forEach _nearEnts;

    _foundBase
};

QM_fnc_canOpenPylonMenu = {
    params ["_unit"];
    private _veh = if (vehicle _unit != _unit) then { vehicle _unit } else { cursorTarget };
    if (isNull _veh || {!(_veh isKindOf "Air")} || {speed _veh > 1} || {(_unit distance _veh > 12)}) exitWith {false};
    private _base = [_veh] call QM_fnc_getNearbyAmmoSource;
    if (_base == "") exitWith {false};
    (missionNamespace getVariable [format["LogiScore_%1_Ammo", _base], 0] > 0)
};

QM_fnc_addPylonAction = {
    params ["_unit"];
    _unit addAction [
        "<t color='#00FFFF'>[ Open Aircraft Pylon Manager ]</t>",
        {
            params ["_target","_caller","_actionId","_arguments"];
            private _veh = if (vehicle _caller != _caller) then { vehicle _caller } else { cursorTarget };
            private _baseKey = [_veh] call QM_fnc_getNearbyAmmoSource;
            [_veh, _baseKey] spawn QM_fnc_pylonManager;
        },
        nil, 1.5, false, true, "",
        "[_this] call QM_fnc_canOpenPylonMenu"
    ];
};

// ---------------------------------------------------------------------------
// 2. CLIENT DAEMONS (BACKGROUND THREADS)
// ---------------------------------------------------------------------------

// --- A. Pylon Manager Initialization ---
[] spawn {
    waitUntil { !isNull player };
    [player] call QM_fnc_addPylonAction;
    player addEventHandler ["Respawn", { [(_this select 0)] call QM_fnc_addPylonAction; }];
};

// --- B. JIP Safe Pipeline For Action Menus ---
// Safely adds actions to terminals once they locally exist for the player.
[] spawn {
    private _processedHubs = [];
    while {true} do {
        private _globalHubs = missionNamespace getVariable ["QM_Global_Terminals", []];
        {
            private _hub = _x;
            if (!isNull _hub && !(_hub in _processedHubs)) then {
                private _baseKey = _hub getVariable ["QM_Crate_OwningBase", ""];
                if (_baseKey != "") then {
                    if (!isNil "QM_fnc_clientRegisterTraderActions") then { [_hub, _baseKey] call QM_fnc_clientRegisterTraderActions; };
                    if (!isNil "QM_fnc_clientRegisterFlagActions") then { [_hub, _baseKey] call QM_fnc_clientRegisterFlagActions; };
                    if (!isNil "QM_fnc_clientRegisterBarracksActions") then { [_hub, _baseKey] call QM_fnc_clientRegisterBarracksActions; };
                    _processedHubs pushBack _hub;
                };
            };
        } forEach _globalHubs;
        uiSleep 3;
    };
};

// --- C. Client-Side Base Manifest Ledger (Diary UI) ---
player createDiarySubject ["BasesManifestTab", "Base Supply Manifest"];

[] spawn {
    private _diaryHandlesMap = createHashMap;
    {
        private _recordHandle = player createDiaryRecord ["BasesManifestTab", [_x, "Synchronizing UI layers..."]];
        _diaryHandlesMap set [_x, _recordHandle];
    } forEach logisticsBases;

    while {true} do {
        {
            private _base = _x;
            private _cPoints = missionNamespace getVariable [format["LogiScore_%1_Cargo", _base], 0];
            private _aPoints = missionNamespace getVariable [format["LogiScore_%1_Ammo", _base], 0];
            private _fPoints = missionNamespace getVariable [format["LogiScore_%1_Fuel", _base], 0];
            private _mPoints = missionNamespace getVariable [format["LogiScore_%1_Medical", _base], 0];
            private _rPoints = missionNamespace getVariable [format["LogiScore_%1_Repair", _base], 0];
            private _vPoints = missionNamespace getVariable [format["LogiScore_%1_Vehicle", _base], 0];
            private _tPoints = missionNamespace getVariable [format["LogiScore_%1_Troops", _base], 0];

            private _reportText = format ["<br/><font color='#00FFFF' size='16'>%1 Supply Manifest Ledger</font><br/><br/>  [Cargo Pool]: <font color='#FFFF00'>%2</font> Points<br/>  [Ammo Pool]: <font color='#FFFF00'>%3</font> Resources<br/>  [Fuel Pool]: <font color='#FFFF00'>%4</font> Liters<br/>  [Medical Pool]: <font color='#FFFF00'>%5</font> Supplies<br/>  [Repair Pool]: <font color='#FFFF00'>%6</font> Kits<br/>  [Vehicle Pool]: <font color='#FFFF00'>%7</font> Material<br/>  [Troops Pool]: <font color='#FFFF00'>%8</font> Personnel<br/>", _base, _cPoints, _aPoints, _fPoints, _mPoints, _rPoints, _vPoints, _tPoints];

            private _activeHandle = _diaryHandlesMap get _base;
            if (!isNil "_activeHandle") then {
                player setDiaryRecordText [["BasesManifestTab", _activeHandle], [_base, _reportText]];
            };
        } forEach logisticsBases;
        uiSleep 4;
    };
};