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
                if (toUpper _potBase != "MSR" && { _potBase in logisticsBases || { ["SB", _potBase] call BIS_fnc_inString } || { ["FOB", _potBase] call BIS_fnc_inString } }) then {
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
            if (toUpper _potBase != "MSR" && { _potBase in logisticsBases || { ["SB", _potBase] call BIS_fnc_inString } || { ["FOB", _potBase] call BIS_fnc_inString } }) then {
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
// Safely adds actions to terminals and medical facilities once they locally exist for the player.
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

        private _globalMeds = missionNamespace getVariable ["QM_Global_MedicalFacilities", []];
        {
            private _medHub = _x;
            if (!isNull _medHub && !(_medHub in _processedHubs)) then {
                private _baseKey = _medHub getVariable ["QM_Crate_OwningBase", ""];
                if (_baseKey != "") then {
                    if (!isNil "QM_fnc_clientRegisterMedicalActions") then { [_medHub, _baseKey] call QM_fnc_clientRegisterMedicalActions; };
                    _processedHubs pushBack _medHub;
                };
            };
        } forEach _globalMeds;

        uiSleep 3;
    };
};

// --- C. Client-Side Universal Base Supply Manifest Ledger (Diary & Map Tasks) ---
// Accessible by ALL players (infantry, armor, pilots, logistics) regardless of role.
// Provides both a dedicated Map Diary subject and an informational Map Task (with no 3D waypoints).

