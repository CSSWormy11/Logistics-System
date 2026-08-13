/*
    ============================================================================
    LOGISTICS SYSTEM: QUARTERMASTER UI (PART 2)
    File: qm_quartermasterUI.hpp
    Description: Dialog definitions for Barracks, Motorpool, and Admin tablet.
    ============================================================================
*/

// --- DIALOG A: TWO-COLUMN INFANTRY RECRUITING HUB ---
class CfgControlHubMenu {
    idd = 9999;
    movingEnable = 0;
    enableSimulation = 1;
    onLoad = "uiNamespace setVariable ['QM_Menu_Display', _this select 0]; [] execVM 'fn_recruiter_list.sqf';";
    
    class controls {
        class MainBackground: RscText {
            idc = -1; x = 0.15 * safezoneW + safezoneX; y = 0.20 * safezoneH + safezoneY;
            w = 0.70 * safezoneW; h = 0.60 * safezoneH; colorBackground[] = {0.08, 0.08, 0.08, 0.95};
        };
        class MainTitle: RscText {
            idc = 1000; text = "GARRISON INFANTRY MOBILIZATION & SQUAD REINFORCEMENTS";
            x = 0.15 * safezoneW + safezoneX; y = 0.16 * safezoneH + safezoneY;
            w = 0.70 * safezoneW; h = 0.04 * safezoneH; colorBackground[] = {0.55, 0.25, 0.0, 1};
        };
        class Col1Header: RscText {
            idc = -1; text = "INDIVIDUAL SQUAD REPLACEMENTS [LOCAL]";
            x = 0.17 * safezoneW + safezoneX; y = 0.22 * safezoneH + safezoneY;
            w = 0.32 * safezoneW; h = 0.03 * safezoneH; colorText[] = {0.0, 0.85, 1, 1};
        };
        class IndividualList: RscListBox {
            idc = 1500; x = 0.17 * safezoneW + safezoneX; y = 0.26 * safezoneH + safezoneY;
            w = 0.32 * safezoneW; h = 0.44 * safezoneH;
        };
        class ConfirmCol1Btn: RscButton {
            idc = 2010; text = "DRAFT BODY TO YOUR SQUAD"; action = "[0] execVM 'fn_recruiter.sqf';";
            x = 0.17 * safezoneW + safezoneX; y = 0.72 * safezoneH + safezoneY; w = 0.32 * safezoneW; h = 0.04 * safezoneH;
        };
        class Col2Header: RscText {
            idc = -1; text = "AUTONOMOUS LOGISTICS GROUPS [SERVER]";
            x = 0.51 * safezoneW + safezoneX; y = 0.22 * safezoneH + safezoneY;
            w = 0.32 * safezoneW; h = 0.03 * safezoneH; colorText[] = {1, 0.75, 0.0, 1};
        };
        class GroupList: RscListBox {
            idc = 1550; x = 0.51 * safezoneW + safezoneX; y = 0.26 * safezoneH + safezoneY;
            w = 0.32 * safezoneW; h = 0.44 * safezoneH;
        };
        class ConfirmCol2Btn: RscButton {
            idc = 2020; text = "MOBILIZE INDEPENDENT UNIT"; action = "[1] execVM 'fn_recruiter.sqf';";
            x = 0.51 * safezoneW + safezoneX; y = 0.72 * safezoneH + safezoneY; w = 0.32 * safezoneW; h = 0.04 * safezoneH;
        };
        class CloseButton: RscButton {
            idc = -1; text = "DISCONNECT TERMINAL"; action = "closeDialog 0;";
            x = 0.15 * safezoneW + safezoneX; y = 0.76 * safezoneH + safezoneY; w = 0.70 * safezoneW; h = 0.03 * safezoneH;
            colorBackground[] = {0.3, 0.0, 0.0, 0.8}; colorBackgroundActive[] = {0.5, 0.0, 0.0, 1};
        };
    };
};

// --- DIALOG B: ISOLATED VEHICLE FACTORY MOTORPOOL ---
class CfgVehicleProcureMenu {
    idd = 8888;
    movingEnable = 0;
    enableSimulation = 1;
    onLoad = "uiNamespace setVariable ['QM_Vehicle_Display', _this select 0]; [0] execVM 'c_vehicleTabs.sqf';";
    
    class controls {
        class MainBackground: RscText {
            idc = -1; x = 0.25 * safezoneW + safezoneX; y = 0.25 * safezoneH + safezoneY;
            w = 0.5 * safezoneW; h = 0.5 * safezoneH; colorBackground[] = {0.1, 0.1, 0.1, 0.9};
        };
        class MainTitle: RscText {
            idc = 1000; text = "VEHICLE FACTORY INFRASTRUCTURE PROCUREMENT";
            x = 0.25 * safezoneW + safezoneX; y = 0.21 * safezoneH + safezoneY;
            w = 0.5 * safezoneW; h = 0.04 * safezoneH; colorBackground[] = {0, 0.45, 0.30, 1};
        };
        
