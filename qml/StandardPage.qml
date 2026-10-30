pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

FocusScope {
    id: page
    required property CalculationSession session
    implicitHeight: content.implicitHeight
    signal memoryRequested()
    function focusMemoryInput() { memoryBar.focusInput() }
    readonly property var keySequences: ({
        backspace: ["Backspace"], clearEntry: ["Delete"], reciprocal: ["R"], squareRoot: ["@"],
        clear: ["Escape"], percent: ["%"], sign: ["F9"], square: ["Q"], divide: ["/"], multiply: ["*"],
        subtract: ["-"], add: ["+"], decimal: ["."],
        equals: ["=", "Return", "Enter"]
    })
    readonly property var commandNames: ({
        backspace: qsTr("Backspace"), clearEntry: qsTr("Clear entry"), reciprocal: qsTr("Reciprocal"),
        squareRoot: qsTr("Square root"), square: qsTr("Square"), sign: qsTr("Negate"),
        percent: qsTr("Percent"), clear: qsTr("Clear"), divide: qsTr("Divide"), multiply: qsTr("Multiply"),
        subtract: qsTr("Subtract"), add: qsTr("Add"), decimal: qsTr("Decimal separator"),
        equals: qsTr("Equals")
    })
    focus: true
    Shortcut {
        enabled: page.visible
        sequence: StandardKey.Copy
        context: Qt.WindowShortcut
        onActivated: page.session.copyResult()
    }
    function revealControl(control: Item) {
        const viewport = scroll.contentItem as Flickable
        if (!viewport)
            return
        const top = control.mapToItem(viewport.contentItem, 0, 0).y
        if (top < viewport.contentY)
            viewport.contentY = top
        else if (top + control.height > viewport.contentY + viewport.height)
            viewport.contentY = top + control.height - viewport.height
    }
    ScrollView {
        id: scroll
        anchors.fill: parent
        contentWidth: availableWidth
        ColumnLayout {
            id: content
            width: scroll.availableWidth
            height: Math.max(implicitHeight, scroll.availableHeight)
            spacing: 4
            Label {
                objectName: "expressionDisplay"
                Layout.fillWidth: true
                Layout.minimumHeight: 28
                horizontalAlignment: Text.AlignRight
                text: page.session.expression
            }
            Label {
                objectName: "resultDisplay"
                Layout.fillWidth: true
                Layout.minimumHeight: 72
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 40
                minimumPixelSize: 16
                fontSizeMode: Text.Fit
                padding: 8
                text: page.session.display
                Accessible.role: Accessible.StaticText
                Accessible.name: page.session.error ? qsTr("Error: %1").arg(text) : qsTr("Result: %1").arg(text)
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: resultMenu.popup()
                }
                Menu {
                    id: resultMenu
                    objectName: "resultContextMenu"
                    MenuItem {
                        objectName: "copyResultItem"
                        text: qsTr("Copy")
                        onTriggered: page.session.copyResult()
                    }
                }
            }
            Label {
                objectName: "errorIndicator"
                Layout.alignment: Qt.AlignRight
                visible: page.session.error
                text: qsTr("Error")
            }
            Item { Layout.fillHeight: true; Layout.minimumHeight: 12 }
            MemoryBar {
                id: memoryBar
                session: page.session
                onListRequested: page.memoryRequested()
                onControlFocused: control => page.revealControl(control)
                Layout.fillWidth: true
            }
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 4
                rows: 6
                columnSpacing: 4
                rowSpacing: 4
                Repeater {
                    model: [
                        { command: "percent", label: "%", row: 0, column: 0 },
                        { command: "clearEntry", label: "CE", row: 0, column: 1 },
                        { command: "clear", label: "C", row: 0, column: 2 },
                        { command: "backspace", label: "⌫", row: 0, column: 3 },
                        { command: "reciprocal", label: "1/x", row: 1, column: 0 },
                        { command: "square", label: "x²", row: 1, column: 1 },
                        { command: "squareRoot", label: "√x", row: 1, column: 2 },
                        { command: "divide", label: "÷", row: 1, column: 3 },
                        { command: "7", label: "7", row: 2, column: 0 },
                        { command: "8", label: "8", row: 2, column: 1 },
                        { command: "9", label: "9", row: 2, column: 2 },
                        { command: "multiply", label: "×", row: 2, column: 3 },
                        { command: "4", label: "4", row: 3, column: 0 },
                        { command: "5", label: "5", row: 3, column: 1 },
                        { command: "6", label: "6", row: 3, column: 2 },
                        { command: "subtract", label: "−", row: 3, column: 3 },
                        { command: "1", label: "1", row: 4, column: 0 },
                        { command: "2", label: "2", row: 4, column: 1 },
                        { command: "3", label: "3", row: 4, column: 2 },
                        { command: "add", label: "+", row: 4, column: 3 },
                        { command: "sign", label: "+/−", row: 5, column: 0 },
                        { command: "0", label: "0", row: 5, column: 1 },
                        { command: "decimal", label: ".", row: 5, column: 2 },
                        { command: "equals", label: "=", row: 5, column: 3 }
                    ]
                    delegate: CalculatorButton {
                        id: keyButton
                        required property var modelData
                        objectName: "key_" + modelData.command
                        text: modelData.label
                        Accessible.name: page.commandNames[modelData.command] || qsTr("Digit %1").arg(modelData.label)
                        Layout.row: modelData.row
                        Layout.column: modelData.column
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: 44
                        Layout.minimumWidth: 44
                        numeric: modelData.command.length === 1
                        accent: modelData.command === "equals"
                        enabled: !page.session.error || numeric
                                 || ["clear", "clearEntry", "backspace", "decimal", "equals"].indexOf(modelData.command) !== -1
                        onActiveFocusChanged: if (activeFocus) page.revealControl(keyButton)
                        onClicked: page.session.send(modelData.command)
                        Shortcut {
                            enabled: page.visible && keyButton.enabled
                            sequences: page.keySequences[keyButton.modelData.command] || [keyButton.modelData.label]
                            context: Qt.WindowShortcut
                            onActivated: page.session.send(keyButton.modelData.command)
                        }
                    }
                }
            }
        }
    }
}