QM_fnc_initBaseSupplyLedger = {
    if (!hasInterface) exitWith {};

    // 1. Ensure player unit and base database are fully available
    if (isNull player || !alive player) exitWith {};
    if (isNil "logisticsBases" || { count logisticsBases == 0 }) exitWith {};

    // 2. Initialize Map Diary Subject
    if !(player diarySubjectExists "BasesManifestTab") then {
        player createDiarySubject ["BasesManifestTab", "Base Supply Manifest"];
    };

    // Master Theater Overview Record
    private _overviewHandle = player createDiaryRecord ["BasesManifestTab", ["0. Theater Overview (All Bases)", "Synchronizing base ledger..."]];

    // Individual Base Records
    private _diaryHandlesMap = createHashMap;
    _diaryHandlesMap set ["__OVERVIEW__", _overviewHandle];

    {
        private _cleanBase = (_x splitString "_") joinString " ";
        private _recordHandle = player createDiaryRecord ["BasesManifestTab", [_cleanBase, "Synchronizing base data..."]];
        _diaryHandlesMap set [_x, _recordHandle];
    } forEach logisticsBases;

    // 3. Initialize Global Informational Map Task (No 3D Waypoint, Never Overrides Current Route)
    if !(["Logi_Base_Ledger_Task"] call BIS_fnc_taskExists) then {
        [
            player, 
            "Logi_Base_Ledger_Task", 
            ["Synchronizing theater base supply ledger...", "Base Supply Ledger [Theater Overview]", ""], 
            objNull, 
            "CREATED", 
            -1, 
            false, 
            "whiteboard", 
            false
        ] call BIS_fnc_taskCreate;
    };

    // 4. Terminate any previous updater thread on this client to prevent duplicate loops
    private _existingThread = player getVariable ["QM_BaseSupplyLedgerThread", scriptNull];
    if (!isNull _existingThread) then { terminate _existingThread; };

    // 5. Spawn Live Background Updater Daemon
    private _thread = [_diaryHandlesMap] spawn {
        params ["_diaryMap"];

        while { alive player } do {
            private _allSBs = logisticsBases select { "SB" in toUpper _x };
            private _allFOBs = logisticsBases select { "FOB" in toUpper _x };
            private _allOthers = logisticsBases select { !("SB" in toUpper _x) && !("FOB" in toUpper _x) };

            // --- A. COMPILE THEATER MASTER OVERVIEW REPORT ---
            private _masterText = "<br/><font color='#00FFFF' size='16'>THEATER BASE SUPPLY MANIFEST</font><br/>";
            _masterText = _masterText + "<font color='#999999'>Real-time logistics inventory across all bases in theater.</font><br/><br/>";

            if (count _allSBs > 0) then {
                _masterText = _masterText + "<font color='#00d0ff' size='14'>=== STAGING BASES (REAR RESERVES) ===</font><br/>";
                {
                    private _base = _x;
                    private _cleanName = (_base splitString "_") joinString " ";
                    _masterText = _masterText + format ["<br/><font color='#ffffff' size='13'>■ %1</font><br/>", _cleanName];
                    {
                        private _cat = _x;
                        private _pts = missionNamespace getVariable [format ["LogiScore_%1_%2", _base, _cat], 0];
                        private _ptsStr = [_pts] call logi_fnc_formatPoints;
                        private _col = if (_pts == -1) then { "#00ff88" } else { if (_pts < 500) then { "#ff4444" } else { "#ffcc00" } };
                        _masterText = _masterText + format ["  <font color='#aaaaaa'>%1:</font> <font color='%2'>%3</font><br/>", _cat, _col, _ptsStr];
                    } forEach ["Cargo", "Ammo", "Fuel", "Medical", "Repair", "Vehicle", "Troops"];
                    _masterText = _masterText + "<font color='#444444'>----------------------------------------</font><br/>";
                } forEach _allSBs;
            };

            if (count _allFOBs > 0) then {
                _masterText = _masterText + "<br/><font color='#00ff88' size='14'>=== FORWARD OPERATING BASES (FRONT-LINE) ===</font><br/>";
                {
                    private _base = _x;
                    private _cleanName = (_base splitString "_") joinString " ";
                    _masterText = _masterText + format ["<br/><font color='#ffffff' size='13'>■ %1</font><br/>", _cleanName];
                    {
                        private _cat = _x;
                        private _pts = missionNamespace getVariable [format ["LogiScore_%1_%2", _base, _cat], 0];
                        private _ptsStr = [_pts] call logi_fnc_formatPoints;
                        private _col = if (_pts == -1) then { "#00ff88" } else { if (_pts < 300) then { "#ff4444" } else { "#ffcc00" } };
                        _masterText = _masterText + format ["  <font color='#aaaaaa'>%1:</font> <font color='%2'>%3</font><br/>", _cat, _col, _ptsStr];
                    } forEach ["Cargo", "Ammo", "Fuel", "Medical", "Repair", "Vehicle", "Troops"];
                    _masterText = _masterText + "<font color='#444444'>----------------------------------------</font><br/>";
                } forEach _allFOBs;
            };

            if (count _allOthers > 0) then {
                _masterText = _masterText + "<br/><font color='#ffbb00' size='14'>=== MAIN SUPPLY ROUTE & SPECIAL HUBS ===</font><br/>";
                {
                    private _base = _x;
                    private _cleanName = (_base splitString "_") joinString " ";
                    _masterText = _masterText + format ["<br/><font color='#ffffff' size='13'>■ %1</font><br/>", _cleanName];
                    {
                        private _cat = _x;
                        private _pts = missionNamespace getVariable [format ["LogiScore_%1_%2", _base, _cat], 0];
                        private _ptsStr = [_pts] call logi_fnc_formatPoints;
                        _masterText = _masterText + format ["  <font color='#aaaaaa'>%1:</font> <font color='#00ff88'>%2</font><br/>", _cat, _ptsStr];
                    } forEach ["Cargo", "Ammo", "Fuel", "Medical", "Repair", "Vehicle", "Troops"];
                    _masterText = _masterText + "<font color='#444444'>----------------------------------------</font><br/>";
                } forEach _allOthers;
            };

            // Update Master Overview Diary Record
            private _ovHandle = _diaryMap get "__OVERVIEW__";
            if (!isNil "_ovHandle") then {
                player setDiaryRecordText [["BasesManifestTab", _ovHandle], ["0. Theater Overview (All Bases)", _masterText]];
            };

            // Update Global Read-Only Informational Task Description
            if (["Logi_Base_Ledger_Task"] call BIS_fnc_taskExists) then {
                private _ledgerTask = ["Logi_Base_Ledger_Task", player] call BIS_fnc_taskReal;
                if (!isNull _ledgerTask) then {
                    _ledgerTask setSimpleTaskDescription [_masterText, "Base Supply Ledger [Theater Overview]", ""];
                };
            };

            // --- B. UPDATE INDIVIDUAL BASE DIARY ENTRIES ---
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

                private _activeHandle = _diaryMap get _base;
                if (!isNil "_activeHandle") then {
                    player setDiaryRecordText [["BasesManifestTab", _activeHandle], [_cleanBase, _reportText]];
                };
            } forEach logisticsBases;

            uiSleep 4;
        };
    };

    player setVariable ["QM_BaseSupplyLedgerThread", _thread];
};

