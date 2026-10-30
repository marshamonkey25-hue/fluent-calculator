pragma Singleton
import QtQml

QtObject {
    function indexForKey(key) {
        for (let i = 0; i < modes.length; ++i) {
            if (modes[i].key === key)
                return i
        }
        return 0
    }
    readonly property var modes: [
        { key: "standard", title: qsTr("Standard"), source: Qt.resolvedUrl("StandardPage.qml") },
        { key: "scientific", title: qsTr("Scientific"), source: Qt.resolvedUrl("ScientificPage.qml") },
        { key: "programmer", title: qsTr("Programmer"), source: Qt.resolvedUrl("ProgrammerPage.qml") },
        { key: "graphing", title: qsTr("Graphing"), source: Qt.resolvedUrl("GraphingPage.qml") },
        { key: "date", title: qsTr("Date calculation"), source: Qt.resolvedUrl("DatePage.qml") },
        { key: "length", title: qsTr("Length"), source: Qt.resolvedUrl("ConverterPage.qml") },
        { key: "temperature", title: qsTr("Temperature"), source: Qt.resolvedUrl("ConverterPage.qml"), conversionCategory: "temperature" },
        { key: "power", title: qsTr("Power"), source: Qt.resolvedUrl("ConverterPage.qml"), conversionCategory: "power" },
        { key: "angle", title: qsTr("Angle"), source: Qt.resolvedUrl("ConverterPage.qml"), conversionCategory: "angle" }
    ]
}
