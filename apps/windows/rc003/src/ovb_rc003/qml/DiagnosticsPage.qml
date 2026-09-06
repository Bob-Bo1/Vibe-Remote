// "诊断" tab: a small, honest place for runtime status and logs.
// Connection-specific checks remain inline on "连接与配置", where the user
// can act on them immediately. This page does not duplicate Windows settings
// or present a second check-and-repair workflow.
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
                        Layout.fillWidth: true
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
                        visible: SettingsController.statusMessage.length > 0
                        text: SettingsController.statusMessage
                        color: SettingsController.errorMessage.length > 0
                            ? tokens.errorColor : tokens.successColor
                        font.pixelSize: tokens.fontSizeSmall
                    }

                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: qsTr("连接、VB-CABLE 和语音软件的配置状态，请回到“连接与配置”页查看。")
                        color: tokens.textSecondary
                        font.pixelSize: tokens.fontSizeSmall
                    }
                }
            }

            Item { Layout.preferredHeight: tokens.spacingLarge }
        }
    }
}
