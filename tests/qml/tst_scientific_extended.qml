import QtQuick
import QtTest
import Calculator

Item {
    MainWindow { id: application; systemPreferences: testSystemPreferences }
    TestCase {
        name: "ScientificExtended"
        when: windowShown && application.visible

        function selectMode(mode) {
            mouseClick(findChild(application.contentItem, "navigationButton"))
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            mouseClick(findChild(drawer.contentItem, "mode_" + mode))
            tryCompare(drawer, "visible", false)
        }

        function button(command) {
            const item = findChild(application.contentItem, "key_" + command)
                      || findChild(application, "key_" + command)
            verify(item !== null, "Visible calculator key: " + command)
            return item
        }

        function clickCommands(commands) {
            for (const command of commands) {
                if (command === "clear") keyClick(Qt.Key_Escape)
                else {
                    const control = button(command)
                    verify(waitForPolish(application))
                    control.forceActiveFocus(Qt.TabFocusReason)
                    verify(waitForPolish(application))
                    mouseClick(control)
                }
            }
        }

        function result() { return findChild(application.contentItem, "resultDisplay").text }
        function expression() { return findChild(application.contentItem, "expressionDisplay").text }

        function initTestCase() {
            application.requestActivate()
            tryCompare(application, "active", true)
        }
        function init() {
            selectMode("scientific")
            clickCommands(["clear"])
        }

        // Independent perfect-square example; the production QML dispatches to CEngine/Ratpack.
        function test_square_and_square_root_keep_expression_and_result_in_sync() {
            clickCommands(["1", "2", "square"])
            compare(result(), "144")
            compare(expression(), "sqr(12)")
            clickCommands(["squareRoot"])
            compare(result(), "12")
            compare(expression(), "√(sqr(12))")
        }

        function test_second_function_resets_after_cube_and_cube_root() {
            clickCommands(["8", "second", "cube"])
            compare(result(), "512")
            compare(expression(), "cube(8)")
            verify(!button("second").checked)
            compare(button("square").text, "x²")
            clickCommands(["second", "cubeRoot"])
            compare(result(), "8")
            compare(expression(), "cuberoot(cube(8))")
            verify(!button("second").checked)
        }

        function test_power_and_second_nth_root_compose_with_precedence() {
            clickCommands(["2", "add", "3", "power", "2", "equals"])
            compare(result(), "11")
            compare(expression(), "2 + 3 ^ 2 =")
            clickCommands(["clear", "2", "7", "negate", "second", "root", "3", "equals"])
            compare(result(), "-3")
            compare(expression(), "-27 yroot 3 =")
            verify(!button("second").checked)
        }

        // Expectations from pinned CalculatorManagerTestScientific2 or exact integer identities.
        function test_exponential_and_logarithm_functions_data() {
            return [
                { tag: "ten-power", commands: ["5", "powerTen"], value: "100,000", expression: "10^(5)" },
                { tag: "two-power", commands: ["8", "second", "powerTwo"], value: "256", expression: "2^(8)" },
                { tag: "log-ten", commands: ["1", "0", "log"], value: "1", expression: "log(10)" },
                { tag: "log-base", commands: ["8", "second", "logBase", "2", "equals"], value: "3", expression: "8 log base 2 =" },
                { tag: "natural-log", commands: ["1", "0", "ln"], value: "2.3025850929940456840179914546844", expression: "ln(10)" },
                { tag: "e-power", commands: ["2", "second", "powerE"], value: "7.389056098930650227230427460575", expression: "e^(2)" }
            ]
        }
        function test_exponential_and_logarithm_functions(data) {
            clickCommands(data.commands)
            compare(result(), data.value)
            compare(expression(), data.expression)
            verify(!button("second").checked)
        }

        function test_factorial_modulo_and_reciprocal_compose_in_real_core() {
            clickCommands(["5", "factorial", "mod", "7", "equals"])
            compare(result(), "1")
            compare(expression(), "fact(5) Mod 7 =")
            clickCommands(["clear", "4", "reciprocal"])
            compare(result(), "0.25")
            compare(expression(), "1/(4)")
        }

        function test_constants_retain_scientific_precision_and_can_continue() {
            clickCommands(["pi"])
            compare(result(), "3.1415926535897932384626433832795")
            clickCommands(["subtract", "pi", "equals"])
            compare(result(), "0")
            clickCommands(["clear", "euler"])
            compare(result(), "2.7182818284590452353602874713527")
            clickCommands(["ln"])
            compare(result(), "1")
        }

        function test_clear_entry_and_backspace_preserve_pending_calculation() {
            compare(button("clear").text, "C")
            clickCommands(["0"])
            compare(button("clear").text, "C", "The core ignores a leading zero")
            clickCommands(["decimal"])
            compare(button("clearEntry").text, "CE", "A decimal point makes an input even at zero")
            clickCommands(["clear", "6", "multiply", "1", "2", "backspace"])
            compare(result(), "1")
            clickCommands(["clearEntry"])
            compare(result(), "0")
            compare(expression(), "6 ×")
            clickCommands(["7", "equals"])
            compare(result(), "42")
            compare(button("clearEntry").text, "CE", "Completed nonzero results follow core input state")
            keyClick(Qt.Key_Escape)
            compare(expression(), "")
            compare(button("clear").text, "C")
        }

        // Pinned CalcInput caps exponent entry at four digits and supports its own sign/backspace.
        function test_exponent_entry_limit_and_editing() {
            clickCommands(["1", "exp", "1", "2", "3", "4"])
            compare(result(), "1.e+1234")
            clickCommands(["5"])
            compare(result(), "1.e+1234")
            clickCommands(["backspace", "backspace", "backspace", "backspace", "2", "negate", "equals"])
            compare(result(), "0.01")
            clickCommands(["clear", "2", "multiply", "3", "exp", "2", "equals"])
            compare(result(), "600")
        }

        function functionCommand(command) {
            clickCommands(["function"])
            const popup = findChild(application, "functionPopup")
            tryCompare(popup, "opened", true)
            const item = findChild(popup.contentItem, "key_function_" + command)
            verify(item !== null, "Visible Function flyout operation: " + command)
            mouseClick(item)
            tryCompare(popup, "visible", false)
        }

        function test_function_flyout_executes_and_closes_data() {
            return [
                { tag: "absolute", input: ["3", "decimal", "8", "negate"], command: "abs", value: "3.8" },
                { tag: "floor", input: ["3", "decimal", "8", "negate"], command: "floor", value: "-4" },
                { tag: "ceiling", input: ["3", "decimal", "8", "negate"], command: "ceil", value: "-3" },
                { tag: "dms", input: ["1", "2", "decimal", "5"], command: "dms", value: "12.3" },
                { tag: "degrees", input: ["1", "2", "decimal", "3"], command: "degrees", value: "12.5" },
                { tag: "random", input: [], command: "rand", value: null }
            ]
        }
        function test_function_flyout_executes_and_closes(data) {
            clickCommands(data.input)
            functionCommand(data.command)
            if (data.value !== null) compare(result(), data.value)
            else {
                verify(/^(0(?:\.\d+)?|[1-9](?:\.\d+)?e-[1-9]\d*)$/.test(result()), "Random is a real number in [0, 1): " + result())
                clickCommands(["multiply", "0", "equals"])
                compare(result(), "0")
            }
        }

        function test_scientific_notation_toggle_and_clear_follow_core_format() {
            clickCommands(["4", "2", "equals", "scientificNotation"])
            compare(result(), "4.2e+1")
            verify(button("scientificNotation").checked)
            clickCommands(["multiply", "2", "equals"])
            compare(result(), "8.4e+1")
            clickCommands(["clearEntry", "4", "2", "add", "0", "equals"])
            compare(result(), "42")
            verify(!button("scientificNotation").checked)
            clickCommands(["scientificNotation"])
            selectMode("standard")
            selectMode("scientific")
            clickCommands(["4", "2", "equals"])
            compare(result(), "42")
            verify(!button("scientificNotation").checked)
        }

        function test_scientific_domain_and_range_errors_recover_data() {
            return [
                { tag: "negative-log", commands: ["2", "negate", "log"], english: "Invalid input", chinese: "无效输入" },
                { tag: "zero-log", commands: ["ln"], english: "Invalid input", chinese: "无效输入" },
                { tag: "negative-square-root", commands: ["1", "negate", "squareRoot"], english: "Invalid input", chinese: "无效输入" },
                { tag: "negative-factorial", commands: ["1", "negate", "factorial"], english: "Invalid input", chinese: "无效输入" },
                { tag: "even-negative-root", commands: ["8", "negate", "second", "root", "2", "equals"], english: "Invalid input", chinese: "无效输入" },
                { tag: "reciprocal-zero", commands: ["reciprocal"], english: "Cannot divide by zero", chinese: "除数不能为零" },
                // Pinned CalculatorManagerTestScientific commands13 (underflow is reported as Overflow).
                { tag: "range", commands: ["1", "exp", "negate", "9", "9", "9", "9", "divide", "1", "0", "equals"], english: "Overflow", chinese: "溢出" }
            ]
        }
        function test_scientific_domain_and_range_errors_recover(data) {
            clickCommands(data.commands)
            const error = findChild(application.contentItem, "errorIndicator")
            verify(error.visible)
            compare(result(), Qt.locale().name.indexOf("zh") === 0 ? data.chinese : data.english)
            for (const command of ["square", "power", "factorial", "exp", "pi", "function", "scientificNotation"])
                verify(!button(command).enabled, command + " is unavailable during an error")
            const message = result()
            keyClick("q")
            compare(result(), message)
            keyClick(Qt.Key_Delete)
            verify(!error.visible)
            clickCommands(["4", "2", "add", "1", "equals"])
            compare(result(), "43")
            clickCommands(["clear", "2", "square"])
            compare(result(), "4")
        }

        // Pinned en-US Resources.resw accelerators; ExpButton constructor overrides X with E.
        function test_reference_shortcuts_work_without_opening_second_or_function_panels_data() {
            return [
                { tag: "square", input: "12", key: Qt.Key_Q, modifiers: Qt.NoModifier, value: "144" },
                { tag: "cube", input: "8", key: "#", modifiers: Qt.NoModifier, value: "512" },
                { tag: "square-root", input: "9", key: "@", modifiers: Qt.NoModifier, value: "3" },
                { tag: "cube-root", input: "8", key: Qt.Key_B, modifiers: Qt.NoModifier, value: "2" },
                { tag: "power", input: "3", key: Qt.Key_Y, modifiers: Qt.NoModifier, tail: "2=", value: "9" },
                { tag: "power-symbol", input: "3", key: "^", modifiers: Qt.NoModifier, tail: "2=", value: "9" },
                { tag: "root", input: "8", key: Qt.Key_Y, modifiers: Qt.ControlModifier, tail: "3=", value: "2" },
                { tag: "ten-power", input: "2", key: Qt.Key_G, modifiers: Qt.ControlModifier, value: "100" },
                { tag: "two-power", input: "8", key: Qt.Key_G, modifiers: Qt.NoModifier, value: "256" },
                { tag: "log", input: "10", key: Qt.Key_L, modifiers: Qt.NoModifier, value: "1" },
                { tag: "log-base", input: "8", key: Qt.Key_L, modifiers: Qt.ShiftModifier, tail: "2=", value: "3" },
                { tag: "ln", input: "1", key: Qt.Key_N, modifiers: Qt.NoModifier, value: "0" },
                { tag: "exponential", input: "0", key: Qt.Key_N, modifiers: Qt.ControlModifier, value: "1" },
                { tag: "factorial", input: "5", key: "!", modifiers: Qt.NoModifier, value: "120" },
                { tag: "modulo", input: "17", key: "%", modifiers: Qt.NoModifier, tail: "5=", value: "2" },
                { tag: "reciprocal", input: "4", key: Qt.Key_R, modifiers: Qt.NoModifier, value: "0.25" },
                { tag: "pi", input: "", key: Qt.Key_P, modifiers: Qt.NoModifier, value: "3.1415926535897932384626433832795" },
                { tag: "euler", input: "", key: Qt.Key_E, modifiers: Qt.ShiftModifier, value: "2.7182818284590452353602874713527" },
                { tag: "exponent-entry", input: "2", key: Qt.Key_E, modifiers: Qt.NoModifier, tail: "3=", value: "2,000" },
                { tag: "absolute", input: "3", before: Qt.Key_F9, key: "|", modifiers: Qt.NoModifier, value: "3" },
                { tag: "floor", input: "3.8", key: "[", modifiers: Qt.NoModifier, value: "3" },
                { tag: "ceiling", input: "3.8", key: "]", modifiers: Qt.NoModifier, value: "4" },
                { tag: "dms", input: "12.5", key: Qt.Key_M, modifiers: Qt.NoModifier, value: "12.3" },
                { tag: "negate", input: "2", key: Qt.Key_F9, modifiers: Qt.NoModifier, value: "-2" },
                { tag: "notation", input: "42=", key: Qt.Key_V, modifiers: Qt.NoModifier, value: "4.2e+1" }
            ]
        }
        function test_reference_shortcuts_work_without_opening_second_or_function_panels(data) {
            for (const character of data.input) keyClick(character)
            if (data.before !== undefined) keyClick(data.before)
            keyClick(data.key, data.modifiers)
            for (const character of (data.tail || "")) keyClick(character)
            compare(result(), data.value)
            verify(!button("second").checked)
        }

        function openSettings() {
            mouseClick(findChild(application.contentItem, "navigationButton"))
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            mouseClick(findChild(drawer.contentItem, "settingsButton"))
            tryCompare(drawer, "visible", false)
        }
        function setLanguage(language) {
            openSettings()
            mouseClick(findChild(application.contentItem, "language_" + language))
            selectMode("scientific")
        }

        function test_runtime_translation_preserves_extended_calculation_and_labels() {
            setLanguage("en-US")
            clickCommands(["clear", "2", "power"])
            setLanguage("zh-CN")
            compare(button("power").Accessible.name, "幂")
            compare(button("second").Accessible.name, "第二功能")
            compare(button("function").Accessible.name, "函数")
            compare(button("scientificNotation").Accessible.name, "科学记数法")
            compare(button("clearEntry").Accessible.name, "清除输入")
            clickCommands(["3", "equals"])
            compare(result(), "8")
            clickCommands(["second"])
            compare(button("cube").Accessible.name, "立方")
            clickCommands(["cube"])
            compare(result(), "512")
            clickCommands(["clear", "ln"])
            compare(result(), "无效输入")
            setLanguage("en-US")
            compare(result(), "Invalid input")
            compare(button("second").Accessible.name, "Second function")
            setLanguage("system")
        }

        function test_second_function_restores_focus_and_visual_tab_order() {
            clickCommands(["8", "second", "cube"])
            verify(button("second").activeFocus, "Second function returns focus to its toggle")
            keyClick(Qt.Key_Tab)
            verify(button("pi").activeFocus, "Tab follows the visible first row")
            keyClick(Qt.Key_Space)
            compare(result(), "3.1415926535897932384626433832795")
        }

        function test_function_flyout_supports_tab_space_and_escape() {
            clickCommands(["3", "decimal", "8"])
            button("function").forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_Space)
            const popup = findChild(application, "functionPopup")
            tryCompare(popup, "opened", true)
            const absolute = findChild(popup.contentItem, "key_function_abs")
            absolute.forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_Tab)
            verify(findChild(popup.contentItem, "key_function_floor").activeFocus)
            keyClick(Qt.Key_Space)
            tryCompare(popup, "visible", false)
            compare(result(), "3")
            verify(button("function").activeFocus)
            keyClick(Qt.Key_Space)
            tryCompare(popup, "opened", true)
            keyClick(Qt.Key_Escape)
            tryCompare(popup, "visible", false)
            compare(result(), "3", "Escape closes the flyout without clearing the calculation")
        }

        function test_settings_disable_all_extended_shortcuts() {
            clickCommands(["2", "power"])
            openSettings()
            findChild(application.contentItem, "theme_light").forceActiveFocus(Qt.TabFocusReason)
            for (const key of [Qt.Key_Q, Qt.Key_B, Qt.Key_G, Qt.Key_L, Qt.Key_N, Qt.Key_E, Qt.Key_P, Qt.Key_V, Qt.Key_M])
                keyClick(key)
            keyClick(Qt.Key_Y, Qt.ControlModifier)
            keyClick(Qt.Key_R, Qt.ShiftModifier)
            for (const symbol of ["#", "@", "!", "%", "|", "[", "]"])
                keyClick(symbol)
            selectMode("scientific")
            clickCommands(["3", "equals"])
            compare(result(), "8")
            compare(expression(), "2 ^ 3 =")
        }

        function test_extended_controls_fit_and_keep_the_pinned_grid_data() {
            return [{ tag: "narrow", width: 320, height: 540 }, { tag: "wide", width: 900, height: 800 }]
        }
        function test_extended_controls_fit_and_keep_the_pinned_grid(data) {
            application.width = data.width
            application.height = data.height
            verify(waitForPolish(application))
            const primary = ["second", "pi", "euler", "clear", "backspace", "square", "reciprocal", "abs", "exp", "mod",
                             "squareRoot", "openParenthesis", "closeParenthesis", "factorial", "divide", "power", "7", "8", "9", "multiply",
                             "powerTen", "4", "5", "6", "subtract", "log", "1", "2", "3", "add", "ln", "negate", "0", "decimal", "equals",
                             "scientificNotation", "function"]
            function checkBounds(commands) {
                for (const command of commands) {
                    const control = button(command)
                    control.forceActiveFocus(Qt.TabFocusReason)
                    verify(waitForPolish(application))
                    verify(control.visible && control.enabled)
                    verify(control.width >= 44 && control.height >= 44, command + " target size")
                    tryVerify(function() {
                        const position = control.mapToItem(application.contentItem, 0, 0)
                        return position.x >= 0 && position.x + control.width <= application.width + 1
                    }, 5000, command + " horizontal bounds after resize/focus layout settles")
                    tryVerify(function() {
                        const position = control.mapToItem(application.contentItem, 0, 0)
                        return position.y >= 0 && position.y + control.height <= application.height + 1
                    }, 5000, command + " vertical bounds after resize/focus layout settles")
                    verify(control.Accessible.name.length > 0)
                }
            }
            checkBounds(primary)
            compare(button("square").y, button("reciprocal").y)
            compare(button("squareRoot").y, button("factorial").y)
            compare(button("pi").x, button("7").x)
            const scheme = application.color.r < 0.5 ? "dark" : "light"
            grabImage(application.contentItem).save("scientific-extended-" + scheme + "-" + data.tag + ".png")
            clickCommands(["second"])
            checkBounds(["cube", "cubeRoot", "root", "powerTwo", "logBase", "powerE"])
            grabImage(application.contentItem).save("scientific-second-" + scheme + "-" + data.tag + ".png")
            clickCommands(["second", "function"])
            const popup = findChild(application, "functionPopup")
            tryCompare(popup, "opened", true)
            grabImage(application.contentItem).save("scientific-function-" + scheme + "-" + data.tag + ".png")
            keyClick(Qt.Key_Escape)
            tryCompare(popup, "visible", false)
            application.width = 360
            application.height = 560
        }

        function test_random_shortcut_and_direct_absolute_value() {
            keyClick(Qt.Key_R, Qt.ShiftModifier)
            verify(/^(0(?:\.\d+)?|[1-9](?:\.\d+)?e-[1-9]\d*)$/.test(result()), "Shift+R enters a random number in [0, 1)")
            clickCommands(["clear", "4", "2", "negate", "abs"])
            compare(result(), "42")
        }

        function test_error_recovery_by_digit_decimal_equals_backspace_and_clear_data() {
            return [
                { tag: "digit", key: "7", value: "7" },
                { tag: "decimal", key: ".", value: "0." },
                { tag: "equals", key: "=", value: "0" },
                { tag: "backspace", key: Qt.Key_Backspace, value: "0" },
                { tag: "clear", key: Qt.Key_Escape, value: "0" }
            ]
        }
        function test_error_recovery_by_digit_decimal_equals_backspace_and_clear(data) {
            clickCommands(["1", "negate", "squareRoot"])
            verify(findChild(application.contentItem, "errorIndicator").visible)
            keyClick(data.key)
            compare(result(), data.value)
            verify(!findChild(application.contentItem, "errorIndicator").visible)
        }

        function test_leaving_an_error_resets_the_actual_scientific_notation() {
            clickCommands(["scientificNotation", "1", "negate", "squareRoot"])
            verify(findChild(application.contentItem, "errorIndicator").visible)
            selectMode("standard")
            selectMode("scientific")
            verify(!button("scientificNotation").checked)
            clickCommands(["4", "2", "equals"])
            compare(result(), "42", "Mode return must reset actual core notation as well as its toggle")
        }

        // Pinned OperatorsPanel caches ScientificOperators; its 2nd selection
        // survives a temporary mode change until a secondary function is used.
        function test_second_function_selection_survives_mode_navigation() {
            clickCommands(["second"])
            verify(button("second").checked)
            selectMode("standard")
            selectMode("scientific")
            verify(button("second").checked)
            clickCommands(["2", "cube"])
            compare(result(), "8")
            verify(!button("second").checked)
        }

        function cleanupTestCase() { application.close() }
    }
}
