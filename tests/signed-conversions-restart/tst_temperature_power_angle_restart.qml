import QtQuick
import QtTest
import Calculator

Item {
    MainWindow { id: application; systemPreferences: testSystemPreferences }
    TestCase {
        name: "TemperaturePowerAngleRestart"
        when: windowShown && application.visible

        function control(name) { return findChild(application.contentItem, name) }
        function navigate(name) {
            mouseClick(control("navigationButton"))
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            const entry = findChild(drawer.contentItem, name)
            verify(entry !== null)
            mouseClick(entry)
            tryCompare(drawer, "visible", false)
        }
        function test_recent_signed_conversion_mode_and_preferences_survive_restart() {
            application.requestActivate()
            tryCompare(application, "active", true)
            const parts = restartStage.split("-")
            const mode = parts[0]
            if (parts[1] === "write") {
                navigate("settingsButton")
                mouseClick(control("theme_dark"))
                mouseClick(control("language_zh-CN"))
                navigate("mode_" + mode)
                mouseClick(control("converterKey_5"))
                mouseClick(control("converterKey_negate"))
                compare(control("converterValue1").text, "-5")
            } else {
                compare(parts[1], "restore")
                const titles = {temperature: "温度", power: "功率", angle: "角度"}
                compare(control("pageTitle").text, titles[mode])
                compare(control("converterValue1").text, "0", "Entry is fresh after ordinary restart")
                verify(application.color.r < 0.25, "Dark theme preference is restored")
                const source = control("converterUnit1")
                const target = control("converterUnit2")
                compare(source.currentText, {temperature: "华氏度", power: "千瓦", angle: "度"}[mode])
                const index = target.indexOfValue(source.currentValue)
                verify(index >= 0)
                target.forceActiveFocus(Qt.TabFocusReason)
                keyClick(Qt.Key_Home)
                for (let row = 0; row < index; ++row) keyClick(Qt.Key_Down)
                mouseClick(control("converterKey_1"))
                mouseClick(control("converterKey_negate"))
                compare(control("converterValue1").text, "-1")
                compare(control("converterValue2").text, "-1", "Restored mode has a functional signed converter")
            }
        }
        function cleanupTestCase() { application.close() }
    }
}
