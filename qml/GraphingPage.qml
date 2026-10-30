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
            ColumnLayout {
                visible: root.wide || viewSwitch.currentIndex === 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: root.width * 2 / 3
                spacing: 4
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    ToolButton {
                        objectName: "graphZoomInButton"
                        text: "+"
                        Accessible.name: qsTr("Zoom in")
                        Layout.preferredWidth: 32
                        enabled: graph.canZoomIn
                        onClicked: graph.zoom(0.5)
                    }
                    ToolButton {
                        objectName: "graphZoomOutButton"
                        text: "−"
                        Accessible.name: qsTr("Zoom out")
                        Layout.preferredWidth: 32
                        enabled: graph.canZoomOut
                        onClicked: graph.zoom(2)
                    }
                    Repeater {
                        model: [
                            { key: "Left", symbol: "←", label: qsTr("Pan left"), x: -0.25, y: 0 },
                            { key: "Right", symbol: "→", label: qsTr("Pan right"), x: 0.25, y: 0 },
                            { key: "Up", symbol: "↑", label: qsTr("Pan up"), x: 0, y: 0.25 },
                            { key: "Down", symbol: "↓", label: qsTr("Pan down"), x: 0, y: -0.25 }
                        ]
                        delegate: ToolButton {
                            required property var modelData
                            objectName: "graphPan" + modelData.key + "Button"
                            text: modelData.symbol
                            Accessible.name: modelData.label
                            Layout.preferredWidth: 32
                            onClicked: graph.pan(modelData.x, modelData.y)
                        }
                    }
                    ToolButton {
                        objectName: "graphResetButton"
                        text: qsTr("Reset")
                        Accessible.name: qsTr("Reset view")
                        onClicked: graph.resetView()
                    }
                    Item { Layout.fillWidth: true }
                }
                FunctionGraph {
                    id: graph
                    objectName: "functionGraph"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 160
                    curveColor: root.palette.highlight
                    axisColor: root.palette.text
                    gridColor: root.palette.mid
                    backgroundColor: root.palette.base
                    Accessible.role: Accessible.Chart
                    Accessible.name: qsTr("Function graph")
                    Accessible.description: rangeLabel.text + ". " + statusLabel.text
                    activeFocusOnTab: true
                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Left) graph.pan(-0.25, 0)
                        else if (event.key === Qt.Key_Right) graph.pan(0.25, 0)
                        else if (event.key === Qt.Key_Up) graph.pan(0, 0.25)
                        else if (event.key === Qt.Key_Down) graph.pan(0, -0.25)
                        else if (event.key === Qt.Key_Plus || event.key === Qt.Key_Equal) graph.zoom(0.5)
                        else if (event.key === Qt.Key_Minus) graph.zoom(2)
                        else if (event.key === Qt.Key_Home) graph.resetView()
                        else if (event.key === Qt.Key_Space) graph.inspectAt(graph.width / 2, graph.height / 2)
                        else return
                        event.accepted = true
                    }
                    Rectangle {
                        anchors.fill: parent
                        visible: graph.activeFocus
                        color: "transparent"
                        border.color: root.palette.highlight
                        border.width: 2
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.CrossCursor
                        property point lastPosition
                        onPressed: function(mouse) {
                            graph.forceActiveFocus(Qt.MouseFocusReason)
                            lastPosition = Qt.point(mouse.x, mouse.y)
                            graph.inspectAt(mouse.x, mouse.y)
                        }
                        onPositionChanged: function(mouse) {
                            if (!pressed) return
                            graph.pan((lastPosition.x - mouse.x) / width, (mouse.y - lastPosition.y) / height)
                            lastPosition = Qt.point(mouse.x, mouse.y)
                            graph.inspectAt(mouse.x, mouse.y)
                        }
                        onWheel: function(wheel) {
                            if (wheel.angleDelta.y !== 0) graph.zoom(wheel.angleDelta.y > 0 ? 0.5 : 2)
                            wheel.accepted = true
                        }
                    }
                }
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
                        Connections {
                            target: graph
                            function onExpressionChanged() { functionInput.text = graph.expression }
                        }
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
                RowLayout {
                    Layout.fillWidth: true
                    Button {
                        objectName: "addFunctionButton"
                        text: qsTr("Add function")
                        Layout.fillWidth: true
                        onClicked: { graph.addFunction(); functionInput.forceActiveFocus(Qt.TabFocusReason) }
                    }
                    Button {
                        objectName: "deleteFunctionButton"
                        text: qsTr("Delete")
                        onClicked: { graph.deleteFunction(); functionInput.forceActiveFocus(Qt.TabFocusReason) }
                    }
                }
                ListView {
                    id: functionList
                    objectName: "functionList"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 40
                    clip: true
                    model: graph.functions
                    currentIndex: graph.selectedIndex
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                    ScrollBar.vertical: ScrollBar {}
                    delegate: Button {
                        id: functionRow
                        required property var modelData
                        required property int index
                        objectName: "selectFunction_" + modelData.id
                        width: functionList.width
                        checkable: true
                        checked: index === graph.selectedIndex
                        flat: true
                        text: "F" + modelData.id + ": y = " + modelData.expression
                            + (modelData.status === FunctionGraph.Invalid ? " — " + qsTr("Invalid expression") : "")
                        Accessible.name: text
                        Accessible.selected: checked
                        onActiveFocusChanged: {
                            if (activeFocus) functionList.positionViewAtIndex(index, ListView.Contain)
                        }
                        contentItem: Label {
                            text: functionRow.text
                            color: functionRow.checked ? functionRow.palette.highlightedText : functionRow.palette.buttonText
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }
                        leftPadding: 22
                        Rectangle {
                            objectName: "graphFunctionColor_" + functionRow.modelData.id
                            x: 4; anchors.verticalCenter: parent.verticalCenter
                            width: 10; height: 10; radius: 5
                            color: functionRow.modelData.color
                        }
                        onClicked: { graph.selectedIndex = index; functionInput.forceActiveFocus(Qt.TabFocusReason) }
                    }
                }
            }
        }
        Label {
            id: rangeLabel
            objectName: "graphRange"
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            function number(value: real): string { return graph.formatCoordinate(value) }
            text: "x: " + number(graph.minimumX) + " … " + number(graph.maximumX)
                + "; y: " + number(graph.minimumY) + " … " + number(graph.maximumY)
            Accessible.name: text
        }
        Label {
            objectName: "graphCoordinates"
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: graph.inspection.id === undefined ? qsTr("Click the graph to inspect coordinates.")
                : qsTr("x: %1; y: %2; F%3(x): %4").arg(graph.inspection.x).arg(graph.inspection.y)
                    .arg(graph.inspection.id).arg(graph.inspection.defined ? graph.inspection.value : qsTr("Undefined"))
            Accessible.name: text
        }
        Label {
            id: statusLabel
            objectName: "graphStatus"
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
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
        height: Math.min(520, root.height - 24)
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onClosed: functionInput.forceActiveFocus(Qt.TabFocusReason)
        contentItem: ColumnLayout {
            spacing: 12
            ScrollView {
                id: helpScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: availableWidth
                ColumnLayout {
                    width: helpScroll.availableWidth
                    spacing: 12
                    Label {
                        objectName: "graphSyntaxText"
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        text: qsTr("Use x, pi, e, decimal numbers, + - * / ^ and parentheses. Functions: sin, cos, tan, sqrt, abs, ln, log (base 10), exp. Angles are radians. Write multiplication explicitly, for example 2*x. Powers associate right; -x^2 means -(x^2). Use a decimal point. Limit: 512 characters and 64 parser levels. Only y=f(x) is supported.")
                    }
                    Label {
                        objectName: "graphNavigationHelp"
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        text: qsTr("Select a function to edit it, then press Plot. Drag or use arrows to pan; use +/− or the wheel to zoom. Home resets the view. Click or press Space on the graph to inspect coordinates.")
                    }
                }
            }
            Button {
                text: qsTr("Close")
                Layout.alignment: Qt.AlignRight
                onClicked: syntaxPopup.close()
            }
        }
    }
}
