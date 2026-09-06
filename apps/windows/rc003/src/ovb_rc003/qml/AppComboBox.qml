import QtQuick
import QtQuick.Controls.Basic
ComboBox {
    id: control
    property Tokens theme: Tokens {}
    property int popupMinimumWidth: 240
    property int popupMaximumHeight: 300
    implicitHeight: 34
    font.family: "Microsoft YaHei UI"
    font.pixelSize: 13
    leftPadding: 10; rightPadding: 28
    hoverEnabled: true
    flat: true
    palette.text: theme.textPrimary
    palette.buttonText: theme.textPrimary
    palette.base: theme.fieldBackground
    palette.window: theme.surface
    palette.highlight: theme.accent
    palette.highlightedText: theme.accentText
    opacity: enabled ? 1 : 0.5
    background: Rectangle {
        radius: 7
        color: theme.fieldBackground
        border.color: control.activeFocus ? theme.accent : (control.hovered ? theme.disabledText : theme.border)
        border.width: control.activeFocus ? 2 : 1
    }
    indicator: Canvas {
        width: 12; height: 12
        x: control.width - width - 10; y: (control.height - height) / 2
        onPaint: {
            var ctx = getContext("2d"); ctx.reset()
            ctx.strokeStyle = theme.textSecondary; ctx.lineWidth = 1.5
            ctx.beginPath(); ctx.moveTo(3,4);ctx.lineTo(6,7);ctx.lineTo(9,4);ctx.stroke()
        }
    }

    popup: Popup {
        id: actionPopup
        objectName: control.objectName + "_popup"
        y: control.height
        width: Math.max(control.width, control.popupMinimumWidth)
        implicitHeight: contentItem.contentHeight + topPadding + bottomPadding
        height: Math.min(implicitHeight, control.popupMaximumHeight)
        padding: 5

        contentItem: ListView {
            id: actionPopupList
            objectName: control.objectName + "_popupList"
            clip: true
            implicitHeight: contentHeight
            model: actionPopup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            boundsBehavior: Flickable.StopAtBounds
            ScrollIndicator.vertical: ScrollIndicator {}
        }

        background: Rectangle {
            radius: 9
            color: control.theme.surface
            border.color: control.theme.border
            border.width: 1
        }
    }
}
