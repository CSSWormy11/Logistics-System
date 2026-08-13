/*
    ============================================================================
    LOGISTICS SYSTEM: DYNAMIC PYLON INTERFACE (PART 3C)
    File: qm_pylonMenu.hpp
    Note: Requires #include "qm_pylonMenu.hpp" in description.ext
    ============================================================================
*/

class RscText {
    type = 0;
    idc = -1;
    style = 0;
    colorBackground[] = {0,0,0,0};
    colorText[] = {1,1,1,1};
    font = "RobotoCondensed";
    sizeEx = 0.04;
    text = "";
};

class RscButton {
    type = 1;
    idc = -1;
    style = 2;
    colorText[] = {1,1,1,1};
    colorDisabled[] = {0.4,0.4,0.4,1};
    colorBackground[] = {0.2,0.2,0.2,1};
    colorBackgroundDisabled[] = {0.95,0.95,0.95,1};
    colorBackgroundActive[] = {0.5,0.5,0.5,1};
    colorFocused[] = {0.5,0.5,0.5,1};
    colorShadow[] = {0,0,0,1};
    colorBorder[] = {0,0,0,1};
    font = "RobotoCondensed";
    sizeEx = 0.04;
    offsetX = 0; offsetY = 0; offsetPressedX = 0; offsetPressedY = 0;
    borderSize = 0;
    text = "";
    // FIX: Silent sound arrays to clear RPT Warnings
    soundEnter[] = {"",0.1,1};
    soundPush[] = {"",0.1,1};
    soundClick[] = {"",0.1,1};
    soundEscape[] = {"",0.1,1};
};

class RscListbox {
    type = 5;
    style = 16;
    font = "RobotoCondensed";
    sizeEx = 0.04;
    rowHeight = 0.04;
    colorText[] = {1,1,1,1};
    colorDisabled[] = {1,1,1,0.25};
    colorScrollbar[] = {1,0,0,0};
    colorSelect[] = {0,0,0,1};
    colorSelect2[] = {0,0,0,1};
    colorSelectBackground[] = {0.95,0.95,0.95,1};
    colorSelectBackground2[] = {1,1,1,0.5};
    colorBackground[] = {0,0,0,0.3};
    maxHistoryDelay = 1.0;
    period = 1;
    // FIX: Silent sound arrays to clear RPT Warnings
    soundSelect[] = {"",0.1,1};
    class ListScrollBar {
        color[] = {1,1,1,0.6};
        thumb = "#(argb,8,8,3)color(1,1,1,1)";
        width = 0; height = 0;
    };
};

class RscCombo {
    type = 4;
    style = "0x00 + 0x10";
    font = "RobotoCondensed";
    sizeEx = 0.04;
    rowHeight = 0.04;
    wholeHeight = 0.25;
    colorText[] = {1,1,1,1};
    colorDisabled[] = {1,1,1,0.25};
    colorSelect[] = {0,0,0,1};
    colorSelectBackground[] = {1,1,1,0.7};
    colorBackground[] = {0,0,0,0.8};
    // FIX: Silent sound arrays & Arrow UI calls to clear RPT Warnings
    soundSelect[] = {"",0.1,1};
    soundExpand[] = {"",0.1,1};
    soundCollapse[] = {"",0.1,1};
    arrowEmpty = "\A3\ui_f\data\GUI\RscCommon\rsccombo\arrow_combo_ca.paa";
    arrowFull = "\A3\ui_f\data\GUI\RscCommon\rsccombo\arrow_combo_active_ca.paa";
    maxHistoryDelay = 1.0;
    class ComboScrollBar {
        color[] = {1,1,1,0.6};
        thumb = "#(argb,8,8,3)color(1,1,1,1)";
    };
};

class RscXSliderH {
    type = 43;
    style = 0x400;
    color[] = {1, 1, 1, 0.4};
    colorActive[] = {1, 1, 1, 1};
    colorDisable[] = {1, 1, 1, 0.4};
    arrowEmpty = "\A3\ui_f\data\gui\cfg\slider\arrowEmpty_ca.paa";
    arrowFull = "\A3\ui_f\data\gui\cfg\slider\arrowFull_ca.paa";
    border = "\A3\ui_f\data\gui\cfg\slider\border_ca.paa";
    thumb = "\A3\ui_f\data\gui\cfg\slider\thumb_ca.paa";
};

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