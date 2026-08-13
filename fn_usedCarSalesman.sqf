// ============================================================================
// LOGISTICS SYSTEM: MOTORPOOL SALVAGEMAN (PART 2)
// File: fn_usedCarSalesman.sqf
// Description: Scans the terminal pad for the nearest vehicle and sends a 
//              remote execution request to the server to scrap it for points.
// Called By: qm_clientActionCompiler.sqf (Terminal Hub Action Menu)
// ============================================================================

private _baseKey = player getVariable ["QM_Current_Terminal_Base", ""];
private _centerPoint = getMarkerPos _baseKey;

// Search for any active user vehicle sitting directly on the maintenance pad radius
private _nearVehicles = nearestObjects [_centerPoint, ["LandVehicle", "Air"], 14];
if (count _nearVehicles == 0) exitWith { hint "SALVAGEMAN: No vehicle detected inside the maintenance pad layout zone."; };

private _targetScrapVehicle = _nearVehicles select 0;
[_baseKey, _targetScrapVehicle, player] remoteExec ["QM_fnc_serverVehicleSale", 2];