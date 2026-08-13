// ============================================================================
// TACTICAL COMMAND CENTER: CLIENT TASK MASTER (PART 6)
// File: tsk_clientTaskMaster.sqf
// Description: Client-side loop that reads the GIN Public Ledger and assigns
//              tasks dynamically based on the player's CURRENT vehicle and 
//              weapon capabilities (e.g., A/A, A/G, SEAD).
//              *NEW*: Evaluates live Infantry squad loadouts for AT/AA/Recon.
// Called By: init.sqf (Executed on Clients)
// ============================================================================

if (!hasInterface) exitWith {};
waitUntil { !isNull player };

diag_log "TACTICAL COMMAND CENTER: Initializing Combat Task Master...";

// ============================================================================
// FUNCTION: EVALUATE PLAYER CAPABILITIES
// Purpose: Scans the player's current vehicle and ordnance to determine 
//          which mission tags they are eligible to receive.
// ============================================================================
TSK_fnc_getLocalPlayerCaps = {
    private _veh = vehicle player;
    private _caps = [];
    
    // --- INFANTRY & SQUAD LOADOUT SCANNER ---
    if (_veh == player) then {
        _caps pushBack "INF";
        _caps pushBack "RECCE";
        
        private _hasRecon = false;
        private _hasAT = false;
        private _hasAA = false;
        
        // Loop through every living member of the player's current group
        {
            private _unit = _x;
            if (alive _unit) then {
                
                // 1. RECON CHECK: Binoculars, Rangefinders, Laser Designators, UAV Terminals
                if (binocular _unit != "") then { _hasRecon = true; };
                if (({_x find "UavTerminal" != -1} count (assignedItems _unit)) > 0) then { _hasRecon = true; };

                // 2. ANTI-ARMOR / ANTI-AIR CHECK: Scan launchers and their loaded/carried magazines
                if (secondaryWeapon _unit != "") then {
                    {
                        private _ammoClass = getText (configFile >> "CfgMagazines" >> _x >> "ammo");
                        private _sim = getText (configFile >> "CfgAmmo" >> _ammoClass >> "simulation");
                        private _airLock = getNumber (configFile >> "CfgAmmo" >> _ammoClass >> "airLock");
                        
                        // Check if the ammo is a rocket or missile
                        if (_sim == "shotMissile" || _sim == "shotRocket") then {
                            if (_airLock == 1) then { _hasAA = true; } else { _hasAT = true; };
                        };
                    } forEach (magazines _unit);
                };
            };
        } forEach (units group player);
        
        if (_hasRecon) then { _caps pushBack "RECON"; };
        if (_hasAT) then { _caps pushBack "ARM"; _caps pushBack "MECH"; };
        if (_hasAA) then { _caps pushBack "CAP"; _caps pushBack "INT"; };
        
    } else {
        // --- LOGISTICS GATEKEEPER ---
        // Prevents heavy logistics trucks from taking combat extractions, but still allows helicopters
        // to take CLT_AIR tasks while remaining eligible for CAS/CAP if they are armed.
        if (typeOf _veh in allowedLogisticsVehicles) then {
            if (_veh isKindOf "Air") then { 
                _caps pushBack "CLT_AIR"; 
            } else { 
                // Only light ground vehicles (like Prowlers) should be doing tactical CLT extraction
                if (getMass _veh < 15000) then { _caps pushBack "CLT_GROUND"; };
            };
        };

        // --- COMBAT VEHICLE SCANNER ---
        if (_veh isKindOf "Air") then {
            _caps pushBack "RECON"; 
            
            private _hasAA = false;
            private _hasAG = false;
            private _hasSEAD = false;
            
            // Check native Arma 3 airLock values for every equipped weapon
            {
                private _magClass = _x select 0;
                private _magUpper = toUpper _magClass;
                private _ammoClass = getText (configFile >> "CfgMagazines" >> _magClass >> "ammo");
                private _airLock = getNumber (configFile >> "CfgAmmo" >> _ammoClass >> "airLock");

                if ("HARM" in _magUpper || "KH58" in _magUpper) then { _hasSEAD = true; };
                if (_airLock == 1 || _airLock == 2) then { _hasAA = true; }; // 1 = Air Only, 2 = Both
                if (_airLock == 0 || _airLock == 2) then { _hasAG = true; }; // 0 = Ground Only
            } forEach (magazinesAllTurrets _veh);
            
            if (_hasSEAD) then { _caps pushBack "SEAD"; };
            if (_hasAG) then { _caps pushBack "CAS"; };
            if (_hasAA) then { _caps pushBack "CAP"; _caps pushBack "INT"; };
        };
        if (_veh isKindOf "Tank" || _veh isKindOf "Car") then {
            _caps pushBack "ARM";
            _caps pushBack "MECH";
        };
    };
    _caps
};

