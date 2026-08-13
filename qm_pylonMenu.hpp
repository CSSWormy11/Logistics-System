/*
    ============================================================================
    LOGISTICS SYSTEM: DYNAMIC PYLON INTERFACE (PART 3C)
    File: qm_pylonMenu.hpp
    Note: Requires #include "qm_pylonMenu.hpp" in description.ext
    ============================================================================
*/

class QM_PylonDialog {
    idd = 8000;
    movingEnable = 0;
    enableSimulation = 1;

    class controls {
        class MainBackground: RscText {
            idc = -1;
            text = ""; 
            x = 0.15 * safezoneW + safezoneX;
            y = 0.15 * safezoneH + safezoneY;
            w = 0.70 * safezoneW;
            h = 0.70 * safezoneH;
            colorBackground[] = {0.1, 0.1, 0.1, 0.9};
        };
        class HeaderText: RscText {
            idc = 8001;
            text = "QUARTERMASTER: DYNAMIC AIRCRAFT LOADOUT";
            x = 0.15 * safezoneW + safezoneX;
            y = 0.10 * safezoneH + safezoneY;
            w = 0.70 * safezoneW;
            h = 0.05 * safezoneH;
            colorBackground[] = {0, 0.5, 0.8, 1};
        };

        class PylonDropdown: RscCombo {
            idc = 8100;
            wholeHeight = 0.25;
            x = 0.17 * safezoneW + safezoneX;
            y = 0.18 * safezoneH + safezoneY;
            w = 0.20 * safezoneW;
            h = 0.04 * safezoneH;
        };
        
        class PylonApplyBtn: RscButton {
            idc = 8101;
            text = "APPLY TO PYLON";
            x = 0.38 * safezoneW + safezoneX;
            y = 0.18 * safezoneH + safezoneY;
            w = 0.12 * safezoneW;
            h = 0.04 * safezoneH;
        };

        // --- NEW: CURRENT WEAPON LABELS ---
        class PylonCurrentLbl: RscText {
            idc = -1;
            text = "CURRENTLY EQUIPPED:";
            x = 0.52 * safezoneW + safezoneX;
            y = 0.17 * safezoneH + safezoneY;
            w = 0.30 * safezoneW;
            h = 0.02 * safezoneH;
            colorText[] = {0.6, 0.6, 0.6, 1};
            sizeEx = 0.035;
        };
        class PylonCurrentTxt: RscText {
            idc = 8102;
            text = "Select a pylon...";
            x = 0.52 * safezoneW + safezoneX;
            y = 0.19 * safezoneH + safezoneY;
            w = 0.30 * safezoneW;
            h = 0.03 * safezoneH;
            colorText[] = {0, 1, 1, 1}; // Bright Cyan
        };

        class Col1Header: RscText {
            idc = -1;
            text = "AIR-TO-AIR (AA)";
            x = 0.17 * safezoneW + safezoneX;
            y = 0.25 * safezoneH + safezoneY;
            w = 0.20 * safezoneW;
            h = 0.04 * safezoneH;
            colorBackground[] = {0.2, 0.2, 0.2, 1};
        };
        class Col1List: RscListbox {
            idc = 8201;
            x = 0.17 * safezoneW + safezoneX;
            y = 0.29 * safezoneH + safezoneY;
            w = 0.20 * safezoneW;
            h = 0.40 * safezoneH;
        };

        class Col2Header: RscText {
            idc = -1;
            text = "AIR-TO-GROUND (AG)";
            x = 0.40 * safezoneW + safezoneX;
            y = 0.25 * safezoneH + safezoneY;
            w = 0.20 * safezoneW;
            h = 0.04 * safezoneH;
            colorBackground[] = {0.2, 0.2, 0.2, 1};
        };
        class Col2List: RscListbox {
            idc = 8202;
            x = 0.40 * safezoneW + safezoneX;
            y = 0.29 * safezoneH + safezoneY;
            w = 0.20 * safezoneW;
            h = 0.40 * safezoneH;
        };

        class Col3Header: RscText {
            idc = -1;
            text = "MISCELLANEOUS / PODS";
            x = 0.63 * safezoneW + safezoneX;
            y = 0.25 * safezoneH + safezoneY;
            w = 0.20 * safezoneW;
            h = 0.04 * safezoneH;
            colorBackground[] = {0.2, 0.2, 0.2, 1};
        };
        class Col3List: RscListbox {
            idc = 8203;
            x = 0.63 * safezoneW + safezoneX;
            y = 0.29 * safezoneH + safezoneY;
            w = 0.20 * safezoneW;
            h = 0.40 * safezoneH;
        };

        class GunHeader: RscText {
            idc = 8300;
            text = "INTERNAL WEAPON SYSTEMS";
            x = 0.63 * safezoneW + safezoneX;
            y = 0.72 * safezoneH + safezoneY;
            w = 0.20 * safezoneW;
            h = 0.03 * safezoneH;
            colorText[] = {0.8, 0.8, 0.8, 1};
        };
        class GunSlider: RscXSliderH {
            idc = 8301;
            x = 0.63 * safezoneW + safezoneX;
            y = 0.75 * safezoneH + safezoneY;
            w = 0.16 * safezoneW;
            h = 0.03 * safezoneH;
        };
        class GunSliderText: RscText {
            idc = 8302;
            text = "100%";
            x = 0.79 * safezoneW + safezoneX;
            y = 0.75 * safezoneH + safezoneY;
            w = 0.04 * safezoneW;
            h = 0.03 * safezoneH;
        };

        class CamoDropdown: RscCombo {
            idc = 8400;
            wholeHeight = 0.25;
            x = 0.17 * safezoneW + safezoneX;
            y = 0.75 * safezoneH + safezoneY;
            w = 0.20 * safezoneW;
            h = 0.04 * safezoneH;
        };

        class CloseBtn: RscButton {
            idc = 8999;
            text = "CLOSE MANIFEST";
            x = 0.40 * safezoneW + safezoneX;
            y = 0.75 * safezoneH + safezoneY;
            w = 0.20 * safezoneW;
            h = 0.04 * safezoneH;
        };
    };
};