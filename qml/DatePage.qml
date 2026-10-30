pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: root
    required property CalculationSession session
    implicitHeight: 380
    contentWidth: availableWidth
    padding: 12
    clip: true
    DateCalculation { id: dateCalculation }

    function daysText(days) {
        return (days === 1 ? qsTr("%1 day") : qsTr("%1 days")).arg(days)
    }

    function differenceText() {
        if (dateCalculation.totalDays === 0)
            return qsTr("Same dates")
        const difference = dateCalculation.difference
        const parts = []
        if (difference.years > 0)
            parts.push((difference.years === 1 ? qsTr("%1 year") : qsTr("%1 years")).arg(difference.years))
        if (difference.months > 0)
            parts.push((difference.months === 1 ? qsTr("%1 month") : qsTr("%1 months")).arg(difference.months))
        if (difference.weeks > 0)
            parts.push((difference.weeks === 1 ? qsTr("%1 week") : qsTr("%1 weeks")).arg(difference.weeks))
        if (difference.days > 0)
            parts.push(daysText(difference.days))
        return parts.join(qsTr(", "))
    }

    ColumnLayout {
        width: root.availableWidth
        spacing: 24
        DateCombo {
            id: calculationOption
            objectName: "dateCalculationOption"
            model: 2
            displayText: currentIndex === 0 ? qsTr("Difference between dates") : qsTr("Add or subtract days")
            delegate: ItemDelegate {
                required property int index
                width: calculationOption.width
                text: index === 0 ? qsTr("Difference between dates") : qsTr("Add or subtract days")
                highlighted: calculationOption.highlightedIndex === index
            }
            Accessible.name: qsTr("Date calculation option")
            Layout.fillWidth: true
            Layout.maximumWidth: 360
        }
        ColumnLayout {
            visible: calculationOption.currentIndex === 0
            Layout.fillWidth: true
            spacing: 24
            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true
                Label { text: qsTr("From") }
                DatePicker {
                    objectName: "fromDatePicker"
                    calculation: dateCalculation
                    dateValue: dateCalculation.fromDate
                    language: root.session.language
                    onDateSelected: date => dateCalculation.fromDate = date
                    Layout.fillWidth: true
                    Layout.maximumWidth: 360
                    Accessible.name: qsTr("From: %1").arg(text)
                }
            }
            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true
                Label { text: qsTr("To") }
                DatePicker {
                    objectName: "toDatePicker"
                    calculation: dateCalculation
                    dateValue: dateCalculation.toDate
                    language: root.session.language
                    onDateSelected: date => dateCalculation.toDate = date
                    Layout.fillWidth: true
                    Layout.maximumWidth: 360
                    Accessible.name: qsTr("To: %1").arg(text)
                }
            }
            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true
                Label { text: qsTr("Difference") }
                Label {
                    objectName: "dateDifferenceResult"
                    text: root.differenceText()
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    font.pixelSize: 20
                    Accessible.name: qsTr("Difference %1").arg(text)
                }
                Label {
                    objectName: "dateDifferenceDays"
                    text: dateCalculation.difference.years > 0 || dateCalculation.difference.months > 0 || dateCalculation.difference.weeks > 0
                        ? root.daysText(dateCalculation.totalDays) : ""
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }
        }
        ColumnLayout {
            visible: calculationOption.currentIndex === 1
            Layout.fillWidth: true
            spacing: 24
            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true
                Label { text: qsTr("From") }
                DatePicker {
                    objectName: "startDatePicker"
                    calculation: dateCalculation
                    dateValue: dateCalculation.startDate
                    language: root.session.language
                    onDateSelected: date => dateCalculation.startDate = date
                    Layout.fillWidth: true
                    Layout.maximumWidth: 360
                    Accessible.name: qsTr("From: %1").arg(text)
                }
            }
            RowLayout {
                RadioButton {
                    id: addOption
                    objectName: "dateAddOption"
                    text: qsTr("Add")
                    checked: true
                }
                RadioButton {
                    objectName: "dateSubtractOption"
                    text: qsTr("Subtract")
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: 360
                spacing: 12
                OffsetField { id: years; controlName: "dateYearsOffset"; label: qsTr("Years") }
                OffsetField { id: months; controlName: "dateMonthsOffset"; label: qsTr("Months") }
                OffsetField { id: days; controlName: "dateDaysOffset"; label: qsTr("Days") }
            }
            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true
                Label { text: qsTr("Date") }
                Label {
                    objectName: "dateOffsetResult"
                    readonly property string resultDate: dateCalculation.adjustedDate(dateCalculation.startDate,
                            addOption.checked, years.value, months.value, days.value)
                    text: resultDate === "" ? qsTr("Date out of Bound")
                                           : dateCalculation.formattedResultDate(resultDate, root.session.language)
                    font.pixelSize: 20
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    Accessible.name: qsTr("Resulting date: %1").arg(text)
                }
            }
        }
    }

    component DateCombo: ComboBox {
        id: combo
        popup.background: Rectangle {
            color: combo.palette.base
            border.color: combo.palette.mid
            radius: 4
        }
        indicator: Canvas {
            x: combo.width - width - 12
            y: (combo.height - height) / 2
            width: 12
            height: 12
            property color strokeColor: combo.palette.buttonText
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
    }

    component OffsetField: ColumnLayout {
        id: field
        required property string label
        required property string controlName
        property alias value: offset.currentIndex
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        spacing: 4
        Label { text: field.label; Layout.fillWidth: true; wrapMode: Text.WordWrap }
        DateCombo {
            id: offset
            objectName: field.controlName
            model: 1000
            Layout.fillWidth: true
            Accessible.name: field.label
        }
    }
}
