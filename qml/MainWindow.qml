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
    property int currentMode: 0
    readonly property Item currentPage: page.item as Item
    CalculationSession { id: calculator }

    function loadMode() {
        calculator.selectMode(ModeRegistry.modes[currentMode].key)
        page.setSource(ModeRegistry.modes[currentMode].source, { session: calculator })
    }
    onCurrentModeChanged: loadMode()

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
                objectName: "modeTitle"
                text: ModeRegistry.modes[window.currentMode].title
                font.pixelSize: 20
                font.bold: true
                Layout.fillWidth: true
            }
        }
        Loader {
            id: page
            focus: true
            Layout.fillWidth: true
            Layout.fillHeight: true
            Component.onCompleted: window.loadMode()
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
                    highlighted: index === window.currentMode
                    onClicked: {
                        window.currentMode = index
                        navigation.close()
                    }
                }
            }
            Item { Layout.fillHeight: true }
        }
    }
}
