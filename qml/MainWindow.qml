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
    minimumHeight: Math.max(460, currentPage ? currentPage.implicitHeight + 52 : 0)
    title: qsTr("Calculator")
    // Fluent's Fusion fallback Labels otherwise retain the native text color
    // when an application override first changes the scheme.
    palette.windowText: Application.styleHints.colorScheme === Qt.Dark ? "#ffffff" : "#1b1b1b"
    readonly property Item currentPage: page.item as Item
    property int currentMode: 0
    property bool settingsOpen: false
    readonly property bool historyAvailable: !settingsOpen && ["standard", "scientific"].indexOf(ModeRegistry.modes[currentMode].key) !== -1
    readonly property bool historySidebarVisible: historyAvailable && width >= 560
    onHistorySidebarVisibleChanged: if (historySidebarVisible) historyDrawer.close()
    onHistoryAvailableChanged: if (!historyAvailable) historyDrawer.close()
    property SystemPreferences systemPreferences
    AppPreferences { id: appPreferences; systemPreferences: window.systemPreferences }
    CalculationSession { id: calculator; language: appPreferences.effectiveLanguage }

    function loadMode() {
        calculator.selectMode(ModeRegistry.modes[currentMode].key)
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
            ToolButton {
                objectName: "historyButton"
                text: qsTr("History")
                visible: window.historyAvailable && !window.historySidebarVisible
                onClicked: historyDrawer.open()
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: window.settingsOpen ? 1 : 0
                Loader {
                    id: page
                    focus: true
                    enabled: !historyDrawer.visible
                    Component.onCompleted: window.loadMode()
                }
                SettingsPage { preferences: appPreferences }
            }
            HistoryPanel {
                objectName: "historySidebar"
                session: calculator
                visible: window.historySidebarVisible
                // Pinned Calculator.xaml: 320:240 columns from 560px, history capped at 320px.
                Layout.preferredWidth: Math.min(320, (window.width - 12) * 240 / 560)
                Layout.fillHeight: true
            }
        }
    }

    Drawer {
        id: historyDrawer
        objectName: "historyDrawer"
        edge: Qt.BottomEdge
        width: window.width
        height: window.height * 0.7
        modal: true
        interactive: window.historyAvailable && !window.historySidebarVisible
        onClosed: page.forceActiveFocus()
        onOpened: contentItem.forceActiveFocus()
        HistoryPanel {
            anchors.fill: parent
            session: calculator
            dismissible: true
            onCloseRequested: historyDrawer.close()
            onRecordReused: historyDrawer.close()
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