// ============================================================================
// MAIN TASK DISTRIBUTION LOOP
// ============================================================================
[] spawn {
    private _activeLocalTasks = []; 
    
    while {true} do {
        private _publicLedger = missionNamespace getVariable ["TSK_GIN_Public_Ledger", []];
        private _myCaps = [] call TSK_fnc_getLocalPlayerCaps;
        private _validTaskIDsThisTick = [];
        
        {
            // Safely extracts the new Dropoff Grid Parameter (Default: Empty)
            _x params ["_intelID", "_obj", "_pos", "_tags", "_category", ["_dropoffPos", []]];
            
            // Check if any of the target's tags match my current capabilities
            private _isMatch = false;
            { if (_x in _myCaps) exitWith { _isMatch = true; }; } forEach _tags;
            
            if (_isMatch) then {
                _validTaskIDsThisTick pushBack _intelID;
                
                if (!([_intelID] call BIS_fnc_taskExists)) then {
                    // Format the Task UI based on the category
                    private _taskTitle = "Tactical Objective";
                    private _taskDesc = "Neutralize the target.";
                    private _taskType = "attack";
                    
                    switch (_category) do {
                        case "RADAR": { _taskTitle = "SEAD: Destroy Air Defense"; _taskDesc = "Active radar signature detected. Employ Anti-Radiation weapons."; _taskType = "destroy"; };
                        case "ARMOR": { _taskTitle = "CAS: Destroy Armor"; _taskDesc = "Hostile armored elements spotted. Clear the area."; _taskType = "destroy"; };
                        case "AIR": { _taskTitle = "INTERCEPT: Hostile Aircraft"; _taskDesc = "Enemy air asset in AO. Intercept and destroy."; _taskType = "plane"; };
                        case "INFANTRY": { _taskTitle = "RECCE: Sweep Infantry"; _taskDesc = "Hostile infantry detected. Sweep and clear."; _taskType = "kill"; };
                        case "TRANSPORT_REQ": { 
                            _taskTitle = "LOGI: Combat Transport (LZ)"; 
                            _taskDesc = "Friendly assets requesting immediate airlift/transport.";
                            
                            // Unpack the DO marker coordinates and push them clearly onto the map UI
                            if (count _dropoffPos > 0) then {
                                _taskDesc = _taskDesc + format ["<br/><br/>Requested Dropoff Grid: <font color='#00FF00'>%1</font>", mapGridPosition _dropoffPos];
                            };
                            _taskType = "pickup"; 
                        };
                    };
                    
                    // Assign task locally to the player
                    [player, _intelID, [_taskDesc, _taskTitle, ""], _pos, "CREATED", -1, false, _taskType, false] call BIS_fnc_taskCreate;
                } else {
                    // Update the map marker position dynamically if the target is a moving vehicle
                    if (!isNull _obj) then {
                        [_intelID, getPos _obj] call BIS_fnc_taskSetDestination;
                    };
                };
            };
        } forEach _publicLedger;
        
        // --- CLEANUP PROCESS ---
        // Remove tasks the player is no longer qualified for, or that were destroyed
        private _tasksToDelete = [];
        {
            private _trackedTaskID = _x;
            if (!(_trackedTaskID in _validTaskIDsThisTick)) then {
                
                // Check if it's gone from the ledger entirely (meaning someone blew it up)
                private _existsInLedger = false;
                { if ((_x select 0) == _trackedTaskID) exitWith { _existsInLedger = true; }; } forEach _publicLedger;
                
                if (!_existsInLedger) then {
                    // Target destroyed! Flash "SUCCEEDED" before deleting
                    [_trackedTaskID, "SUCCEEDED", true] call BIS_fnc_taskSetState;
                    [_trackedTaskID] spawn { sleep 5; [_this select 0] call BIS_fnc_deleteTask; };
                } else {
                    // Target is still alive, but player changed roles (e.g., jumped out of Jet)
                    [_trackedTaskID] call BIS_fnc_deleteTask;
                };
            };
        } forEach _activeLocalTasks;
        
        _activeLocalTasks = _validTaskIDsThisTick;
        
        uiSleep 5; // Sync every 5 seconds
    };
};