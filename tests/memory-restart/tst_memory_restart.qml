import QtQuick
import QtTest
import Calculator

Item {
    MainWindow { id: application; systemPreferences: testSystemPreferences }
    TestCase {
        name: "MemoryRestart"
        when: windowShown && application.visible
        function navigate(name) {
            mouseClick(findChild(application.contentItem, "navigationButton"))
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            mouseClick(findChild(drawer.contentItem, name))
            tryCompare(drawer, "visible", false)
        }
        function memoryPanel() {
            mouseClick(findChild(application.contentItem, "memoryTab"))
            const panel = findChild(application.contentItem, "memorySidebar")
            tryCompare(panel, "visible", true)
            return panel
        }
        function test_ordinary_restart_clears_shared_memory_and_keeps_preferences() {
            application.requestActivate()
            tryCompare(application, "active", true)
            application.width = 900
            waitForRendering(application.contentItem)
            const mode = restartStage.split("-")[0]
            if (restartStage.endsWith("write")) {
                navigate("mode_" + mode)
                for (const key of "42") keyClick(key)
                keyClick(Qt.Key_M, Qt.ControlModifier)
                keyClick(Qt.Key_Escape)
                for (const key of "34") keyClick(key)
                keyClick(Qt.Key_M, Qt.ControlModifier)
                for (const arithmeticMode of ["standard", "scientific", "programmer"]) {
                    navigate("mode_" + arithmeticMode)
                    compare(findChild(memoryPanel(), "memoryList").count, 2)
                }
                navigate("settingsButton")
                mouseClick(findChild(application.contentItem, "theme_dark"))
                mouseClick(findChild(application.contentItem, "language_en-US"))
                navigate("mode_" + mode)
            } else {
                compare(findChild(application.contentItem, "pageTitle").text,
                        ({standard: "Standard", scientific: "Scientific", programmer: "Programmer"})[mode])
                verify(application.darkTheme, "Appearance preference survives the ordinary restart")
                for (const arithmeticMode of ["standard", "scientific", "programmer"]) {
                    navigate("mode_" + arithmeticMode)
                    const panel = memoryPanel()
                    compare(findChild(panel, "memoryList").count, 0)
                    verify(findChild(panel, "memoryEmpty").visible)
                    verify(!findChild(panel, "clearMemoryButton").enabled)
                    verify(!findChild(application.contentItem, "memory_list").enabled)
                }
            }
        }
        function cleanupTestCase() {
            application.close()
            compare(application.visible, false)
        }
    }
}
