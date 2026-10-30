import QtQuick
import QtTest
import Calculator

Item {
    MainWindow { id: application }
    // Receive a real clipboard paste as another editable UI control would.
    TextEdit {
        id: clipboardReceiver
        parent: application.contentItem
        width: 200
        height: 30
        visible: false
    }
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
            clipboardReceiver.visible = false
            clipboardReceiver.clear()
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
            compare(button("multiply").Accessible.name, "Multiply")
            compare(button("divide").Accessible.name, "Divide")
            compare(button("clear").Accessible.name, "Clear")
            compare(button("decimal").Accessible.name, "Decimal separator")
            compare(button("equals").Accessible.name, "Equals")
            const names = { percent: "Percent", sign: "Negate", square: "Square", squareRoot: "Square root",
                            reciprocal: "Reciprocal", clearEntry: "Clear entry", backspace: "Backspace" }
            for (const command in names)
                compare(button(command).Accessible.name, names[command])
            waitForRendering(application.contentItem)
            button("clear").forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_Tab)
            tryCompare(button("backspace"), "activeFocus", true)
            keyClick(Qt.Key_Tab)
            tryCompare(button("reciprocal"), "activeFocus", true)
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
                              "decimal", "add", "subtract", "multiply", "divide", "equals", "clear",
                              "percent", "sign", "square", "squareRoot", "reciprocal", "clearEntry", "backspace"]
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

        // Percent expectations follow the pinned Standard manager tests and the
        // reference's relative (+/-) versus fractional (×/÷) behavior.
        function test_percent_uses_the_pending_operator_context_data() {
            const cases = [
                { tag: "add", commands: ["5", "0", "add", "2", "0", "percent", "equals"], expected: "60" },
                { tag: "subtract", commands: ["5", "0", "subtract", "2", "0", "percent", "equals"], expected: "40" },
                { tag: "multiply", commands: ["6", "multiply", "6", "percent", "equals"], expected: "0.36" },
                { tag: "divide", commands: ["5", "0", "divide", "2", "0", "percent", "equals"], expected: "250" },
                { tag: "standalone", commands: ["5", "0", "percent"], expected: "0" }
            ]
            return withInputMethods(cases)
        }

        function test_percent_uses_the_pending_operator_context(data) {
            runCommands(data.commands, data.keyboard)
            compare(findChild(application.contentItem, "resultDisplay").text, data.expected)
        }

        function inputMethods() {
            return [{ tag: "mouse", keyboard: false }, { tag: "keyboard", keyboard: true }]
        }

        function withInputMethods(cases) {
            const rows = []
            for (const scenario of cases) {
                for (const method of inputMethods())
                    rows.push(Object.assign({}, scenario, { tag: scenario.tag + "-" + method.tag, keyboard: method.keyboard }))
            }
            return rows
        }

        function runCommands(commands, keyboard) {
            for (const command of commands) {
                if (command.length === 1 || command === "decimal")
                    enterNumber(command === "decimal" ? "." : command, keyboard)
                else
                    operate(command, keyboard)
            }
        }

        function operate(command, keyboard) {
            if (!keyboard) {
                mouseClick(button(command))
                return
            }
            // Pinned en-US Resources.resw keyboard accelerators.
            const shortcuts = {
                percent: "%", sign: Qt.Key_F9, square: "q", squareRoot: "@", reciprocal: "r",
                clearEntry: Qt.Key_Delete, backspace: Qt.Key_Backspace, clear: Qt.Key_Escape,
                add: "+", subtract: "-", multiply: "*", divide: "/", equals: Qt.Key_Return
            }
            keyClick(shortcuts[command])
        }

        function test_sign_changes_the_current_operand_data() { return inputMethods() }

        function test_sign_changes_the_current_operand(data) {
            enterNumber("12", data.keyboard)
            operate("add", data.keyboard)
            enterNumber("5", data.keyboard)
            operate("sign", data.keyboard)
            compare(findChild(application.contentItem, "resultDisplay").text, "-5")
            operate("equals", data.keyboard)
            compare(findChild(application.contentItem, "resultDisplay").text, "7")
            operate("sign", data.keyboard)
            compare(findChild(application.contentItem, "resultDisplay").text, "-7")
        }

        function test_square_transforms_the_current_operand_data() { return inputMethods() }

        function test_square_transforms_the_current_operand(data) {
            enterNumber("12", data.keyboard)
            operate("square", data.keyboard)
            compare(findChild(application.contentItem, "resultDisplay").text, "144")
            operate("add", data.keyboard)
            enterNumber("3", data.keyboard)
            operate("equals", data.keyboard)
            compare(findChild(application.contentItem, "resultDisplay").text, "147")
        }

        function test_square_root_can_be_repeated_data() { return inputMethods() }

        function test_square_root_can_be_repeated(data) {
            enterNumber("256", data.keyboard)
            operate("squareRoot", data.keyboard)
            compare(findChild(application.contentItem, "resultDisplay").text, "16")
            operate("squareRoot", data.keyboard)
            compare(findChild(application.contentItem, "resultDisplay").text, "4")
            operate("squareRoot", data.keyboard)
            compare(findChild(application.contentItem, "resultDisplay").text, "2")
        }

        function test_reciprocal_preserves_the_operand_sign_data() { return inputMethods() }

        function test_reciprocal_preserves_the_operand_sign(data) {
            enterNumber("100", data.keyboard)
            operate("sign", data.keyboard)
            operate("reciprocal", data.keyboard)
            compare(findChild(application.contentItem, "resultDisplay").text, "-0.01")
            verify(findChild(application.contentItem, "expressionDisplay").text.indexOf("-100") !== -1)
        }

        function test_clear_entry_retains_the_pending_calculation_data() { return inputMethods() }

        function test_clear_entry_retains_the_pending_calculation(data) {
            enterNumber("12", data.keyboard)
            operate("add", data.keyboard)
            enterNumber("5", data.keyboard)
            operate("clearEntry", data.keyboard)
            compare(findChild(application.contentItem, "resultDisplay").text, "0")
            compare(findChild(application.contentItem, "expressionDisplay").text, "12 +")
            enterNumber("2", data.keyboard)
            operate("equals", data.keyboard)
            compare(findChild(application.contentItem, "resultDisplay").text, "14")
            operate("add", data.keyboard)
            enterNumber("9", data.keyboard)
            operate("clear", data.keyboard)
            compare(findChild(application.contentItem, "expressionDisplay").text, "")
            compare(findChild(application.contentItem, "resultDisplay").text, "0")
            enterNumber("2", data.keyboard)
            operate("equals", data.keyboard)
            compare(findChild(application.contentItem, "resultDisplay").text, "2")
        }

        function test_backspace_edits_entry_without_clearing_the_pending_operator_data() { return inputMethods() }

        function test_backspace_edits_entry_without_clearing_the_pending_operator(data) {
            enterNumber("9", data.keyboard)
            operate("add", data.keyboard)
            enterNumber("123", data.keyboard)
            operate("backspace", data.keyboard)
            compare(findChild(application.contentItem, "resultDisplay").text, "12")
            compare(findChild(application.contentItem, "expressionDisplay").text, "9 +")
            operate("backspace", data.keyboard)
            compare(findChild(application.contentItem, "resultDisplay").text, "1")
            operate("backspace", data.keyboard)
            compare(findChild(application.contentItem, "resultDisplay").text, "0")
            operate("backspace", data.keyboard)
            compare(findChild(application.contentItem, "resultDisplay").text, "0")
            enterNumber("3", data.keyboard)
            operate("equals", data.keyboard)
            operate("backspace", data.keyboard)
            // Backspace cannot edit a completed result.
            compare(findChild(application.contentItem, "resultDisplay").text, "12")
        }

        function test_error_recovery_starts_a_fresh_calculation_data() {
            return inputMethods()
        }

        function test_error_recovery_starts_a_fresh_calculation(data) {
            enterNumber("8", data.keyboard)
            operate("divide", data.keyboard)
            enterNumber("0", data.keyboard)
            operate("equals", data.keyboard)
            compare(findChild(application.contentItem, "errorIndicator").visible, true)
            enterNumber("7", data.keyboard)
            compare(findChild(application.contentItem, "errorIndicator").visible, false)
            compare(findChild(application.contentItem, "expressionDisplay").text, "")
            compare(findChild(application.contentItem, "resultDisplay").text, "7")
            operate("add", data.keyboard)
            enterNumber("2", data.keyboard)
            operate("equals", data.keyboard)
            compare(findChild(application.contentItem, "resultDisplay").text, "9")
        }

        function test_error_disables_operators_until_recovery() {
            clickCommands(["8", "divide", "0", "equals"])
            const disabled = ["percent", "squareRoot", "square", "reciprocal", "divide",
                              "multiply", "subtract", "add", "sign"]
            for (const command of disabled)
                compare(button(command).enabled, false, command + " disabled during errors")
            // Disabled keyboard accelerators must not accidentally clear the error.
            for (const command of disabled)
                operate(command, true)
            compare(findChild(application.contentItem, "errorIndicator").visible, true)
            waitForRendering(application.contentItem)
            const scheme = Application.styleHints.colorScheme === Qt.Dark ? "dark" : "light"
            grabImage(application.contentItem).save("standard-" + scheme + "-error.png")
            clickCommands(["clearEntry"])
            compare(findChild(application.contentItem, "errorIndicator").visible, false)
            compare(findChild(application.contentItem, "expressionDisplay").text, "")
            for (const command of disabled)
                compare(button(command).enabled, true, command + " restored after recovery")
            clickCommands(["9", "squareRoot", "add", "1", "equals"])
            compare(findChild(application.contentItem, "resultDisplay").text, "4")
        }

        function copyAndPaste(keyboard) {
            if (keyboard) {
                keyClick(Qt.Key_C, Qt.ControlModifier)
            } else {
                const result = findChild(application.contentItem, "resultDisplay")
                mouseClick(result, result.width / 2, result.height / 2, Qt.RightButton)
                const menu = findChild(application, "resultContextMenu")
                verify(menu !== null, "Result context menu exists")
                tryCompare(menu, "opened", true)
                const copy = findChild(menu.contentItem, "copyResultItem")
                verify(copy !== null && copy.enabled, "Copy is available")
                mouseClick(copy)
                tryCompare(menu, "visible", false)
            }
            clipboardReceiver.clear()
            clipboardReceiver.visible = true
            clipboardReceiver.forceActiveFocus()
            keyClick(Qt.Key_V, Qt.ControlModifier)
        }

        function test_copy_preserves_exact_digits_without_grouping_data() { return inputMethods() }

        function test_copy_preserves_exact_digits_without_grouping(data) {
            enterNumber("9007199254740992", false)
            clickCommands(["add", "1", "equals"])
            copyAndPaste(data.keyboard)
            compare(clipboardReceiver.text, "9007199254740993")
            compare(findChild(application.contentItem, "resultDisplay").text, "9,007,199,254,740,993")
        }

        // Reference sequences: CalculatorManagerTestStandard commands4/7/11/12.
        function test_repeated_equals_operator_replacement_and_result_entry_data() {
            return withInputMethods([
                { tag: "repeat-equals", commands: ["2", "add", "3", "equals", "equals", "equals"], expected: "11" },
                { tag: "digit-after-result", commands: ["2", "add", "3", "equals", "4"], expected: "4" },
                { tag: "digit-then-repeat", commands: ["2", "add", "3", "equals", "4", "equals"], expected: "7" },
                { tag: "operator-after-result", commands: ["3", "subtract", "6", "equals", "multiply", "3", "equals"], expected: "-9" },
                { tag: "operator-replacement", commands: ["5", "add", "multiply", "3", "equals"], expected: "15" },
                { tag: "replace-several-times", commands: ["5", "add", "subtract", "multiply", "divide", "2", "equals"], expected: "2.5" },
                { tag: "missing-right-operand", commands: ["4", "add", "equals"], expected: "8" },
                { tag: "clear-entry-after-step", commands: ["9", "multiply", "6", "subtract", "clearEntry", "8", "equals"], expected: "46" }
            ])
        }

        function test_repeated_equals_operator_replacement_and_result_entry(data) {
            runCommands(data.commands, data.keyboard)
            compare(findChild(application.contentItem, "resultDisplay").text, data.expected)
        }

        function test_all_standard_errors_are_clear_and_recoverable_data() {
            const chinese = Qt.locale().name.indexOf("zh") === 0
            const cases = []
            const errors = [
                { tag: "division-by-zero", number: "8", commands: ["divide", "0", "equals"], message: chinese ? "除数不能为零" : "Cannot divide by zero" },
                { tag: "undefined", number: "0", commands: ["divide", "0", "equals"], message: chinese ? "结果未定义" : "Result is undefined" },
                { tag: "invalid-domain", number: "1", commands: ["sign", "squareRoot"], message: chinese ? "无效输入" : "Invalid input" },
                { tag: "reciprocal-zero", number: "0", commands: ["reciprocal"], message: chinese ? "除数不能为零" : "Cannot divide by zero" },
                { tag: "overflow", number: "9999999999999999", commands: ["square", "square", "square", "square", "square", "square", "square", "square", "square", "square"], message: chinese ? "溢出" : "Overflow" }
            ]
            for (const error of errors) {
                for (const recovery of ["digit", "decimal", "clear", "clearEntry", "backspace", "equals"])
                    cases.push(Object.assign({}, error, { tag: error.tag + "-" + recovery, recovery: recovery }))
            }
            return withInputMethods(cases)
        }

        function test_all_standard_errors_are_clear_and_recoverable(data) {
            enterNumber(data.number, data.keyboard)
            runCommands(data.commands, data.keyboard)
            const result = findChild(application.contentItem, "resultDisplay")
            const expression = findChild(application.contentItem, "expressionDisplay")
            const error = findChild(application.contentItem, "errorIndicator")
            compare(result.text, data.message)
            compare(error.visible, true)
            if (data.recovery === "digit")
                enterNumber("7", data.keyboard)
            else if (data.recovery === "decimal")
                enterNumber(".", data.keyboard)
            else
                operate(data.recovery, data.keyboard)
            compare(error.visible, false)
            compare(expression.text, "")
            compare(result.text, data.recovery === "digit" ? "7" : data.recovery === "decimal" ? "0." : "0")
            if (data.recovery === "decimal") {
                enterNumber("5", data.keyboard)
                operate("multiply", data.keyboard)
                enterNumber("2", data.keyboard)
                operate("equals", data.keyboard)
                compare(result.text, "1")
            } else {
                if (data.recovery !== "digit")
                    enterNumber("7", data.keyboard)
                operate("add", data.keyboard)
                enterNumber("2", data.keyboard)
                operate("equals", data.keyboard)
                compare(result.text, "9")
            }
            for (const command of ["percent", "squareRoot", "square", "reciprocal", "divide", "multiply", "subtract", "add", "sign"])
                verify(button(command).enabled, command + " reenabled after recovery")
        }

        function test_copy_preserves_decimal_text_and_error_messages_data() {
            const chinese = Qt.locale().name.indexOf("zh") === 0
            return withInputMethods([
                { tag: "trailing-zeroes", commands: ["1", "decimal", "2", "0"], expected: "1.20", error: false },
                { tag: "negative-fraction", commands: ["1", "0", "0", "sign", "reciprocal"], expected: "-0.01", error: false },
                { tag: "error", commands: ["8", "divide", "0", "equals"], expected: chinese ? "除数不能为零" : "Cannot divide by zero", error: true }
            ])
        }

        function test_copy_preserves_decimal_text_and_error_messages(data) {
            clickCommands(data.commands)
            const expressionBefore = findChild(application.contentItem, "expressionDisplay").text
            copyAndPaste(data.keyboard)
            compare(clipboardReceiver.text, data.expected)
            compare(findChild(application.contentItem, "resultDisplay").text, data.expected)
            compare(findChild(application.contentItem, "expressionDisplay").text, expressionBefore)
            compare(findChild(application.contentItem, "errorIndicator").visible, data.error)
        }

        function test_standard_mode_evaluates_in_input_order() {
            clickCommands(["2", "add", "3", "multiply", "4", "equals"])
            compare(findChild(application.contentItem, "resultDisplay").text, "20")
            compare(findChild(application.contentItem, "expressionDisplay").text, "5 × 4 =")
        }
    }
}
