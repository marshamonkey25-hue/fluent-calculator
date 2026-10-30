import QtQuick
import QtTest
import Calculator

Item {
    MainWindow { id: application; systemPreferences: testSystemPreferences }
    TestCase {
        name: "PreferencesRestart"
        when: windowShown && application.visible

        function navigate(name) {
            mouseClick(findChild(application.contentItem, "navigationButton"))
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            mouseClick(findChild(drawer.contentItem, name))
            tryCompare(drawer, "visible", false)
        }

        function test_preferences_survive_ordinary_process_restart() {
            application.requestActivate()
            tryCompare(application, "active", true)
            if (restartStage === "scientific-write") {
                navigate("mode_scientific")
                compare(findChild(application.contentItem, "pageTitle").text, "科学")
                for (const command of ["2", "add", "3", "multiply", "4", "equals"])
                    mouseClick(findChild(application.contentItem, "key_" + command))
                compare(findChild(application.contentItem, "resultDisplay").text, "14")
            } else if (restartStage === "scientific-restore") {
                compare(findChild(application.contentItem, "pageTitle").text, "科学")
                compare(findChild(application.contentItem, "resultDisplay").text, "0")
                compare(findChild(application.contentItem, "expressionDisplay").text, "")
                verify(findChild(application.contentItem, "key_openParenthesis") !== null)
                for (const command of ["2", "add", "3", "multiply", "4", "equals"])
                    mouseClick(findChild(application.contentItem, "key_" + command))
                compare(findChild(application.contentItem, "resultDisplay").text, "14")
            } else if (restartStage === "write") {
                navigate("settingsButton")
                mouseClick(findChild(application.contentItem, "theme_dark"))
                mouseClick(findChild(application.contentItem, "language_zh-CN"))
                navigate("mode_standard")
                compare(findChild(application.contentItem, "pageTitle").text, "标准")
                for (const command of ["6", "multiply", "7", "equals"])
                    mouseClick(findChild(application.contentItem, "key_" + command))
                compare(findChild(application.contentItem, "resultDisplay").text, "42")
            } else if (restartStage === "restore") {
                compare(findChild(application.contentItem, "pageTitle").text, "标准")
                compare(findChild(application.contentItem, "resultDisplay").text, "0")
                compare(findChild(application.contentItem, "expressionDisplay").text, "")
                tryCompare(Application.styleHints, "colorScheme", Qt.Dark)
                navigate("settingsButton")
                compare(findChild(application.contentItem, "theme_dark").checked, true)
                compare(findChild(application.contentItem, "language_zh-CN").checked, true)
            } else {
                compare(restartStage, "invalid")
                compare(findChild(application.contentItem, "pageTitle").text, "Standard")
                compare(findChild(application.contentItem, "resultDisplay").text, "0")
                tryCompare(Application.styleHints, "colorScheme", Qt.Light)
                navigate("settingsButton")
                compare(findChild(application.contentItem, "theme_system").checked, true)
                compare(findChild(application.contentItem, "language_system").checked, true)
            }
        }

        function cleanupTestCase() {
            application.close()
            compare(application.visible, false)
        }
    }
}
