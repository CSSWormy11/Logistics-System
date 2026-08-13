// ============================================================================
// LOGISTICS SYSTEM: DYNAMIC PYLON INTERFACE LOGIC (PART 3)
// File: fn_pylonManager.sqf
// Description: Custom Dynamic Aircraft Pylon Weapon Allocation. Ties exact 
//              weight of the ordnance to the base's Ammo supply pool.
// Called By: init.sqf (Action Menu attached to Aircraft)
// ============================================================================

params [
    ["_veh", objNull, [objNull]],
    ["_baseKey", "", [""]]
];

if (isNull _veh || _baseKey == "") exitWith { systemChat "R4-C PYLON ERROR: Invalid connection parameters."; };

createDialog "QM_PylonDialog";
waitUntil { !isNull findDisplay 8000 };
private _display = findDisplay 8000;

uiNamespace setVariable ["QM_Pylon_ActiveVeh", _veh];
uiNamespace setVariable ["QM_Pylon_BaseKey", _baseKey];

// ============================================================================
// 1. SAFETY MONITOR: CLOSE MENU IF AIRCRAFT MOVES
// ============================================================================
[_veh, _display] spawn {
    params ["_veh", "_display"];
    while { !isNull _display } do {
        if (speed _veh > 1) exitWith {
            _display closeDisplay 1;
            systemChat "R4-C PYLON WARNING: Aircraft in motion. Ground safety protocols engaged. Manifest closed.";
        };
        uiSleep 0.5;
    };
};

