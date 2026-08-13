// ============================================================================
// LOGISTICS SYSTEM: ZEUS TABLET DATA COMPILER (PART 2)
// File: fn_adminTabletLoad.sqf
// Description: Populates the admin tablet UI listbox with active logistics bases.
// Called By: qm_quartermasterUI.hpp (CfgZeusMasterAdminMenu onLoad event)
// ============================================================================

disableSerialization;
private _display = uiNamespace getVariable ["QM_Admin_Display", displayNull];
if (isNull _display) exitWith {};

private _listBox = _display displayCtrl 1700;
lbClear _listBox;

{
    private _idx = _listBox lbAdd _x;
} forEach logisticsBases;

_listBox lbSetCurSel 0;