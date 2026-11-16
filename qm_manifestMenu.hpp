/*
    ============================================================================
    LOGISTICS SYSTEM: SELECTIVE CARGO MANIFEST UI (SECTION 5.3)
    File: qm_manifestMenu.hpp
    Description: Dialog definition for interactive supply manifest selection.
                 Provides fine-grained player control over cargo loading/unloading
                 while strictly filtering out scene props and base clutter.
    ============================================================================
*/

class CfgCargoManifestMenu {
    idd = 5500;
    movingEnable = 0;
    enableSimulation = 1;
    onLoad = "uiNamespace setVariable ['QM_Manifest_Display', _this select 0]; [] execVM 'fn_manifestMenuPopulate.sqf';";
    
    class controls {
        class MainBackground: RscText {
            idc = -1;
            x = 0.15 * safezoneW + safezoneX;
            y = 0.18 * safezoneH + safezoneY;
            w = 0.70 * safezoneW;
            h = 0.64 * safezoneH;
            colorBackground[] = {0.08, 0.08, 0.08, 0.95};
        };

        class MainTitle: RscText {
            idc = 1000;
            text = "LOGISTICS CARGO MANIFEST & SELECTIVE LOADING";
            x = 0.15 * safezoneW + safezoneX;
            y = 0.14 * safezoneH + safezoneY;
            w = 0.70 * safezoneW;
            h = 0.04 * safezoneH;
            colorBackground[] = {0.0, 0.40, 0.55, 1};
        };

        class SubTitleStatus: RscText {
            idc = 1001;
            text = "Scanning vehicle cargo bay and nearby perimeter...";
            x = 0.17 * safezoneW + safezoneX;
            y = 0.19 * safezoneH + safezoneY;
            w = 0.66 * safezoneW;
            h = 0.03 * safezoneH;
            colorBackground[] = {0.14, 0.14, 0.14, 0.9};
            colorText[] = {0.0, 0.90, 1.0, 1};
            sizeEx = 0.032;
        };

        // --- LEFT COLUMN: GROUND SUPPLY MANIFEST ---
        class Col1Header: RscText {
            idc = 1100;
            text = "AVAILABLE GROUND SUPPLIES (WITHIN 25M)";
            x = 0.17 * safezoneW + safezoneX;
            y = 0.23 * safezoneH + safezoneY;
            w = 0.32 * safezoneW;
            h = 0.03 * safezoneH;
            colorText[] = {0.0, 0.85, 1, 1};
        };

        class GroundList: RscListBox {
            idc = 1500;
            x = 0.17 * safezoneW + safezoneX;
            y = 0.27 * safezoneH + safezoneY;
            w = 0.32 * safezoneW;
            h = 0.45 * safezoneH;
        };

        class LoadBtn: RscButton {
            idc = 2010;
            text = "LOAD SELECTED INTO VEHICLE";
            action = "[] execVM 'fn_manifestLoadExecute.sqf';";
            x = 0.17 * safezoneW + safezoneX;
            y = 0.73 * safezoneH + safezoneY;
            w = 0.32 * safezoneW;
            h = 0.04 * safezoneH;
            colorBackground[] = {0.0, 0.50, 0.30, 0.9};
            colorBackgroundActive[] = {0.0, 0.70, 0.40, 1};
        };

        // --- RIGHT COLUMN: VEHICLE CARGO BAY ---
        class Col2Header: RscText {
            idc = 1200;
            text = "CURRENT VEHICLE CARGO BAY";
            x = 0.51 * safezoneW + safezoneX;
            y = 0.23 * safezoneH + safezoneY;
            w = 0.32 * safezoneW;
            h = 0.03 * safezoneH;
            colorText[] = {1.0, 0.75, 0.0, 1};
        };

        class CargoBayList: RscListBox {
            idc = 1550;
            x = 0.51 * safezoneW + safezoneX;
            y = 0.27 * safezoneH + safezoneY;
            w = 0.32 * safezoneW;
            h = 0.45 * safezoneH;
        };

        class UnloadBtn: RscButton {
            idc = 2020;
            text = "UNLOAD SELECTED TO GROUND";
            action = "[] execVM 'fn_manifestUnloadExecute.sqf';";
            x = 0.51 * safezoneW + safezoneX;
            y = 0.73 * safezoneH + safezoneY;
            w = 0.32 * safezoneW;
            h = 0.04 * safezoneH;
            colorBackground[] = {0.60, 0.35, 0.0, 0.9};
            colorBackgroundActive[] = {0.80, 0.45, 0.0, 1};
        };

        // --- FOOTER CONTROLS ---
        class RefreshBtn: RscButton {
            idc = 2030;
            text = "REFRESH MANIFEST";
            action = "[] execVM 'fn_manifestMenuPopulate.sqf';";
            x = 0.17 * safezoneW + safezoneX;
            y = 0.78 * safezoneH + safezoneY;
            w = 0.32 * safezoneW;
            h = 0.03 * safezoneH;
            colorBackground[] = {0.20, 0.20, 0.20, 0.9};
            colorBackgroundActive[] = {0.35, 0.35, 0.35, 1};
            sizeEx = 0.032;
        };

        class CloseBtn: RscButton {
            idc = 2040;
            text = "CLOSE MANIFEST";
            action = "closeDialog 0;";
            x = 0.51 * safezoneW + safezoneX;
            y = 0.78 * safezoneH + safezoneY;
            w = 0.32 * safezoneW;
            h = 0.03 * safezoneH;
            colorBackground[] = {0.35, 0.0, 0.0, 0.85};
            colorBackgroundActive[] = {0.55, 0.0, 0.0, 1};
            sizeEx = 0.032;
        };
    };
};
