pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: panel
    required property CalculationSession session
    signal revealControl(control: Item)
    spacing: 8
    Accessible.name: qsTr("Bit toggling keypad")

    Repeater {
        model: 4
        delegate: RowLayout {
            id: bitRow
            required property int index
            Layout.fillWidth: true
            spacing: 8
            Repeater {
                model: 4
                delegate: ColumnLayout {
                    id: nibble
                    required property int index
                    readonly property int lowestBit: 60 - bitRow.index * 16 - index * 4
                    Layout.fillWidth: true
                    spacing: 2
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Repeater {
                            model: 4
                            delegate: CalculatorButton {
                                id: bitButton
                                required property int index
                                readonly property int position: nibble.lowestBit + 3 - index
                                objectName: "bit_" + position
                                Layout.fillWidth: true
                                Layout.minimumWidth: 16
                                Layout.minimumHeight: 44
                                implicitWidth: 16
                                checkable: true
                                checked: panel.session.binaryBits.charAt(63 - position) === "1"
                                text: checked ? "1" : "0"
                                font.pixelSize: 18
                                accent: checked
                                enabled: position < panel.session.wordWidth && !panel.session.error
                                opacity: enabled ? 1 : 0.4
                                Accessible.name: position === 0 ? qsTr("Least significant bit: %1").arg(text)
                                                 : position === panel.session.wordWidth - 1 ? qsTr("Most significant bit: %1").arg(text)
                                                 : qsTr("Bit %1: %2").arg(position).arg(text)
                                onActiveFocusChanged: if (activeFocus) panel.revealControl(bitButton)
                                onClicked: panel.session.toggleBit(position)
                            }
                        }
                    }
                    Label {
                        text: nibble.lowestBit
                        Layout.alignment: Qt.AlignRight
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}
