import QtQuick
import QtQuick.Controls

MouseArea {
    id: root
    required property CalculationSession session
    readonly property bool popupOpen: resultMenu.visible
    acceptedButtons: Qt.RightButton
    onClicked: mouse => resultMenu.popup(root, mouse.x, mouse.y)

    Shortcut {
        enabled: root.visible && root.enabled
        sequences: [StandardKey.Copy]
        context: Qt.WindowShortcut
        onActivated: root.session.copyResult()
    }
    Shortcut {
        enabled: root.visible && root.enabled
        sequences: [StandardKey.Paste]
        context: Qt.WindowShortcut
        onActivated: root.session.paste()
    }
    Menu {
        id: resultMenu
        objectName: "resultContextMenu"
        // Keep this customized Fluent menu in the application window on every
        // platform, including macOS, and restore keyboard input after dismissal.
        popupType: Popup.Item
        onClosed: root.forceActiveFocus(Qt.PopupFocusReason)
        background: Rectangle {
            implicitWidth: 200
            implicitHeight: 40
            color: resultMenu.palette.base
            border.color: resultMenu.palette.mid
            radius: 8
        }
        MenuItem {
            objectName: "copyResultItem"
            text: qsTr("Copy")
            onTriggered: root.session.copyResult()
        }
        MenuItem {
            objectName: "pasteResultItem"
            text: qsTr("Paste")
            onTriggered: root.session.paste()
        }
    }
}
