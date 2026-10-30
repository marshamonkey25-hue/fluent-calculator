import QtQuick
import QtTest
import Calculator

Item {
    MainWindow { id: application; systemPreferences: testSystemPreferences; height: 632 }
    TestCase {
        name: "ScientificPrecedence"
        when: windowShown && application.visible

        function initTestCase() {
            application.requestActivate()
            tryCompare(application, "active", true)
        }

        function selectMode(mode) {
            mouseClick(findChild(application.contentItem, "navigationButton"))
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            const entry = findChild(drawer.contentItem, "mode_" + mode)
            verify(entry !== null, "Navigation contains " + mode)
            mouseClick(entry)
            tryCompare(drawer, "visible", false)
        }

        function button(command) {
            const item = findChild(application.contentItem, "key_" + command)
            verify(item !== null, "Visible calculator key: " + command)
            return item
        }

        function clickCommands(commands) {
            for (const command of commands)
                mouseClick(button(command))
        }

        function result() {
            return findChild(application.contentItem, "resultDisplay").text
        }

        function expression() {
            return findChild(application.contentItem, "expressionDisplay").text
        }

        function init() {
            selectMode("scientific")
            clickCommands(["clear"])
        }

        function test_parentheses_change_precedence_and_support_nesting_data() {
            return [{ tag: "mouse", keyboard: false }, { tag: "keyboard", keyboard: true }]
        }

        function test_parentheses_change_precedence_and_support_nesting(data) {
            if (data.keyboard) {
                for (const character of "((2+3)*4)=")
                    keyClick(character)
            } else {
                clickCommands(["openParenthesis", "openParenthesis", "2", "add", "3",
                               "closeParenthesis", "multiply", "4", "closeParenthesis", "equals"])
            }
            compare(result(), "20")
            compare(expression(), "((2 + 3) × 4) =")
        }

        function test_scientific_precedence_and_standard_input_order() {
            selectMode("scientific")
            clickCommands(["2", "add", "3", "multiply", "4", "equals"])
            compare(result(), "14")
            compare(expression(), "2 + 3 × 4 =")
            selectMode("standard")
            compare(result(), "0")
            compare(expression(), "")
            verify(findChild(application.contentItem, "key_openParenthesis") === null)
            clickCommands(["2", "add", "3", "multiply", "4", "equals"])
            compare(result(), "20")
            selectMode("scientific")
            compare(result(), "0")
            compare(expression(), "")
        }

        // Pinned CalculatorManagerTestScientificParenthesis commands3/4:
        // unmatched ')' is ignored and a number followed by '(' implies ×.
        function test_unmatched_close_and_implicit_multiplication_follow_core() {
            clickCommands(["1", "2", "closeParenthesis", "closeParenthesis", "openParenthesis"])
            compare(expression(), "12 × (")
            compare(result(), "12")
            clickCommands(["3", "closeParenthesis", "equals"])
            compare(result(), "36")
        }

        // Pinned CEngine/scicomm.cpp IDC_EQU closes remaining parentheses.
        function test_equals_closes_unfinished_parentheses() {
            clickCommands(["2", "add", "openParenthesis", "3", "multiply", "4", "equals"])
            compare(result(), "14")
            compare(expression(), "2 + (3 × 4) =")
        }

        // Pinned Header Files/History.h MAXPRECDEPTH = 25; the next '(' is ignored.
        function test_parenthesis_depth_limit_and_clear_recovery() {
            for (let i = 0; i < 25; ++i)
                mouseClick(button("openParenthesis"))
            compare(expression(), "(".repeat(25))
            mouseClick(button("openParenthesis"))
            compare(expression(), "(".repeat(25))
            clickCommands(["1", "equals"])
            compare(result(), "1")
            clickCommands(["clear"])
            compare(expression(), "")
            clickCommands(["openParenthesis", "6", "add", "2", "closeParenthesis", "divide", "4", "equals"])
            compare(result(), "2")
        }

        // Pinned CalculatorManager.h ScientificModePrecision = 32; values remain strings.
        function test_scientific_32_digit_input_and_rational_precision() {
            for (const digit of "12345678901234567890123456789012")
                mouseClick(button(digit))
            compare(result(), "12,345,678,901,234,567,890,123,456,789,012")
            mouseClick(button("3"))
            compare(result(), "12,345,678,901,234,567,890,123,456,789,012")
            clickCommands(["clear", "1", "divide", "3", "equals"])
            compare(result(), "0.33333333333333333333333333333333")
            clickCommands(["multiply", "3", "equals"])
            compare(result(), "1")
        }

        function test_decimal_input_and_error_recovery_data() {
            return [{ tag: "mouse", keyboard: false }, { tag: "keyboard", keyboard: true }]
        }

        function test_decimal_input_and_error_recovery(data) {
            clickCommands(["openParenthesis", "1", "divide", "0", "equals"])
            const error = findChild(application.contentItem, "errorIndicator")
            verify(error.visible)
            compare(result(), Qt.locale().name.indexOf("zh") === 0 ? "除数不能为零" : "Cannot divide by zero")
            if (data.keyboard) {
                keyClick(Qt.Key_Escape)
                for (const character of "(0.1+0.2)*2=")
                    keyClick(character)
            } else {
                clickCommands(["clear", "openParenthesis", "0", "decimal", "1", "add", "0", "decimal", "2",
                               "closeParenthesis", "multiply", "2", "equals"])
            }
            verify(!error.visible)
            compare(result(), "0.6")
        }

        function test_long_expression_can_be_scrolled_without_overlapping_keys() {
            for (const digit of "12345678901234567890123456789012")
                keyClick(digit)
            keyClick("+")
            for (const digit of "12345678901234567890123456789012")
                keyClick(digit)
            keyClick("=")
            const viewport = findChild(application.contentItem, "expressionViewport")
            verify(viewport !== null, "Long Scientific expressions have a scrollable viewport")
            verify(viewport.clip)
            verify(viewport.contentWidth > viewport.width)
            tryVerify(function() { return viewport.contentX > 0 })
            const before = viewport.contentX
            mouseDrag(viewport, 10, viewport.height / 2, viewport.width - 20, 0)
            tryVerify(function() { return viewport.contentX < before })
            compare(expression(), "12345678901234567890123456789012 + 12345678901234567890123456789012 =")
        }

        function test_scientific_keys_and_title_are_accessible_at_window_sizes_data() {
            return [{ tag: "narrow", width: 320, height: 632 }, { tag: "wide", width: 900, height: 700 }]
        }

        function test_scientific_keys_and_title_are_accessible_at_window_sizes(data) {
            application.width = data.width
            application.height = data.height
            waitForRendering(application.contentItem)
            const title = findChild(application.contentItem, "pageTitle")
            verify(title !== null, "Current mode has a visible title")
            compare(title.text, Qt.locale().name.indexOf("zh") === 0 ? "科学" : "Scientific")
            const commands = ["clear", "openParenthesis", "closeParenthesis", "divide", "7", "8", "9", "multiply",
                              "4", "5", "6", "subtract", "1", "2", "3", "add", "0", "decimal", "equals"]
            for (const command of commands) {
                const key = button(command)
                const position = key.mapToItem(application.contentItem, 0, 0)
                verify(key.visible && key.enabled)
                verify(key.width >= 44 && key.height >= 44)
                verify(position.x >= 0 && position.y >= 0)
                verify(position.x + key.width <= application.width + 1)
                verify(position.y + key.height <= application.height + 1)
            }
            compare(button("openParenthesis").Accessible.name, Qt.locale().name.indexOf("zh") === 0 ? "左括号" : "Open parenthesis")
            compare(button("closeParenthesis").Accessible.name, Qt.locale().name.indexOf("zh") === 0 ? "右括号" : "Close parenthesis")
            button("openParenthesis").forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_Tab)
            verify(button("closeParenthesis").activeFocus)
            keyClick(Qt.Key_Space)
            compare(expression(), "") // unmatched close remains harmless through focus activation
            clickCommands(["openParenthesis", "2", "add", "3", "closeParenthesis", "multiply", "4", "equals"])
            compare(result(), "20")
            const scheme = Application.styleHints.colorScheme === Qt.Dark ? "dark" : "light"
            grabImage(application.contentItem).save("scientific-" + scheme + "-" + data.tag + ".png")
            application.width = 360
            application.height = 632
        }

        function openSettings() {
            mouseClick(findChild(application.contentItem, "navigationButton"))
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            mouseClick(findChild(drawer.contentItem, "settingsButton"))
            tryCompare(drawer, "visible", false)
        }

        function test_runtime_translation_preserves_scientific_calculation() {
            openSettings()
            mouseClick(findChild(application.contentItem, "language_en-US"))
            selectMode("scientific")
            clickCommands(["openParenthesis", "6", "multiply"])
            openSettings()
            mouseClick(findChild(application.contentItem, "language_zh-CN"))
            selectMode("scientific")
            compare(findChild(application.contentItem, "pageTitle").text, "科学")
            compare(button("openParenthesis").Accessible.name, "左括号")
            compare(button("closeParenthesis").Accessible.name, "右括号")
            compare(button("clear").Accessible.name, "清除")
            clickCommands(["7", "closeParenthesis", "equals"])
            compare(result(), "42")
            compare(expression(), "(6 × 7) =")
            clickCommands(["clear", "1", "divide", "0", "equals"])
            compare(result(), "除数不能为零")
            compare(findChild(application.contentItem, "errorIndicator").text, "错误")
            openSettings()
            mouseClick(findChild(application.contentItem, "language_en-US"))
            selectMode("scientific")
            compare(result(), "Cannot divide by zero")
            compare(button("openParenthesis").Accessible.name, "Open parenthesis")
            openSettings()
            mouseClick(findChild(application.contentItem, "language_system"))
            selectMode("scientific")
        }

        function test_settings_keep_hidden_scientific_shortcuts_inactive() {
            clickCommands(["6", "multiply"])
            openSettings()
            findChild(application.contentItem, "theme_light").forceActiveFocus(Qt.TabFocusReason)
            for (const key of ["7", "(", ")", Qt.Key_Escape, Qt.Key_Return])
                keyClick(key)
            selectMode("scientific")
            clickCommands(["7", "equals"])
            compare(result(), "42", "Settings must preserve the pending Scientific calculation")
            compare(expression(), "6 × 7 =")
        }

        function cleanupTestCase() {
            application.close()
        }
    }
}
