// ============================================================================
// LOGISTICS SYSTEM: TRANSPORT TASK INITIALIZATION (PART 1)
// File: fn_initLogisticsTasks.sqf
// Description: Server-side setup script. Scans editor triggers and bases, 
//              creates map markers, and preps global delivery assignments.
// Called By: init.sqf (Executed by Server only)
// ============================================================================

if (!isServer) exitWith {};

// =========================================================================
// STANDARDIZED MARKER GENERATION FROM TRIGGERS (SERVER ONLY)
// =========================================================================
private _allMissionTriggers = allMissionObjects "EmptyDetector";

{
    private _trigger = _x;
    private _triggerName = vehicleVarName _trigger; 
    
    if (_triggerName != "") then {
        private _isPickup = "_pickup" in _triggerName;
        private _isDropoff = "_dropoff" in _triggerName;
        
        if (_isPickup || _isDropoff) then {
            private _stringElements = _triggerName splitString "_";
            _stringElements deleteAt (count _stringElements - 1);
            
            private _parentBase = _stringElements joinString "_"; 
            private _displayName = _stringElements joinString " ";

            private _prefix = if (_isPickup) then {"Pickup_"} else {"Dropoff_"};
            private _expectedMarkerID = format ["%1%2", _prefix, _parentBase]; 
            
            createMarker [_expectedMarkerID, getPos _trigger];
            _expectedMarkerID setMarkerColor (if (_isPickup) then {"ColorBLUFOR"} else {"ColorGreen"});
            _expectedMarkerID setMarkerType (if (_isPickup) then {"mil_pickup"} else {"mil_end"});
            _expectedMarkerID setMarkerText (if (_isPickup) then {format ["%1 - Loading Zone", _displayName]} else {format ["%1 - Delivery Zone", _displayName]});
        };
    };
} forEach _allMissionTriggers;