import QtQuick
import QtTest
import Calculator

Item {
    MainWindow { id: application; systemPreferences: testSystemPreferences }
    TestCase {
        name: "SharedCalculatorMemory"
        when: windowShown && application.visible

        function navigate(name) {
            mouseClick(findChild(application.contentItem, "navigationButton"))
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            mouseClick(findChild(drawer.contentItem, name))
            tryCompare(drawer, "visible", false)
        }
        function button(command) {
            const control = findChild(application.contentItem, "memory_" + command)
            verify(control !== null, "Memory offers " + command)
            return control
        }
        function press(command) { mouseClick(button(command)) }
        function input(sequence) { for (const key of sequence) keyClick(key) }
        function result() { return findChild(application.contentItem, "resultDisplay").text }
        function init() {
            application.requestActivate()
            tryCompare(application, "active", true)
            application.width = 360
            navigate("mode_standard")
            keyClick(Qt.Key_Escape)
            if (button("clear").enabled) press("clear")
        }
        function test_save_recall_and_continue_pending_calculation() {
            input("42")
            press("save")
            keyClick(Qt.Key_Escape)
            input("8+")
            press("recall")
            compare(result(), "42")
            input("=")
            compare(result(), "50")
        }
        function test_memory_add_subtract_and_reference_shortcuts() {
            verify(!button("clear").enabled)
            verify(!button("recall").enabled)
            input("7")
            press("add")
            keyClick(Qt.Key_Escape)
            input("2")
            press("subtract")
            keyClick(Qt.Key_R, Qt.ControlModifier)
            compare(result(), "5")
            keyClick(Qt.Key_L, Qt.ControlModifier)
            verify(!button("recall").enabled)
            keyClick(Qt.Key_Escape)
            input("3")
            keyClick(Qt.Key_Q, Qt.ControlModifier)
            keyClick(Qt.Key_R, Qt.ControlModifier)
            compare(result(), "-3", "M− on empty memory stores the negated current value")
            keyClick(Qt.Key_L, Qt.ControlModifier)
            keyClick(Qt.Key_Escape)
            input("4")
            keyClick(Qt.Key_M, Qt.ControlModifier)
            keyClick(Qt.Key_Escape)
            input("6")
            keyClick(Qt.Key_P, Qt.ControlModifier)
            keyClick(Qt.Key_R, Qt.ControlModifier)
            compare(result(), "10")
        }
        function openMemory() {
            waitForRendering(application.contentItem)
            press("list")
            const drawer = findChild(application, "memoryDrawer")
            verify(drawer !== null, "Memory has a list panel")
            tryCompare(drawer, "opened", true)
            return drawer
        }
        function closeMemory(drawer) {
            mouseClick(findChild(drawer.contentItem, "closeMemoryButton"))
            tryCompare(drawer, "visible", false)
        }
        function test_selected_memory_items_modify_delete_and_recall_data() {
            return [{tag: "standard", mode: "standard"}, {tag: "scientific", mode: "scientific"}, {tag: "programmer", mode: "programmer"}]
        }
        function test_selected_memory_items_modify_delete_and_recall(data) {
            navigate("mode_" + data.mode)
            input("42")
            press("save")
            keyClick(Qt.Key_Escape)
            input("9")
            press("save")
            keyClick(Qt.Key_Escape)
            input("3")
            const drawer = openMemory()
            const list = findChild(drawer.contentItem, "memoryList")
            compare(list.count, 2)
            compare(findChild(drawer.contentItem, "memoryValue_0").text, "9")
            compare(findChild(drawer.contentItem, "memoryValue_1").text, "42")
            mouseClick(findChild(drawer.contentItem, "memoryAdd_1"))
            compare(findChild(drawer.contentItem, "memoryValue_1").text, "45")
            mouseClick(findChild(drawer.contentItem, "memorySubtract_1"))
            compare(findChild(drawer.contentItem, "memoryValue_1").text, "42")
            mouseClick(findChild(drawer.contentItem, "memoryDelete_0"))
            compare(list.count, 1)
            compare(findChild(drawer.contentItem, "memoryValue_0").text, "42")
            closeMemory(drawer)
            keyClick(Qt.Key_Escape)
            input("8+")
            openMemory()
            const row = findChild(drawer.contentItem, "memoryItem_0")
            row.forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_Space)
            tryCompare(drawer, "visible", false)
            input("=")
            compare(result(), "50")
            openMemory()
            mouseClick(findChild(drawer.contentItem, "clearMemoryButton"))
            compare(list.count, 0)
            verify(findChild(drawer.contentItem, "memoryEmpty").visible)
            verify(!findChild(drawer.contentItem, "clearMemoryButton").enabled)
            closeMemory(drawer)
            verify(!button("list").enabled)
        }
        function test_memory_is_shared_and_formatted_by_each_arithmetic_mode() {
            input("255.5")
            press("save")
            navigate("mode_scientific")
            press("recall")
            compare(result(), "255.5")
            let drawer = openMemory()
            compare(findChild(drawer.contentItem, "memoryValue_0").text, "255.5")
            closeMemory(drawer)
            navigate("mode_programmer")
            const programmerRecall = findChild(application.contentItem, "memory_recall")
            verify(!programmerRecall || !programmerRecall.visible, "Programmer follows the reference MS/list toolbar")
            drawer = openMemory()
            compare(findChild(drawer.contentItem, "memoryValue_0").text, "255")
            closeMemory(drawer)
            keyClick(Qt.Key_F5)
            drawer = openMemory()
            compare(findChild(drawer.contentItem, "memoryValue_0").text, "FF")
            closeMemory(drawer)
            keyClick(Qt.Key_F12)
            keyClick(Qt.Key_F6)
            drawer = openMemory()
            compare(findChild(drawer.contentItem, "memoryValue_0").text, "-1")
            mouseClick(findChild(drawer.contentItem, "memoryItem_0"))
            tryCompare(drawer, "visible", false)
            compare(result(), "-1")
            input("+1=")
            compare(result(), "0")
            press("save")
            navigate("mode_standard")
            drawer = openMemory()
            compare(findChild(drawer.contentItem, "memoryList").count, 2)
            compare(findChild(drawer.contentItem, "memoryValue_0").text, "0")
            compare(findChild(drawer.contentItem, "memoryValue_1").text, "255.5", "Programmer recall does not round the stored rational")
            closeMemory(drawer)
        }
        function test_memory_panel_uses_reference_sidebar_and_translates_in_both_layouts() {
            application.width = 560
            const tab = findChild(application.contentItem, "memoryTab")
            verify(tab !== null, "Wide calculators offer the Memory tab beside History")
            tryCompare(tab, "visible", true)
            waitForRendering(application.contentItem)
            mouseClick(tab)
            const sidebar = findChild(application.contentItem, "memorySidebar")
            tryCompare(sidebar, "visible", true)
            verify(!button("list").visible, "Docked Memory replaces the narrow-window list button")
            verify(findChild(sidebar, "memoryEmpty").visible)
            verify(!findChild(sidebar, "clearMemoryButton").enabled)
            const key = findChild(application.contentItem, "key_equals")
            verify(key.width >= 44)
            waitForRendering(application.contentItem)
            verify(key.mapToItem(application.contentItem, key.width, 0).x <= sidebar.mapToItem(application.contentItem, 0, 0).x,
                   "Key right=" + key.mapToItem(application.contentItem, key.width, 0).x + " panel left=" + sidebar.mapToItem(application.contentItem, 0, 0).x + " panel width=" + sidebar.width)
            input("9007199254740992+1=")
            press("save")
            compare(findChild(sidebar, "memoryValue_0").text, "9,007,199,254,740,993")
            mouseClick(findChild(application.contentItem, "historyTab"))
            verify(findChild(application.contentItem, "historySidebar").visible)
            mouseClick(tab)
            application.width = 320
            const drawer = openMemory()
            compare(findChild(drawer.contentItem, "memoryValue_0").text, "9,007,199,254,740,993")
            grabImage(application.contentItem).save("memory-narrow-" + (application.darkTheme ? "dark" : "light") + ".png")
            application.width = 900
            tryCompare(drawer, "visible", false)
            tryCompare(sidebar, "visible", true)
            navigate("settingsButton")
            verify(!sidebar.visible)
            mouseClick(findChild(application.contentItem, "language_zh-CN"))
            navigate("mode_standard")
            mouseClick(findChild(application.contentItem, "memoryTab"))
            compare(findChild(sidebar, "memoryTitle").text, "内存")
            compare(findChild(sidebar, "clearMemoryButton").text, "清除所有内存")
            compare(button("save").Accessible.name, "内存存储")
            grabImage(application.contentItem).save("memory-wide-" + (application.darkTheme ? "dark" : "light") + ".png")
            navigate("mode_programmer")
            tryCompare(sidebar, "visible", true)
            verify(!findChild(application.contentItem, "historyTab").visible)
            mouseClick(findChild(sidebar, "clearMemoryButton"))
            verify(findChild(sidebar, "memoryEmpty").visible)
            navigate("settingsButton")
            mouseClick(findChild(application.contentItem, "language_system"))
            navigate("mode_standard")
        }
        function test_memory_item_context_menu_supports_mouse_and_keyboard_data() {
            return [{tag: "standard", mode: "standard"}, {tag: "scientific", mode: "scientific"}, {tag: "programmer", mode: "programmer"}]
        }
        function test_memory_item_context_menu_supports_mouse_and_keyboard(data) {
            navigate("mode_" + data.mode)
            input("42")
            press("save")
            keyClick(Qt.Key_Escape)
            input("3")
            const drawer = openMemory()
            let row = findChild(drawer.contentItem, "memoryItem_0")
            mouseClick(row, row.width / 2, 8, Qt.RightButton)
            let menu = findChild(row, "memoryContextMenu")
            verify(menu !== null, "Memory items offer the reference context actions")
            tryCompare(menu, "opened", true)
            mouseClick(findChild(menu.contentItem, "subtractMemoryItem"))
            compare(findChild(drawer.contentItem, "memoryValue_0").text, "39")
            row = findChild(drawer.contentItem, "memoryItem_0")
            row.forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_F10, Qt.ShiftModifier)
            menu = findChild(row, "memoryContextMenu")
            tryCompare(menu, "opened", true)
            mouseClick(findChild(menu.contentItem, "addMemoryItem"))
            compare(findChild(drawer.contentItem, "memoryValue_0").text, "42")
            row = findChild(drawer.contentItem, "memoryItem_0")
            mouseClick(row, row.width / 2, 8, Qt.RightButton)
            menu = findChild(row, "memoryContextMenu")
            tryCompare(menu, "opened", true)
            mouseClick(findChild(menu.contentItem, "deleteMemoryItem"))
            compare(findChild(drawer.contentItem, "memoryList").count, 0)
            tryCompare(drawer, "visible", false)
            const focusAction = data.mode === "programmer" ? "save" : "add"
            tryCompare(button(focusAction), "activeFocus", true)
            keyClick(Qt.Key_Space)
            if (data.mode === "programmer") {
                openMemory()
                const recalled = findChild(drawer.contentItem, "memoryItem_0")
                recalled.forceActiveFocus(Qt.TabFocusReason)
                keyClick(Qt.Key_Space)
                tryCompare(drawer, "visible", false)
            } else {
                press("recall")
            }
            compare(result(), "3", "Focus returns to M+/MS after clearing the final item from its context menu")
        }
        function test_memory_limit_evicts_only_oldest_at_one_hundred_and_one() {
            for (let number = 1; number <= 100; ++number) {
                keyClick(Qt.Key_Escape)
                input(number.toString())
                press("save")
            }
            const drawer = openMemory()
            const list = findChild(drawer.contentItem, "memoryList")
            compare(list.count, 100)
            compare(findChild(drawer.contentItem, "memoryValue_0").text, "100")
            list.positionViewAtEnd()
            waitForRendering(list)
            compare(findChild(drawer.contentItem, "memoryValue_99").text, "1")
            closeMemory(drawer)
            keyClick(Qt.Key_Escape)
            input("101")
            press("save")
            openMemory()
            compare(list.count, 100)
            list.positionViewAtBeginning()
            waitForRendering(list)
            compare(findChild(drawer.contentItem, "memoryValue_0").text, "101")
            list.positionViewAtEnd()
            waitForRendering(list)
            compare(findChild(drawer.contentItem, "memoryValue_99").text, "2")
            mouseClick(findChild(drawer.contentItem, "memoryItem_99"))
            tryCompare(drawer, "visible", false)
            compare(result(), "2")
        }
        function test_error_disables_memory_arithmetic_but_panel_can_clear_memory() {
            input("42")
            press("save")
            keyClick(Qt.Key_Escape)
            input("1/0=")
            for (const action of ["save", "recall", "add", "subtract", "clear"])
                verify(!button(action).enabled)
            const drawer = openMemory()
            const list = findChild(drawer.contentItem, "memoryList")
            compare(list.count, 1)
            verify(!list.enabled)
            mouseClick(findChild(drawer.contentItem, "clearMemoryButton"))
            compare(list.count, 0)
            closeMemory(drawer)
            keyClick(Qt.Key_Escape)
            verify(button("save").enabled)
        }
        function test_small_window_keeps_memory_and_keypad_accessible_data() {
            return [{tag: "standard", mode: "standard"}, {tag: "scientific", mode: "scientific"}, {tag: "programmer", mode: "programmer"}]
        }
        function test_small_window_keeps_memory_and_keypad_accessible(data) {
            navigate("mode_" + data.mode)
            application.width = 320
            application.height = 460
            waitForRendering(application.contentItem)
            const save = button("save")
            save.forceActiveFocus(Qt.TabFocusReason)
            waitForRendering(application.contentItem)
            verify(save.mapToItem(application.contentItem, 0, 0).y >= 0)
            verify(save.mapToItem(application.contentItem, save.width, save.height).y <= application.height)
            const minimumTarget = data.mode === "programmer" ? 28 : 44
            verify(save.width >= minimumTarget && save.height >= minimumTarget)
            const equals = findChild(application.contentItem, "key_equals")
            equals.forceActiveFocus(Qt.TabFocusReason)
            waitForRendering(application.contentItem)
            verify(equals.mapToItem(application.contentItem, 0, 0).y >= 0)
            verify(equals.mapToItem(application.contentItem, equals.width, equals.height).y <= application.height,
                   "Keypad fits the minimum window or scrolls its focused key into view")
            application.height = 700
        }
        function test_scientific_notation_reformats_memory_without_losing_value() {
            navigate("mode_scientific")
            input("42")
            press("save")
            keyClick(Qt.Key_V)
            const drawer = openMemory()
            compare(findChild(drawer.contentItem, "memoryValue_0").text, "4.2e+1")
            closeMemory(drawer)
            keyClick(Qt.Key_V)
            openMemory()
            compare(findChild(drawer.contentItem, "memoryValue_0").text, "42")
            closeMemory(drawer)
        }
        function test_memory_retains_native_precision_data() {
            return [
                {tag: "exact-integer", input: "9007199254740992+1=", expected: "9,007,199,254,740,993", continuation: "-9007199254740992=", continued: "1"},
                {tag: "rational", input: "1/3=", expected: "0.3333333333333333", continuation: "*3=", continued: "1"}
            ]
        }
        function test_memory_retains_native_precision(data) {
            input(data.input)
            press("save")
            keyClick(Qt.Key_Escape)
            press("recall")
            compare(result(), data.expected)
            input(data.continuation)
            compare(result(), data.continued)
            navigate("mode_scientific")
            press("recall")
            input(data.continuation)
            compare(result(), data.continued, "The same native value survives the mode switch")
        }
        function test_context_delete_keeps_focus_on_nearest_remaining_memory_item() {
            input("1")
            press("save")
            keyClick(Qt.Key_Escape)
            input("2")
            press("save")
            keyClick(Qt.Key_Escape)
            input("3")
            press("save")
            const drawer = openMemory()
            let row = findChild(drawer.contentItem, "memoryItem_1")
            row.forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_F10, Qt.ShiftModifier)
            let menu = findChild(row, "memoryContextMenu")
            tryCompare(menu, "opened", true)
            mouseClick(findChild(menu.contentItem, "deleteMemoryItem"))
            compare(findChild(drawer.contentItem, "memoryList").count, 2)
            row = findChild(drawer.contentItem, "memoryItem_1")
            compare(findChild(drawer.contentItem, "memoryValue_1").text, "1")
            tryCompare(row, "activeFocus", true)
            keyClick(Qt.Key_F10, Qt.ShiftModifier)
            menu = findChild(row, "memoryContextMenu")
            tryCompare(menu, "opened", true)
            mouseClick(findChild(menu.contentItem, "deleteMemoryItem"))
            row = findChild(drawer.contentItem, "memoryItem_0")
            tryCompare(row, "activeFocus", true)
            keyClick(Qt.Key_Space)
            tryCompare(drawer, "visible", false)
            compare(result(), "3")
        }
        function cleanupTestCase() { application.close() }
    }
}
