// ============================================================================
// LOGISTICS SYSTEM: UNIFIED CUSTOM UI TERMINAL ENTRY LINK (PART 2)
// File: c_unifiedMenu.sqf
// Description: Caches terminal profiles, secures the container inventory, 
//              and launches the master control hub UI dialog.
// Called By: Terminal Interaction / Action Menu
// ============================================================================

params ["_targetBox", "_caller", "_actionId", "_baseKey"];

if (side group _caller != west) exitWith { hint "Access Denied: Faction Lock Validations Failed."; };

// Wipe contents instantly to prevent trade-cycling free gear item loops
clearWeaponCargoGlobal _targetBox;
clearMagazineCargoGlobal _targetBox;
clearItemCargoGlobal _targetBox;
clearBackpackCargoGlobal _targetBox;

// Cache the active framework identifiers onto the player profile space
player setVariable ["QM_Current_Terminal_Box", _targetBox];
player setVariable ["QM_Current_Terminal_Base", _baseKey];

// Open the custom 3-Tab Interface Dialog layout defined inside description.ext
createDialog "CfgControlHubMenu";