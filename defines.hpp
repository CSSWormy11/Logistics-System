// ============================================================================
// LOGISTICS SYSTEM: MASTER GUI BASE CLASSES
// File: defines.hpp
// Description: Defines the core UI building blocks for Arma 3. Included ONCE 
//              at the very top of description.ext.
// ============================================================================

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