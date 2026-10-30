import QtQuick
import QtTest
import Calculator

Item {
    MainWindow { id: application; systemPreferences: testSystemPreferences }
    TestCase {
        name: "StandardCalculator"
        when: windowShown && application.visible

        function initTestCase() {
            application.requestActivate()
            tryCompare(application, "active", true)
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

        function init() {
            clickCommands(["clear"])
        }

        function enterNumber(text, keyboard) {
            for (const character of text) {
                if (keyboard)
                    keyClick(character)
                else
                    mouseClick(button(character === "." ? "decimal" : character))
            }
        }

        function test_exact_integer_beyond_javascript_safe_range_data() {
            return [
                { tag: "mouse", keyboard: false },
                { tag: "keyboard", keyboard: true }
            ]
        }

        function test_exact_integer_beyond_javascript_safe_range(data) {
            const result = findChild(application.contentItem, "resultDisplay")
            enterNumber("9007199254740992", data.keyboard)
            if (data.keyboard) keyClick("+")
            else mouseClick(button("add"))
            enterNumber("1", data.keyboard)
            if (data.keyboard) keyClick(Qt.Key_Enter)
            else mouseClick(button("equals"))
            compare(result.text, "9,007,199,254,740,993")
            if (data.keyboard) keyClick("-")
            else mouseClick(button("subtract"))
            enterNumber("9007199254740992", data.keyboard)
            if (data.keyboard) keyClick("=")
            else mouseClick(button("equals"))
            compare(result.text, "1")
        }

        function test_division_error_is_explicit_and_clear_recovers_data() {
            const chinese = Qt.locale().name.indexOf("zh") === 0
            return [
                { tag: "divide-by-zero", numerator: "8", message: chinese ? "除数不能为零" : "Cannot divide by zero" },
                { tag: "undefined", numerator: "0", message: chinese ? "结果未定义" : "Result is undefined" }
            ]
        }

        function test_division_error_is_explicit_and_clear_recovers(data) {
            clickCommands([data.numerator, "divide", "0", "equals"])
            const result = findChild(application.contentItem, "resultDisplay")
            compare(result.text, data.message)
            const error = findChild(application.contentItem, "errorIndicator")
            verify(error !== null, "Error has a visible state label")
            compare(error.visible, true)
            clickCommands(["clear"])
            compare(error.visible, false)
            compare(result.text, "0")
            compare(findChild(application.contentItem, "expressionDisplay").text, "")
            clickCommands(["9", "divide", "3", "equals"])
            compare(result.text, "3")
        }

        function test_decimal_precision_and_core_digit_limit_are_preserved() {
            clickCommands(["0", "decimal", "1", "add", "0", "decimal", "2", "equals"])
            const result = findChild(application.contentItem, "resultDisplay")
            compare(result.text, "0.3")
            clickCommands(["clear"])
            enterNumber("1234567890123456", false)
            compare(result.text, "1,234,567,890,123,456")
            mouseClick(button("7"))
            compare(result.text, "1,234,567,890,123,456")
            clickCommands(["clear", "2", "subtract", "5", "equals"])
            compare(result.text, "-3")
        }

        function test_operator_labels_and_keyboard_focus_are_accessible() {
            const chinese = Qt.locale().name.indexOf("zh") === 0
            compare(button("multiply").Accessible.name, chinese ? "乘" : "Multiply")
            compare(button("divide").Accessible.name, chinese ? "除" : "Divide")
            compare(button("clear").Accessible.name, chinese ? "清除" : "Clear")
            compare(button("decimal").Accessible.name, chinese ? "小数点" : "Decimal separator")
            compare(button("equals").Accessible.name, chinese ? "等于" : "Equals")
            button("clear").forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_Tab)
            verify(button("divide").activeFocus)
        }

        function test_navigation_returns_to_standard_without_losing_calculation() {
            clickCommands(["6", "multiply"])
            const navigationButton = findChild(application.contentItem, "navigationButton")
            mouseClick(navigationButton)
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            const standardMode = findChild(drawer.contentItem, "mode_standard")
            verify(standardMode !== null)
            mouseClick(standardMode)
            tryCompare(drawer, "visible", false)
            keyClick("7")
            keyClick(Qt.Key_Return)
            compare(findChild(application.contentItem, "resultDisplay").text, "42")
        }

        function test_keyboard_matches_mouse_for_decimal_arithmetic_and_clear() {
            clickCommands(["clear", "1", "decimal", "5", "add", "2", "decimal", "5", "equals"])
            const result = findChild(application.contentItem, "resultDisplay")
            compare(result.text, "4")
            keyClick(Qt.Key_Escape)
            compare(result.text, "0")
            keyClick("1")
            keyClick(".")
            keyClick("5")
            keyClick("+")
            keyClick("2")
            keyClick(".")
            keyClick("5")
            keyClick(Qt.Key_Return)
            compare(result.text, "4")
        }

        function cleanupTestCase() {
            application.close()
            compare(application.visible, false)
        }

        function test_window_layout_keeps_all_keys_accessible_data() {
            return [
                { tag: "narrow", width: 320, height: 460 },
                { tag: "wide", width: 900, height: 700 }
            ]
        }

        function test_window_layout_keeps_all_keys_accessible(data) {
            application.width = data.width
            application.height = data.height
            waitForRendering(application.contentItem)
            const commands = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
                              "decimal", "add", "subtract", "multiply", "divide", "equals", "clear"]
            for (const command of commands) {
                const key = button(command)
                const position = key.mapToItem(application.contentItem, 0, 0)
                verify(key.visible && key.enabled)
                verify(key.width >= 44 && key.height >= 44)
                verify(position.x >= 0 && position.y >= 0)
                verify(position.x + key.width <= application.width + 1)
                verify(position.y + key.height <= application.height + 1)
            }
            clickCommands(["2", "add", "3", "multiply", "4", "equals"])
            compare(findChild(application.contentItem, "resultDisplay").text, "20")
            const scheme = Application.styleHints.colorScheme === Qt.Dark ? "dark" : "light"
            grabImage(application.contentItem).save("standard-" + scheme + "-" + data.tag + ".png")
            application.width = 360
            application.height = 560
        }

        function test_standard_mode_evaluates_in_input_order() {
            clickCommands(["2", "add", "3", "multiply", "4", "equals"])
            compare(findChild(application.contentItem, "resultDisplay").text, "20")
            compare(findChild(application.contentItem, "expressionDisplay").text, "5 × 4 =")
        }
    }
}
