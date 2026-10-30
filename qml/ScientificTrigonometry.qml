pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQml.Models

ColumnLayout {
    id: panel
    required property CalculationSession session
    property real flyoutWidth: width
    readonly property bool popupOpen: trigonometryPopup.visible
    signal controlFocused(Item control)
    spacing: 4

    function sendFunction(command: string) {
        session.send(command)
        inverseButton.checked = false
        hyperbolicButton.checked = false
        trigonometryPopup.close()
    }

    Shortcut {
        sequence: "F3"
        enabled: panel.visible && panel.enabled && !panel.session.error && !panel.popupOpen
        onActivated: panel.session.selectAngleUnit("DEG")
    }
    Shortcut {
        sequence: "F4"
        enabled: panel.visible && panel.enabled && !panel.session.error && !panel.popupOpen
        onActivated: panel.session.selectAngleUnit("RAD")
    }
    Shortcut {
        sequence: "F5"
        enabled: panel.visible && panel.enabled && !panel.session.error && !panel.popupOpen
        onActivated: panel.session.selectAngleUnit("GRAD")
    }
    Instantiator {
        model: ["sin", "cos", "tan", "sec", "csc", "cot"]
        delegate: QtObject {
            id: functionShortcuts
            required property int index
            required property string modelData
            property Shortcut circular: Shortcut {
                sequence: ["S", "O", "T", "U", "I", "J"][functionShortcuts.index]
                context: Qt.ApplicationShortcut
                enabled: panel.visible && panel.enabled && panel.Window.window.active && !panel.session.error
                onActivated: panel.sendFunction(functionShortcuts.modelData)
            }
            property Shortcut inverse: Shortcut {
                sequence: "Shift+" + ["S", "O", "T", "U", "I", "J"][functionShortcuts.index]
                context: Qt.ApplicationShortcut
                enabled: panel.visible && panel.enabled && panel.Window.window.active && !panel.session.error
                onActivated: panel.sendFunction("a" + functionShortcuts.modelData)
            }
            property Shortcut hyperbolic: Shortcut {
                sequence: "Ctrl+" + ["S", "O", "T", "U", "I", "J"][functionShortcuts.index]
                context: Qt.ApplicationShortcut
                enabled: panel.visible && panel.enabled && panel.Window.window.active && !panel.session.error
                onActivated: panel.sendFunction(functionShortcuts.modelData + "h")
            }
            property Shortcut inverseHyperbolic: Shortcut {
                sequence: "Ctrl+Shift+" + ["S", "O", "T", "U", "I", "J"][functionShortcuts.index]
                context: Qt.ApplicationShortcut
                enabled: panel.visible && panel.enabled && panel.Window.window.active && !panel.session.error
                onActivated: panel.sendFunction("a" + functionShortcuts.modelData + "h")
            }
        }
    }
    ToolButton {
        id: angleUnitButton
        objectName: "angleUnitButton"
        text: panel.session.angleUnit
        Accessible.name: panel.session.angleUnit === "DEG" ? qsTr("Degrees toggle")
                       : panel.session.angleUnit === "RAD" ? qsTr("Radians toggle") : qsTr("Gradians toggle")
        enabled: !panel.session.error
        Layout.minimumHeight: 44
        onActiveFocusChanged: if (activeFocus) panel.controlFocused(angleUnitButton)
        onClicked: panel.session.selectAngleUnit(panel.session.angleUnit === "DEG" ? "RAD"
                                                : panel.session.angleUnit === "RAD" ? "GRAD" : "DEG")
    }
    ToolButton {
        id: trigonometryButton
        objectName: "trigonometryButton"
        text: qsTr("Trigonometry") + " ▾"
        Accessible.name: qsTr("Trigonometry")
        enabled: !panel.session.error
        Layout.minimumHeight: 44
        onActiveFocusChanged: if (activeFocus) panel.controlFocused(trigonometryButton)
        onClicked: trigonometryPopup.open()
    }
    Popup {
        id: trigonometryPopup
        objectName: "trigonometryPopup"
        y: trigonometryButton.y + trigonometryButton.height
        width: Math.min(panel.flyoutWidth, 360)
        modal: true
        dim: false
        margins: 4
        background: Rectangle {
            radius: 8
            color: trigonometryPopup.palette.window
            border.color: trigonometryPopup.palette.midlight
        }
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onOpened: {
            // Repeater siblings exist when the flyout opens. Link focus in the
            // visual row order, including the two toggles in the first column.
            inverseButton.KeyNavigation.tab = functionButtons.itemAt(0)
            hyperbolicButton.KeyNavigation.tab = functionButtons.itemAt(3)
            for (let index = 0; index < functionButtons.count; ++index)
                functionButtons.itemAt(index).KeyNavigation.tab = index === 2 ? hyperbolicButton
                                                               : index === 5 ? inverseButton : functionButtons.itemAt(index + 1)
            inverseButton.forceActiveFocus(Qt.PopupFocusReason)
        }
        onClosed: trigonometryButton.forceActiveFocus(Qt.PopupFocusReason)
        contentItem: GridLayout {
            columns: 4
            CalculatorButton {
                id: inverseButton
                objectName: "trigonometryInverse"
                text: "2nd"
                font.pixelSize: 14
                accent: checked
                Accessible.name: qsTr("Inverse function")
                checkable: true
                Layout.row: 0
                Layout.column: 0
                Layout.minimumWidth: 44
                Layout.minimumHeight: 44
            }
            CalculatorButton {
                id: hyperbolicButton
                objectName: "trigonometryHyperbolic"
                text: "hyp"
                font.pixelSize: 14
                accent: checked
                Accessible.name: qsTr("Hyperbolic function")
                checkable: true
                Layout.row: 1
                Layout.column: 0
                Layout.minimumWidth: 44
                Layout.minimumHeight: 44
            }
            Repeater {
                id: functionButtons
                model: [
                    {
                        command: "sin",
                        name: qsTr("Sine"),
                        inverseName: qsTr("Arc sine"),
                        hyperbolicName: qsTr("Hyperbolic sine"),
                        inverseHyperbolicName: qsTr("Hyperbolic arc sine")
                    },
                    {
                        command: "cos",
                        name: qsTr("Cosine"),
                        inverseName: qsTr("Arc cosine"),
                        hyperbolicName: qsTr("Hyperbolic cosine"),
                        inverseHyperbolicName: qsTr("Hyperbolic arc cosine")
                    },
                    {
                        command: "tan",
                        name: qsTr("Tangent"),
                        inverseName: qsTr("Arc tangent"),
                        hyperbolicName: qsTr("Hyperbolic tangent"),
                        inverseHyperbolicName: qsTr("Hyperbolic arc tangent")
                    },
                    {
                        command: "sec",
                        name: qsTr("Secant"),
                        inverseName: qsTr("Arc secant"),
                        hyperbolicName: qsTr("Hyperbolic secant"),
                        inverseHyperbolicName: qsTr("Hyperbolic arc secant")
                    },
                    {
                        command: "csc",
                        name: qsTr("Cosecant"),
                        inverseName: qsTr("Arc cosecant"),
                        hyperbolicName: qsTr("Hyperbolic cosecant"),
                        inverseHyperbolicName: qsTr("Hyperbolic arc cosecant")
                    },
                    {
                        command: "cot",
                        name: qsTr("Cotangent"),
                        inverseName: qsTr("Arc cotangent"),
                        hyperbolicName: qsTr("Hyperbolic cotangent"),
                        inverseHyperbolicName: qsTr("Hyperbolic arc cotangent")
                    }
                ]
                delegate: CalculatorButton {
                    required property var modelData
                    required property int index
                    readonly property string functionName: modelData.command + (hyperbolicButton.checked ? "h" : "")
                    readonly property string command: (inverseButton.checked ? "a" : "") + functionName
                    objectName: "trig_" + command
                    text: functionName + (inverseButton.checked ? "⁻¹" : "")
                    font.pixelSize: 20
                    Accessible.name: hyperbolicButton.checked
                                     ? (inverseButton.checked ? modelData.inverseHyperbolicName : modelData.hyperbolicName)
                                     : (inverseButton.checked ? modelData.inverseName : modelData.name)
                    Layout.row: Math.floor(index / 3)
                    Layout.column: index % 3 + 1
                    Layout.fillWidth: true
                    Layout.minimumWidth: 44
                    Layout.minimumHeight: 44
                    onClicked: panel.sendFunction(command)
                }
            }
        }
    }
}
