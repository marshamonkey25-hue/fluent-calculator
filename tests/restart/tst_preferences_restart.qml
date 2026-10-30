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

        function compareAppearance(theme) {
            tryVerify(function() {
                const brightness = (application.color.r + application.color.g + application.color.b) / 3
                return theme === "dark" ? brightness < 0.25 : brightness > 0.75
            }, 5000, "Restart restores visible " + theme + " background")
            const foreground = findChild(application.contentItem, "pageTitle").color
            const brightness = (foreground.r + foreground.g + foreground.b) / 3
            verify(theme === "dark" ? brightness > 0.75 : brightness < 0.25,
                   "Restored heading remains readable")
        }

        function test_preferences_survive_ordinary_process_restart() {
            application.requestActivate()
            tryCompare(application, "active", true)
            if (restartStage === "programmer-write") {
                navigate("mode_programmer")
                compare(findChild(application.contentItem, "pageTitle").text, "程序员")
                keyClick(Qt.Key_F5)
                keyClick(Qt.Key_F12)
                keyClick("F")
                keyClick("F")
                compare(findChild(application.contentItem, "resultDisplay").text, "FF")
            } else if (restartStage === "programmer-restore") {
                compare(findChild(application.contentItem, "pageTitle").text, "程序员")
                compare(findChild(application.contentItem, "resultDisplay").text, "0")
                compare(findChild(application.contentItem, "expressionDisplay").text, "")
                compare(findChild(application.contentItem, "radix_10").checked, true)
                compare(findChild(application.contentItem, "wordWidthButton").text, "QWORD")
                compare(findChild(application.contentItem, "key_decimal").enabled, false)
                compareAppearance("dark")
                for (const key of ["7", "/", "2", "="]) keyClick(key)
                compare(findChild(application.contentItem, "resultDisplay").text, "3")
            } else if (restartStage === "scientific-write") {
                navigate("mode_scientific")
                compare(findChild(application.contentItem, "pageTitle").text, "科学")
                for (const command of ["2", "add", "3", "multiply", "4", "equals"]) {
                    const control = findChild(application.contentItem, "key_" + command)
                    verify(waitForPolish(application))
                    control.forceActiveFocus(Qt.TabFocusReason)
                    verify(waitForPolish(application))
                    mouseClick(control)
                }
                compare(findChild(application.contentItem, "resultDisplay").text, "14")
            } else if (restartStage === "scientific-restore") {
                compare(findChild(application.contentItem, "pageTitle").text, "科学")
                compare(findChild(application.contentItem, "resultDisplay").text, "0")
                compare(findChild(application.contentItem, "expressionDisplay").text, "")
                verify(findChild(application.contentItem, "key_openParenthesis") !== null)
                for (const command of ["2", "add", "3", "multiply", "4", "equals"]) {
                    const control = findChild(application.contentItem, "key_" + command)
                    verify(waitForPolish(application))
                    control.forceActiveFocus(Qt.TabFocusReason)
                    verify(waitForPolish(application))
                    mouseClick(control)
                }
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
                compareAppearance("dark")
                navigate("settingsButton")
                compare(findChild(application.contentItem, "theme_dark").checked, true)
                compare(findChild(application.contentItem, "language_zh-CN").checked, true)
            } else {
                compare(restartStage, "invalid")
                compare(findChild(application.contentItem, "pageTitle").text, "Standard")
                compare(findChild(application.contentItem, "resultDisplay").text, "0")
                compareAppearance("light")
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
