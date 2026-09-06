import QtQuick
import QtQuick.Controls.Basic
TextField {
    id: control
    property Tokens theme: Tokens {}
    implicitHeight: 34
    font.family: "Microsoft YaHei UI"
    font.pixelSize: 13
    color: theme.textPrimary
    placeholderTextColor: theme.disabledText
    selectionColor: theme.accent
    selectedTextColor: theme.accentText
    leftPadding: 10; rightPadding: 10
    background: Rectangle {
        radius: 7
        color: theme.fieldBackground
        border.color: control.activeFocus ? theme.accent : theme.border
        border.width: control.activeFocus ? 2 : 1
    }
}