// Lifecycle daemon: guarantees Base Supply Ledger persistence across all respawns and JIP
[] spawn {
    while { true } do {
        waitUntil { !isNull player && alive player };
        waitUntil { !isNil "logisticsBases" && { count logisticsBases > 0 } };
        [] call QM_fnc_initBaseSupplyLedger;
        waitUntil { !alive player };
        waitUntil { alive player };
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
// Automatically prompts players upon disembarking a vehicle they were driving
// in a base dropoff zone to confirm recycling/salvage for resources.
// Delivered vehicles (sling-loaded, ViV unloaded, or logistics cargo) bypass
// prompts and auto-despawn directly to eliminate pilot interruption.
// Also registers a context look-at action on the player to salvage unoccupied
// vehicles parked inside any base dropoff zone.
// =========================================================================
QM_fnc_initDropoffSalvageListener = {
    if (!hasInterface) exitWith {};

    // 1. Driver Detection: Track when a player enters a vehicle as driver
    player addEventHandler ["GetInMan", {
        params ["_unit", "_role", "_vehicle", "_turret"];
        if (isNull _vehicle || !alive _vehicle) exitWith {};
        if (_role == "driver") then {
            _vehicle setVariable ["QM_DrivenByPlayer", true, true];
            _vehicle setVariable ["QM_LastDriver", _unit, true];
        };
    }];

    // 2. Disembark Watchdog: Prompts the last player exiting a vehicle they were DRIVING in a dropoff pad
    player addEventHandler ["GetOutMan", {
        params ["_unit", "_role", "_vehicle", "_turret"];
        if (isNull _vehicle || !alive _vehicle) exitWith {};
        if !(_vehicle isKindOf "LandVehicle" || _vehicle isKindOf "Air" || _vehicle isKindOf "Ship") exitWith {};

        private _baseKey = [_vehicle] call QM_fnc_getVehicleDropoffBase;
        if (_baseKey == "") exitWith {};

        // Delivered vehicles (slingload, ViV cargo, logistics spawns) never show disembark prompts
        if (
            _vehicle getVariable ["QM_WasSlingLoaded", false] ||
            _vehicle getVariable ["QM_DroppedFromSling", false] ||
            _vehicle getVariable ["QM_UnloadedFromViV", false] ||
            _vehicle getVariable ["isLogisticsCargo", false] ||
            _vehicle getVariable ["QM_SystemLoaded", false]
        ) exitWith {};

        // The ONLY time the salvage option pops up is when it was a vehicle driven by players
        if !(_vehicle getVariable ["QM_DrivenByPlayer", false]) exitWith {};

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
                _veh setVariable ["QM_PlayerDeclinedSalvage", true, true];
                sleep 8;
                _veh setVariable ["QM_SalvagePromptActive", false];
            };
        };
    }];

    // 3. Direct Look-At Action on Player: For ad-hoc salvage of unoccupied vehicles in any dropoff zone
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

// Auto-initialize salvage listener with persistent respawn support
[] spawn {
    waitUntil { !isNull player && player == player };
    waitUntil { !isNil "logisticsBases" };
    call QM_fnc_initDropoffSalvageListener;
    player addEventHandler ["Respawn", {
        call QM_fnc_initDropoffSalvageListener;
    }];
};