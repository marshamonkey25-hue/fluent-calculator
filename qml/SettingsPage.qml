pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: page
    required property AppPreferences preferences
    readonly property var themeLabels: ({ light: qsTr("Light"), dark: qsTr("Dark"), system: qsTr("Use system setting") })
    readonly property var languageLabels: ({ "en-US": qsTr("English"), "zh-CN": qsTr("Simplified Chinese"), system: qsTr("Use system setting") })
    function reveal(control: Item) {
        if (!control.activeFocus)
            return
        const flickable = page.contentItem as Flickable
        const y = control.mapToItem(flickable.contentItem, 0, 0).y
        if (y < flickable.contentY)
            flickable.contentY = y
        else if (y + control.height > flickable.contentY + flickable.height)
            flickable.contentY = y + control.height - flickable.height
    }
    clip: true
    contentWidth: availableWidth
    ColumnLayout {
        width: page.availableWidth
        spacing: 8
        Label {
            text: qsTr("Appearance")
            font.bold: true
            Layout.fillWidth: true
            Layout.margins: 12
        }
        GroupBox {
            title: qsTr("App theme")
            Layout.fillWidth: true
            Layout.margins: 12
            ColumnLayout {
                anchors.fill: parent
                Repeater {
                    model: ["light", "dark", "system"]
                    delegate: RadioButton {
                        id: themeChoice
                        required property string modelData
                        objectName: "theme_" + modelData
                        text: page.themeLabels[modelData]
                        Accessible.name: text
                        checked: page.preferences.theme === modelData
                        Layout.fillWidth: true
                        Layout.minimumHeight: 44
                        focusPolicy: Qt.StrongFocus
                        onClicked: page.preferences.theme = modelData
                        onActiveFocusChanged: Qt.callLater(page.reveal, themeChoice)
                    }
                }
            }
        }
        GroupBox {
            title: qsTr("App language")
            Layout.fillWidth: true
            Layout.margins: 12
            ColumnLayout {
                anchors.fill: parent
                Repeater {
                    model: ["en-US", "zh-CN", "system"]
                    delegate: RadioButton {
                        id: languageChoice
                        required property string modelData
                        objectName: "language_" + modelData
                        text: page.languageLabels[modelData]
                        Accessible.name: text
                        checked: page.preferences.language === modelData
                        Layout.fillWidth: true
                        Layout.minimumHeight: 44
                        focusPolicy: Qt.StrongFocus
                        onClicked: page.preferences.language = modelData
                        onActiveFocusChanged: Qt.callLater(page.reveal, languageChoice)
                    }
                }
                Label {
                    text: qsTr("Unsupported system languages use English.")
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }
}
