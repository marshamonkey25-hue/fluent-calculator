pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Pane {
    id: panel
    required property CalculationSession session
    property bool dismissible: false
    signal closeRequested()
    signal recordReused()
    ColumnLayout {
        anchors.fill: parent
        RowLayout {
            Layout.fillWidth: true
            Label {
                objectName: "historyTitle"
                text: qsTr("History")
                font.bold: true
                font.pixelSize: 18
                Layout.fillWidth: true
            }
            ToolButton {
                objectName: "closeHistoryButton"
                text: qsTr("Close")
                visible: panel.dismissible
                onClicked: panel.closeRequested()
            }
        }
        Label {
            objectName: "historyEmpty"
            text: qsTr("There's no history yet")
            visible: historyList.count === 0
            Layout.fillWidth: true
            wrapMode: Text.Wrap
        }
        ListView {
            id: historyList
            objectName: "historyList"
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: panel.session.history
            spacing: 4
            ScrollBar.vertical: ScrollBar {}
            delegate: ItemDelegate {
                id: row
                required property var modelData
                required property int index
                objectName: "historyItem_" + index
                width: historyList.width
                contentItem: ColumnLayout {
                    Label {
                        objectName: "historyExpression_" + row.index
                        text: row.modelData.expression
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                        wrapMode: Text.WrapAnywhere
                    }
                    Label {
                        objectName: "historyResult_" + row.index
                        text: row.modelData.result
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                        wrapMode: Text.WrapAnywhere
                        font.pixelSize: 24
                        font.bold: true
                    }
                }
                Accessible.name: modelData.expression + " " + modelData.result
                onClicked: {
                    panel.session.reuseHistory(index)
                    panel.recordReused()
                }
                TapHandler {
                    acceptedButtons: Qt.RightButton
                    onTapped: historyMenu.popup()
                }
                Keys.onMenuPressed: historyMenu.popup()
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_F10 && (event.modifiers & Qt.ShiftModifier)) {
                        historyMenu.popup()
                        event.accepted = true
                    }
                }
                Menu {
                    id: historyMenu
                    objectName: "historyContextMenu"
                    MenuItem {
                        objectName: "deleteHistoryItem"
                        text: qsTr("Delete")
                        onTriggered: panel.session.removeHistory(row.index)
                    }
                }
            }
        }
        Button {
            objectName: "clearHistoryButton"
            text: qsTr("Clear all history")
            Layout.alignment: Qt.AlignRight
            enabled: historyList.count > 0
            onClicked: panel.session.clearHistory()
        }
    }
}
