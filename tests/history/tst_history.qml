import QtQuick
import QtTest
import Calculator

Item {
    MainWindow { id: application; systemPreferences: testSystemPreferences }
    TestCase {
        name: "CalculationHistory"
        when: windowShown && application.visible

        function initTestCase() {
            application.requestActivate()
            tryCompare(application, "active", true)
        }
        function navigate(name) {
            mouseClick(findChild(application.contentItem, "navigationButton"))
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            mouseClick(findChild(drawer.contentItem, name))
            tryCompare(drawer, "visible", false)
        }
        function commands(sequence) {
            for (const command of sequence) {
                // Scientific's shared C/CE button changes with input state; Escape is always clear-all.
                if (command === "clear") keyClick(Qt.Key_Escape)
                else {
                    const control = findChild(application.contentItem, "key_" + command)
                    control.forceActiveFocus(Qt.TabFocusReason)
                    waitForRendering(application.contentItem)
                    mouseClick(control)
                }
            }
        }
        function openHistory() {
            const button = findChild(application.contentItem, "historyButton")
            verify(button !== null, "History is available from the calculator header")
            waitForRendering(application.contentItem)
            mouseClick(button)
            const drawer = findChild(application, "historyDrawer")
            tryCompare(drawer, "opened", true)
            return drawer
        }
        function init() {
            application.requestActivate()
            tryCompare(application, "active", true)
            application.width = 360
            for (const mode of ["scientific", "standard"]) {
                navigate("mode_" + mode)
                const drawer = openHistory()
                const clear = findChild(drawer.contentItem, "clearHistoryButton")
                if (clear.enabled) mouseClick(clear)
                drawer.close()
                tryCompare(drawer, "visible", false)
            }
            commands(["clear"])
        }
        function test_standard_history_reuse_keeps_scientific_angle_on_return() {
            navigate("mode_scientific")
            const angle = findChild(application.contentItem, "angleUnitButton")
            mouseClick(angle)
            compare(angle.text, "RAD")
            navigate("mode_standard")
            commands(["4", "2", "equals"])
            const drawer = openHistory()
            mouseClick(findChild(drawer.contentItem, "historyItem_0"))
            tryCompare(drawer, "visible", false)
            navigate("mode_scientific")
            const returnedAngle = findChild(application.contentItem, "angleUnitButton")
            compare(returnedAngle.text, "RAD")
            // 90 radians has sine about 0.894; interpreting this as degrees gives 1.
            for (const key of "90S") keyClick(key)
            const result = Number(findChild(application.contentItem, "resultDisplay").text)
            verify(Math.abs(result - 0.8939966636005579) < 1e-14, "Scientific still evaluates in radians: " + result)
            keyClick(Qt.Key_Escape)
            mouseClick(returnedAngle)
            mouseClick(returnedAngle)
            compare(returnedAngle.text, "DEG")
        }
        function test_reuse_preserves_selected_scientific_notation_for_continued_calculation() {
            navigate("mode_scientific")
            commands(["4", "2", "equals", "scientificNotation"])
            compare(findChild(application.contentItem, "resultDisplay").text, "4.2e+1")
            const drawer = openHistory()
            mouseClick(findChild(drawer.contentItem, "historyItem_0"))
            tryCompare(drawer, "visible", false)
            verify(findChild(application.contentItem, "key_scientificNotation").checked)
            // The reference restores the saved result, then keeps F-E for new operations.
            compare(findChild(application.contentItem, "resultDisplay").text, "42")
            commands(["multiply", "2", "equals"])
            compare(findChild(application.contentItem, "resultDisplay").text, "8.4e+1")
        }
        function test_reuse_scientific_record_restores_expression_and_continues_calculation() {
            navigate("mode_scientific")
            commands(["2", "add", "3", "multiply", "4", "equals"])
            commands(["clear", "9", "equals"])
            const drawer = openHistory()
            mouseClick(findChild(drawer.contentItem, "historyItem_1"))
            tryCompare(drawer, "visible", false)
            compare(findChild(application.contentItem, "resultDisplay").text, "14")
            compare(findChild(application.contentItem, "expressionDisplay").text, "2 + 3 × 4 =")
            commands(["add", "1", "equals"])
            compare(findChild(application.contentItem, "resultDisplay").text, "15")
            openHistory()
            compare(findChild(drawer.contentItem, "historyList").count, 3, "Replay does not duplicate the selected record")
            drawer.close()
            tryCompare(drawer, "visible", false)
        }
        function test_completed_calculations_show_expression_and_result_newest_first() {
            commands(["6", "multiply", "7", "equals"])
            commands(["clear", "2", "add", "3", "equals"])
            const drawer = openHistory()
            const list = findChild(drawer.contentItem, "historyList")
            compare(list.count, 2)
            compare(findChild(drawer.contentItem, "historyExpression_0").text, "2 + 3 =")
            compare(findChild(drawer.contentItem, "historyResult_0").text, "5")
            compare(findChild(drawer.contentItem, "historyExpression_1").text, "6 × 7 =")
            compare(findChild(drawer.contentItem, "historyResult_1").text, "42")
            drawer.close()
            tryCompare(drawer, "visible", false)
        }
        function test_clear_history_updates_empty_state_without_clearing_other_mode() {
            navigate("mode_scientific")
            commands(["8", "multiply", "9", "equals"])
            navigate("mode_standard")
            commands(["6", "multiply", "7", "equals"])
            let drawer = openHistory()
            const clearButton = findChild(drawer.contentItem, "clearHistoryButton")
            verify(clearButton !== null, "History offers clear all")
            mouseClick(clearButton)
            compare(findChild(drawer.contentItem, "historyList").count, 0)
            verify(findChild(drawer.contentItem, "historyEmpty").visible)
            verify(!clearButton.enabled)
            drawer.close()
            tryCompare(drawer, "visible", false)
            navigate("mode_scientific")
            drawer = openHistory()
            compare(findChild(drawer.contentItem, "historyList").count, 1)
            compare(findChild(drawer.contentItem, "historyResult_0").text, "72")
            mouseClick(findChild(drawer.contentItem, "clearHistoryButton"))
            drawer.close()
            tryCompare(drawer, "visible", false)
            navigate("mode_standard")
        }
        function test_delete_selected_record_preserves_other_records() {
            commands(["1", "add", "1", "equals", "clear", "2", "add", "2", "equals", "clear", "3", "add", "3", "equals"])
            const drawer = openHistory()
            const row = findChild(drawer.contentItem, "historyItem_0")
            mouseClick(row, row.width / 2, row.height / 2, Qt.RightButton)
            const menu = findChild(row, "historyContextMenu")
            verify(menu !== null, "Records offer the reference context menu")
            tryCompare(menu, "opened", true)
            mouseClick(findChild(menu.contentItem, "deleteHistoryItem"))
            compare(findChild(drawer.contentItem, "historyList").count, 2)
            compare(findChild(drawer.contentItem, "historyResult_0").text, "4")
            compare(findChild(drawer.contentItem, "historyResult_1").text, "2")
            drawer.close()
            tryCompare(drawer, "visible", false)
        }
        function test_history_sheet_can_close_with_keyboard_without_changing_pending_calculation() {
            commands(["6", "multiply"])
            const drawer = openHistory()
            const close = findChild(drawer.contentItem, "closeHistoryButton")
            verify(close !== null, "History sheet has a visible close action")
            close.forceActiveFocus(Qt.TabFocusReason)
            keyClick("7")
            keyClick("+")
            keyClick(Qt.Key_Space)
            tryCompare(drawer, "visible", false)
            commands(["7", "equals"])
            compare(findChild(application.contentItem, "resultDisplay").text, "42")
        }
        function test_each_mode_evicts_only_oldest_record_at_twenty_one_data() {
            return [{tag: "standard", mode: "standard"}, {tag: "scientific", mode: "scientific"}]
        }
        function test_each_mode_evicts_only_oldest_record_at_twenty_one(data) {
            navigate("mode_" + data.mode)
            for (let number = 1; number <= 20; ++number) {
                commands(["clear"])
                for (const digit of number.toString()) keyClick(digit)
                keyClick("+"); keyClick("1"); keyClick("=")
            }
            let drawer = openHistory()
            const list = findChild(drawer.contentItem, "historyList")
            compare(list.count, 20)
            compare(findChild(drawer.contentItem, "historyResult_0").text, "21")
            list.positionViewAtEnd()
            waitForRendering(list)
            compare(findChild(drawer.contentItem, "historyExpression_19").text, "1 + 1 =")
            compare(findChild(drawer.contentItem, "historyResult_19").text, "2")
            drawer.close()
            tryCompare(drawer, "visible", false)
            commands(["clear", "2", "1", "add", "1", "equals"])
            drawer = openHistory()
            compare(list.count, 20)
            list.positionViewAtBeginning()
            waitForRendering(list)
            compare(findChild(drawer.contentItem, "historyResult_0").text, "22")
            list.positionViewAtEnd()
            waitForRendering(list)
            compare(findChild(drawer.contentItem, "historyExpression_19").text, "2 + 1 =")
            compare(findChild(drawer.contentItem, "historyResult_19").text, "3")
            drawer.close()
            tryCompare(drawer, "visible", false)
        }
        function test_reuse_keeps_native_precision_sign_and_parentheses_data() {
            return [
                {tag: "exact-integer", mode: "standard", input: "9007199254740992+1=", expected: "9,007,199,254,740,993", continuation: "-9007199254740992=", continued: "1"},
                {tag: "rational", mode: "standard", input: "1/3=", expected: "0.3333333333333333", continuation: "*3=", continued: "1"},
                {tag: "negative", mode: "standard", input: "2-5=", expected: "-3", continuation: "*2=", continued: "-6"},
                {tag: "signed-operand", mode: "standard", input: ["0", ".", "0", "2", Qt.Key_F9, "+", "1", "="], expected: "0.98", continuation: "+1=", continued: "1.98"},
                {tag: "unary", mode: "standard", input: "4@+1=", expected: "3", continuation: "*2=", continued: "6"},
                {tag: "parentheses", mode: "scientific", input: "(2+3)*4=", expected: "20", continuation: "/5=", continued: "4"}
            ]
        }
        function test_reuse_keeps_native_precision_sign_and_parentheses(data) {
            navigate("mode_" + data.mode)
            for (const key of data.input) keyClick(key)
            compare(findChild(application.contentItem, "resultDisplay").text, data.expected)
            const expression = findChild(application.contentItem, "expressionDisplay").text
            commands(["clear", "9", "equals"])
            const drawer = openHistory()
            const row = findChild(drawer.contentItem, "historyItem_1")
            row.forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_Space)
            tryCompare(drawer, "visible", false)
            compare(findChild(application.contentItem, "resultDisplay").text, data.expected)
            compare(findChild(application.contentItem, "expressionDisplay").text, expression)
            for (const key of data.continuation) keyClick(key)
            compare(findChild(application.contentItem, "resultDisplay").text, data.continued)
        }
        function test_history_translates_live_and_keeps_long_records_operable_in_both_layouts() {
            navigate("mode_scientific")
            for (const key of "12345678901234567890123456789012+12345678901234567890123456789012=") keyClick(key)
            const expected = "24,691,357,802,469,135,780,246,913,578,024"
            navigate("settingsButton")
            mouseClick(findChild(application.contentItem, "language_zh-CN"))
            navigate("mode_scientific")
            application.width = 320
            const drawer = openHistory()
            compare(findChild(drawer.contentItem, "historyTitle").text, "历史记录")
            compare(findChild(drawer.contentItem, "clearHistoryButton").text, "清除所有历史记录")
            compare(findChild(drawer.contentItem, "closeHistoryButton").text, "关闭")
            compare(findChild(drawer.contentItem, "historyResult_0").text, expected)
            const row = findChild(drawer.contentItem, "historyItem_0")
            const clear = findChild(drawer.contentItem, "clearHistoryButton")
            verify(row.height < findChild(drawer.contentItem, "historyList").height)
            verify(clear.mapToItem(drawer.contentItem, 0, clear.height).y <= drawer.height)
            grabImage(application.contentItem).save("history-narrow-" + (application.darkTheme ? "dark" : "light") + ".png")
            application.width = 900
            tryCompare(drawer, "visible", false)
            const sidebar = findChild(application.contentItem, "historySidebar")
            verify(sidebar.visible)
            const result = findChild(sidebar, "historyResult_0")
            compare(result.text, expected)
            const key = findChild(application.contentItem, "key_equals")
            verify(key.mapToItem(application.contentItem, key.width, 0).x <= sidebar.mapToItem(application.contentItem, 0, 0).x)
            const record = findChild(sidebar, "historyItem_0")
            record.forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_Space)
            compare(findChild(application.contentItem, "resultDisplay").text, expected)
            grabImage(application.contentItem).save("history-wide-" + (application.darkTheme ? "dark" : "light") + ".png")
            navigate("settingsButton")
            verify(!sidebar.visible)
            mouseClick(findChild(application.contentItem, "language_system"))
            navigate("mode_scientific")
            application.width = 360
        }
        function test_only_completed_records_are_collected_and_programmer_has_no_history() {
            commands(["2", "add", "3"])
            let drawer = openHistory()
            compare(findChild(drawer.contentItem, "historyList").count, 0)
            drawer.close()
            tryCompare(drawer, "visible", false)
            commands(["equals", "equals"])
            drawer = openHistory()
            compare(findChild(drawer.contentItem, "historyList").count, 2)
            compare(findChild(drawer.contentItem, "historyResult_0").text, "8")
            compare(findChild(drawer.contentItem, "historyResult_1").text, "5")
            drawer.close()
            tryCompare(drawer, "visible", false)
            commands(["clear", "1", "divide", "0", "equals"])
            drawer = openHistory()
            compare(findChild(drawer.contentItem, "historyList").count, 2, "Errors are not completed history")
            drawer.close()
            tryCompare(drawer, "visible", false)
            navigate("mode_programmer")
            for (const width of [320, 900]) {
                application.width = width
                verify(!findChild(application.contentItem, "historyButton").visible)
                verify(!findChild(application.contentItem, "historySidebar").visible)
            }
            commands(["2", "add", "2", "equals"])
            navigate("mode_standard")
            compare(findChild(findChild(application.contentItem, "historySidebar"), "historyList").count, 2)
            navigate("mode_scientific")
            compare(findChild(findChild(application.contentItem, "historySidebar"), "historyList").count, 0)
            application.width = 360
        }
        function test_reference_sidebar_breakpoint_keeps_calculator_keys_accessible() {
            const sidebar = findChild(application.contentItem, "historySidebar")
            application.width = 559
            tryCompare(sidebar, "visible", false)
            application.width = 560
            tryCompare(sidebar, "visible", true)
            waitForRendering(application.contentItem)
            const key = findChild(application.contentItem, "key_equals")
            verify(key.width >= 44)
            verify(sidebar.width <= 320)
            verify(key.mapToItem(application.contentItem, key.width, 0).x <= sidebar.mapToItem(application.contentItem, 0, 0).x)
            application.width = 900
            waitForRendering(application.contentItem)
            fuzzyCompare(sidebar.width, 320, 1)
            application.width = 360
        }
        function cleanupTestCase() { application.close() }
    }
}
