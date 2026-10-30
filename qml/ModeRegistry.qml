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
        { key: "volume", title: qsTr("Volume"), source: Qt.resolvedUrl("ConverterPage.qml"), converterCategory: "volume" },
        { key: "length", title: qsTr("Length"), source: Qt.resolvedUrl("ConverterPage.qml"), converterCategory: "length" },
        { key: "weight", title: qsTr("Weight and Mass"), source: Qt.resolvedUrl("ConverterPage.qml"), converterCategory: "weight" },
        { key: "area", title: qsTr("Area"), source: Qt.resolvedUrl("ConverterPage.qml"), converterCategory: "area" },
        { key: "energy", title: qsTr("Energy"), source: Qt.resolvedUrl("ConverterPage.qml"), converterCategory: "energy" },
        { key: "speed", title: qsTr("Speed"), source: Qt.resolvedUrl("ConverterPage.qml"), converterCategory: "speed" },
        { key: "time", title: qsTr("Time"), source: Qt.resolvedUrl("ConverterPage.qml"), converterCategory: "time" },
        { key: "pressure", title: qsTr("Pressure"), source: Qt.resolvedUrl("ConverterPage.qml"), converterCategory: "pressure" }
    ]
}
