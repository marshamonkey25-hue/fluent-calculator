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
        { key: "standard", title: qsTr("Standard"), source: Qt.resolvedUrl("StandardPage.qml") }
    ]
}
