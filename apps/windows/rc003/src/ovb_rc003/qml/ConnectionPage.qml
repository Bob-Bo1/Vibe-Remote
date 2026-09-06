// Primary setup flow for RC003 and the standalone DJI Mic 2 input.
// The page is ordered by what a user needs to finish. Implementation-only
// details such as the HID tap stay as an inline status.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import OvbRc003Settings 1.0

Item {
    id: root
    property var tokens
    property int diagnosticsRevision: 0

    function cableCheck() {
        var rows = DiagnosticsController.checkResults
        for (var i = 0; i < rows.length; i++) {
            if (rows[i].checkId === "vb_cable_endpoints")
                return rows[i]
        }
        return { status: "checking", detail: qsTr("正在检查 CABLE Input 和 CABLE Output…") }
    }

    function cableReady() {
        diagnosticsRevision
        return cableCheck().status === "pass"
    }

    function cableRestartRequired() {
        diagnosticsRevision
        return DiagnosticsController.driverRestartRequired && !cableReady()
    }

    function cableStatusLabel() {
        diagnosticsRevision
        var status = cableCheck().status
        if (status === "pass") return qsTr("已检测到")
        if (cableRestartRequired()) return qsTr("等待重启")
        if (status === "fail") return qsTr("未配置（可选）")
        if (status === "unsupported") return qsTr("暂时无法检测")
        return qsTr("正在检测")
    }

    function cableStatusColor() {
        diagnosticsRevision
        var status = cableCheck().status
        if (status === "pass") return tokens.successColor
        if (cableRestartRequired()) return tokens.voiceAccent
        if (status === "fail") return tokens.voiceAccent
        return tokens.voiceAccent
    }

    function cableDescription() {
        diagnosticsRevision
        if (root.cableReady())
            return qsTr("已检测到 CABLE Input 和 CABLE Output。点击“使用 CABLE Input”后，遥控器麦克风声音会进入微信或豆包；未选择时，录音软件使用 Windows 默认麦克风。")
        if (root.cableRestartRequired())
            return qsTr("安装程序已打开。完成安装后请重启电脑，回来后点击“重新检测”。")
        if (root.cableCheck().status === "fail")
            return qsTr("可选：选择 CABLE Input 后，遥控器麦克风声音会进入微信或豆包；未选择时，录音软件使用 Windows 默认麦克风。")
        return root.cableCheck().detail
    }

    Dialog {
        id: cableConfirmDialog
        objectName: "connectionCableConfirmDialog"
        title: qsTr("安装 VB-CABLE？")
        modal: true
        anchors.centerIn: parent
        width: 460
        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: DiagnosticsController.launchVbCableSetup()

        Label {
            width: parent.width - 32
            wrapMode: Text.WordWrap
            text: qsTr("将启动 VB-Audio 官方 VB-CABLE 安装程序。安装会请求管理员权限，"
                + "并修改 Windows 音频设备；安装完成后需要重启电脑。程序不会自动修改"
                + "Windows 默认输入/输出设备。重启后回到这里点击“重新检测”。")
            color: tokens.textPrimary
        }
    }

    ScrollView {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: saveFooter.top
        clip: true
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: root.width - tokens.spacingLarge * 2
            x: tokens.spacingLarge
            y: tokens.spacingLarge
            spacing: 14

            // -- Device and real connection state ----------------------------
            Rectangle {
                Layout.fillWidth: true
                radius: tokens.cornerRadiusLarge
                color: tokens.surface
                border.color: SettingsController.connectionState === "connected"
                    ? tokens.successColor : tokens.border
                border.width: SettingsController.connectionState === "connected" ? 2 : 1
                implicitHeight: deviceHeader.implicitHeight + tokens.spacingLarge * 2

                RowLayout {
                    id: deviceHeader
                    anchors.fill: parent
                    anchors.margins: tokens.spacingLarge
                    spacing: tokens.spacingMedium

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        Label {
                            text: qsTr("当前设备")
                            font.pixelSize: tokens.fontSizeSmall
                            color: tokens.textSecondary
                        }
                        AppComboBox {
                            id: deviceCombo
                            objectName: "deviceCombo"
                            Layout.fillWidth: true
                            model: SettingsController.deviceOptions
                            currentIndex: SettingsController.selectedDeviceIndex
                            onActivated: SettingsController.selectedDeviceIndex = index
                            enabled: SettingsController.deviceCatalogAvailable
                            Accessible.name: qsTr("当前设备")
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        color: tokens.border
                    }

                    ColumnLayout {
                        Layout.preferredWidth: 220
                        spacing: 4
                        RowLayout {
                            spacing: 8
                            Rectangle {
                                width: 10; height: 10; radius: 5
                                color: SettingsController.connectionState === "connected"
                                    ? tokens.successColor
                                    : (SettingsController.connectionState === "error"
                                        ? tokens.errorColor : tokens.voiceAccent)
                            }
                            Label {
                                text: {
                                    var state = SettingsController.connectionState
                                    if (state === "connected") return qsTr("已连接")
                                    if (state === "connecting") return qsTr("连接中")
                                    if (state === "waiting") return qsTr("等待遥控器")
                                    if (state === "error") return qsTr("连接需要处理")
                                    return qsTr("未连接")
                                }
                                font.pixelSize: tokens.fontSizeBody
                                font.bold: true
                                color: tokens.textPrimary
                            }
                        }
                        Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            text: SettingsController.isRc003Device
                                ? qsTr("连接后会自动准备全部按键")
                                : qsTr("使用 Windows 系统麦克风输入")
                            color: tokens.textSecondary
                            font.pixelSize: tokens.fontSizeSmall
                        }
                    }

                    AppButton {
                        id: saveAndLaunchButton
                        objectName: "saveAndLaunchButton"
                        text: SettingsController.connectionState === "connected"
                            ? qsTr("重新连接") : qsTr("连接")
                        highlighted: true
                        enabled: SettingsController.isRc003Device
                            && SettingsController.connectionState !== "connecting"
                        onClicked: SettingsController.saveAndLaunch()
                    }
                }
            }

            Label {
                visible: !SettingsController.deviceCatalogAvailable
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: SettingsController.deviceCatalogErrorText
                color: tokens.errorColor
                font.pixelSize: tokens.fontSizeSmall
            }

            // -- Ordered setup rail ------------------------------------------
            Item {
                visible: SettingsController.isRc003Device
                Layout.fillWidth: true
                implicitHeight: setupColumn.implicitHeight

                Rectangle {
                    x: 17
                    y: 22
                    width: 2
                    height: Math.max(0, parent.height - 44)
                    color: tokens.border
                }

                ColumnLayout {
                    id: setupColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 12

                    // Step 1: connection and automatic full-key readiness.
                    Rectangle {
                        Layout.fillWidth: true
                        radius: tokens.cornerRadiusLarge
                        color: tokens.surface
                        border.color: tokens.border
                        border.width: 1
                        implicitHeight: connectionStepColumn.implicitHeight + 28

                        RowLayout {
                            id: connectionStepColumn
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 14

                            Rectangle {
                                Layout.alignment: Qt.AlignTop
                                width: 34; height: 34; radius: 17
                                color: tokens.accent
                                Label {
                                    anchors.centerIn: parent
                                    text: "1"
                                    color: tokens.accentText
                                    font.pixelSize: 15
                                    font.bold: true
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 5
                                Label {
                                    text: qsTr("连接设备")
                                    font.pixelSize: tokens.fontSizeTitle
                                    font.bold: true
                                    color: tokens.textPrimary
                                }
                                Label {
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    text: qsTr("先完成蓝牙连接。程序会在连接过程中自动准备返回、音量等特殊按键，"
                                        + "只有第一次需要时才会请求一次授权。")
                                    color: tokens.textSecondary
                                    font.pixelSize: tokens.fontSizeSmall
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    Rectangle {
                                        width: 8; height: 8; radius: 4
                                        color: SettingsController.fullKeysStatus === "全部按键已就绪"
                                            ? tokens.successColor : tokens.voiceAccent
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                        text: qsTr("按键支持：") + SettingsController.fullKeysStatus
                                        color: tokens.textSecondary
                                        font.pixelSize: tokens.fontSizeSmall
                                    }
                                    AppButton {
                                        visible: SettingsController.fullKeysStatus !== "全部按键已就绪"
                                        text: qsTr("重新准备")
                                        onClicked: SettingsController.prepareFullKeys()
                                    }
                                }
                            }
                        }
                    }

                    // Step 2: virtual audio route.
                    Rectangle {
                        Layout.fillWidth: true
                        radius: tokens.cornerRadiusLarge
                        color: tokens.surface
                        border.color: root.cableReady()
                            ? tokens.successColor
                            : (root.cableRestartRequired() ? tokens.voiceAccent : tokens.border)
                        border.width: root.cableReady() || root.cableRestartRequired() ? 2 : 1
                        implicitHeight: cableStepColumn.implicitHeight + 28

                        RowLayout {
                            id: cableStepColumn
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 14

                            Rectangle {
                                Layout.alignment: Qt.AlignTop
                                width: 34; height: 34; radius: 17
                                color: root.cableReady() ? tokens.successColor : tokens.voiceAccent
                                Label {
                                    anchors.centerIn: parent
                                    text: "2"
                                    color: "white"
                                    font.pixelSize: 15
                                    font.bold: true
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 5
                                RowLayout {
                                    Layout.fillWidth: true
                                    Label {
                                        Layout.fillWidth: true
                                        text: qsTr("准备语音通道（可选）")
                                        font.pixelSize: tokens.fontSizeTitle
                                        font.bold: true
                                        color: tokens.textPrimary
                                    }
                                    Label {
                                        text: root.cableStatusLabel()
                                        color: root.cableStatusColor()
                                        font.pixelSize: tokens.fontSizeSmall
                                        font.bold: true
                                    }
                                }
                                Label {
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    text: root.cableDescription()
                                    color: tokens.textSecondary
                                    font.pixelSize: tokens.fontSizeSmall
                                }
                                RowLayout {
                                    spacing: 8
                                    AppButton {
                                        visible: !root.cableReady() && !root.cableRestartRequired()
                                        text: qsTr("安装 VB-CABLE")
                                        highlighted: true
                                        onClicked: cableConfirmDialog.open()
                                    }
                                    AppButton {
                                        visible: root.cableReady()
                                        text: qsTr("使用 CABLE Input")
                                        onClicked: DiagnosticsController.selectDetectedCableInputAsOutput()
                                    }
                                    AppButton {
                                        text: qsTr("重新检测")
                                        enabled: !DiagnosticsController.isRefreshing
                                        onClicked: DiagnosticsController.refreshDiagnostics()
                                    }
                                }
                                Rectangle {
                                    objectName: "cableRestartNotice"
                                    Layout.fillWidth: true
                                    visible: root.cableRestartRequired()
                                    radius: tokens.cornerRadiusSmall
                                    color: tokens.dark ? "#3A2B15" : "#FFF4DF"
                                    border.color: tokens.voiceAccent
                                    border.width: 1
                                    implicitHeight: restartNoticeColumn.implicitHeight + 16

                                    ColumnLayout {
                                        id: restartNoticeColumn
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.margins: 8
                                        spacing: 3
                                        Label {
                                            text: qsTr("安装后需要重启电脑")
                                            color: tokens.voiceAccent
                                            font.pixelSize: tokens.fontSizeBody
                                            font.bold: true
                                        }
                                        Label {
                                            Layout.fillWidth: true
                                            wrapMode: Text.WordWrap
                                            text: qsTr("请完成 VB-CABLE 安装并重启 Windows。重启后打开本工具，点击“重新检测”确认语音通道。")
                                            color: tokens.textPrimary
                                            font.pixelSize: tokens.fontSizeSmall
                                        }
                                    }
                                }
                                Label {
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    visible: DiagnosticsController.driverInfoMessage.length > 0
                                    text: DiagnosticsController.driverInfoMessage
                                    color: tokens.textSecondary
                                    font.pixelSize: tokens.fontSizeSmall
                                }
                                Label {
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    visible: DiagnosticsController.driverErrorMessage.length > 0
                                    text: DiagnosticsController.driverErrorMessage
                                    color: tokens.errorColor
                                    font.pixelSize: tokens.fontSizeSmall
                                }
                            }
                        }
                    }

                    // Step 3: choose a named voice app preset.
                    Rectangle {
                        Layout.fillWidth: true
                        radius: tokens.cornerRadiusLarge
                        color: tokens.surface
                        border.color: tokens.border
                        border.width: 1
                        implicitHeight: voiceStepColumn.implicitHeight + 28

                        RowLayout {
                            id: voiceStepColumn
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 14

                            Rectangle {
                                Layout.alignment: Qt.AlignTop
                                width: 34; height: 34; radius: 17
                                color: tokens.accent
                                Label {
                                    anchors.centerIn: parent
                                    text: "3"
                                    color: tokens.accentText
                                    font.pixelSize: 15
                                    font.bold: true
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 7
                                Label {
                                    text: qsTr("选择语音软件")
                                    font.pixelSize: tokens.fontSizeTitle
                                    font.bold: true
                                    color: tokens.textPrimary
                                }
                                AppComboBox {
                                    id: voiceAppCombo
                                    objectName: "voiceAppCombo"
                                    Layout.fillWidth: true
                                    model: SettingsController.voiceAppOptions
                                    currentIndex: SettingsController.voiceAppIndex
                                    onActivated: SettingsController.voiceAppIndex = index
                                    Accessible.name: qsTr("语音软件")
                                }
                                Label {
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    text: SettingsController.voiceAppDescription
                                    color: tokens.textSecondary
                                    font.pixelSize: tokens.fontSizeSmall
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    Label {
                                        text: qsTr("当前快捷键")
                                        color: tokens.textSecondary
                                        font.pixelSize: tokens.fontSizeSmall
                                    }
                                    Label {
                                        text: SettingsController.voiceHotkeyDisplay
                                        color: tokens.accent
                                        font.pixelSize: tokens.fontSizeBody
                                        font.bold: true
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        text: SettingsController.voiceAppIsCustom
                                            ? qsTr("可在下方填写") : qsTr("已按该软件的方式配置")
                                        color: tokens.textSecondary
                                        font.pixelSize: tokens.fontSizeSmall
                                    }
                                }
                                GridLayout {
                                    visible: SettingsController.voiceAppIsCustom
                                    Layout.fillWidth: true
                                    columns: 2
                                    columnSpacing: 12
                                    rowSpacing: 7
                                    Label { text: qsTr("快捷键"); color: tokens.textPrimary }
                                    AppTextField {
                                        id: customHotkeyField
                                        objectName: "hotkeyField"
                                        Layout.fillWidth: true
                                        text: SettingsController.hotkeyText
                                        selectByMouse: true
                                        onEditingFinished: SettingsController.hotkeyText = text
                                    }
                                    Label { text: qsTr("触发方式"); color: tokens.textPrimary }
                                    AppComboBox {
                                        Layout.fillWidth: true
                                        model: SettingsController.triggerModeOptions
                                        currentIndex: SettingsController.triggerModeIndex
                                        onActivated: SettingsController.triggerModeIndex = index
                                    }
                                }
                            }
                        }
                    }

                    // Step 4: close the loop with a concrete test action.
                    Rectangle {
                        Layout.fillWidth: true
                        radius: tokens.cornerRadiusLarge
                        color: Qt.alpha(tokens.accent, 0.08)
                        border.color: Qt.alpha(tokens.accent, 0.30)
                        border.width: 1
                        implicitHeight: testStepColumn.implicitHeight + 28

                        RowLayout {
                            id: testStepColumn
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 14
                            Rectangle {
                                Layout.alignment: Qt.AlignTop
                                width: 34; height: 34; radius: 17
                                color: tokens.accent
                                Label {
                                    anchors.centerIn: parent
                                    text: "4"
                                    color: tokens.accentText
                                    font.pixelSize: 15
                                    font.bold: true
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 5
                                Label {
                                    text: qsTr("完成测试")
                                    font.pixelSize: tokens.fontSizeTitle
                                    font.bold: true
                                    color: tokens.textPrimary
                                }
                                Label {
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    text: qsTr("点击上方“连接”，然后按一次遥控器按键；需要语音时，按住语音键说一句话。"
                                        + "右上角显示“已连接”后，才代表 BLE 会话真正建立。")
                                    color: tokens.textSecondary
                                    font.pixelSize: tokens.fontSizeSmall
                                }
                                RowLayout {
                                    spacing: 8
                                    Label {
                                        text: qsTr("按键映射可在左侧继续设置")
                                        color: tokens.textSecondary
                                        font.pixelSize: tokens.fontSizeSmall
                                    }
                                    AppButton {
                                        id: openLogButton
                                        objectName: "openLogButton"
                                        text: qsTr("打开日志目录")
                                        onClicked: SettingsController.openLogLocation()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // DJI Mic 2 has its own short workflow and never shows RC003
            // Bluetooth, HID, ATVV, or VB-CABLE steps.
            Rectangle {
                visible: SettingsController.isDjiMic2Device
                Layout.fillWidth: true
                radius: tokens.cornerRadiusLarge
                color: tokens.surface
                border.color: tokens.border
                border.width: 1
                implicitHeight: djiInputColumn.implicitHeight + tokens.spacingLarge * 2

                ColumnLayout {
                    id: djiInputColumn
                    anchors.fill: parent
                    anchors.margins: tokens.spacingLarge
                    spacing: tokens.spacingSmall
                    Label {
                        text: qsTr("DJI Mic 2 录音输入")
                        font.pixelSize: tokens.fontSizeTitle
                        font.bold: true
                        color: tokens.textPrimary
                    }
                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: SettingsController.djiMicStatusText
                        color: tokens.textSecondary
                        font.pixelSize: tokens.fontSizeBody
                    }
                    RowLayout {
                        spacing: tokens.spacingSmall
                        AppButton {
                            text: qsTr("重新检测")
                            onClicked: SettingsController.refreshDjiMicStatus()
                        }
                        AppButton {
                            text: qsTr("打开 Windows 声音输入设置")
                            highlighted: true
                            onClicked: SettingsController.openSoundSettings()
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: tokens.spacingLarge }
        }
    }

    Rectangle {
        id: saveFooter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Math.max(76, footerContent.implicitHeight + 28)
        color: tokens.background
        Rectangle { width: parent.width; height: 1; color: tokens.border }
        RowLayout {
            id: footerContent
            anchors.fill: parent
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            anchors.topMargin: 14
            anchors.bottomMargin: 14
            spacing: 12
            Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: SettingsController.errorMessage.length > 0
                    ? SettingsController.errorMessage
                    : (SettingsController.statusMessage.length > 0
                        ? SettingsController.statusMessage : qsTr("修改后，点击保存并应用。"))
                color: SettingsController.errorMessage.length > 0
                    ? tokens.errorColor
                    : (SettingsController.statusMessage.length > 0
                        ? tokens.successColor : tokens.textSecondary)
                font.pixelSize: tokens.fontSizeSmall
            }
            AppButton {
                visible: SettingsController.isRc003Device
                text: qsTr("恢复全部默认")
                onClicked: SettingsController.restoreDefaults()
            }
            AppButton {
                objectName: "deviceSaveButton"
                text: SettingsController.isRc003Device ? qsTr("保存并应用") : qsTr("保存设备选择")
                highlighted: true
                onClicked: SettingsController.saveSettings()
            }
        }
    }

    Connections {
        target: DiagnosticsController
        function onCheckResultsChanged() { root.diagnosticsRevision += 1 }
    }
}
