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

// =========================================================================
// GLOBAL STRING FORMATTER: FULL LENGTH VALUES, COMMAS & SCALE NOTATION
// Handles numbers from 0 up to 100+ Trillion without scientific notation
// =========================================================================
logi_fnc_formatPoints = {
    private _num = 0;
    private _includeScale = true;
    if (_this isEqualType []) then {
        _num = _this param [0, 0];
        _includeScale = _this param [1, true];
    } else {
        _num = _this;
    };

    if (_num isEqualType "") then {
        if (_num == "-1" || _num == "UNLIMITED") exitWith { "UNLIMITED" };
        _num = parseNumber _num;
    };

    if (_num == -1) exitWith { "UNLIMITED" };
    if (_num == 0) exitWith { "0" };

    private _isNeg = (_num < 0);
    private _integer = floor (abs _num);
    private _str = str _integer;

    // Expand scientific notation if present (e.g. "1.6e+006", "1.6e+06", "1e+014")
    private _eIdx = _str find "e";
    if (_eIdx == -1) then { _eIdx = _str find "E"; };

    if (_eIdx != -1) then {
        private _sig = _str select [0, _eIdx];
        private _expStr = _str select [_eIdx + 1];
        private _exp = parseNumber _expStr;

        private _dotIdx = _sig find ".";
        if (_dotIdx == -1) then {
            for "_i" from 1 to _exp do { _sig = _sig + "0"; };
            _str = _sig;
        } else {
            private _intPart = _sig select [0, _dotIdx];
            private _decPart = _sig select [_dotIdx + 1];
            private _decLen = count _decPart;

            if (_exp >= _decLen) then {
                private _zeroCount = _exp - _decLen;
                private _combined = _intPart + _decPart;
                for "_i" from 1 to _zeroCount do { _combined = _combined + "0"; };
                _str = _combined;
            } else {
                private _shiftedInt = _intPart + (_decPart select [0, _exp]);
                _str = _shiftedInt;
            };
        };
    };

    // Strip any trailing decimal residue if present
    private _finalDot = _str find ".";
    if (_finalDot != -1) then {
        _str = _str select [0, _finalDot];
    };

    // Determine value range scale descriptor
    private _digitCount = count _str;
    private _scaleTag = "";
    if (_includeScale) then {
        if (_digitCount >= 19) then {
            _scaleTag = " (Quintillions)";
        } else {
            if (_digitCount >= 16) then {
                _scaleTag = " (Quadrillions)";
            } else {
                if (_digitCount >= 13) then {
                    _scaleTag = " (Trillions)";
                } else {
                    if (_digitCount >= 10) then {
                        _scaleTag = " (Billions)";
                    } else {
                        if (_digitCount >= 7) then {
                            _scaleTag = " (Millions)";
                        } else {
                            if (_digitCount >= 4) then {
                                _scaleTag = " (Thousands)";
                            };
                        };
                    };
                };
            };
        };
    };

    // Insert thousands commas from right to left
    private _arr = _str splitString "";
    private _res = "";
    private _cnt = 0;
    for "_i" from (_digitCount - 1) to 0 step -1 do {
        if (_cnt > 0 && (_cnt % 3 == 0)) then { _res = "," + _res; };
        _res = (_arr # _i) + _res;
        _cnt = _cnt + 1;
    };

    if (_isNeg) then { _res = "-" + _res; };
    _res + _scaleTag
};

QM_fnc_getNearbyAmmoSource = {
    params ["_veh"];
    if (isNull _veh) exitWith {""};
    private _foundBase = "";

    private _triggers = allMissionObjects "EmptyDetector";
    {
        private _tName = vehicleVarName _x;
        private _tLower = toLowerANSI _tName;
        private _idx = _tLower find "_service";
        if (_idx != -1) then {
            if (_veh inArea _x || _veh distance2D _x < 40) then {
                private _potBase = _tName select [0, _idx];
                if (_potBase in logisticsBases || { ["SB", _potBase] call BIS_fnc_inString } || { ["FOB", _potBase] call BIS_fnc_inString } || { ["MSR", _potBase] call BIS_fnc_inString }) then {
                    _foundBase = _potBase;
                };
            };
        };
        if (_foundBase != "") exitWith {};
    } forEach _triggers;

    if (_foundBase != "") exitWith { _foundBase };

    private _nearEnts = nearestObjects [_veh, ["AllVehicles","ReammoBox_F","ThingX","Building"], 40];
    {
        private _varName = vehicleVarName _x;
        private _vLower = toLowerANSI _varName;
        private _idx = _vLower find "_ammo";
        if (_idx != -1) then {
            private _potBase = _varName select [0, _idx];
            if (_potBase in logisticsBases || { ["SB", _potBase] call BIS_fnc_inString } || { ["FOB", _potBase] call BIS_fnc_inString } || { ["MSR", _potBase] call BIS_fnc_inString }) then {
                _foundBase = _potBase;
            };
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
    private _ammoPool = missionNamespace getVariable [format["LogiScore_%1_Ammo", _base], 0];
    (_ammoPool > 0 || _ammoPool == -1)
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
        private _cleanBase = (_x splitString "_") joinString " ";
        private _recordHandle = player createDiaryRecord ["BasesManifestTab", [_cleanBase, "Synchronizing UI layers..."]];
        _diaryHandlesMap set [_x, _recordHandle];
    } forEach logisticsBases;

    while {true} do {
        {
            private _base = _x;
            private _cleanBase = (_base splitString "_") joinString " ";
            private _cPoints = missionNamespace getVariable [format["LogiScore_%1_Cargo", _base], 0];
            private _aPoints = missionNamespace getVariable [format["LogiScore_%1_Ammo", _base], 0];
            private _fPoints = missionNamespace getVariable [format["LogiScore_%1_Fuel", _base], 0];
            private _mPoints = missionNamespace getVariable [format["LogiScore_%1_Medical", _base], 0];
            private _rPoints = missionNamespace getVariable [format["LogiScore_%1_Repair", _base], 0];
            private _vPoints = missionNamespace getVariable [format["LogiScore_%1_Vehicle", _base], 0];
            private _tPoints = missionNamespace getVariable [format["LogiScore_%1_Troops", _base], 0];

            private _cStr = [_cPoints] call logi_fnc_formatPoints;
            private _aStr = [_aPoints] call logi_fnc_formatPoints;
            private _fStr = [_fPoints] call logi_fnc_formatPoints;
            private _mStr = [_mPoints] call logi_fnc_formatPoints;
            private _rStr = [_rPoints] call logi_fnc_formatPoints;
            private _vStr = [_vPoints] call logi_fnc_formatPoints;
            private _tStr = [_tPoints] call logi_fnc_formatPoints;

            private _reportText = format [
                "<br/><font color='#00FFFF' size='16'>%1 Supply Manifest Ledger</font><br/><br/>  [Cargo Pool]: <font color='#FFFF00'>%2</font> Points<br/>  [Ammo Pool]: <font color='#FFFF00'>%3</font> Resources<br/>  [Fuel Pool]: <font color='#FFFF00'>%4</font> Liters<br/>  [Medical Pool]: <font color='#FFFF00'>%5</font> Supplies<br/>  [Repair Pool]: <font color='#FFFF00'>%6</font> Kits<br/>  [Vehicle Pool]: <font color='#FFFF00'>%7</font> Material<br/>  [Troops Pool]: <font color='#FFFF00'>%8</font> Personnel<br/>", 
                _cleanBase, _cStr, _aStr, _fStr, _mStr, _rStr, _vStr, _tStr
            ];

            private _activeHandle = _diaryHandlesMap get _base;
            if (!isNil "_activeHandle") then {
                player setDiaryRecordText [["BasesManifestTab", _activeHandle], [_cleanBase, _reportText]];
            };
        } forEach logisticsBases;
        uiSleep 4;
    };
};

// =========================================================================
// HELPER: DETECT IF VEHICLE IS INSIDE ANY BASE DROPOFF ZONE
// Returns: BaseKey (String) or "" if outside dropoff zones
// =========================================================================
QM_fnc_getVehicleDropoffBase = {
    params [["_vehicle", objNull]];
    if (isNull _vehicle || !alive _vehicle) exitWith { "" };

    private _allBases = missionNamespace getVariable ["logisticsBases", []];
    private _foundBase = "";

    {
        private _bKey = _x;
        private _trigList = missionNamespace getVariable [format ["LogiDropoffTriggers_%1", _bKey], []];
        if ({ _vehicle inArea _x } count _trigList > 0) exitWith {
            _foundBase = _bKey;
        };
    } forEach _allBases;

    _foundBase
};

// =========================================================================
// DROPOFF ZONE VEHICLE SALVAGE CONTROLLER
// Automatically prompts players upon disembarking an unoccupied vehicle
// in a base dropoff zone to confirm recycling/salvage for resources.
// Also registers a context action on the player to salvage unoccupied
// vehicles parked inside any base dropoff zone.
// =========================================================================
QM_fnc_initDropoffSalvageListener = {
    if (!hasInterface) exitWith {};

    // 1. Disembark Watchdog: Prompts the last player to exit an unoccupied vehicle in a dropoff pad
    player addEventHandler ["GetOutMan", {
        params ["_unit", "_role", "_vehicle", "_turret"];
        if (isNull _vehicle || !alive _vehicle) exitWith {};
        if !(_vehicle isKindOf "LandVehicle" || _vehicle isKindOf "Air" || _vehicle isKindOf "Ship") exitWith {};

        private _baseKey = [_vehicle] call QM_fnc_getVehicleDropoffBase;
        if (_baseKey == "") exitWith {};

        [_vehicle, _baseKey, _unit] spawn {
            params ["_veh", "_bKey", "_playerUnit"];
            sleep 0.5;
            if (!alive _veh || !alive _playerUnit) exitWith {};

            // Check if any human players are still inside the vehicle
            if ({ isPlayer _x } count (crew _veh) > 0) exitWith {};

            // Prevent spamming if already prompting
            if (_veh getVariable ["QM_SalvagePromptActive", false]) exitWith {};
            _veh setVariable ["QM_SalvagePromptActive", true];

            private _class = typeOf _veh;
            private _displayName = getText (configFile >> "CfgVehicles" >> _class >> "displayName");
            private _cleanBase = _bKey splitString "_" joinString " ";

            private _prompt = format [
                "You have parked a %1 in the %2 Delivery / Return Zone.<br/><br/>Would you like to SALVAGE this vehicle and recycle its resources back to %2?",
                _displayName, _cleanBase
            ];

            private _confirmed = [_prompt, "VEHICLE SALVAGE CONFIRMATION", "YES (SALVAGE)", "NO (KEEP VEHICLE)"] call BIS_fnc_guiMessage;
            
            if (_confirmed && alive _veh && { { isPlayer _x } count (crew _veh) == 0 }) then {
                [_bKey, _veh, _playerUnit] remoteExec ["QM_fnc_serverVehicleSale", 2];
            } else {
                systemChat format ["[SALVAGE CONTROL]: %1 kept active. Parked in %2.", _displayName, _cleanBase];
                sleep 8;
                _veh setVariable ["QM_SalvagePromptActive", false];
            };
        };
    }];

    // 2. Direct Look-At Action on Player: For ad-hoc salvage of unoccupied vehicles in any dropoff zone
    player addAction [
        "<t color='#00FF88' font='RobotoCondensedBold'>[SALVAGE CONTROL] Recycle Vehicle to Base</t>",
        {
            params ["_target", "_caller", "_actionId", "_arguments"];
            private _veh = cursorObject;
            if (isNull _veh || !alive _veh) exitWith {};
            private _baseKey = [_veh] call QM_fnc_getVehicleDropoffBase;
            if (_baseKey == "") exitWith { hint "Vehicle is not inside a designated Dropoff Zone."; };
            
            [_veh, _baseKey, _caller] spawn {
                params ["_v", "_bKey", "_p"];
                if ({ isPlayer _x } count (crew _v) > 0) exitWith {
                    hint "Cannot salvage vehicle while human crew members are inside!";
                };
                private _displayName = getText (configFile >> "CfgVehicles" >> typeOf _v >> "displayName");
                private _cleanBase = _bKey splitString "_" joinString " ";
                private _prompt = format [
                    "Would you like to SALVAGE this %1 and recycle its resources back to %2?",
                    _displayName, _cleanBase
                ];
                private _confirmed = [_prompt, "VEHICLE SALVAGE CONFIRMATION", "YES (SALVAGE)", "NO (CANCEL)"] call BIS_fnc_guiMessage;
                if (_confirmed && alive _v && { { isPlayer _x } count (crew _v) == 0 }) then {
                    [_bKey, _v, _p] remoteExec ["QM_fnc_serverVehicleSale", 2];
                };
            };
        },
        [],
        1.5,
        false,
        true,
        "",
        "private _v = cursorObject; !isNull _v && {alive _v} && {player distance _v < 8} && {(_v isKindOf 'LandVehicle' || _v isKindOf 'Air' || _v isKindOf 'Ship')} && {!(_v isKindOf 'Man')} && {({isPlayer _x} count (crew _v)) == 0} && {([_v] call QM_fnc_getVehicleDropoffBase) != ''}",
        5
    ];
};

// Auto-initialize salvage listener
[] spawn {
    waitUntil { !isNull player && player == player };
    waitUntil { !isNil "logisticsBases" };
    call QM_fnc_initDropoffSalvageListener;
};