pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls

ToolButton {
    id: control
    property bool bitsView: false
    implicitWidth: 40
    implicitHeight: 32
    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 4
    ToolTip.text: Accessible.name
    ToolTip.visible: hovered
    contentItem: Item {
        readonly property color color: control.palette.buttonText
        Item {
            anchors.centerIn: parent
            width: 16
            height: 16
            Repeater {
                model: control.bitsView
                    ? [{x: 4, y: 1}, {x: 10, y: 1}, {x: 1, y: 7}, {x: 13, y: 7}, {x: 4, y: 13}, {x: 10, y: 13}]
                    : [{x: 1, y: 1}, {x: 7, y: 1}, {x: 13, y: 1}, {x: 1, y: 7}, {x: 7, y: 7}, {x: 13, y: 7}, {x: 1, y: 13}, {x: 7, y: 13}, {x: 13, y: 13}]
                delegate: Rectangle {
                    required property var modelData
                    x: modelData.x
                    y: modelData.y
                    width: 3
                    height: 3
                    radius: 1.5
                    color: control.bitsView ? "transparent" : control.palette.buttonText
                    border.width: control.bitsView ? 1 : 0
                    border.color: control.palette.buttonText
                }
            }
        }
    }
    background: Rectangle {
        radius: 4
        color: control.down ? control.palette.midlight : control.hovered ? control.palette.light : "transparent"
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 2
            width: 18
            height: 2
            radius: 1
            color: control.palette.highlight
            visible: control.checked
        }
    }
}
