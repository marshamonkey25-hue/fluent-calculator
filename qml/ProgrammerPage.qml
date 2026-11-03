pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

FocusScope {
    id: page
    required property CalculationSession session
    signal memoryRequested()
    function focusMemoryInput() { memoryBar.focusInput() }
    property bool bitPanelVisible: false
    property string shiftMode: "arithmetic"
    readonly property var shiftModes: [
        { key: "arithmetic", name: qsTr("Arithmetic shift") },
        { key: "logical", name: qsTr("Logical shift") },
        { key: "circular", name: qsTr("Rotate circular shift") },
        { key: "carry", name: qsTr("Rotate through carry shift") }
    ]
    readonly property var shiftCommands: ({
        arithmetic: ["shiftLeft", "shiftRight"], logical: ["shiftLeft", "shiftRightLogical"],
        circular: ["rotateLeft", "rotateRight"], carry: ["rotateCarryLeft", "rotateCarryRight"]
    })
    readonly property var bitwiseOperations: [
        { command: "and", label: "AND", name: qsTr("And"), shortcut: "&" },
        { command: "or", label: "OR", name: qsTr("Or"), shortcut: "|" },
        { command: "not", label: "NOT", name: qsTr("Not"), shortcut: "~" },
        { command: "nand", label: "NAND", name: qsTr("Nand"), shortcut: "." },
        { command: "nor", label: "NOR", name: qsTr("Nor"), shortcut: "\\" },
        { command: "xor", label: "XOR", name: qsTr("Exclusive or"), shortcut: "^" }
    ]
    Instantiator {
        model: page.bitwiseOperations
        delegate: Shortcut {
            required property var modelData
            sequence: modelData.shortcut
            enabled: page.visible && !page.session.error
            onActivated: {
                page.session.send(modelData.command)
                bitwisePopup.close()
            }
        }
    }
    Instantiator {
        model: [{ command: "clear", shortcut: "Escape" }, { command: "clearEntry", shortcut: "Delete" }]
        delegate: Shortcut {
            required property var modelData
            sequence: modelData.shortcut
            enabled: page.visible && !bitwisePopup.visible && !bitShiftPopup.visible
            onActivated: page.session.send(modelData.command)
        }
    }
    readonly property var keySequences: ({
        clear: ["Escape"], clearEntry: ["Delete"], backspace: ["Backspace"], negate: ["F9"],
        open: ["("], close: [")"], mod: ["%"], divide: ["/"], multiply: ["*"],
        shift_left: ["<"], shift_right: [">"],
        subtract: ["-"], add: ["+"], equals: ["=", "Return", "Enter"]
    })
    readonly property var commandNames: ({
        clear: qsTr("Clear"), clearEntry: qsTr("Clear entry"), backspace: qsTr("Backspace"),
        shiftLeft: qsTr("Left shift"), shiftRight: qsTr("Arithmetic right shift"),
        shiftRightLogical: qsTr("Logical right shift"), rotateLeft: qsTr("Rotate left"),
        rotateRight: qsTr("Rotate right"), rotateCarryLeft: qsTr("Rotate left through carry"),
        rotateCarryRight: qsTr("Rotate right through carry"),
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
                ResultCopyMenu { anchors.fill: parent; session: page.session }
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
            MemoryBar {
                id: memoryBar
                session: page.session
                onListRequested: page.memoryRequested()
                onControlFocused: control => page.revealControl(control)
                Layout.fillWidth: true
            }
            RowLayout {
                Layout.fillWidth: true
                ToolButton {
                    id: fullKeypadButton
                    objectName: "fullKeypadButton"
                    text: qsTr("Keypad")
                    Accessible.name: qsTr("Full keypad")
                    checkable: true
                    autoExclusive: true
                    checked: !page.bitPanelVisible
                    contentItem: Text {
                        text: fullKeypadButton.text
                        font: fullKeypadButton.font
                        color: fullKeypadButton.checked ? fullKeypadButton.palette.highlightedText : fullKeypadButton.palette.buttonText
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onActiveFocusChanged: if (activeFocus) page.revealControl(fullKeypadButton)
                    onClicked: page.bitPanelVisible = false
                }
                ToolButton {
                    id: bitPanelButton
                    objectName: "bitPanelButton"
                    text: qsTr("Bits")
                    Accessible.name: qsTr("Bit toggling keypad")
                    checkable: true
                    autoExclusive: true
                    checked: page.bitPanelVisible
                    contentItem: Text {
                        text: bitPanelButton.text
                        font: bitPanelButton.font
                        color: bitPanelButton.checked ? bitPanelButton.palette.highlightedText : bitPanelButton.palette.buttonText
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onActiveFocusChanged: if (activeFocus) page.revealControl(bitPanelButton)
                    onClicked: page.bitPanelVisible = true
                }
                Item { Layout.fillWidth: true }
                ToolButton {
                    id: wordWidthButton
                    objectName: "wordWidthButton"
                    text: ({64: "QWORD", 32: "DWORD", 16: "WORD", 8: "BYTE"})[page.session.wordWidth]
                    Accessible.name: qsTr("Word size: %1 bits").arg(page.session.wordWidth)
                    enabled: !page.session.error
                    onActiveFocusChanged: if (activeFocus) page.revealControl(wordWidthButton)
                    onClicked: page.session.selectWordWidth(({64: 32, 32: 16, 16: 8, 8: 64})[page.session.wordWidth])
                }
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
            RowLayout {
                Layout.fillWidth: true
                visible: !page.bitPanelVisible
                ToolButton {
                    id: bitwiseButton
                    objectName: "bitwiseButton"
                    text: qsTr("Bitwise") + " ▾"
                    enabled: !page.session.error
                    onActiveFocusChanged: if (activeFocus) page.revealControl(bitwiseButton)
                    onClicked: bitwisePopup.open()
                    Popup {
                        id: bitwisePopup
                        objectName: "bitwisePopup"
                        y: parent.height
                        width: Math.min(page.width, 300)
                        margins: 4
                        background: Rectangle {
                            radius: 8
                            color: bitwisePopup.palette.window
                            border.color: bitwisePopup.palette.midlight
                        }
                        focus: true
                        contentItem: GridLayout {
                            columns: 3
                            Repeater {
                                model: page.bitwiseOperations
                                delegate: CalculatorButton {
                                    required property var modelData
                                    objectName: "key_" + modelData.command
                                    text: modelData.label
                                    Accessible.name: modelData.name
                                    implicitWidth: 80
                                    implicitHeight: 44
                                    font.pixelSize: 14
                                    enabled: !page.session.error
                                    onClicked: {
                                        page.session.send(modelData.command)
                                        bitwisePopup.close()
                                    }
                                }
                            }
                        }
                    }
                }
                ToolButton {
                    id: bitShiftButton
                    objectName: "bitShiftButton"
                    text: qsTr("Bit shift") + " ▾"
                    enabled: !page.session.error
                    onActiveFocusChanged: if (activeFocus) page.revealControl(bitShiftButton)
                    onClicked: bitShiftPopup.open()
                    Popup {
                        id: bitShiftPopup
                        objectName: "bitShiftPopup"
                        y: parent.height
                        width: Math.min(page.width, 320)
                        margins: 4
                        background: Rectangle {
                            radius: 8
                            color: bitShiftPopup.palette.window
                            border.color: bitShiftPopup.palette.midlight
                        }
                        focus: true
                        contentItem: ColumnLayout {
                            Repeater {
                                model: page.shiftModes
                                delegate: RadioButton {
                                    required property var modelData
                                    objectName: "shiftMode_" + modelData.key
                                    text: modelData.name
                                    checked: page.shiftMode === modelData.key
                                    enabled: !page.session.error
                                    onClicked: {
                                        page.shiftMode = modelData.key
                                        bitShiftPopup.close()
                                    }
                                }
                            }
                        }
                    }
                }
                Item { Layout.fillWidth: true }
            }
            ProgrammerBitPanel {
                visible: page.bitPanelVisible
                Layout.fillWidth: true
                session: page.session
                onRevealControl: control => page.revealControl(control)
            }
            Item { Layout.fillHeight: true }
            GridLayout {
                visible: !page.bitPanelVisible
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 5
                rows: 6
                uniformCellWidths: true
                uniformCellHeights: true
                columnSpacing: 4
                rowSpacing: 4
                Repeater {
                    model: [
                        { command: "A", label: "A", row: 0, column: 0 },
                        { command: "shift_left", label: "≪", row: 0, column: 1 },
                        { command: "shift_right", label: "≫", row: 0, column: 2 },
                        { command: "clearSlot", label: "", row: 0, column: 3 },
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
                        readonly property string command: modelData.command === "clearSlot"
                                                          ? (page.session.inputEmpty ? "clear" : "clearEntry")
                                                          : modelData.command === "shift_left" ? page.shiftCommands[page.shiftMode][0]
                                                          : modelData.command === "shift_right" ? page.shiftCommands[page.shiftMode][1]
                                                          : modelData.command
                        objectName: "key_" + (modelData.command.startsWith("shift_") ? modelData.command : command)
                        text: modelData.command === "clearSlot" ? (page.session.inputEmpty ? "C" : "CE") : modelData.label
                        Accessible.name: page.commandNames[command] || qsTr("Digit %1").arg(modelData.label)
                        Layout.row: modelData.row
                        Layout.column: modelData.column
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: 44
                        Layout.minimumWidth: 44
                        numeric: modelData.command.length === 1
                        enabled: modelData.command !== "decimal" && (numeric ? "0123456789ABCDEF".indexOf(modelData.command) < page.session.radix
                                         : !page.session.error || ["clear", "clearEntry", "backspace", "equals"].indexOf(command) !== -1)
                        opacity: enabled ? 1 : 0.4
                        accent: modelData.command === "equals"
                        onActiveFocusChanged: if (activeFocus) page.revealControl(keyButton)
                        onClicked: page.session.send(command)
                        Shortcut {
                            sequences: keyButton.modelData.command === "clearSlot" ? []
                                       : page.keySequences[keyButton.modelData.command] || [keyButton.modelData.label]
                            context: Qt.WindowShortcut
                            enabled: page.visible && keyButton.enabled
                            onActivated: page.session.send(keyButton.command)
                        }
                    }
                }
            }
        }
    }
}
