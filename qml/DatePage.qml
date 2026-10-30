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
        Label {
            text: qsTr("Difference between dates")
            font.pixelSize: 16
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
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
}
