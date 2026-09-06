// "权限" tab (XRBM-030 In-scope item 6): Windows' real permission surfaces
// for this app - Bluetooth pairing, microphone/speech recognition (Win+H
// dictation depends on it), and log-directory diagnostics. This page never
// renders a fabricated "已授权" state: Windows does not expose a single API
// this app can query for all of these states, so every row only offers to OPEN
// the relevant Settings page/log folder and states plainly what it is for.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import OvbRc003Settings 1.0

Item {
    id: root
    property var tokens

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: root.width - tokens.spacingLarge * 2
            x: tokens.spacingLarge
            y: tokens.spacingLarge
            spacing: tokens.spacingLarge

            Rectangle {
                Layout.fillWidth: true
                radius: tokens.cornerRadiusLarge
                color: tokens.surface
                border.color: tokens.border
                border.width: 1
                implicitHeight: permissionsColumn.implicitHeight + tokens.spacingLarge * 2

                ColumnLayout {
                    id: permissionsColumn
                    anchors.fill: parent
                    anchors.margins: tokens.spacingLarge
                    spacing: tokens.spacingLarge

                    Label {
                        text: qsTr("所需权限")
                        font.pixelSize: tokens.fontSizeTitle
                        font.bold: true
                        color: tokens.textPrimary
                    }

                    // -- Bluetooth --------------------------------------------
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: tokens.spacingMedium
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Label {
                                text: qsTr("蓝牙")
                                color: tokens.textPrimary
                                font.pixelSize: tokens.fontSizeBody
                            }
                            Label {
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                text: qsTr("在 Windows 蓝牙设置中配对 RC003，再回到连接与配置页启动遥控器服务。")
                                color: tokens.textSecondary
                                font.pixelSize: tokens.fontSizeSmall
                            }
                        }
                        AppButton {
                            text: qsTr("打开蓝牙设置")
                            onClicked: SettingsController.openBluetoothSettings()
                        }
                    }

                    // -- Microphone / speech recognition ----------------------
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: tokens.spacingMedium
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Label {
                                text: qsTr("麦克风与语音识别")
                                color: tokens.textPrimary
                                font.pixelSize: tokens.fontSizeBody
                            }
                            Label {
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                text: qsTr("遥控器的语音键会按“连接与配置”页选择的语音软件预设发送快捷键。"
                                    + "如果目标软件有麦克风下拉框，请选择 VB-CABLE 的 CABLE Output；"
                                    + "程序会把遥控器声音写入同一条虚拟声卡通道。")
                                color: tokens.textSecondary
                                font.pixelSize: tokens.fontSizeSmall
                            }
                        }
                        ColumnLayout {
                            spacing: tokens.spacingTiny
                            AppButton {
                                text: qsTr("打开麦克风隐私设置")
                                onClicked: SettingsController.openMicrophonePrivacySettings()
                            }
                            AppButton {
                                text: qsTr("打开语音识别设置")
                                onClicked: SettingsController.openSpeechSettings()
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                radius: tokens.cornerRadiusLarge
                color: tokens.surface
                border.color: tokens.border
                border.width: 1
                implicitHeight: diagnosticsColumn.implicitHeight + tokens.spacingLarge * 2

                ColumnLayout {
                    id: diagnosticsColumn
                    anchors.fill: parent
                    anchors.margins: tokens.spacingLarge
                    spacing: tokens.spacingSmall

                    Label {
                        text: qsTr("诊断")
                        font.pixelSize: tokens.fontSizeTitle
                        font.bold: true
                        color: tokens.textPrimary
                    }
                    RowLayout {
                        spacing: tokens.spacingMedium
                        Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            text: qsTr("遇到连接或输入问题时，可以打开日志查看运行记录。")
                            color: tokens.textSecondary
                            font.pixelSize: tokens.fontSizeSmall
                        }
                        AppButton {
                            text: qsTr("打开日志目录")
                            onClicked: SettingsController.openLogLocation()
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        visible: text.length > 0
                        text: SettingsController.statusMessage
                        color: tokens.successColor
                        font.pixelSize: tokens.fontSizeSmall
                    }
                }
            }

            Item { Layout.preferredHeight: tokens.spacingLarge }
        }
    }
}
