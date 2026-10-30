pragma Singleton
import QtQml

QtObject {
    readonly property var modes: [
        { key: "standard", title: qsTr("Standard"), source: Qt.resolvedUrl("StandardPage.qml") },
        { key: "programmer", title: qsTr("Programmer"), source: Qt.resolvedUrl("ProgrammerPage.qml") }
    ]
}
