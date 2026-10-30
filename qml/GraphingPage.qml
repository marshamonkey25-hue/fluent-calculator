pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Calculator

Page {
    id: root
    required property CalculationSession session
    implicitHeight: 408
    // MainWindow reserves 8px for the content margins. The reference switches
    // graph/equation panels below an 800px window, with both visible above it.
    readonly property bool wide: width >= 792
    onWideChanged: {
        if (!visible || !enabled || !functionInput || !graphViewButton || syntaxPopup.visible) return
        if (wide) functionInput.forceActiveFocus(Qt.TabFocusReason)
        else if (viewSwitch.currentIndex === 0) graphViewButton.forceActiveFocus(Qt.TabFocusReason)
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8
        TabBar {
            id: viewSwitch
            visible: !root.wide
            Layout.alignment: Qt.AlignRight
            Layout.preferredWidth: 240
            TabButton {
                id: graphViewButton
                objectName: "graphViewButton"
                text: qsTr("Graph")
                Accessible.name: text
                Accessible.selected: checked
            }
            TabButton {
                objectName: "graphEquationsButton"
                text: qsTr("Equations")
                Accessible.name: text
                Accessible.selected: checked
                onClicked: functionInput.forceActiveFocus(Qt.TabFocusReason)
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12
            FunctionGraph {
                id: graph
                objectName: "functionGraph"
                visible: root.wide || viewSwitch.currentIndex === 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 160
                Layout.preferredWidth: root.width * 2 / 3
                curveColor: root.palette.highlight
                axisColor: root.palette.text
                gridColor: root.palette.mid
                backgroundColor: root.palette.base
                Accessible.role: Accessible.Chart
                Accessible.name: qsTr("Function graph")
                Accessible.description: qsTr("x and y range from -10 to 10. %1").arg(statusLabel.text)
            }
            ColumnLayout {
                visible: root.wide || viewSwitch.currentIndex === 1
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: root.wide ? Math.min(420, Math.max(300, root.width / 3)) : root.width
                spacing: 8
                Label { text: qsTr("Equation"); font.bold: true }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "y ="; font.pixelSize: 18 }
                    TextField {
                        id: functionInput
                        objectName: "functionInput"
                        Layout.fillWidth: true
                        Accessible.name: qsTr("Function of x")
                        placeholderText: qsTr("Enter a function of x")
                        selectByMouse: true
                        onAccepted: graph.expression = text
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Button {
                        objectName: "plotFunctionButton"
                        text: qsTr("Plot")
                        Layout.fillWidth: true
                        onClicked: graph.expression = functionInput.text
                    }
                    ToolButton {
                        objectName: "graphSyntaxButton"
                        text: qsTr("Syntax")
                        onClicked: syntaxPopup.open()
                    }
                }
                Item { Layout.fillHeight: true }
            }
        }
        Label {
            id: statusLabel
            objectName: "graphStatus"
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: graph.status === FunctionGraph.Empty ? qsTr("Enter a function, then press Enter or Plot.")
                : graph.status === FunctionGraph.Invalid ? qsTr("Invalid or unsupported expression. Check the syntax.")
                : graph.status === FunctionGraph.NoPoints ? qsTr("No defined points in this range.")
                : graph.status === FunctionGraph.NoVisibleCurve ? qsTr("The curve is outside the visible range.")
                : graph.status === FunctionGraph.PartialDomain ? qsTr("Showing y = %1. Undefined or unresolved intervals are omitted.").arg(graph.expression)
                : qsTr("Showing y = %1").arg(graph.expression)
            Accessible.name: text
        }
    }
    Popup {
        id: syntaxPopup
        objectName: "graphSyntaxPopup"
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: Math.min(440, root.width - 24)
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onClosed: functionInput.forceActiveFocus(Qt.TabFocusReason)
        contentItem: ColumnLayout {
            spacing: 12
            Label {
                objectName: "graphSyntaxText"
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: qsTr("Use x, pi, e, decimal numbers, + - * / ^ and parentheses. Functions: sin, cos, tan, sqrt, abs, ln, log (base 10), exp. Angles are radians. Write multiplication explicitly, for example 2*x. Powers associate right; -x^2 means -(x^2). Use a decimal point. Limit: 512 characters and 64 parser levels. Only y=f(x) is supported.")
            }
            Button {
                text: qsTr("Close")
                Layout.alignment: Qt.AlignRight
                onClicked: syntaxPopup.close()
            }
        }
    }
}
