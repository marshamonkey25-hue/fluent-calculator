pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

FocusScope {
    id: page
    required property CalculationSession session
    implicitHeight: category === "currency" ? 552 : 428
    focus: true
    required property ConversionSession converter
    readonly property string category: page.converter.category
    // currentValue is read-only in Qt 6.8; keep the selection binding on currentIndex.
    function unitIndex(unitId: int): int {
        const units = page.converter.units
        for (let index = 0; index < units.length; ++index) {
            if (units[index].id === unitId)
                return index
        }
        return -1
    }
    readonly property string negativeInputMessage: category === "currency" ? qsTr("Currency amount cannot be negative")
        : category === "energy" ? qsTr("Energy cannot be negative")
        : category === "speed" ? qsTr("Speed cannot be negative")
        : category === "time" ? qsTr("Time cannot be negative")
        : category === "data" ? qsTr("Data cannot be negative")
        : category === "pressure" ? qsTr("Pressure cannot be negative")
        : category === "volume" ? qsTr("Volume cannot be negative")
        : category === "area" ? qsTr("Area cannot be negative")
        : category === "weight" ? qsTr("Weight and mass cannot be negative") : qsTr("Length cannot be negative")
    Component.onCompleted: if (category === "currency") converter.currency.refresh()
    readonly property bool landscape: width >= height
    readonly property var keySequences: ({ clear: ["Escape", "Delete"], backspace: ["Backspace"], decimal: ["."], negate: ["-", "F9"] })
    readonly property var commandNames: ({ clear: qsTr("Clear entry"), backspace: qsTr("Backspace"), decimal: qsTr("Decimal separator"), negate: qsTr("Positive negative") })

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
                displayPrefix: page.category === "currency" && firstUnit.currentIndex >= 0 ? page.converter.units[firstUnit.currentIndex].symbol : ""
                text: page.converter.value1
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 44
                enabled: page.converter.activeSide === 1 || (text !== "—" && (page.category !== "currency" || page.converter.currency.available))
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
                currentIndex: page.unitIndex(page.converter.unit1)
                Accessible.name: qsTr("First unit")
                onActivated: page.converter.unit1 = currentValue
            }
            ConverterValue {
                objectName: "converterValue2"
                displayPrefix: page.category === "currency" && secondUnit.currentIndex >= 0 ? page.converter.units[secondUnit.currentIndex].symbol : ""
                text: page.converter.value2
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 44
                enabled: page.converter.activeSide === 2 || (text !== "—" && (page.category !== "currency" || page.converter.currency.available))
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
                currentIndex: page.unitIndex(page.converter.unit2)
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
            ColumnLayout {
                visible: page.category === "currency"
                Layout.fillWidth: true
                spacing: 2
                Label {
                    objectName: "currencySource"
                    text: qsTr("Frankfurter · Daily reference rates")
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    font.pixelSize: 12
                }
                Label {
                    objectName: "currencyDate"
                    text: page.converter.currency.observationDate === "" ? qsTr("No observation date")
                        : qsTr("Data date: %1").arg(page.converter.currency.observationDate)
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    font.pixelSize: 12
                }
                Label {
                    objectName: "currencyRefreshed"
                    text: page.converter.currency.refreshedAt === "" ? qsTr("Not refreshed yet")
                        : qsTr("Last refresh: %1").arg(page.converter.currency.refreshedAt)
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    font.pixelSize: 12
                }
                Label {
                    objectName: "currencyStatus"
                    readonly property string refreshState: page.converter.currency.state
                    text: refreshState === "loading" ? qsTr("Refreshing…")
                        : refreshState === "ready" ? qsTr("Up to date")
                        : refreshState === "failed" ? qsTr("Refresh failed. Try again.")
                        : refreshState === "invalid" ? qsTr("No valid quote for this currency pair. Try again.")
                        : qsTr("Rates unavailable. Refresh to try again.")
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    font.pixelSize: 12
                    Accessible.role: Accessible.AlertMessage
                }
                Label {
                    objectName: "currencyCache"
                    visible: page.converter.currency.usingCached || page.converter.currency.cacheWriteFailed
                    text: page.converter.currency.cacheWriteFailed ? qsTr("Rates could not be saved. Offline data may be older.")
                        : qsTr("Using cached rates")
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    font.pixelSize: 12
                    Accessible.role: Accessible.AlertMessage
                }
                Button {
                    objectName: "currencyRefresh"
                    text: qsTr("Refresh rates")
                    Accessible.name: text
                    focusPolicy: Qt.StrongFocus
                    Layout.minimumHeight: 32
                    onClicked: page.converter.currency.refresh()
                }
            }
        }
        GridLayout {
            Layout.preferredWidth: 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 3
            rows: 5
            uniformCellWidths: true
            uniformCellHeights: true
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
                    {command: "negate", label: "±", row: 4, column: 0},
                    {command: "0", label: "0", row: 4, column: 1},
                    {command: "decimal", label: ".", row: 4, column: 2}
                ]
                delegate: CalculatorButton {
                    id: keyButton
                    required property var modelData
                    objectName: "converterKey_" + modelData.command
                    visible: modelData.command !== "negate" || page.converter.supportsNegative
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
                        enabled: page.visible && page.enabled && keyButton.visible
                        sequences: page.keySequences[keyButton.modelData.command] || [keyButton.modelData.label]
                        context: Qt.WindowShortcut
                        onActivated: page.converter.send(keyButton.modelData.command)
                    }
                }
            }
        }
    }
}
