pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

FocusScope {
    id: page
    required property CalculationSession session
    implicitHeight: 580
    readonly property var keySequences: ({
        clear: ["Escape"], clearEntry: ["Delete"], backspace: ["Backspace"], divide: ["/"], multiply: ["*"],
        subtract: ["-"], add: ["+"], decimal: ["."],
        equals: ["=", "Return", "Enter"],
        openParenthesis: ["("], closeParenthesis: [")"],
        square: ["Q"], cube: ["#"], squareRoot: ["@"], cubeRoot: ["B"],
        power: ["Y", "^"], root: ["Ctrl+Y"], powerTen: ["Ctrl+G"], powerTwo: ["G"],
        log: ["L"], logBase: ["Shift+L"], ln: ["N"], powerE: ["Ctrl+N"],
        factorial: ["!"], mod: ["%"], reciprocal: ["R"], pi: ["P"],
        euler: ["Shift+E"], exp: ["E"], abs: ["|"], floor: ["["], ceil: ["]"],
        rand: ["Shift+R"], dms: ["M"], negate: ["F9"], scientificNotation: ["V"]
    })
    readonly property var commandNames: ({
        clear: qsTr("Clear"), divide: qsTr("Divide"), multiply: qsTr("Multiply"),
        subtract: qsTr("Subtract"), add: qsTr("Add"), decimal: qsTr("Decimal separator"),
        equals: qsTr("Equals"), openParenthesis: qsTr("Open parenthesis"),
        closeParenthesis: qsTr("Close parenthesis"), square: qsTr("Square"),
        squareRoot: qsTr("Square root"), cube: qsTr("Cube"), cubeRoot: qsTr("Cube root"),
        power: qsTr("Power"), root: qsTr("Nth root"), negate: qsTr("Negate"),
        powerTen: qsTr("Ten to the power"), powerTwo: qsTr("Two to the power"),
        log: qsTr("Logarithm"), logBase: qsTr("Logarithm with base"),
        ln: qsTr("Natural logarithm"), powerE: qsTr("Exponential"),
        factorial: qsTr("Factorial"), mod: qsTr("Modulo"), reciprocal: qsTr("Reciprocal"),
        pi: qsTr("Pi"), euler: qsTr("Euler's number"),
        clearEntry: qsTr("Clear entry"), backspace: qsTr("Backspace"),
        exp: qsTr("Enter exponent"), abs: qsTr("Absolute value"), floor: qsTr("Floor"),
        ceil: qsTr("Ceiling"), rand: qsTr("Random number"),
        dms: qsTr("Degrees, minutes, seconds"), degrees: qsTr("Decimal degrees")
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
    function commandEnabled(command) {
        return !session.error || /^[0-9]$/.test(command)
            || ["clear", "clearEntry", "backspace", "equals", "decimal"].indexOf(command) !== -1
    }
    function activate(command) {
        session.send(command)
        if (["cube", "cubeRoot", "root", "powerTwo", "logBase", "powerE"].indexOf(command) !== -1) {
            session.secondFunction = false
            secondButton.forceActiveFocus(Qt.OtherFocusReason)
        }
    }
    // Register both function layers so reference accelerators work while the
    // alternate column or Function flyout is closed.
    Instantiator {
        model: Object.keys(page.keySequences).concat(["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"])
        delegate: Shortcut {
            required property string modelData
            sequences: page.keySequences[modelData] || [modelData]
            enabled: page.visible && page.enabled && page.Window.window.active && page.commandEnabled(modelData)
                     && (modelData !== "clear" || (!trigonometry.popupOpen && !functionPopup.visible))
            context: Qt.ApplicationShortcut
            onActivated: page.activate(modelData)
        }
    }
    ColumnLayout {
        anchors.fill: parent
        spacing: 4
        Flickable {
            id: expressionViewport
            objectName: "expressionViewport"
            Layout.fillWidth: true
            Layout.minimumHeight: 28
            Layout.preferredHeight: 28
            clip: true
            contentWidth: Math.max(width, expressionLabel.implicitWidth)
            contentHeight: height
            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds
            onContentWidthChanged: contentX = Math.max(0, contentWidth - width)
            onWidthChanged: contentX = Math.max(0, contentWidth - width)
            ScrollBar.horizontal: ScrollBar { }
            Label {
                id: expressionLabel
                objectName: "expressionDisplay"
                width: expressionViewport.contentWidth
                horizontalAlignment: Text.AlignRight
                text: page.session.expression
            }
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
        }
        Label {
            objectName: "errorIndicator"
            Layout.alignment: Qt.AlignRight
            visible: page.session.error
            text: qsTr("Error")
        }
        Item { Layout.fillHeight: true; Layout.minimumHeight: 12 }
        ScrollView {
            id: scroll
            objectName: "scientificScroll"
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth
            ColumnLayout {
                width: scroll.availableWidth
                height: Math.max(implicitHeight, scroll.availableHeight)
                spacing: 4
                RowLayout {
                    Layout.fillWidth: true
                    ScientificTrigonometry {
                        id: trigonometry
                        session: page.session
                        flyoutWidth: page.width
                        onControlFocused: function(control) { page.revealControl(control) }
                        Layout.fillWidth: true
                    }
                    ColumnLayout {
                        spacing: 4
                        RowLayout {
                            Layout.fillWidth: true
                            ToolButton {
                                id: notationButton
                                objectName: "key_scientificNotation"
                                text: "F-E"
                                Accessible.name: qsTr("Scientific notation")
                                checkable: true
                                checked: page.session.scientificNotation
                                highlighted: checked
                                enabled: !page.session.error
                                Layout.minimumHeight: 44
                                Layout.minimumWidth: 44
                                onActiveFocusChanged: if (activeFocus) page.revealControl(notationButton)
                                onClicked: page.activate("scientificNotation")
                            }
                            Item { Layout.fillWidth: true }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            ToolButton {
                                id: functionButton
                                objectName: "key_function"
                                text: qsTr("Function") + " ▾"
                                Accessible.name: qsTr("Function")
                                enabled: !page.session.error
                                Layout.minimumHeight: 44
                                onActiveFocusChanged: if (activeFocus) page.revealControl(functionButton)
                                onClicked: functionPopup.open()
                                Popup {
                                    id: functionPopup
                                    objectName: "functionPopup"
                                    y: functionButton.height
                                    width: Math.min(page.width, 240)
                                    height: 112
                                    modal: true
                                    margins: 4
                                    background: Rectangle {
                                        radius: 8
                                        color: functionPopup.palette.window
                                        border.color: functionPopup.palette.midlight
                                    }
                                    focus: true
                                    contentItem: GridLayout {
                                        columns: 3
                                        columnSpacing: 4
                                        rowSpacing: 4
                                        Repeater {
                                            model: [
                                                { command: "abs", label: "|x|" }, { command: "floor", label: "⌊x⌋" },
                                                { command: "ceil", label: "⌈x⌉" }, { command: "rand", label: "rand" },
                                                { command: "dms", label: "→dms" }, { command: "degrees", label: "→deg" }
                                            ]
                                            delegate: CalculatorButton {
                                                required property var modelData
                                                objectName: "key_function_" + modelData.command
                                                text: modelData.label
                                                font.pixelSize: 17
                                                Accessible.name: page.commandNames[modelData.command]
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                Layout.minimumWidth: 44
                                                Layout.minimumHeight: 44
                                                onClicked: {
                                                    page.activate(modelData.command)
                                                    functionPopup.close()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            Item { Layout.fillWidth: true }
                        }
                    }
                }
                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 5
                    rows: 7
                    uniformCellWidths: true
                    uniformCellHeights: true
                    columnSpacing: 4
                    rowSpacing: 4
                    // Preserve the reference's extension-function column and second row.
                    CalculatorButton {
                        id: secondButton
                        objectName: "key_second"
                        text: "2ⁿᵈ"
                        Accessible.name: qsTr("Second function")
                        checkable: true
                        checked: page.session.secondFunction
                        onToggled: page.session.secondFunction = checked
                        accent: checked
                        enabled: !page.session.error
                        Layout.row: 0
                        Layout.column: 0
                        Layout.minimumWidth: 44
                        Layout.minimumHeight: 44
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        onActiveFocusChanged: if (activeFocus) page.revealControl(secondButton)
                    }
                    Repeater {
                        model: [
                            { command: "pi", label: "π", row: 0, column: 1 },
                            { command: "euler", label: "e", row: 0, column: 2 },
                            { command: "clear", label: "C", row: 0, column: 3 },
                            { command: "backspace", label: "⌫", row: 0, column: 4 },
                            { command: "square", label: "x²", secondary: "cube", secondaryLabel: "x³", row: 1, column: 0 },
                            { command: "reciprocal", label: "1/x", row: 1, column: 1 },
                            { command: "abs", label: "|x|", row: 1, column: 2 },
                            { command: "exp", label: "exp", row: 1, column: 3 },
                            { command: "mod", label: "mod", row: 1, column: 4 },
                            { command: "squareRoot", label: "√x", secondary: "cubeRoot", secondaryLabel: "∛x", row: 2, column: 0 },
                            { command: "openParenthesis", label: "(", row: 2, column: 1 },
                            { command: "closeParenthesis", label: ")", row: 2, column: 2 },
                            { command: "factorial", label: "n!", row: 2, column: 3 },
                            { command: "divide", label: "÷", row: 2, column: 4 },
                            { command: "power", label: "xʸ", secondary: "root", secondaryLabel: "ʸ√x", row: 3, column: 0 },
                            { command: "7", label: "7", row: 3, column: 1 },
                            { command: "8", label: "8", row: 3, column: 2 },
                            { command: "9", label: "9", row: 3, column: 3 },
                            { command: "multiply", label: "×", row: 3, column: 4 },
                            { command: "powerTen", label: "10ˣ", secondary: "powerTwo", secondaryLabel: "2ˣ", row: 4, column: 0 },
                            { command: "4", label: "4", row: 4, column: 1 },
                            { command: "5", label: "5", row: 4, column: 2 },
                            { command: "6", label: "6", row: 4, column: 3 },
                            { command: "subtract", label: "−", row: 4, column: 4 },
                            { command: "log", label: "log", secondary: "logBase", secondaryLabel: "logᵧx", row: 5, column: 0 },
                            { command: "1", label: "1", row: 5, column: 1 },
                            { command: "2", label: "2", row: 5, column: 2 },
                            { command: "3", label: "3", row: 5, column: 3 },
                            { command: "add", label: "+", row: 5, column: 4 },
                            { command: "ln", label: "ln", secondary: "powerE", secondaryLabel: "eˣ", row: 6, column: 0 },
                            { command: "negate", label: "±", row: 6, column: 1 },
                            { command: "0", label: "0", row: 6, column: 2 },
                            { command: "decimal", label: ".", row: 6, column: 3 },
                            { command: "equals", label: "=", row: 6, column: 4 }
                        ]
                        delegate: CalculatorButton {
                            id: keyButton
                            required property var modelData
                            readonly property string command: modelData.command === "clear" ? (page.session.inputEmpty ? "clear" : "clearEntry")
                                                             : secondButton.checked && modelData.secondary ? modelData.secondary : modelData.command
                            objectName: "key_" + command
                            text: modelData.command === "clear" ? (page.session.inputEmpty ? "C" : "CE")
                                : secondButton.checked && modelData.secondaryLabel ? modelData.secondaryLabel : modelData.label
                            Accessible.name: page.commandNames[command] || qsTr("Digit %1").arg(modelData.label)
                            Layout.row: modelData.row
                            Layout.column: modelData.column
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: 44
                            Layout.minimumWidth: 44
                            numeric: modelData.command.length === 1
                            enabled: page.commandEnabled(command)
                            opacity: enabled ? 1 : 0.4
                            accent: modelData.command === "equals"
                            onActiveFocusChanged: if (activeFocus) page.revealControl(keyButton)
                            onClicked: page.activate(command)
                        }
                    }
                }
            }
        }
    }
}
