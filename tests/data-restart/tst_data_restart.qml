import QtQuick
import QtTest
import Calculator

Item {
    MainWindow { id: application; systemPreferences: testSystemPreferences }
    TestCase {
        name: "DataRestart"
        when: windowShown && application.visible

        function control(name) {
            const item = findChild(application.contentItem, name)
            verify(item !== null, "Visible control: " + name)
            return item
        }

        function navigate(key) {
            mouseClick(control("navigationButton"))
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            const item = findChild(drawer.contentItem, key === "settings" ? "settingsButton" : "mode_" + key)
            verify(item !== null, "Functional navigation entry: " + key)
            const list = findChild(drawer.contentItem, "navigationList")
            for (let attempt = 0; attempt < 15 && key !== "settings"; ++attempt) {
                const point = item.mapToItem(list, 0, 0)
                if (point.y >= 0 && point.y + item.height <= list.height) break
                mouseWheel(list, list.width / 2, list.height / 2, 0, point.y < 0 ? 120 : -120)
                tryCompare(list, "moving", false)
            }
            mouseClick(item)
            tryCompare(drawer, "visible", false)
        }

        function test_recent_data_mode_and_preferences_survive_restart() {
            application.requestActivate()
            tryCompare(application, "active", true)
            if (restartStage === "write") {
                navigate("settings")
                mouseClick(control("theme_dark"))
                mouseClick(control("language_zh-CN"))
                navigate("data")
                mouseClick(control("converterKey_5"))
                compare(control("converterValue1").text, "5")
                compare(control("converterValue2").text, "5,000")
            } else {
                compare(restartStage, "restore")
                compare(control("pageTitle").text, "数据")
                compare(control("converterValue1").text, "0")
                verify(application.color.r < 0.25, "Dark theme is restored")
                compare(control("converterUnit1").currentText, "GB")
                compare(control("converterUnit2").currentText, "MB")
                mouseClick(control("converterKey_1"))
                compare(control("converterValue2").text, "1,000")
            }
        }

        function cleanupTestCase() { application.close() }
    }
}
