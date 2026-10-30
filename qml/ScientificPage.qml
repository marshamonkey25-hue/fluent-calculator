pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

FocusScope {
    id: page
    required property CalculationSession session
    implicitHeight: 488
    readonly property var keySequences: ({
        clear: ["Escape"], divide: ["/"], multiply: ["*"],
        subtract: ["-"], add: ["+"], decimal: ["."],
        equals: ["=", "Return", "Enter"],
        openParenthesis: ["("], closeParenthesis: [")"]
    })
    readonly property var commandNames: ({
        clear: qsTr("Clear"), divide: qsTr("Divide"), multiply: qsTr("Multiply"),
        subtract: qsTr("Subtract"), add: qsTr("Add"), decimal: qsTr("Decimal separator"),
        equals: qsTr("Equals"), openParenthesis: qsTr("Open parenthesis"),
        closeParenthesis: qsTr("Close parenthesis")
    })
    focus: true
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
            Item {
                Layout.row: 0
                Layout.column: 0
                Layout.minimumWidth: 44
                Layout.fillWidth: true
            }
            Item {
                Layout.row: 1
                Layout.column: 0
                Layout.minimumHeight: 44
                Layout.fillHeight: true
            }
            Repeater {
                model: [
                    { command: "clear", label: "C", row: 0, column: 3 },
                    { command: "openParenthesis", label: "(", row: 2, column: 1 },
                    { command: "closeParenthesis", label: ")", row: 2, column: 2 },
                    { command: "divide", label: "÷", row: 2, column: 4 },
                    { command: "7", label: "7", row: 3, column: 1 },
                    { command: "8", label: "8", row: 3, column: 2 },
                    { command: "9", label: "9", row: 3, column: 3 },
                    { command: "multiply", label: "×", row: 3, column: 4 },
                    { command: "4", label: "4", row: 4, column: 1 },
                    { command: "5", label: "5", row: 4, column: 2 },
                    { command: "6", label: "6", row: 4, column: 3 },
                    { command: "subtract", label: "−", row: 4, column: 4 },
                    { command: "1", label: "1", row: 5, column: 1 },
                    { command: "2", label: "2", row: 5, column: 2 },
                    { command: "3", label: "3", row: 5, column: 3 },
                    { command: "add", label: "+", row: 5, column: 4 },
                    { command: "0", label: "0", row: 6, column: 2 },
                    { command: "decimal", label: ".", row: 6, column: 3 },
                    { command: "equals", label: "=", row: 6, column: 4 }
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
                    onClicked: page.session.send(modelData.command)
                    Shortcut {
                        enabled: page.visible
                        sequences: page.keySequences[keyButton.modelData.command] || [keyButton.modelData.label]
                        context: Qt.WindowShortcut
                        onActivated: page.session.send(keyButton.modelData.command)
                    }
                }
            }
        }
    }
}
