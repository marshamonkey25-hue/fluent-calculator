pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: bar
    required property CalculationSession session
    signal listRequested()
    signal controlFocused(Item control)
    signal inputFocusRequested()
    function focusInput() { inputFocusRequested() }
    spacing: 0
    Item {
        visible: bar.session.mode === "programmer"
        Layout.fillWidth: true
    }
    Repeater {
        model: [
            { action: "clear", label: "MC", name: qsTr("Clear all memory"), shortcut: "Ctrl+L" },
            { action: "recall", label: "MR", name: qsTr("Memory recall"), shortcut: "Ctrl+R" },
            { action: "add", label: "M+", name: qsTr("Memory add"), shortcut: "Ctrl+P" },
            { action: "subtract", label: "M−", name: qsTr("Memory subtract"), shortcut: "Ctrl+Q" },
            { action: "save", label: "MS", name: qsTr("Memory store"), shortcut: "Ctrl+M" }
        ]
        delegate: ToolButton {
            id: control
            required property var modelData
            objectName: "memory_" + modelData.action
            text: modelData.label
            Accessible.name: modelData.name
            Layout.fillWidth: true
            Layout.minimumWidth: 44
            Layout.maximumWidth: 80
            Layout.minimumHeight: 44
            visible: bar.session.mode !== "programmer" || modelData.action === "save"
            enabled: visible && !bar.session.error && (["save", "add", "subtract"].indexOf(modelData.action) !== -1 || bar.session.memory.length > 0)
            ToolTip.text: modelData.name + " (" + modelData.shortcut + ")"
            ToolTip.visible: hovered
            onActiveFocusChanged: if (activeFocus) bar.controlFocused(control)
            onClicked: bar.session.memoryAction(modelData.action)
            Connections {
                target: bar
                function onInputFocusRequested() {
                    const action = bar.session.mode === "programmer" ? "save" : "add"
                    if (control.modelData.action === action)
                        control.forceActiveFocus(Qt.TabFocusReason)
                }
            }
            Shortcut {
                sequence: control.modelData.shortcut
                enabled: bar.visible && bar.enabled && control.enabled
                context: Qt.WindowShortcut
                onActivated: bar.session.memoryAction(control.modelData.action)
            }
        }
    }
    ToolButton {
        id: listButton
        objectName: "memory_list"
        text: "M▾"
        Accessible.name: qsTr("Show memory")
        Layout.fillWidth: true
        Layout.minimumWidth: 44
        Layout.minimumHeight: 44
        enabled: bar.session.memory.length > 0
        visible: bar.Window.window && bar.Window.window.width < 560
        Layout.maximumWidth: 80
        onActiveFocusChanged: if (activeFocus) bar.controlFocused(listButton)
        onClicked: bar.listRequested()
    }
}
