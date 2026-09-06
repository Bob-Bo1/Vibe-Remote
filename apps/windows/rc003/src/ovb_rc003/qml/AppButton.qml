import QtQuick
import QtQuick.Controls.Basic
Button {
    id: control
    property Tokens theme: Tokens {}
    implicitHeight: 34
    implicitWidth: Math.max(34, implicitContentWidth + 26)
    leftPadding: 12; rightPadding: 12
    font.family: "Microsoft YaHei UI"
    font.pixelSize: 13
    hoverEnabled: true
    opacity: enabled ? 1 : 0.45
    contentItem: Text {
        text: control.text; font: control.font
        color: control.highlighted ? theme.accentText : theme.textPrimary
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    background: Rectangle {
        radius: 8
        color: control.highlighted ? (control.down ? Qt.darker(theme.accent,1.15) : theme.accent)
            : (control.down ? theme.sidebar : (control.hovered ? theme.background : theme.buttonBackground))
        border.width: control.activeFocus ? 2 : 1
        border.color: control.activeFocus ? theme.accent : (control.highlighted ? "transparent" : theme.border)
    }
}
