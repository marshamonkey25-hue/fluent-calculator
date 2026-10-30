pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

FocusScope {
    id: page
    required property CalculationSession session
    implicitHeight: 428
    focus: true
    required property ConversionSession converter
    readonly property string category: page.converter.category
    readonly property string negativeInputMessage: category === "energy" ? qsTr("Energy cannot be negative")
        : category === "speed" ? qsTr("Speed cannot be negative")
        : category === "time" ? qsTr("Time cannot be negative")
        : category === "pressure" ? qsTr("Pressure cannot be negative")
        : category === "volume" ? qsTr("Volume cannot be negative")
        : category === "area" ? qsTr("Area cannot be negative")
        : category === "weight" ? qsTr("Weight and mass cannot be negative") : qsTr("Length cannot be negative")
    readonly property bool landscape: width >= height
    readonly property var keySequences: ({ clear: ["Escape", "Delete"], backspace: ["Backspace"], decimal: ["."] })
    readonly property var commandNames: ({ clear: qsTr("Clear entry"), backspace: qsTr("Backspace"), decimal: qsTr("Decimal separator") })

    Shortcut {
        enabled: page.visible && page.enabled && page.activeFocus
        sequences: [StandardKey.Paste]
        context: Qt.WindowShortcut
        onActivated: page.converter.paste()
    }
    Shortcut {
        enabled: page.visible && page.enabled && page.activeFocus
        sequences: [StandardKey.Copy]
        context: Qt.WindowShortcut
        onActivated: page.converter.copy()
    }
    Menu {
        id: valueMenu
        objectName: "converterContextMenu"
        MenuItem {
            objectName: "converterCopy"
            text: qsTr("Copy")
            onTriggered: page.converter.copy()
        }
        MenuItem {
            objectName: "converterPaste"
            text: qsTr("Paste")
            onTriggered: page.converter.paste()
        }
    }

    GridLayout {
        anchors.fill: parent
        columns: page.landscape ? 2 : 1
        columnSpacing: 12
        rowSpacing: 4
        ColumnLayout {
            Layout.preferredWidth: 1
            Layout.minimumWidth: 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4
            ConverterValue {
                objectName: "converterValue1"
                text: page.converter.value1
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 44
                checked: page.converter.activeSide === 1
                Accessible.name: (page.converter.activeSide === 1 ? qsTr("Input: %1 %2") : qsTr("Result: %1 %2")).arg(text).arg(firstUnit.currentText)
                onClicked: page.converter.activate(1)
                onContextRequested: { page.converter.activate(1); valueMenu.popup() }
            }
            ConverterUnitSelector {
                id: firstUnit
                objectName: "converterUnit1"
                Layout.fillWidth: true
                Layout.minimumHeight: 32
                model: page.converter.units
                textRole: "name"
                valueRole: "id"
                currentValue: page.converter.unit1
                Accessible.name: qsTr("First unit")
                onActivated: page.converter.unit1 = currentValue
            }
            ConverterValue {
                objectName: "converterValue2"
                text: page.converter.value2
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 44
                checked: page.converter.activeSide === 2
                Accessible.name: (page.converter.activeSide === 2 ? qsTr("Input: %1 %2") : qsTr("Result: %1 %2")).arg(text).arg(secondUnit.currentText)
                onClicked: page.converter.activate(2)
                onContextRequested: { page.converter.activate(2); valueMenu.popup() }
            }
            ConverterUnitSelector {
                id: secondUnit
                objectName: "converterUnit2"
                Layout.fillWidth: true
                Layout.minimumHeight: 32
                model: page.converter.units
                textRole: "name"
                valueRole: "id"
                currentValue: page.converter.unit2
                Accessible.name: qsTr("Second unit")
                onActivated: page.converter.unit2 = currentValue
            }
            Label {
                objectName: "converterStatus"
                Layout.fillWidth: true
                visible: page.converter.status !== ""
                text: page.converter.status === "limit" ? qsTr("Maximum 15 digits")
                    : page.converter.status === "negative" ? page.negativeInputMessage
                    : page.converter.status === "unavailable" ? qsTr("Result cannot be displayed")
                    : page.converter.status === "invalid" ? qsTr("Invalid input") : ""
                wrapMode: Text.Wrap
                Accessible.role: Accessible.AlertMessage
            }
        }
        GridLayout {
            Layout.preferredWidth: 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 3
            rows: 5
            columnSpacing: 4
            rowSpacing: 4
            Repeater {
                model: [
                    {command: "clear", label: "CE", row: 0, column: 1},
                    {command: "backspace", label: "⌫", row: 0, column: 2},
                    {command: "7", label: "7", row: 1, column: 0},
                    {command: "8", label: "8", row: 1, column: 1},
                    {command: "9", label: "9", row: 1, column: 2},
                    {command: "4", label: "4", row: 2, column: 0},
                    {command: "5", label: "5", row: 2, column: 1},
                    {command: "6", label: "6", row: 2, column: 2},
                    {command: "1", label: "1", row: 3, column: 0},
                    {command: "2", label: "2", row: 3, column: 1},
                    {command: "3", label: "3", row: 3, column: 2},
                    {command: "0", label: "0", row: 4, column: 1},
                    {command: "decimal", label: ".", row: 4, column: 2}
                ]
                delegate: CalculatorButton {
                    id: keyButton
                    required property var modelData
                    objectName: "converterKey_" + modelData.command
                    text: modelData.label
                    Accessible.name: page.commandNames[modelData.command] || qsTr("Digit %1").arg(text)
                    Layout.row: modelData.row
                    Layout.column: modelData.column
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 44
                    Layout.minimumWidth: 44
                    numeric: modelData.command.length === 1
                    onClicked: page.converter.send(modelData.command)
                    Shortcut {
                        enabled: page.visible && page.enabled
                        sequences: page.keySequences[keyButton.modelData.command] || [keyButton.modelData.label]
                        context: Qt.WindowShortcut
                        onActivated: page.converter.send(keyButton.modelData.command)
                    }
                }
            }
        }
    }
}
