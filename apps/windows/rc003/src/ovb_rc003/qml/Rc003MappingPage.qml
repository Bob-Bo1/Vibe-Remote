import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import OvbRc003Settings 1.0

// The RC003 mapping workspace follows the physical object: the remote stays
// in the middle and each side contains the keys that sit on that side of the
// photo. The model, hotspot geometry and save path remain the existing
// production objects; this component only changes their presentation.
Item {
    id: root

    property var tokens
    readonly property real photoAspectRatio: 1030 / 508
    readonly property var leftButtonIndexes: [0, 2, 3, 7, 9, 11]
    readonly property var rightButtonIndexes: [1, 4, 5, 6, 8, 10, 12]

    function isLeft(index) {
        return leftButtonIndexes.indexOf(index) >= 0
    }

    function slotFor(index) {
        var slots = isLeft(index) ? leftButtonIndexes : rightButtonIndexes
        return slots.indexOf(index)
    }

    function actionTextFor(row, trigger) {
        if (trigger === "single_click")
            return row.actionText
        if (trigger === "double_click")
            return row.doubleClickText
        return row.longPressText
    }

    function gestureTrigger(index) {
        return ["single_click", "double_click", "long_press"][index]
    }

    function gestureLabel(index) {
        return [qsTr("单击"), qsTr("双击"), qsTr("长按")][index]
    }

    function selectedDeviceLabel() {
        if (SettingsController.isRc003Device)
            return qsTr("小米蓝牙遥控器 2 Pro")
        var index = SettingsController.selectedDeviceIndex
        var options = SettingsController.deviceOptions
        if (index >= 0 && index < options.length)
            return options[index]
        return qsTr("小米蓝牙遥控器 2 Pro")
    }

    function openShortcutRecorder(buttonId, rowIndex, isMic, trigger) {
        shortcutRecorder.buttonId = buttonId
        shortcutRecorder.rowIndex = rowIndex
        shortcutRecorder.isMic = isMic
        shortcutRecorder.trigger = trigger || "single_click"
        shortcutRecorder.previewText = qsTr("请按下要映射的真实按键")
        shortcutRecorder.open()
    }

    Dialog {
        id: shortcutRecorder
        objectName: "shortcutRecorderDialog"
        modal: true
        anchors.centerIn: parent
        width: 430
        title: qsTr("录制自定义快捷键")
        standardButtons: Dialog.Cancel

        property string buttonId: ""
        property int rowIndex: -1
        property bool isMic: false
        property string trigger: "single_click"
        property string previewText: ""

        function commitShortcut(chord) {
            previewText = chord
            if (isMic)
                SettingsController.hotkeyText = chord
            else if (trigger === "single_click")
                ButtonMappingModel.setActionTextAt(rowIndex, chord)
            else
                ButtonMappingModel.setSecondaryActionTextAt(rowIndex, trigger, chord)
            close()
        }

        onOpened: {
            captureArea.forceActiveFocus()
            SettingsController.startHotkeyCapture()
        }

        onClosed: SettingsController.stopHotkeyCapture()

        Connections {
            target: SettingsController
            function onHotkeyCaptured(chord) {
                if (shortcutRecorder.visible)
                    shortcutRecorder.commitShortcut(chord)
            }
            function onHotkeyCaptureError(message) {
                if (shortcutRecorder.visible)
                    shortcutRecorder.previewText = message
            }
        }

        contentItem: FocusScope {
            id: captureArea
            implicitHeight: 150
            focus: true

            ColumnLayout {
                anchors.fill: parent
                spacing: tokens.spacingMedium

                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: shortcutRecorder.previewText
                    font.pixelSize: tokens.fontSizeTitle
                    color: tokens.accent
                }
                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    text: qsTr("请直接按下要映射的真实按键；左右修饰键会分别记录。录制期间不会执行该快捷键。")
                    color: tokens.textSecondary
                    font.pixelSize: tokens.fontSizeSmall
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: tokens.spacingLarge
        spacing: tokens.spacingSmall

        RowLayout {
            id: mappingToolbar
            objectName: "mappingToolbar"
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            spacing: tokens.spacingMedium

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Label {
                    text: qsTr("自定义按键")
                    color: tokens.textPrimary
                    font.pixelSize: tokens.fontSizeTitle
                    font.bold: true
                }
                Label {
                    text: qsTr("点击遥控器或左右卡片，编辑对应的 Windows 操作")
                    color: tokens.textSecondary
                    font.pixelSize: tokens.fontSizeSmall
                }
            }

            Rectangle {
                id: deviceSummary
                objectName: "mappingDeviceSummary"
                Layout.preferredWidth: 248
                Layout.preferredHeight: 44
                radius: 13
                color: tokens.surface
                border.color: tokens.border
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Rectangle {
                        Layout.preferredWidth: 9
                        Layout.preferredHeight: 9
                        radius: 5
                        color: tokens.accent
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Label {
                            Layout.fillWidth: true
                            text: qsTr("当前设备")
                            color: tokens.textSecondary
                            font.pixelSize: 10
                        }
                        Label {
                            Layout.fillWidth: true
                            text: root.selectedDeviceLabel()
                            color: tokens.textPrimary
                            font.pixelSize: tokens.fontSizeSmall
                            font.bold: true
                            elide: Text.ElideRight
                        }
                    }
                    Label {
                        text: qsTr("配置已加载")
                        color: tokens.successColor
                        font.pixelSize: 10
                    }
                }
            }
        }

        Rectangle {
            id: detectionStrip
            objectName: "mappingDetectionStrip"
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            radius: 11
            color: tokens.surface
            border.color: SettingsController.keyDetectionActive ? tokens.accent : tokens.border
            border.width: SettingsController.keyDetectionActive ? 2 : 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                Text {
                    text: "⌁"
                    color: SettingsController.keyDetectionActive ? tokens.accent : tokens.textSecondary
                    font.pixelSize: 20
                    font.bold: true
                }
                Label {
                    Layout.fillWidth: true
                    text: SettingsController.keyDetectionText
                    color: SettingsController.keyDetectionActive ? tokens.accent : tokens.textSecondary
                    font.pixelSize: tokens.fontSizeSmall
                    elide: Text.ElideRight
                }
                AppButton {
                    id: detectRealKeyButton
                    objectName: "detectRealKeyButton"
                    theme: tokens
                    text: SettingsController.keyDetectionActive
                        ? qsTr("停止检测") : qsTr("检测真实按键")
                    highlighted: SettingsController.keyDetectionActive
                    Layout.preferredHeight: 30
                    onClicked: SettingsController.keyDetectionActive
                        ? SettingsController.stopKeyDetection()
                        : SettingsController.startKeyDetection()
                    Accessible.name: qsTr("检测真实遥控器按键")
                }
            }
        }

        Item {
            id: mappingStage
            objectName: "mappingStage"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 350

            readonly property real columnGap: 12
            readonly property real remoteColumnWidth: Math.min(
                220, Math.max(172, width * 0.23)
            )
            readonly property real sideColumnWidth: Math.max(
                226, Math.min(320, (width - remoteColumnWidth - columnGap * 2) / 2)
            )
            readonly property real sideInset: Math.max(
                0, (width - sideColumnWidth * 2 - remoteColumnWidth - columnGap * 2) / 2
            )

            Flickable {
                id: mappingViewport
                objectName: "mappingViewport"
                anchors.fill: parent
                clip: true
                contentWidth: width
                contentHeight: mappingList.contentHeight
                boundsBehavior: Flickable.StopAtBounds
                onContentYChanged: lineCanvas.requestPaint()

                Item {
                    id: mappingList
                    objectName: "mappingList"
                    width: mappingViewport.width
                    height: contentHeight

                    property int currentIndex: ButtonMappingModel.indexOfButton(
                        SettingsController.selectedButtonId
                    )
                    property var currentItem: mappingRepeater.itemAt(currentIndex)
                    property var model: ButtonMappingModel
                    readonly property real topInset: 2
                    readonly property real cardGap: 6
                    readonly property real cardHeight: Math.max(
                        58, Math.min(78, (mappingViewport.height - topInset - cardGap * 6) / 7)
                    )
                    readonly property real contentHeight: topInset + cardHeight * 7 + cardGap * 6

                    onCurrentIndexChanged: lineCanvas.requestPaint()

                    Repeater {
                        id: mappingRepeater
                        model: ButtonMappingModel

                        delegate: Rectangle {
                            id: mappingRow

                            required property int index
                            required property string buttonId
                            required property string displayName
                            required property string hidUsage
                            required property string actionText
                            required property string doubleClickText
                            required property string longPressText
                            required property bool isMic
                            required property bool isSelected
                            required property bool isVoice
                            required property real hotspotX
                            required property real hotspotY

                            objectName: "mappingCard_" + buttonId
                            width: mappingStage.sideColumnWidth
                            height: mappingList.cardHeight
                            x: root.isLeft(index)
                                ? mappingStage.sideInset
                                : mappingStage.width - mappingStage.sideInset - width
                            y: mappingList.topInset + root.slotFor(index) * (
                                mappingList.cardHeight + mappingList.cardGap
                            )
                            radius: 12
                            color: isSelected
                                ? Qt.rgba(tokens.accent.r, tokens.accent.g, tokens.accent.b, 0.13)
                                : tokens.surface
                            border.color: isSelected ? tokens.accent : tokens.border
                            border.width: isSelected ? 2 : 1
                            z: 2

                            onXChanged: lineCanvas.requestPaint()
                            onYChanged: lineCanvas.requestPaint()
                            onWidthChanged: lineCanvas.requestPaint()
                            onHeightChanged: lineCanvas.requestPaint()
                            Component.onCompleted: lineCanvas.requestPaint()

                            Accessible.role: Accessible.Button
                            Accessible.name: displayName

                            TapHandler {
                                onTapped: SettingsController.selectButton(mappingRow.buttonId)
                            }

                            RowLayout {
                                id: cardHeader
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.leftMargin: 9
                                anchors.rightMargin: 9
                                anchors.topMargin: 5
                                height: 19
                                spacing: 5

                                Text {
                                    text: mappingRow.isVoice ? "♩" : root.iconFor(mappingRow.buttonId)
                                    font.family: "Segoe UI Symbol"
                                    color: mappingRow.isVoice ? tokens.voiceAccent : tokens.textPrimary
                                    font.pixelSize: 15
                                    font.bold: true
                                }
                                Label {
                                    Layout.fillWidth: true
                                    text: mappingRow.displayName
                                    color: tokens.textPrimary
                                    font.pixelSize: 11
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                                Label {
                                    text: mappingRow.isVoice ? qsTr("固定通道") : mappingRow.hidUsage
                                    color: tokens.textSecondary
                                    font.pixelSize: 9
                                    elide: Text.ElideRight
                                }
                            }

                            RowLayout {
                                id: gestureContent
                                objectName: "gestureContent_" + mappingRow.buttonId
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: cardHeader.bottom
                                anchors.bottom: parent.bottom
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                anchors.bottomMargin: 6
                                anchors.topMargin: 1
                                spacing: 5
                                visible: !mappingRow.isMic

                                ColumnLayout {
                                    id: singleCell
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    spacing: 1
                                    Label {
                                        text: qsTr("单击")
                                        color: tokens.textSecondary
                                        font.pixelSize: 9
                                    }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        spacing: 2
                                        AppComboBox {
                                            id: actionCombo
                                            objectName: "actionCombo_" + mappingRow.buttonId
                                            theme: tokens
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            Layout.minimumWidth: 0
                                            implicitHeight: 28
                                            leftPadding: 6
                                            rightPadding: 18
                                            font.pixelSize: 10
                                            editable: true
                                            model: SettingsController.presetActionOptions
                                            ToolTip.visible: hovered
                                            ToolTip.text: qsTr("单击动作，可直接输入快捷键")
                                            property bool initialized: false
                                            Component.onCompleted: {
                                                editText = mappingRow.actionText
                                                initialized = true
                                            }
                                            onEditTextChanged: {
                                                if (initialized)
                                                    ButtonMappingModel.setActionTextAt(mappingRow.index, editText)
                                            }
                                            onAccepted: ButtonMappingModel.setActionTextAt(mappingRow.index, editText)
                                            onActivated: ButtonMappingModel.setActionTextAt(mappingRow.index, currentText)
                                        }
                                        AppButton {
                                            objectName: "recordSingleShortcut_" + mappingRow.buttonId
                                            theme: tokens
                                            text: qsTr("录")
                                            Layout.preferredWidth: 25
                                            Layout.minimumWidth: 25
                                            Layout.fillHeight: true
                                            leftPadding: 0
                                            rightPadding: 0
                                            font.pixelSize: 10
                                            onClicked: root.openShortcutRecorder(mappingRow.buttonId, mappingRow.index, false, "single_click")
                                            Accessible.name: qsTr("录制单击") + mappingRow.displayName
                                        }
                                    }
                                }

                                ColumnLayout {
                                    id: doubleCell
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    spacing: 1
                                    Label {
                                        text: qsTr("双击")
                                        color: tokens.textSecondary
                                        font.pixelSize: 9
                                    }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        spacing: 2
                                        AppComboBox {
                                            id: doubleActionCombo
                                            objectName: "doubleActionCombo_" + mappingRow.buttonId
                                            theme: tokens
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            Layout.minimumWidth: 0
                                            implicitHeight: 28
                                            leftPadding: 6
                                            rightPadding: 18
                                            font.pixelSize: 10
                                            editable: true
                                            model: SettingsController.presetActionOptions
                                            ToolTip.visible: hovered
                                            ToolTip.text: qsTr("双击动作，可直接输入快捷键")
                                            property bool initialized: false
                                            Component.onCompleted: {
                                                editText = mappingRow.doubleClickText
                                                initialized = true
                                            }
                                            onEditTextChanged: {
                                                if (initialized)
                                                    ButtonMappingModel.setSecondaryActionTextAt(mappingRow.index, "double_click", editText)
                                            }
                                            onAccepted: ButtonMappingModel.setSecondaryActionTextAt(mappingRow.index, "double_click", editText)
                                            onActivated: ButtonMappingModel.setSecondaryActionTextAt(mappingRow.index, "double_click", currentText)
                                        }
                                        AppButton {
                                            objectName: "recordDoubleShortcut_" + mappingRow.buttonId
                                            theme: tokens
                                            text: qsTr("录")
                                            Layout.preferredWidth: 25
                                            Layout.minimumWidth: 25
                                            Layout.fillHeight: true
                                            leftPadding: 0
                                            rightPadding: 0
                                            font.pixelSize: 10
                                            onClicked: root.openShortcutRecorder(mappingRow.buttonId, mappingRow.index, false, "double_click")
                                            Accessible.name: qsTr("录制双击") + mappingRow.displayName
                                        }
                                    }
                                }

                                ColumnLayout {
                                    id: longCell
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    spacing: 1
                                    Label {
                                        text: qsTr("长按")
                                        color: tokens.textSecondary
                                        font.pixelSize: 9
                                    }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        spacing: 2
                                        AppComboBox {
                                            id: longActionCombo
                                            objectName: "longActionCombo_" + mappingRow.buttonId
                                            theme: tokens
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            Layout.minimumWidth: 0
                                            implicitHeight: 28
                                            leftPadding: 6
                                            rightPadding: 18
                                            font.pixelSize: 10
                                            editable: true
                                            model: SettingsController.presetActionOptions
                                            ToolTip.visible: hovered
                                            ToolTip.text: qsTr("长按动作，可直接输入快捷键")
                                            property bool initialized: false
                                            Component.onCompleted: {
                                                editText = mappingRow.longPressText
                                                initialized = true
                                            }
                                            onEditTextChanged: {
                                                if (initialized)
                                                    ButtonMappingModel.setSecondaryActionTextAt(mappingRow.index, "long_press", editText)
                                            }
                                            onAccepted: ButtonMappingModel.setSecondaryActionTextAt(mappingRow.index, "long_press", editText)
                                            onActivated: ButtonMappingModel.setSecondaryActionTextAt(mappingRow.index, "long_press", currentText)
                                        }
                                        AppButton {
                                            objectName: "recordLongShortcut_" + mappingRow.buttonId
                                            theme: tokens
                                            text: qsTr("录")
                                            Layout.preferredWidth: 25
                                            Layout.minimumWidth: 25
                                            Layout.fillHeight: true
                                            leftPadding: 0
                                            rightPadding: 0
                                            font.pixelSize: 10
                                            onClicked: root.openShortcutRecorder(mappingRow.buttonId, mappingRow.index, false, "long_press")
                                            Accessible.name: qsTr("录制长按") + mappingRow.displayName
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                id: voiceContent
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: cardHeader.bottom
                                anchors.bottom: parent.bottom
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                anchors.bottomMargin: 6
                                anchors.topMargin: 1
                                spacing: 4
                                visible: mappingRow.isMic

                                AppTextField {
                                    id: voiceHotkeyField
                                    objectName: "voiceHotkeyField_" + mappingRow.buttonId
                                    theme: tokens
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.minimumWidth: 0
                                    text: SettingsController.hotkeyText
                                    placeholderText: qsTr("语音组合键")
                                    selectByMouse: true
                                    font.pixelSize: 10
                                    onEditingFinished: SettingsController.hotkeyText = text
                                    Accessible.name: qsTr("语音键组合键")
                                }
                                AppButton {
                                    objectName: "recordShortcut_" + mappingRow.buttonId
                                    theme: tokens
                                    text: qsTr("录")
                                    Layout.preferredWidth: 28
                                    Layout.fillHeight: true
                                    leftPadding: 0
                                    rightPadding: 0
                                    font.pixelSize: 10
                                    onClicked: root.openShortcutRecorder(
                                        mappingRow.buttonId, mappingRow.index,
                                        true, "single_click"
                                    )
                                    Accessible.name: qsTr("录制语音键快捷键")
                                }
                            }
                        }
                    }
                }
            }

            Canvas {
                id: lineCanvas
                objectName: "mappingConnectorCanvas"
                anchors.fill: parent
                // The connector must remain visible across the remote photo so
                // each card points to the physical key center, while the
                // cards themselves remain above the canvas for interaction.
                z: 3.5
                renderTarget: Canvas.FramebufferObject

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    if (!SettingsController.photoAvailable || remotePhotoImage.paintedWidth <= 0)
                        return

                    var imageOrigin = remotePhotoImage.mapToItem(lineCanvas, 0, 0)
                    var paintedW = remotePhotoImage.paintedWidth
                    var paintedH = remotePhotoImage.paintedHeight
                    var imageX = imageOrigin.x + (remotePhotoImage.width - paintedW) / 2
                    var imageY = imageOrigin.y + (remotePhotoImage.height - paintedH) / 2

                    ctx.lineWidth = 1.15
                    for (var i = 0; i < mappingRepeater.count; i++) {
                        var card = mappingRepeater.itemAt(i)
                        if (!card)
                            continue
                        var target = card.mapToItem(lineCanvas, card.width / 2, card.height / 2)
                        var startX = imageX + card.hotspotX * paintedW
                        var startY = imageY + card.hotspotY * paintedH
                        var endX = root.isLeft(i)
                            ? target.x + card.width / 2 - 4
                            : target.x - card.width / 2 + 4
                        var direction = root.isLeft(i) ? -1 : 1
                        var bend = Math.max(26, Math.abs(endX - startX) * 0.34)

                        ctx.beginPath()
                        ctx.moveTo(startX, startY)
                        ctx.bezierCurveTo(
                            startX + direction * bend, startY,
                            endX - direction * bend, target.y,
                            endX, target.y
                        )
                        ctx.strokeStyle = card.isSelected
                            ? tokens.accent
                            : Qt.rgba(tokens.textSecondary.r, tokens.textSecondary.g, tokens.textSecondary.b, 0.42)
                        ctx.globalAlpha = card.isSelected ? 0.95 : 0.72
                        ctx.stroke()
                    }
                    ctx.globalAlpha = 1
                }
            }

            Item {
                id: remoteStage
                objectName: "remoteStage"
                width: mappingStage.remoteColumnWidth
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                z: 3

                Rectangle {
                    id: photoFrame
                    objectName: "photoFrame"
                    width: Math.min(210, parent.width - 16)
                    height: Math.min(parent.height - 18, width * root.photoAspectRatio)
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 18
                    color: tokens.surface
                    border.color: tokens.border
                    border.width: 1
                    clip: true

                    Image {
                        id: remotePhotoImage
                        objectName: "photoImage"
                        anchors.fill: parent
                        anchors.margins: 7
                        fillMode: Image.PreserveAspectFit
                        source: SettingsController.photoAvailable ? SettingsController.photoSource : ""
                        visible: SettingsController.photoAvailable
                        smooth: true
                        asynchronous: true
                        onPaintedWidthChanged: lineCanvas.requestPaint()
                        onPaintedHeightChanged: lineCanvas.requestPaint()
                    }

                    Label {
                        anchors.centerIn: parent
                        anchors.margins: tokens.spacingLarge
                        width: parent.width - tokens.spacingMedium * 2
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        visible: !SettingsController.photoAvailable
                        text: qsTr("实物图资源缺失")
                        color: tokens.textSecondary
                        font.pixelSize: tokens.fontSizeSmall
                    }

                    Repeater {
                        model: ButtonMappingModel

                        delegate: Item {
                            id: hotspot
                            objectName: "photoHotspot_" + buttonId

                            required property string buttonId
                            required property string displayName
                            required property real hotspotX
                            required property real hotspotY
                            required property real hotspotWidth
                            required property real hotspotHeight
                            required property bool isSelected
                            required property bool isVoice

                            readonly property real paintedW: remotePhotoImage.paintedWidth
                            readonly property real paintedH: remotePhotoImage.paintedHeight
                            readonly property real offsetX: remotePhotoImage.x + (
                                remotePhotoImage.width - paintedW
                            ) / 2
                            readonly property real offsetY: remotePhotoImage.y + (
                                remotePhotoImage.height - paintedH
                            ) / 2

                            width: hotspotWidth * paintedW
                            height: hotspotHeight * paintedH
                            x: offsetX + hotspotX * paintedW - width / 2
                            y: offsetY + hotspotY * paintedH - height / 2
                            visible: SettingsController.photoAvailable

                            activeFocusOnTab: true
                            Accessible.role: Accessible.Button
                            Accessible.name: displayName

                            Rectangle {
                                anchors.fill: parent
                                radius: height / 2
                                color: hotspot.isSelected
                                    ? Qt.rgba(tokens.accent.r, tokens.accent.g, tokens.accent.b, 0.28)
                                    : (hotspotHover.hovered
                                        ? Qt.rgba(tokens.accent.r, tokens.accent.g, tokens.accent.b, 0.14)
                                        : "transparent")
                                border.width: hotspot.isSelected ? 2 : (hotspot.activeFocus ? 1 : 0)
                                border.color: hotspot.isVoice ? tokens.voiceAccent : tokens.accent
                            }

                            HoverHandler { id: hotspotHover }
                            TapHandler { onTapped: SettingsController.selectButton(hotspot.buttonId) }
                            Keys.onReturnPressed: SettingsController.selectButton(hotspot.buttonId)
                            Keys.onSpacePressed: SettingsController.selectButton(hotspot.buttonId)
                        }
                    }
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: photoFrame.bottom
                    anchors.topMargin: 5
                    text: qsTr("点击遥控器按键定位")
                    color: tokens.textSecondary
                    font.pixelSize: 10
                }
            }
        }

        Rectangle {
            id: mappingFooter
            objectName: "mappingFooter"
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            radius: 15
            color: tokens.surface
            border.color: tokens.border
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 10

                Text {
                    text: "⌨"
                    font.family: "Segoe UI Symbol"
                    color: tokens.textSecondary
                    font.pixelSize: 18
                }
                ColumnLayout {
                    Layout.preferredWidth: 150
                    spacing: 0
                    Label {
                        text: qsTr("按键映射")
                        color: tokens.textPrimary
                        font.pixelSize: tokens.fontSizeSmall
                        font.bold: true
                    }
                    Label {
                        text: qsTr("13 个实体按键")
                        color: tokens.textSecondary
                        font.pixelSize: 10
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 32
                    color: tokens.border
                }

                Label {
                    Layout.fillWidth: true
                    Layout.maximumWidth: 330
                    text: SettingsController.errorMessage.length > 0
                        ? SettingsController.errorMessage
                        : (SettingsController.statusMessage.length > 0
                            ? SettingsController.statusMessage
                            : qsTr("修改后点击“保存映射”；恢复默认也需要保存才会写入设置。"))
                    color: SettingsController.errorMessage.length > 0
                        ? tokens.errorColor
                        : (SettingsController.statusMessage.length > 0
                            ? tokens.successColor : tokens.textSecondary)
                    font.pixelSize: 10
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                AppButton {
                    id: restoreDefaultsButton
                    objectName: "restoreDefaultsButton"
                    theme: tokens
                    text: qsTr("恢复默认")
                    Layout.preferredHeight: 32
                    onClicked: SettingsController.restoreDefaults()
                }
                AppButton {
                    id: saveMappingButton
                    objectName: "saveMappingButton"
                    theme: tokens
                    text: qsTr("保存映射")
                    highlighted: true
                    Layout.preferredHeight: 32
                    onClicked: SettingsController.saveSettings()
                }
            }
        }
    }

    function iconFor(buttonId) {
        var icons = {
            power: "⏻",
            up: "⌃",
            left: "‹",
            ok: "◎",
            right: "›",
            down: "⌄",
            back: "↶",
            volume_up: "＋",
            home: "⌂",
            volume_down: "−",
            menu: "≡",
            tv: "▣"
        }
        return icons[buttonId] || "•"
    }

    Connections {
        target: SettingsController
        function onSelectedButtonIdChanged() {
            mappingList.currentIndex = ButtonMappingModel.indexOfButton(
                SettingsController.selectedButtonId
            )
            lineCanvas.requestPaint()
        }
    }
}
