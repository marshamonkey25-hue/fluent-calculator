pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: root
    required property string dateValue
    required property string language
    required property DateCalculation calculation
    signal dateSelected(string date)
    text: calculation.formattedDate(dateValue, language)
    implicitHeight: Math.max(44, contentItem.implicitHeight + topPadding + bottomPadding)
    flat: true
    contentItem: RowLayout {
        spacing: 12
        Label {
            objectName: "label"
            text: root.text
            font: root.font
            color: root.palette.buttonText
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            Accessible.ignored: true
        }
        Canvas {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            property color strokeColor: root.palette.buttonText
            onStrokeColorChanged: requestPaint()
            onPaint: {
                const context = getContext("2d")
                context.reset()
                context.strokeStyle = strokeColor
                context.lineWidth = 1.5
                context.strokeRect(3, 5, 14, 13)
                context.beginPath()
                context.moveTo(3, 9)
                context.lineTo(17, 9)
                context.moveTo(7, 2)
                context.lineTo(7, 7)
                context.moveTo(13, 2)
                context.lineTo(13, 7)
                context.stroke()
            }
        }
    }
    onClicked: calendar.open()

    function isoDate(year, month, day) {
        return String(year).padStart(4, "0") + "-" + String(month + 1).padStart(2, "0")
                + "-" + String(day).padStart(2, "0")
    }

    Popup {
        id: calendar
        objectName: "dateCalendar"
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: Math.min(336, parent.width - 24)
        padding: 12
        modal: true
        focus: true
        palette: root.palette
        background: Rectangle {
            color: calendar.palette.window
            border.color: calendar.palette.mid
            radius: 8
        }
        onOpened: {
            const parts = root.dateValue.split("-")
            yearInput.text = parts[0]
            monthInput.currentIndex = Number(parts[1]) - 1
            yearInput.forceActiveFocus(Qt.TabFocusReason)
        }
        onClosed: root.forceActiveFocus(Qt.PopupFocusReason)
        ColumnLayout {
            width: calendar.availableWidth
            spacing: 8
            RowLayout {
                Layout.fillWidth: true
                ComboBox {
                    id: monthInput
                    objectName: "calendarMonth"
                    Layout.fillWidth: true
                    model: Array.from({length: 12}, (_, month) => Qt.locale(root.language).standaloneMonthName(month, Locale.LongFormat))
                    Accessible.name: qsTr("Month")
                    indicator: Canvas {
                        x: monthInput.width - width - 12
                        y: (monthInput.height - height) / 2
                        width: 12
                        height: 12
                        property color strokeColor: monthInput.palette.buttonText
                        onStrokeColorChanged: requestPaint()
                        onPaint: {
                            const context = getContext("2d")
                            context.reset()
                            context.strokeStyle = strokeColor
                            context.lineWidth = 1.5
                            context.beginPath()
                            context.moveTo(2, 4)
                            context.lineTo(6, 8)
                            context.lineTo(10, 4)
                            context.stroke()
                        }
                    }
                    background: Rectangle {
                        implicitHeight: 32
                        color: monthInput.palette.button
                        border.color: monthInput.visualFocus ? monthInput.palette.highlight : monthInput.palette.mid
                        radius: 4
                    }
                    popup.background: Rectangle {
                        color: monthInput.palette.base
                        border.color: monthInput.palette.mid
                        radius: 4
                    }
                }
                TextField {
                    id: yearInput
                    objectName: "calendarYear"
                    Layout.preferredWidth: 80
                    validator: IntValidator { bottom: 1601; top: 9999 }
                    selectByMouse: true
                    inputMethodHints: Qt.ImhDigitsOnly
                    Accessible.name: qsTr("Year")
                    background: Rectangle {
                        implicitHeight: 32
                        color: yearInput.palette.base
                        border.color: yearInput.activeFocus ? yearInput.palette.highlight : yearInput.palette.mid
                        border.width: yearInput.activeFocus ? 2 : 1
                        radius: 4
                    }
                }
            }
            Label {
                objectName: "calendarYearError"
                text: qsTr("Enter a year from 1601 to 9999.")
                visible: !yearInput.acceptableInput
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                Accessible.name: text
            }
            DayOfWeekRow {
                locale: Qt.locale(root.language)
                Layout.fillWidth: true
            }
            MonthGrid {
                id: grid
                year: yearInput.acceptableInput ? Number(yearInput.text) : 2000
                month: Math.max(0, monthInput.currentIndex)
                locale: Qt.locale(root.language)
                Layout.fillWidth: true
                Layout.preferredHeight: 252
                spacing: 0
                delegate: Button {
                    id: dayControl
                    required property var model
                    readonly property string iso: root.isoDate(model.year, model.month, model.day)
                    objectName: "dateDay_" + iso
                    text: String(model.day)
                    enabled: yearInput.acceptableInput && model.month === grid.month
                    opacity: model.month === grid.month ? 1 : 0
                    highlighted: iso === root.dateValue
                    flat: true
                    padding: 0
                    contentItem: Label {
                        text: dayControl.text
                        font: dayControl.font
                        color: dayControl.highlighted ? dayControl.palette.highlightedText : dayControl.palette.buttonText
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        Accessible.ignored: true
                    }
                    Accessible.name: root.calculation.formattedDate(iso, root.language)
                    onClicked: {
                        root.dateSelected(iso)
                        calendar.close()
                    }
                }
            }
        }
    }
}