// ============================================================================
// 2. WEIGHT OVERRIDE DICTIONARY & HELPER FUNCTION
// Fixes broken Arma 3 configs. Enter the Classname and your desired Weight in KG.
// ============================================================================
private _weightOverrides = createHashMapFromArray [
    // --- BOMBS ---
    ["PylonMissile_1Rnd_Bomb_04_F", 226],           // GBU-12 (500lb)
    ["PylonMissile_Bomb_GBU12_x1", 226],            // GBU-12 LGB x1
    ["magazine_Bomb_GBU12_x1", 226],                // GBU-12 LGB x1
    ["PylonRack_Bomb_GBU12_x2", 452],               // GBU-12 LGB x2
    ["PylonMissile_1Rnd_Mk82_F", 226],              // Mk82 (500lb)
    ["PylonMissile_1Rnd_Bomb_03_F", 256],           // LOM-250G (565lb)
    ["PylonMissile_Bomb_KAB250_x1", 256],           // KAB 250 LGB x1
    ["magazine_Bomb_KAB250_x1", 256],               // KAB 250 LGB x1
    ["PylonMissile_1Rnd_BombCluster_01_F", 340],    // CBU-85 Cluster x1
    ["PylonRack_2Rnd_BombCluster_01_F", 680],       // CBU-85 Cluster x2
    ["PylonMissile_1Rnd_BombCluster_02_F", 498],    // RBK-500F Cluster x1
    ["PylonMissile_1Rnd_BombCluster_02_cap_F", 498],// RBK-500F Cluster x1
    ["PylonMissile_1Rnd_BombCluster_03_F", 263],    // BL778 Cluster x1
    ["PylonRack_2Rnd_BombCluster_03_F", 526],       // BL778 Cluster x2
    ["PylonRack_Bomb_SDB_x4", 453],                 // GBU SDB x4
    ["magazine_Bomb_SDB_x1", 113],                  // GBU SDB x1

    // --- AIR TO AIR (AA) MISSILES ---
    ["PylonMissile_Missile_BIM9X_x1", 85],          // AIM-9X
    ["PylonRack_Missile_BIM9X_x1", 85],             // BIM 9X AA x1
    ["PylonRack_Missile_BIM9X_x2", 170],            // BIM 9X AA x2
    ["magazine_Missile_BIM9X_x1", 85],              // BIM 9X AA x1
    ["PylonMissile_Missile_AMRAAM_D_INT_x1", 152],  // AMRAAM D
    ["PylonMissile_Missile_AMRAAM_D_x1", 152],      // AMRAAM D AA x1
    ["PylonRack_Missile_AMRAAM_D_x1", 152],         // AMRAAM D AA x1
    ["PylonRack_Missile_AMRAAM_D_x2", 304],         // AMRAAM D AA x2
    ["magazine_Missile_AMRAAM_D_x1", 152],          // AMRAAM D AA x1
    ["PylonMissile_Missile_AMRAAM_C_x1", 152],      // AMRAAM C AA x1
    ["PylonRack_Missile_AMRAAM_C_x1", 152],         // AMRAAM C AA x1
    ["PylonRack_Missile_AMRAAM_C_x2", 304],         // AMRAAM C AA x2
    ["magazine_Missile_AMRAAM_C_x1", 152],          // AMRAAM C AA x1
    ["PylonRack_1Rnd_AAA_missiles", 88],            // ASRAAM
    ["PylonMissile_1Rnd_AAA_missiles", 88],         // ASRAAM
    ["PylonRack_1Rnd_GAA_missiles", 87],            // Zephyr (IRIS-T analogue)
    ["PylonMissile_1Rnd_GAA_missiles", 87],         // Zephyr
    ["PylonRack_1Rnd_Missile_AA_04_F", 112],        // Falchion-22 (MICA analogue)
    ["PylonMissile_1Rnd_Missile_AA_04_F", 112],     // Falchion-22
    ["PylonRack_1Rnd_Missile_AA_03_F", 150],        // Sahr-3 (Heavy AA)
    ["PylonMissile_1Rnd_Missile_AA_03_F", 150],     // Sahr-3
    ["PylonMissile_Missile_AA_R73_x1", 105],        // R73
    ["magazine_Missile_AA_R73_x1", 105],            // R73
    ["PylonMissile_Missile_AA_R77_x1", 175],        // R77
    ["PylonMissile_Missile_AA_R77_INT_x1", 175],    // R77
    ["magazine_Missile_AA_R77_x1", 175],            // R77

    // --- AIR TO GROUND (AG) MISSILES ---
    ["PylonRack_1Rnd_Missile_AGM_02_F", 230],       // Macer (Maverick)
    ["PylonRack_3Rnd_Missile_AGM_02_F", 690],       // Macer 3x
    ["PylonMissile_Missile_AGM_02_x1", 230],        // Macer II
    ["PylonMissile_Missile_AGM_02_x2", 460],        // Macer II x2
    ["PylonRack_Missile_AGM_02_x1", 230],           // Macer II
    ["PylonRack_Missile_AGM_02_x2", 460],           // Macer II x2
    ["magazine_Missile_AGM_02_x1", 230],            // Macer II
    ["PylonRack_1Rnd_Missile_AGM_01_F", 650],       // Sharur (Kh-29 analogue)
    ["PylonMissile_Missile_AGM_KH25_x1", 300],      // KH25
    ["PylonMissile_Missile_AGM_KH25_INT_x1", 300],  // KH25
    ["magazine_Missile_AGM_KH25_x1", 300],          // KH25
    ["PylonRack_1Rnd_LG_scalpel", 49],              // Scalpel (Hellfire)
    ["PylonMissile_1Rnd_LG_scalpel", 49],           // Scalpel
    ["PylonRack_3Rnd_LG_scalpel", 147],             // Scalpel 3x
    ["PylonRack_4Rnd_LG_scalpel", 196],             // Scalpel 4x
    ["PylonRack_12Rnd_PG_missiles", 192],           // DAGR (12x ~16kg ea)
    ["PylonMissile_Missile_HARM_x1", 361],          // HARM
    ["PylonRack_Missile_HARM_x1", 361],             // HARM
    ["PylonMissile_Missile_HARM_INT_x1", 361],      // HARM
    ["magazine_Missile_HARM_x1", 361],              // HARM
    ["PylonMissile_Missile_KH58_x1", 650],          // KH58
    ["PylonMissile_Missile_KH58_INT_x1", 650],      // KH58
    ["magazine_Missile_KH58_x1", 650],              // KH58
    ["4Rnd_LG_Jian", 200],                          // Jian
    ["PylonRack_1Rnd_Missile_Jian", 50],            // Jian

    // --- ROCKETS ---
    ["PylonRack_7Rnd_Rocket_04_HE_F", 100],         // Shrieker 7x
    ["PylonRack_7Rnd_Rocket_04_AP_F", 100],         // Shrieker 7x
    ["PylonRack_12Rnd_missiles", 120],              // DAR 12x
    ["PylonRack_20Rnd_Rocket_03_HE_F", 200],        // Tratnyr 20x
    ["PylonRack_20Rnd_Rocket_03_AP_F", 200],        // Tratnyr 20x
    ["PylonRack_19Rnd_Rocket_Skyfire", 200]         // Skyfire 19x
];
uiNamespace setVariable ["QM_Pylon_WeightDict", _weightOverrides];

