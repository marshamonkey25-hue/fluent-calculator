pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

FocusScope {
    id: page
    required property CalculationSession session
    readonly property var keySequences: ({
        clear: ["Escape"], clearEntry: ["Delete"], backspace: ["Backspace"], negate: ["F9"],
        open: ["("], close: [")"], mod: ["%"], divide: ["/"], multiply: ["*"],
        subtract: ["-"], add: ["+"], equals: ["=", "Return", "Enter"]
    })
    readonly property var commandNames: ({
        clear: qsTr("Clear"), clearEntry: qsTr("Clear entry"), backspace: qsTr("Backspace"),
        negate: qsTr("Negate"), open: qsTr("Open parenthesis"), close: qsTr("Close parenthesis"),
        mod: qsTr("Modulo"), divide: qsTr("Divide"), multiply: qsTr("Multiply"),
        decimal: qsTr("Decimal separator"),
        subtract: qsTr("Subtract"), add: qsTr("Add"), equals: qsTr("Equals")
    })
    focus: true
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
        objectName: "programmerScroll"
        anchors.fill: parent
        contentWidth: availableWidth
        ColumnLayout {
            width: scroll.availableWidth
            height: Math.max(implicitHeight, scroll.availableHeight)
            spacing: 4
            Label {
                objectName: "expressionDisplay"
                Layout.fillWidth: true
                Layout.minimumHeight: 24
                horizontalAlignment: Text.AlignRight
                text: page.session.expression
            }
            Label {
                objectName: "resultDisplay"
                Layout.fillWidth: true
                Layout.minimumHeight: 64
                horizontalAlignment: Text.AlignRight
                font.pixelSize: 40
                minimumPixelSize: 16
                fontSizeMode: Text.Fit
                padding: 8
                text: page.session.display
                Accessible.name: page.session.error ? qsTr("Error: %1").arg(text) : qsTr("Result: %1").arg(text)
            }
            Label {
                objectName: "errorIndicator"
                visible: page.session.error
                text: qsTr("Error")
            }
            Repeater {
                model: [
                    { radix: 16, label: "HEX", name: qsTr("Hexadecimal") },
                    { radix: 10, label: "DEC", name: qsTr("Decimal") },
                    { radix: 8, label: "OCT", name: qsTr("Octal") },
                    { radix: 2, label: "BIN", name: qsTr("Binary") }
                ]
                delegate: Button {
                    id: radixButton
                    required property var modelData
                    required property int index
                    objectName: "radix_" + modelData.radix
                    Layout.fillWidth: true
                    Layout.minimumHeight: 36
                    checkable: true
                    checked: page.session.radix === modelData.radix
                    enabled: !page.session.error
                    Accessible.name: qsTr("%1: %2").arg(modelData.name).arg(page.session.radixDisplays[index])
                    background: Rectangle {
                        radius: 4
                        color: radixButton.down ? radixButton.palette.midlight
                             : radixButton.hovered ? radixButton.palette.light : "transparent"
                        border.width: radixButton.visualFocus ? 2 : 0
                        border.color: radixButton.palette.highlight
                        Rectangle {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 3
                            height: 16
                            radius: 1
                            color: radixButton.palette.highlight
                            visible: radixButton.checked
                        }
                    }
                    contentItem: RowLayout {
                        Label { text: radixButton.modelData.label; font.bold: radixButton.checked; Layout.preferredWidth: 40 }
                        Label {
                            objectName: "radixValue_" + radixButton.modelData.radix
                            text: page.session.radixDisplays[radixButton.index]
                            Layout.fillWidth: true
                            wrapMode: Text.WrapAnywhere
                            font.pixelSize: 12
                        }
                    }
                    onActiveFocusChanged: if (activeFocus) page.revealControl(radixButton)
                    onClicked: page.session.selectRadix(modelData.radix)
                    Shortcut {
                        sequence: ({16: "F5", 10: "F6", 8: "F7", 2: "F8"})[radixButton.modelData.radix]
                        enabled: page.visible && radixButton.enabled
                        onActivated: page.session.selectRadix(radixButton.modelData.radix)
                    }
                }
            }
            ToolButton {
                id: wordWidthButton
                objectName: "wordWidthButton"
                text: ({64: "QWORD", 32: "DWORD", 16: "WORD", 8: "BYTE"})[page.session.wordWidth]
                Accessible.name: qsTr("Word size: %1 bits").arg(page.session.wordWidth)
                enabled: !page.session.error
                onActiveFocusChanged: if (activeFocus) page.revealControl(wordWidthButton)
                onClicked: page.session.selectWordWidth(({64: 32, 32: 16, 16: 8, 8: 64})[page.session.wordWidth])
            }
            Instantiator {
                model: [
                    { width: 64, shortcut: "F2" }, { width: 32, shortcut: "F3" },
                    { width: 16, shortcut: "F4" }, { width: 8, shortcut: "F12" }
                ]
                delegate: Shortcut {
                    required property var modelData
                    sequence: modelData.shortcut
                    enabled: page.visible && !page.session.error
                    onActivated: page.session.selectWordWidth(modelData.width)
                }
            }
            Item { Layout.fillHeight: true }
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 5
                rows: 6
                columnSpacing: 4
                rowSpacing: 4
                Repeater {
                    model: [
                        { command: "A", label: "A", row: 0, column: 0 },
                        { command: "clearEntry", label: "CE", row: 0, column: 2 },
                        { command: "clear", label: "C", row: 0, column: 3 },
                        { command: "backspace", label: "⌫", row: 0, column: 4 },
                        { command: "B", label: "B", row: 1, column: 0 },
                        { command: "open", label: "(", row: 1, column: 1 },
                        { command: "close", label: ")", row: 1, column: 2 },
                        { command: "mod", label: "mod", row: 1, column: 3 },
                        { command: "divide", label: "÷", row: 1, column: 4 },
                        { command: "C", label: "C", row: 2, column: 0 },
                        { command: "7", label: "7", row: 2, column: 1 },
                        { command: "8", label: "8", row: 2, column: 2 },
                        { command: "9", label: "9", row: 2, column: 3 },
                        { command: "multiply", label: "×", row: 2, column: 4 },
                        { command: "D", label: "D", row: 3, column: 0 },
                        { command: "4", label: "4", row: 3, column: 1 },
                        { command: "5", label: "5", row: 3, column: 2 },
                        { command: "6", label: "6", row: 3, column: 3 },
                        { command: "subtract", label: "−", row: 3, column: 4 },
                        { command: "E", label: "E", row: 4, column: 0 },
                        { command: "1", label: "1", row: 4, column: 1 },
                        { command: "2", label: "2", row: 4, column: 2 },
                        { command: "3", label: "3", row: 4, column: 3 },
                        { command: "add", label: "+", row: 4, column: 4 },
                        { command: "F", label: "F", row: 5, column: 0 },
                        { command: "negate", label: "+/−", row: 5, column: 1 },
                        { command: "0", label: "0", row: 5, column: 2 },
                        { command: "decimal", label: ".", row: 5, column: 3 },
                        { command: "equals", label: "=", row: 5, column: 4 }
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
                        enabled: modelData.command !== "decimal" && (numeric ? "0123456789ABCDEF".indexOf(modelData.command) < page.session.radix
                                         : !page.session.error || ["clear", "clearEntry", "backspace", "equals"].indexOf(modelData.command) !== -1)
                        opacity: enabled ? 1 : 0.4
                        accent: modelData.command === "equals"
                        onActiveFocusChanged: if (activeFocus) page.revealControl(keyButton)
                        onClicked: page.session.send(modelData.command)
                        Shortcut {
                            sequences: page.keySequences[keyButton.modelData.command] || [keyButton.modelData.label]
                            context: Qt.WindowShortcut
                            enabled: page.visible && keyButton.enabled
                            onActivated: page.session.send(keyButton.modelData.command)
                        }
                    }
                }
            }
        }
    }
}