        // --- EXPANDED 7-TAB LAYOUT ---
        class TabWheeled: RscButton {
            idc = 3001; text = "WHEELED"; action = "[0] execVM 'c_vehicleTabs.sqf';";
            x = 0.260 * safezoneW + safezoneX; y = 0.26 * safezoneH + safezoneY; w = 0.068 * safezoneW; h = 0.04 * safezoneH;
            sizeEx = 0.032;
        };
        class TabTracked: RscButton {
            idc = 3002; text = "TRACKED"; action = "[1] execVM 'c_vehicleTabs.sqf';";
            x = 0.329 * safezoneW + safezoneX; y = 0.26 * safezoneH + safezoneY; w = 0.068 * safezoneW; h = 0.04 * safezoneH;
            sizeEx = 0.032;
        };
        class TabHeli: RscButton {
            idc = 3003; text = "HELI"; action = "[2] execVM 'c_vehicleTabs.sqf';";
            x = 0.398 * safezoneW + safezoneX; y = 0.26 * safezoneH + safezoneY; w = 0.068 * safezoneW; h = 0.04 * safezoneH;
            sizeEx = 0.032;
        };
        class TabPlane: RscButton {
            idc = 3004; text = "PLANE"; action = "[3] execVM 'c_vehicleTabs.sqf';";
            x = 0.467 * safezoneW + safezoneX; y = 0.26 * safezoneH + safezoneY; w = 0.068 * safezoneW; h = 0.04 * safezoneH;
            sizeEx = 0.032;
        };
        class TabBoat: RscButton {
            idc = 3005; text = "BOAT"; action = "[4] execVM 'c_vehicleTabs.sqf';";
            x = 0.536 * safezoneW + safezoneX; y = 0.26 * safezoneH + safezoneY; w = 0.068 * safezoneW; h = 0.04 * safezoneH;
            sizeEx = 0.032;
        };
        class TabDrone: RscButton {
            idc = 3006; text = "DRONE"; action = "[5] execVM 'c_vehicleTabs.sqf';";
            x = 0.605 * safezoneW + safezoneX; y = 0.26 * safezoneH + safezoneY; w = 0.068 * safezoneW; h = 0.04 * safezoneH;
            sizeEx = 0.032;
        };
        class TabSupply: RscButton {
            idc = 3007; text = "SUPPLY"; action = "[6] execVM 'c_vehicleTabs.sqf';";
            x = 0.674 * safezoneW + safezoneX; y = 0.26 * safezoneH + safezoneY; w = 0.068 * safezoneW; h = 0.04 * safezoneH;
            sizeEx = 0.032;
        };

        class VehicleList: RscListBox {
            idc = 1600; x = 0.26 * safezoneW + safezoneX; y = 0.31 * safezoneH + safezoneY;
            w = 0.482 * safezoneW; h = 0.37 * safezoneH;
        };
        class ConfirmBtn: RscButton {
            idc = 3010; text = "CONFIRM FACTORY ORDER"; action = "[] execVM 'fn_newCarDealership.sqf';";
            x = 0.26 * safezoneW + safezoneX; y = 0.70 * safezoneH + safezoneY; w = 0.23 * safezoneW; h = 0.04 * safezoneH;
        };
        class CloseBtn: RscButton {
            idc = -1; text = "CLOSE MOTORPOOL"; action = "closeDialog 0;";
            x = 0.51 * safezoneW + safezoneX; y = 0.70 * safezoneH + safezoneY; w = 0.23 * safezoneW; h = 0.04 * safezoneH;
        };
    };
};

// --- DIALOG C: MASTER ADMIN COMMAND TABLET ---
class CfgZeusMasterAdminMenu {
    idd = 7777;
    movingEnable = 0;
    enableSimulation = 1;
    onLoad = "uiNamespace setVariable ['QM_Admin_Display', _this select 0]; [] execVM 'fn_adminTabletLoad.sqf';";
    
    class controls {
        class MainBackground: RscText {
            idc = -1; x = 0.2 * safezoneW + safezoneX; y = 0.2 * safezoneH + safezoneY;
            w = 0.6 * safezoneW; h = 0.6 * safezoneH; colorBackground[] = {0.05, 0.05, 0.1, 0.95};
        };
        class MainTitle: RscText {
            idc = 1000; text = "ZEUS FIELD OPERATIONAL COMMAND TABLET [OVERLORD-SYS]";
            x = 0.2 * safezoneW + safezoneX; y = 0.16 * safezoneH + safezoneY;
            w = 0.6 * safezoneW; h = 0.04 * safezoneH; colorBackground[] = {0.5, 0, 0.5, 1};
        };
        class BasesList: RscListBox {
            idc = 1700; x = 0.22 * safezoneW + safezoneX; y = 0.24 * safezoneH + safezoneY;
            w = 0.25 * safezoneW; h = 0.44 * safezoneH;
        };
        class BtnOpenWeapons: RscButton {
            idc = -1; text = "ROUTE ARSENAL REQUISITION"; action = "['WEAPONS'] execVM 'fn_adminTabletExecute.sqf';";
            x = 0.50 * safezoneW + safezoneX; y = 0.26 * safezoneH + safezoneY; w = 0.26 * safezoneW; h = 0.05 * safezoneH;
        };
        class BtnOpenVehicles: RscButton {
            idc = -1; text = "ROUTE VEHICLE FACTORY"; action = "['VEHICLES'] execVM 'fn_adminTabletExecute.sqf';";
            x = 0.50 * safezoneW + safezoneX; y = 0.36 * safezoneH + safezoneY; w = 0.26 * safezoneW; h = 0.05 * safezoneH;
        };
        class BtnOpenTroops: RscButton {
            idc = -1; text = "ROUTE INFANTRY REC-HUB"; action = "['TROOPS'] execVM 'fn_adminTabletExecute.sqf';";
            x = 0.50 * safezoneW + safezoneX; y = 0.46 * safezoneH + safezoneY; w = 0.26 * safezoneW; h = 0.05 * safezoneH;
        };
        class CloseBtn: RscButton {
            idc = -1; text = "DISCONNECT TABLET"; action = "closeDialog 0;";
            x = 0.22 * safezoneW + safezoneX; y = 0.72 * safezoneH + safezoneY; w = 0.54 * safezoneW; h = 0.04 * safezoneH;
        };
    };
};