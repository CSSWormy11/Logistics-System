// ============================================================================
// LOGISTICS SYSTEM: ZEUS TABLET OVERLAY ROUTER (PART 2)
// File: fn_adminTabletExecute.sqf
// Description: Forwards Admin Command choices to separate menus.
// Called By: qm_quartermasterUI.hpp (Admin Tablet Action Buttons)
// ============================================================================

private _routeCategory = param [0, "", [""]];
disableSerialization;

private _display = uiNamespace getVariable ["QM_Admin_Display", displayNull];
if (isNull _display) exitWith {};

private _listBox = _display displayCtrl 1700;
private _selIdx = lbCurSel _listBox;
if (_selIdx == -1) exitWith { hint "ZEUS: Select a destination base context node first."; };

private _selectedBaseKey = _listBox lbText _selIdx;
closeDialog 0;

player setVariable ["QM_Current_Terminal_Base", _selectedBaseKey];

private _tempVirtualBox = nearestObject [player, "VirtualReammoBox_camonet_F"];
if (isNull _tempVirtualBox) then { 
    _tempVirtualBox = player; 
};
player setVariable ["QM_Current_Terminal_Box", _tempVirtualBox];

switch (_routeCategory) do {
    case "WEAPONS": { 
        // Directly route to your whitelisting loop inside the compiler
        [objNull, player] spawn {
            params ["_target", "_caller"];
            _caller setVariable ["QM_LocalTrade_InitialMass", loadAbs _caller];
            [missionNamespace, "virtual", true] call BIS_fnc_addVirtualWeaponCargo;
            private _vWeapons = G_Allowed_Weapons apply { _x select 0 };
            private _vMags = G_Allowed_Magazines apply { _x select 0 };
            private _vItems = G_Allowed_Items apply { _x select 0 };
            private _vBackpacks = G_Allowed_Backpacks apply { _x select 0 };
            [missionNamespace, _vWeapons, false, false] call BIS_fnc_addVirtualWeaponCargo;
            [missionNamespace, _vMags, false, false] call BIS_fnc_addVirtualMagazineCargo;
            [missionNamespace, _vItems, false, false] call BIS_fnc_addVirtualItemCargo;
            [missionNamespace, _vBackpacks, false, false] call BIS_fnc_addVirtualBackpackCargo;
            ["Open", [false, player, player]] call BIS_fnc_arsenal;
            waitUntil { isNull (uiNamespace getVariable ["RscDisplayArsenal", displayNull]) };
            if (!isNil "QM_fnc_traderOnContainerClosed") then { [objNull, player] call QM_fnc_traderOnContainerClosed; };
        };
    };
    case "VEHICLES": { 
        createDialog "CfgVehicleProcureMenu"; // Untangled: Opens the dedicated procurement window
    };
    case "TROOPS": { 
        createDialog "CfgControlHubMenu";     // Untangled: Opens the dedicated recruitment window
    };
};