// Centralized Weight fetcher to ensure UI and Ledger always use the same math
QM_fnc_getWeaponWeight = {
    params ["_magClass"];
    if (_magClass == "") exitWith { 0 }; // Empty pylon is 0 kg
    
    // 1. Check custom overrides first
    private _dict = uiNamespace getVariable ["QM_Pylon_WeightDict", createHashMap];
    private _overrideWeight = _dict getOrDefault [_magClass, 0];
    if (_overrideWeight > 0) exitWith { _overrideWeight }; // Ignore if 0
    
    // 2. Check native flight-model weight
    private _w = getNumber (configFile >> "CfgMagazines" >> _magClass >> "weight");
    
    // 3. Fallback to raw mass math if weight is broken/missing
    if (_w == 0) then { _w = round ((getNumber (configFile >> "CfgMagazines" >> _magClass >> "mass")) * 30); };
    _w
};

// ============================================================================
// 3. POPULATE THE PYLON DROPDOWN
// ============================================================================
private _ctrlPylons = _display displayCtrl 8100;
private _pylonInfo = getAllPylonsInfo _veh;

{
    _x params ["_pylonIndex", "_pylonName"];
    private _idx = _ctrlPylons lbAdd format ["Pylon %1: %2", _pylonIndex, _pylonName];
    _ctrlPylons lbSetValue [_idx, _pylonIndex];
} forEach _pylonInfo;

// ============================================================================
// 4. DROPDOWN SELECTION EVENT (Smart Filtering & UI Updates)
// ============================================================================
_ctrlPylons ctrlAddEventHandler ["LBSelChanged", {
    params ["_control", "_selectedIndex"];
    private _display = ctrlParent _control;
    private _veh = uiNamespace getVariable ["QM_Pylon_ActiveVeh", objNull];
    
    private _pylonIndex = _control lbValue _selectedIndex;

    // --- UPDATE CURRENTLY EQUIPPED TEXT ---
    private _currentPylons = getPylonMagazines _veh;
    private _currentMag = _currentPylons select (_pylonIndex - 1);
    private _currentMagName = if (_currentMag == "") then { "< EMPTY PYLON >" } else { getText (configFile >> "CfgMagazines" >> _currentMag >> "displayName") };
    (_display displayCtrl 8102) ctrlSetText _currentMagName;

    lbClear (_display displayCtrl 8201); 
    lbClear (_display displayCtrl 8202); 
    lbClear (_display displayCtrl 8203); 

    private _compatibleMags = _veh getCompatiblePylonMagazines _pylonIndex;
    
    {
        private _magClass = _x;
        private _magName = getText (configFile >> "CfgMagazines" >> _magClass >> "displayName");
        
        // Fetch weight safely through our new helper function
        private _weight = [_magClass] call QM_fnc_getWeaponWeight;
        
        // --- SMART STRING SCANNER ---
        private _category = "MISC"; 
        private _magNameUpper = toUpper _magName;
        private _magClassUpper = toUpper _magClass;
        
        if ("AA" in _magNameUpper || "AIR-TO-AIR" in _magNameUpper || "AMRAAM" in _magNameUpper || "BIM9X" in _magNameUpper || "SIDEWINDER" in _magNameUpper || "FALCON" in _magNameUpper || "AA" in _magClassUpper) then {
            _category = "AA";
        } else {
            if ("AG" in _magNameUpper || "AIR-TO-GROUND" in _magNameUpper || "BOMB" in _magNameUpper || "MISSILE" in _magNameUpper || "MAVERICK" in _magNameUpper || "SCALPEL" in _magNameUpper || "GBU" in _magNameUpper || "AGM" in _magClassUpper || "BOMB" in _magClassUpper || "ROCKET" in _magNameUpper) then {
                _category = "AG";
            };
        };

        private _targetCtrl = switch (_category) do {
            case "AA": { _display displayCtrl 8201 };
            case "AG": { _display displayCtrl 8202 };
            default { _display displayCtrl 8203 };
        };

        private _displayName = format ["%1 [%2 kg]", _magName, _weight];
        private _idx = _targetCtrl lbAdd _displayName;
        _targetCtrl lbSetData [_idx, _magClass]; 
        
    } forEach _compatibleMags;
    
    private _emptyIdx = (_display displayCtrl 8203) lbAdd "< EMPTY PYLON > [0 kg]";
    (_display displayCtrl 8203) lbSetData [_emptyIdx, ""];
}];

