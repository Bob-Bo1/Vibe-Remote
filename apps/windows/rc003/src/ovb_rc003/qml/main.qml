import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import OvbRc003Settings 1.0
ApplicationWindow {
    id: window
    title: qsTr("Remote Mic")
    width: 1180; height: 820
    minimumWidth: 1040; minimumHeight: 720
    visible: true
    font.family: "Microsoft YaHei UI"
    font.pixelSize: 14
    property Tokens tokens: Tokens {}
    color: tokens.background
    palette.window: tokens.background
    palette.windowText: tokens.textPrimary
    palette.button: tokens.buttonBackground
    palette.buttonText: tokens.buttonText
    palette.base: tokens.fieldBackground
    palette.text: tokens.textPrimary
    palette.highlight: tokens.accent
    palette.highlightedText: tokens.accentText
    RowLayout {
        anchors.fill: parent
        spacing: 0
        Rectangle {
            Layout.preferredWidth: 202
            Layout.fillHeight: true
            color: tokens.sidebar
            Rectangle { anchors.right: parent.right; height: parent.height; width: 1; color: tokens.border }
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 16
                spacing: 8
                Item { Layout.preferredHeight: 14 }
                Image { source: "assets/app-icon.png"; Layout.preferredWidth: 52; Layout.preferredHeight: 52; smooth: true }
                Label { text: "Remote Mic"; font.pixelSize: 22; font.weight: Font.DemiBold; color: tokens.textPrimary; Layout.topMargin: 5 }
                Label { text: qsTr("随手控制，自在表达"); font.pixelSize: 11; color: tokens.textSecondary }
                Item { Layout.preferredHeight: 28 }
                ColumnLayout {
                    id: tabBar
                    objectName: "tabBar"
                    property int currentIndex: 0
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: [qsTr("连接与配置"), SettingsController.mappingPageTitle, qsTr("系统权限"), qsTr("检查与修复")]
                        delegate: AppButton {
                            id: navButton
                            required property int index
                            required property string modelData
                            objectName: index === 0 ? "connectionTabButton" : (index === 3 ? "diagnosticsTabButton" : "navigationButton" + index)
                            Layout.fillWidth: true
                            implicitHeight: 42
                            text: modelData
                            highlighted: tabBar.currentIndex === index
                            Accessible.name: text
                            Accessible.role: Accessible.PageTab
                            Accessible.selected: highlighted
                            onClicked: tabBar.currentIndex = index
                            contentItem: RowLayout {
                                spacing: 11
                                Image {
                                    source: "assets/nav-" + index + (navButton.highlighted ? "-white" : (tokens.dark ? "-light" : "")) + ".svg"
                                    Layout.preferredWidth: 18; Layout.preferredHeight: 18
                                }
                                Text { text: modelData; font.pixelSize: 13; font.family: window.font.family; color: navButton.highlighted ? "white" : tokens.textPrimary; Layout.fillWidth: true }
                            }
                            background: Rectangle {
                                radius: 9
                                color: navButton.highlighted ? tokens.accent : (navButton.hovered ? tokens.surface : "transparent")
                                border.width: navButton.activeFocus ? 2 : 0
                                border.color: tokens.accent
                            }
                        }
                    }
                }
                Item { Layout.fillHeight: true }
                Rectangle { Layout.fillWidth: true; height: 1; color: tokens.border }
                Label { text: qsTr("小米蓝牙遥控器 2 Pro"); color: tokens.textSecondary; font.pixelSize: 11; Layout.topMargin: 10 }
                Label { text: "RC003  ·  v21"; color: tokens.disabledText; font.pixelSize: 11 }
                Item { Layout.preferredHeight: 6 }
            }
        }
        ColumnLayout {
            Layout.fillWidth: true; Layout.fillHeight: true
            spacing: 0
            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: 24; Layout.bottomMargin: 4
                spacing: 7
                Label {
                    text: [qsTr("连接与配置"), SettingsController.mappingPageTitle, qsTr("系统权限"), qsTr("检查与修复")][tabBar.currentIndex]
                    font.pixelSize: 28; font.weight: Font.DemiBold; color: tokens.textPrimary
                }
                Label {
                    Layout.fillWidth: true
                    text: [qsTr("按顺序完成连接、语音通道和快捷键配置。"), qsTr("点选遥控器上的按键，设置你顺手的操作。"), qsTr("在 Windows 中管理蓝牙、麦克风和语音权限。"), qsTr("查看检测结果，按提示解决连接和输入问题。")][tabBar.currentIndex]
                    font.pixelSize: 13; color: tokens.textSecondary; wrapMode: Text.WordWrap
                }
            }
            StackLayout {
                Layout.fillWidth: true; Layout.fillHeight: true
                currentIndex: tabBar.currentIndex
                ConnectionPage { tokens: window.tokens }
                ButtonsPage { tokens: window.tokens }
                PermissionsPage { tokens: window.tokens }
                DiagnosticsPage { tokens: window.tokens }
            }
        }
    }
}
