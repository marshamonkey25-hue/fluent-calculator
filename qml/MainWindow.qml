pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window
    objectName: "calculatorWindow"
    visible: true
    width: 360
    height: 560
    minimumWidth: 320
    minimumHeight: 460
    title: qsTr("Calculator")
    // Fluent's Fusion fallback Labels otherwise retain the native text color
    // when an application override first changes the scheme.
    palette.windowText: Application.styleHints.colorScheme === Qt.Dark ? "#ffffff" : "#1b1b1b"
    property int currentMode: 0
    property bool settingsOpen: false
    property SystemPreferences systemPreferences
    AppPreferences { id: appPreferences; systemPreferences: window.systemPreferences }
    CalculationSession { id: calculator; language: appPreferences.effectiveLanguage }

    function loadMode() {
        page.setSource(ModeRegistry.modes[currentMode].source, { session: calculator })
    }
    onCurrentModeChanged: {
        loadMode()
        appPreferences.lastMode = ModeRegistry.modes[currentMode].key
    }
    Component.onCompleted: {
        window.currentMode = ModeRegistry.indexForKey(appPreferences.lastMode)
        appPreferences.lastMode = ModeRegistry.modes[window.currentMode].key
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 4
        RowLayout {
            Layout.fillWidth: true
            ToolButton {
                objectName: "navigationButton"
                text: "☰"
                Accessible.name: qsTr("Open navigation")
                onClicked: navigation.open()
            }
            Label {
                objectName: "pageTitle"
                text: window.settingsOpen ? qsTr("Settings") : ModeRegistry.modes[window.currentMode].title
                font.pixelSize: 20
                font.bold: true
                Layout.fillWidth: true
            }
        }
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: window.settingsOpen ? 1 : 0
            Loader {
                id: page
                Component.onCompleted: window.loadMode()
            }
            SettingsPage { preferences: appPreferences }
        }
    }

    Drawer {
        id: navigation
        objectName: "navigationDrawer"
        width: Math.min(window.width - 40, 280)
        height: window.height
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            Label { text: qsTr("Calculator"); font.pixelSize: 20; font.bold: true }
            Repeater {
                model: ModeRegistry.modes
                delegate: ItemDelegate {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    objectName: "mode_" + modelData.key
                    text: modelData.title
                    highlighted: !window.settingsOpen && index === window.currentMode
                    onClicked: {
                        window.settingsOpen = false
                        window.currentMode = index
                        navigation.close()
                    }
                }
            }
            Item { Layout.fillHeight: true }
            ItemDelegate {
                objectName: "settingsButton"
                text: qsTr("Settings")
                Layout.fillWidth: true
                highlighted: window.settingsOpen
                onClicked: {
                    window.settingsOpen = true
                    navigation.close()
                }
            }
        }
    }
}
