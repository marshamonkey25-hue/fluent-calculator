import QtQuick
import QtTest
import Calculator

Item {
    MainWindow { id: application; systemPreferences: testSystemPreferences }
    TestCase {
        name: "HistoryRestart"
        when: windowShown && application.visible

        function navigate(mode) {
            mouseClick(findChild(application.contentItem, "navigationButton"))
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            mouseClick(findChild(drawer.contentItem, "mode_" + mode))
            tryCompare(drawer, "visible", false)
        }
        function historyCount() {
            const sidebar = findChild(application.contentItem, "historySidebar")
            tryCompare(sidebar, "visible", true)
            return findChild(sidebar, "historyList").count
        }
        function test_ordinary_restart_keeps_recent_mode_and_clears_both_histories() {
            application.requestActivate()
            tryCompare(application, "active", true)
            application.width = 900
            const mode = restartStage.indexOf("scientific") === 0 ? "scientific" : "standard"
            if (restartStage.endsWith("write")) {
                for (const arithmeticMode of ["standard", "scientific"]) {
                    navigate(arithmeticMode)
                    for (const key of "6*7=") keyClick(key)
                    compare(historyCount(), 1)
                }
                navigate(mode)
            } else {
                compare(findChild(application.contentItem, "pageTitle").text, mode === "standard" ? "Standard" : "Scientific")
                compare(historyCount(), 0)
                for (const arithmeticMode of ["standard", "scientific"]) {
                    navigate(arithmeticMode)
                    compare(historyCount(), 0)
                    verify(findChild(findChild(application.contentItem, "historySidebar"), "historyEmpty").visible)
                }
            }
        }
        function cleanupTestCase() {
            application.close()
            compare(application.visible, false)
        }
    }
}
