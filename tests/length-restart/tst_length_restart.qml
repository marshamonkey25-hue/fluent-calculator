import QtQuick
import QtTest
import Calculator

Item {
    MainWindow { id: application; systemPreferences: testSystemPreferences }
    TestCase {
        name: "LengthRestart"
        when: windowShown && application.visible

        function navigate(name) {
            mouseClick(findChild(application.contentItem, "navigationButton"))
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            mouseClick(findChild(drawer.contentItem, name))
            tryCompare(drawer, "visible", false)
        }

        function test_recent_length_mode_and_preferences_survive_restart() {
            application.requestActivate()
            tryCompare(application, "active", true)
            if (restartStage === "write") {
                navigate("settingsButton")
                mouseClick(findChild(application.contentItem, "theme_dark"))
                mouseClick(findChild(application.contentItem, "language_zh-CN"))
                navigate("mode_length")
                mouseClick(findChild(application.contentItem, "converterKey_5"))
                compare(findChild(application.contentItem, "converterValue1").text, "5")
            } else {
                compare(restartStage, "restore")
                compare(findChild(application.contentItem, "pageTitle").text, "长度")
                compare(findChild(application.contentItem, "converterValue1").text, "0")
                verify(application.color.r < 0.25, "Dark theme is restored")
                const source = findChild(application.contentItem, "converterUnit1")
                const target = findChild(application.contentItem, "converterUnit2")
                compare(source.currentText, "厘米")
                compare(target.currentText, "英寸")
                mouseClick(findChild(application.contentItem, "converterKey_1"))
                compare(findChild(application.contentItem, "converterValue2").text, "0.393701")
            }
        }

        function cleanupTestCase() { application.close() }
    }
}
