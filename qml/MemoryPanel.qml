pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Pane {
    id: panel
    required property CalculationSession session
    property bool dismissible: false
    signal closeRequested()
    signal valueRecalled()
    signal memoryEmptied()
    function deleteFromMenu(index: int) {
        const nextIndex = Math.min(index, session.memory.length - 2)
        if (nextIndex < 0)
            memoryEmptied()
        session.memoryAction("delete", index)
        if (nextIndex >= 0) {
            Qt.callLater(function() {
                memoryList.currentIndex = nextIndex
                memoryList.forceActiveFocus(Qt.TabFocusReason)
            })
        }
    }
    ColumnLayout {
        anchors.fill: parent
        RowLayout {
            Layout.fillWidth: true
            Label {
                objectName: "memoryTitle"
                text: qsTr("Memory")
                font.bold: true
                font.pixelSize: 18
                Layout.fillWidth: true
            }
            ToolButton {
                objectName: "closeMemoryButton"
                text: qsTr("Close")
                visible: panel.dismissible
                onClicked: panel.closeRequested()
            }
        }
        Label {
            objectName: "memoryEmpty"
            text: qsTr("There's nothing saved in memory")
            visible: memoryList.count === 0
            Layout.fillWidth: true
            wrapMode: Text.Wrap
        }
        ListView {
            id: memoryList
            objectName: "memoryList"
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: panel.session.memory
            enabled: !panel.session.error
            spacing: 4
            ScrollBar.vertical: ScrollBar {}
            delegate: ItemDelegate {
                id: row
                required property string modelData
                required property int index
                objectName: "memoryItem_" + index
                width: memoryList.width
                Accessible.name: qsTr("Recall %1").arg(modelData)
                onClicked: {
                    panel.session.memoryAction("recall", index)
                    panel.valueRecalled()
                }
                TapHandler {
                    acceptedButtons: Qt.RightButton
                    onTapped: memoryMenu.popup()
                }
                Keys.onMenuPressed: memoryMenu.popup()
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_F10 && (event.modifiers & Qt.ShiftModifier)) {
                        memoryMenu.popup()
                        event.accepted = true
                    }
                }
                Menu {
                    id: memoryMenu
                    objectName: "memoryContextMenu"
                    MenuItem {
                        objectName: "deleteMemoryItem"
                        text: qsTr("Clear memory item")
                        onTriggered: panel.deleteFromMenu(row.index)
                    }
                    MenuItem {
                        objectName: "addMemoryItem"
                        text: qsTr("Add to memory item")
                        onTriggered: panel.session.memoryAction("add", row.index)
                    }
                    MenuItem {
                        objectName: "subtractMemoryItem"
                        text: qsTr("Subtract from memory item")
                        onTriggered: panel.session.memoryAction("subtract", row.index)
                    }
                }
                contentItem: ColumnLayout {
                    Label {
                        objectName: "memoryValue_" + row.index
                        text: row.modelData
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                        wrapMode: Text.WrapAnywhere
                        font.pixelSize: 24
                        font.bold: true
                    }
                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        ToolButton {
                            objectName: "memoryDelete_" + row.index
                            text: "MC"
                            Accessible.name: qsTr("Clear memory item")
                            Layout.minimumWidth: 44
                            Layout.minimumHeight: 44
                            onClicked: panel.session.memoryAction("delete", row.index)
                        }
                        ToolButton {
                            objectName: "memoryAdd_" + row.index
                            text: "M+"
                            Accessible.name: qsTr("Add to memory item")
                            Layout.minimumWidth: 44
                            Layout.minimumHeight: 44
                            onClicked: panel.session.memoryAction("add", row.index)
                        }
                        ToolButton {
                            objectName: "memorySubtract_" + row.index
                            text: "M−"
                            Accessible.name: qsTr("Subtract from memory item")
                            Layout.minimumWidth: 44
                            Layout.minimumHeight: 44
                            onClicked: panel.session.memoryAction("subtract", row.index)
                        }
                    }
                }
            }
        }
        Button {
            objectName: "clearMemoryButton"
            text: qsTr("Clear all memory")
            Layout.alignment: Qt.AlignRight
            enabled: memoryList.count > 0
            onClicked: panel.session.memoryAction("clear")
        }
    }
}
