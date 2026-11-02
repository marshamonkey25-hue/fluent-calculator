import QtQuick
import QtQuick.Controls

Button {
    id: control
    property bool numeric: false
    property bool accent: false
    Accessible.name: text
    focusPolicy: Qt.StrongFocus
    hoverEnabled: true
    font.pixelSize: 22
    contentItem: Text {
        text: control.text
        font: control.font
        color: !control.enabled ? control.palette.placeholderText
             : control.accent ? control.palette.highlightedText : control.palette.buttonText
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle {
        radius: 4
        color: control.accent ? control.palette.highlight
             : control.down ? control.palette.midlight
             : control.hovered ? control.palette.light
             : control.numeric ? control.palette.base : control.palette.button
        opacity: control.accent && (control.down || control.hovered) ? 0.85 : 1
        border.width: control.visualFocus ? 2 : 1
        border.color: control.visualFocus ? control.palette.highlight : control.palette.midlight
    }
}
