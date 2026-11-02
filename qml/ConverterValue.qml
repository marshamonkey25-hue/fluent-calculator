pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls

// Pinned converter values are selectable: the bold side receives the keypad.
Button {
    id: value
    property string displayPrefix: ""
    flat: true
    checkable: false
    signal contextRequested()
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: value.contextRequested()
    }
    leftPadding: 12
    rightPadding: 12
    font.pixelSize: 40
    font.bold: checked
    background: Rectangle {
        color: "transparent"
        radius: 4
        border.width: value.visualFocus ? 2 : 0
        border.color: value.palette.highlight
    }
    contentItem: Label {
        text: value.displayPrefix === "" ? value.text : value.displayPrefix + " " + value.text
        color: value.palette.windowText
        font: value.font
        minimumPixelSize: 14
        fontSizeMode: Text.Fit
        verticalAlignment: Text.AlignVCenter
    }
}
