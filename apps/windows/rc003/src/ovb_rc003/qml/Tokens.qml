import QtQuick
QtObject {
    property SystemPalette palette: SystemPalette { colorGroup: SystemPalette.Active }
    readonly property bool dark: palette.window.hslLightness < 0.45
    property color background: dark ? "#1C1C1E" : "#F5F5F7"
    property color sidebar: dark ? "#252527" : "#ECECEF"
    property color surface: dark ? "#2C2C2E" : "#FFFFFF"
    property color textPrimary: dark ? "#F5F5F7" : "#1D1D1F"
    property color textSecondary: dark ? "#AEAEB2" : "#65656C"
    property color disabledText: dark ? "#747479" : "#94949B"
    property color accent: dark ? "#0A84FF" : "#007AFF"
    property color accentText: "#FFFFFF"
    property color border: dark ? "#414144" : "#E2E2E7"
    property color fieldBackground: dark ? "#363638" : "#FFFFFF"
    property color buttonBackground: dark ? "#414144" : "#FFFFFF"
    property color buttonText: textPrimary
    property color voiceAccent: dark ? "#FFB340" : "#B96B00"
    property color successColor: dark ? "#54CF78" : "#248A3D"
    property color errorColor: dark ? "#FF6961" : "#C9342D"
    property int cornerRadiusSmall: 8
    property int cornerRadiusLarge: 16
    property int spacingTiny: 4
    property int spacingSmall: 8
    property int spacingMedium: 14
    property int spacingLarge: 24
    property int fontSizeSmall: 12
    property int fontSizeBody: 14
    property int fontSizeTitle: 17
}