// ============================================================================
// 5. MUTUALLY EXCLUSIVE LISTBOXES
// ============================================================================
{
    private _listCtrl = _display displayCtrl _x;
    _listCtrl ctrlAddEventHandler ["LBSelChanged", {
        params ["_control", "_selectedIndex"];
        if (_selectedIndex == -1) exitWith {};

        private _display = ctrlParent _control;
        private _myIdc = ctrlIDC _control;
        
        {
            if (_x != _myIdc) then {
                private _otherCtrl = _display displayCtrl _x;
                if (lbCurSel _otherCtrl != -1) then { _otherCtrl lbSetCurSel -1; };
            };
        } forEach [8201, 8202, 8203];
    }];
} forEach [8201, 8202, 8203];

// ============================================================================
// 6. "APPLY" BUTTON LOGIC & OVERRIDE ECONOMY
// ============================================================================
private _btnApply = _display displayCtrl 8101;
_btnApply ctrlAddEventHandler ["ButtonClick", {
    private _display = ctrlParent (_this select 0);
    private _veh = uiNamespace getVariable ["QM_Pylon_ActiveVeh", objNull];
    private _baseKey = uiNamespace getVariable ["QM_Pylon_BaseKey", ""];
    
    private _ctrlPylons = _display displayCtrl 8100;
    private _selPylonIdx = lbCurSel _ctrlPylons;
    if (_selPylonIdx == -1) exitWith { systemChat "R4-C: Select a target pylon from the dropdown first."; };
    private _pylonIndex = _ctrlPylons lbValue _selPylonIdx;

    private _selectedMagClass = "NONE";
    {
        private _list = _display displayCtrl _x;
        private _sel = lbCurSel _list;
        if (_sel != -1) exitWith { _selectedMagClass = _list lbData _sel; };
    } forEach [8201, 8202, 8203];

    if (_selectedMagClass == "NONE") exitWith { systemChat "R4-C: Select a weapon system from the lists below to apply."; };

    private _currentPylons = getPylonMagazines _veh;
    private _oldMag = _currentPylons select (_pylonIndex - 1);
    
    if (_oldMag == _selectedMagClass) exitWith { systemChat "R4-C: That ordnance is already equipped to this pylon."; };

    // Point calculations using our centralized helper function
    private _poolVar = format ["LogiScore_%1_Ammo", _baseKey];
    private _currentPool = missionNamespace getVariable [_poolVar, 0];

    private _oldWeight = [_oldMag] call QM_fnc_getWeaponWeight;
    private _newWeight = [_selectedMagClass] call QM_fnc_getWeaponWeight;

    private _netCost = _newWeight - _oldWeight;

    if (_netCost > 0 && _currentPool < _netCost) exitWith { 
        systemChat format ["R4-C: Insufficient Ammo at %1. Net requirement is %2 kg, but ledger only holds %3.", _baseKey, _netCost, _currentPool]; 
    };

    if (_netCost != 0) then {
        missionNamespace setVariable [_poolVar, (_currentPool - _netCost) max 0, true];
        if (_netCost > 0) then { systemChat format ["R4-C: Pylon %1 updated. Billed %2 kg of Ammo.", _pylonIndex, _netCost]; } 
        else { systemChat format ["R4-C: Pylon %1 updated. Refunded %2 kg of Ammo.", _pylonIndex, abs _netCost]; };
    } else {
        systemChat format ["R4-C: Pylon %1 swapped successfully. Ordnance weights are equal.", _pylonIndex];
    };

    _veh setPylonLoadout [_pylonIndex, _selectedMagClass, true];
    playSound "3DEN_notificationDefault";

    (_display displayCtrl 8102) ctrlSetText (if (_selectedMagClass == "") then { "< EMPTY PYLON >" } else { getText (configFile >> "CfgMagazines" >> _selectedMagClass >> "displayName") });
}];

// ============================================================================
// 7. CLOSE BUTTON LOGIC
// ============================================================================
private _btnClose = _display displayCtrl 8999;
_btnClose ctrlAddEventHandler ["ButtonClick", {
    private _display = ctrlParent (_this select 0);
    _display closeDisplay 1;
}];