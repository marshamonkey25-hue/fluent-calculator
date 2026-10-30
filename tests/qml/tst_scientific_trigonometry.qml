import QtQuick
import QtTest
import Calculator

Item {
    TextMetrics { id: keyMetrics }
    MainWindow { id: application; systemPreferences: testSystemPreferences }
    TestCase {
        name: "ScientificTrigonometry"
        when: windowShown && application.visible

        function selectMode(mode) {
            mouseClick(findChild(application.contentItem, "navigationButton"))
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            mouseClick(findChild(drawer.contentItem, "mode_" + mode))
            tryCompare(drawer, "visible", false)
        }

        function visualControl(root, name) {
            if (root.objectName === name)
                return root
            for (const child of root.children || []) {
                const item = visualControl(child, name)
                if (item)
                    return item
            }
            return null
        }

        function control(name) {
            const popup = findChild(application, "trigonometryPopup") || findChild(application.contentItem, "trigonometryPopup")
            const item = findChild(application.contentItem, name) || findChild(application, name)
                       || (popup ? visualControl(popup.contentItem, name) : null)
            verify(item !== null, "User control exists: " + name)
            return item
        }

        function enter(text) {
            for (const digit of text)
                mouseClick(control("key_" + (digit === "." ? "decimal" : digit)))
        }

        function result() { return control("resultDisplay").text }

        function applyFunction(command, inverse = false, hyperbolic = false) {
            mouseClick(control("trigonometryButton"))
            const popup = control("trigonometryPopup")
            tryCompare(popup, "opened", true)
            if (inverse)
                mouseClick(control("trigonometryInverse"))
            if (hyperbolic)
                mouseClick(control("trigonometryHyperbolic"))
            mouseClick(control("trig_" + command))
            tryCompare(popup, "visible", false)
        }

        function initTestCase() {
            application.requestActivate()
            tryCompare(application, "active", true)
            selectMode("scientific")
            compare(control("angleUnitButton").text, "DEG", "A fresh Scientific session starts in degrees")
        }

        function init() {
            selectMode("scientific")
            mouseClick(control("key_clear"))
            const angle = control("angleUnitButton")
            for (let step = 0; step < 3 && angle.text !== "DEG"; ++step)
                mouseClick(angle)
            compare(angle.text, "DEG")
        }

        function test_angle_units_cycle_without_changing_input_and_survive_mode_return() {
            const angle = control("angleUnitButton")
            mouseClick(angle)
            compare(angle.text, "RAD")
            enter("1.5707963267948966192313216916398") // independent π/2 decimal
            applyFunction("sin")
            verify(Math.abs(Number(result()) - 1) < 1e-14)
            mouseClick(control("key_clear"))
            compare(angle.text, "RAD", "Clear retains the selected unit")
            enter("50")
            mouseClick(angle)
            compare(angle.text, "GRAD")
            compare(result(), "50", "Unit selection does not convert the current entry")
            applyFunction("sin")
            verify(Math.abs(Number(result()) - 0.7071067811865475) < 1e-14)
            selectMode("standard")
            selectMode("scientific")
            compare(control("angleUnitButton").text, "GRAD", "The cached Scientific engine retains its unit")
            compare(result(), "0")
            mouseClick(control("angleUnitButton"))
            compare(control("angleUnitButton").text, "DEG")
            enter("30")
            applyFunction("sin")
            compare(result(), "0.5")
        }

        function test_circular_functions_match_known_degree_values_data() {
            return [
                { tag: "sin", input: "30", expected: 0.5 },
                { tag: "cos", input: "60", expected: 0.5 },
                { tag: "tan", input: "45", expected: 1 },
                { tag: "sec", input: "60", expected: 2 },
                { tag: "csc", input: "30", expected: 2 },
                { tag: "cot", input: "45", expected: 1 }
            ]
        }

        function test_circular_functions_match_known_degree_values(data) {
            enter(data.input)
            applyFunction(data.tag)
            verify(Math.abs(Number(result()) - data.expected) < 1e-14)
            verify(!control("errorIndicator").visible)
        }

        function test_inverse_circular_functions_use_selected_unit_and_reset_toggle_data() {
            return [
                { tag: "asin", input: "0.5", expected: 30 },
                { tag: "acos", input: "0.5", expected: 60 },
                { tag: "atan", input: "1", expected: 45 },
                { tag: "asec", input: "2", expected: 60 },
                { tag: "acsc", input: "2", expected: 30 },
                { tag: "acot", input: "1", expected: 45 }
            ]
        }

        function test_inverse_circular_functions_use_selected_unit_and_reset_toggle(data) {
            enter(data.input)
            applyFunction(data.tag, true)
            verify(Math.abs(Number(result()) - data.expected) < 1e-12, data.tag + " result: " + result())
            mouseClick(control("trigonometryButton"))
            tryCompare(control("trigonometryPopup"), "opened", true)
            compare(control("trigonometryInverse").checked, false)
            compare(control("trig_sin").text, "sin")
            mouseClick(control("trig_sin"))
            tryCompare(control("trigonometryPopup"), "visible", false)
        }

        function test_hyperbolic_functions_are_independent_of_angle_unit_data() {
            return [
                { tag: "sinh", expected: 1.3333333333333333 },
                { tag: "cosh", expected: 1.6666666666666667 },
                { tag: "tanh", expected: 0.8 },
                { tag: "sech", expected: 0.6 },
                { tag: "csch", expected: 0.75 },
                { tag: "coth", expected: 1.25 }
            ]
        }

        function test_hyperbolic_functions_are_independent_of_angle_unit(data) {
            // e^ln(3)=3 gives independently known rational hyperbolic values.
            for (let unit = 0; unit < 3; ++unit) {
                enter("1.0986122886681096913952452369225")
                applyFunction(data.tag, false, true)
                verify(Math.abs(Number(result()) - data.expected) < 1e-14, data.tag + " result: " + result())
                mouseClick(control("key_clear"))
                mouseClick(control("angleUnitButton"))
            }
        }

        function test_inverse_hyperbolic_combinations_match_known_values_data() {
            return [
                { tag: "asinh", input: "1.3333333333333333333333333333333" },
                { tag: "acosh", input: "1.6666666666666666666666666666667" },
                { tag: "atanh", input: "0.8" },
                { tag: "asech", input: "0.6" },
                { tag: "acsch", input: "0.75" },
                { tag: "acoth", input: "1.25" }
            ]
        }

        function test_inverse_hyperbolic_combinations_match_known_values(data) {
            enter(data.input)
            applyFunction(data.tag, true, true)
            verify(Math.abs(Number(result()) - 1.0986122886681098) < 1e-14, data.tag + " result: " + result())
            mouseClick(control("trigonometryButton"))
            tryCompare(control("trigonometryPopup"), "opened", true)
            compare(control("trigonometryInverse").checked, false)
            compare(control("trigonometryHyperbolic").checked, false)
            compare(control("trig_sin").text, "sin")
            mouseClick(control("trig_sin"))
            tryCompare(control("trigonometryPopup"), "visible", false)
        }

        function test_reference_keyboard_shortcuts_invoke_all_function_families() {
            const cases = [
                [Qt.Key_S, "30", 0.5, Qt.NoModifier], [Qt.Key_O, "60", 0.5, Qt.NoModifier],
                [Qt.Key_T, "45", 1, Qt.NoModifier], [Qt.Key_U, "60", 2, Qt.NoModifier],
                [Qt.Key_I, "30", 2, Qt.NoModifier], [Qt.Key_J, "45", 1, Qt.NoModifier],
                [Qt.Key_S, "0.5", 30, Qt.ShiftModifier], [Qt.Key_O, "0.5", 60, Qt.ShiftModifier],
                [Qt.Key_T, "1", 45, Qt.ShiftModifier], [Qt.Key_U, "2", 60, Qt.ShiftModifier],
                [Qt.Key_I, "2", 30, Qt.ShiftModifier], [Qt.Key_J, "1", 45, Qt.ShiftModifier],
                [Qt.Key_S, "0", 0, Qt.ControlModifier], [Qt.Key_O, "0", 1, Qt.ControlModifier],
                [Qt.Key_T, "0", 0, Qt.ControlModifier], [Qt.Key_U, "0", 1, Qt.ControlModifier],
                [Qt.Key_I, "1", 0.8509181282393216, Qt.ControlModifier],
                [Qt.Key_J, "1", 1.3130352854993313, Qt.ControlModifier],
                [Qt.Key_S, "0", 0, Qt.ControlModifier | Qt.ShiftModifier],
                [Qt.Key_O, "1", 0, Qt.ControlModifier | Qt.ShiftModifier],
                [Qt.Key_T, "0", 0, Qt.ControlModifier | Qt.ShiftModifier],
                [Qt.Key_U, "1", 0, Qt.ControlModifier | Qt.ShiftModifier],
                [Qt.Key_I, "1", 0.881373587019543, Qt.ControlModifier | Qt.ShiftModifier],
                [Qt.Key_J, "2", 0.5493061443340548, Qt.ControlModifier | Qt.ShiftModifier]
            ]
            for (const entry of cases) {
                keyClick(Qt.Key_Escape)
                for (const character of entry[1])
                    keyClick(character)
                keyClick(entry[0], entry[3])
                verify(Math.abs(Number(result()) - entry[2]) < 1e-12,
                       "Shortcut " + entry[0] + "/" + entry[3] + " result: " + result())
            }
            keyClick(Qt.Key_F4)
            compare(control("angleUnitButton").text, "RAD")
            keyClick(Qt.Key_Escape)
            keyClick("1")
            keyClick(Qt.Key_S, Qt.ShiftModifier)
            verify(Math.abs(Number(result()) - 1.5707963267948966) < 1e-14)
            keyClick(Qt.Key_F5)
            compare(control("angleUnitButton").text, "GRAD")
            keyClick(Qt.Key_Escape)
            keyClick("1")
            keyClick(Qt.Key_S, Qt.ShiftModifier)
            compare(result(), "100")
            keyClick(Qt.Key_F3)
            compare(control("angleUnitButton").text, "DEG")
        }

        function test_flyout_keyboard_focus_and_escape_preserve_entry() {
            enter("30")
            const opener = control("trigonometryButton")
            opener.forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_Space)
            const popup = control("trigonometryPopup")
            tryCompare(popup, "opened", true)
            tryCompare(control("trigonometryInverse"), "activeFocus", true)
            keyClick(Qt.Key_Tab)
            verify(control("trig_sin").activeFocus, "Tab follows the visible first function row")
            keyClick(Qt.Key_Escape)
            tryCompare(popup, "visible", false)
            compare(result(), "30", "Escape dismisses the flyout without clearing the calculation")
            verify(opener.activeFocus)
            keyClick(Qt.Key_Space)
            tryCompare(popup, "opened", true)
            keyClick(Qt.Key_Space) // inverse
            verify(control("trigonometryInverse").checked)
            keyClick(Qt.Key_Tab)
            compare(control("trig_asin").text, "sin⁻¹")
            keyClick(Qt.Key_Escape)
            tryCompare(popup, "visible", false)
            keyClick(Qt.Key_Space)
            tryCompare(popup, "opened", true)
            verify(control("trigonometryInverse").checked, "Dismissal retains flyout toggles, matching the reference")
            keyClick(Qt.Key_Space) // ordinary functions
            keyClick(Qt.Key_Tab)
            keyClick(Qt.Key_Space)
            tryCompare(popup, "visible", false)
            compare(result(), "0.5")
        }

        function openSettings() {
            mouseClick(control("navigationButton"))
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            mouseClick(findChild(drawer.contentItem, "settingsButton"))
            tryCompare(drawer, "visible", false)
        }

        function test_runtime_translation_preserves_units_entry_and_function_labels() {
            enter("30")
            openSettings()
            mouseClick(control("language_zh-CN"))
            selectMode("scientific")
            compare(control("trigonometryButton").Accessible.name, "三角函数")
            compare(control("angleUnitButton").Accessible.name, "角度切换")
            mouseClick(control("trigonometryButton"))
            tryCompare(control("trigonometryPopup"), "opened", true)
            compare(control("trig_sin").Accessible.name, "正弦")
            compare(control("trigonometryInverse").Accessible.name, "反函数")
            compare(control("trigonometryHyperbolic").Accessible.name, "双曲函数")
            mouseClick(control("trigonometryInverse"))
            compare(control("trig_asin").Accessible.name, "反正弦")
            mouseClick(control("trigonometryHyperbolic"))
            compare(control("trig_asinh").Accessible.name, "反双曲正弦")
            mouseClick(control("trigonometryInverse"))
            compare(control("trig_sinh").Accessible.name, "双曲正弦")
            mouseClick(control("trigonometryHyperbolic"))
            mouseClick(control("trig_sin"))
            tryCompare(control("trigonometryPopup"), "visible", false)
            compare(result(), "0.5")
            openSettings()
            mouseClick(control("language_en-US"))
            selectMode("scientific")
            compare(control("trigonometryButton").Accessible.name, "Trigonometry")
            openSettings()
            mouseClick(control("language_system"))
            selectMode("scientific")
        }

        function test_domain_singular_and_range_errors_are_localized_and_recoverable() {
            // Expectations follow pinned scifunc.cpp and Ratpack's domain/divide checks.
            const cases = [
                ["asin", "2", true, false, "invalid"],
                ["acos", "2", true, false, "invalid"],
                ["asec", "0.5", true, false, "invalid"],
                ["tan", "90", false, false, "invalid"],
                ["csc", "0", false, false, "zero"],
                ["cot", "0", false, false, "zero"],
                ["acosh", "0", true, true, "invalid"],
                ["atanh", "1", true, true, "zero"],
                ["asech", "2", true, true, "invalid"],
                ["acsch", "0", true, true, "zero"],
                ["acoth", "0.5", true, true, "invalid"],
                ["sinh", "100000", false, true, "overflow"] // sinh(100000) exceeds 10^9999
            ]
            const chinese = Qt.locale().name.indexOf("zh") === 0
            for (let index = 0; index < cases.length; ++index) {
                const entry = cases[index]
                enter(entry[1])
                applyFunction(entry[0], entry[2], entry[3])
                verify(control("errorIndicator").visible, entry[0] + " reports an error")
                compare(result(), entry[4] === "zero" ? (chinese ? "除数不能为零" : "Cannot divide by zero")
                                : entry[4] === "overflow" ? (chinese ? "溢出" : "Overflow")
                                : (chinese ? "无效输入" : "Invalid input"))
                verify(!control("angleUnitButton").enabled)
                verify(!control("trigonometryButton").enabled)
                const errorText = result()
                keyClick(Qt.Key_F4)
                keyClick(Qt.Key_S)
                compare(result(), errorText, "Disabled Scientific shortcuts do not mutate the error")
                compare(control("angleUnitButton").text, "DEG")
                if (index % 2 === 0)
                    mouseClick(control("key_clear"))
                keyClick("3") // a digit also recovers directly from the error
                verify(!control("errorIndicator").visible)
                keyClick("+")
                keyClick("4")
                keyClick("=")
                compare(result(), "7")
                mouseClick(control("key_clear"))
            }
        }

        function test_hidden_scientific_shortcuts_do_not_change_settings_calculation() {
            enter("30")
            openSettings()
            control("theme_light").forceActiveFocus(Qt.TabFocusReason)
            for (const modifier of [Qt.NoModifier, Qt.ShiftModifier, Qt.ControlModifier, Qt.ControlModifier | Qt.ShiftModifier])
                for (const key of [Qt.Key_S, Qt.Key_O, Qt.Key_T, Qt.Key_U, Qt.Key_I, Qt.Key_J])
                    keyClick(key, modifier)
            keyClick(Qt.Key_F4)
            keyClick(Qt.Key_F5)
            selectMode("scientific")
            compare(result(), "30")
            compare(control("angleUnitButton").text, "DEG")
            applyFunction("sin")
            compare(result(), "0.5")
        }

        function test_flyout_controls_fit_both_window_sizes_and_show_all_states_data() {
            return [{ tag: "narrow", width: 320, height: 632 }, { tag: "wide", width: 900, height: 700 }]
        }

        function test_flyout_controls_fit_both_window_sizes_and_show_all_states(data) {
            application.width = data.width
            application.height = data.height
            waitForRendering(application.contentItem)
            for (const name of ["angleUnitButton", "trigonometryButton"])
                verifyInsideWindow(control(name))
            mouseClick(control("trigonometryButton"))
            tryCompare(control("trigonometryPopup"), "opened", true)
            for (let variant = 0; variant < 4; ++variant) {
                const inverse = variant % 2 === 1
                const hyperbolic = variant >= 2
                if (control("trigonometryInverse").checked !== inverse)
                    mouseClick(control("trigonometryInverse"))
                if (control("trigonometryHyperbolic").checked !== hyperbolic)
                    mouseClick(control("trigonometryHyperbolic"))
                waitForRendering(application.contentItem)
                verifyInsideWindow(control("trigonometryInverse"))
                verifyInsideWindow(control("trigonometryHyperbolic"))
                for (const base of ["sin", "cos", "tan", "sec", "csc", "cot"]) {
                    const label = base + (hyperbolic ? "h" : "") + (inverse ? "⁻¹" : "")
                    const command = (inverse ? "a" : "") + base + (hyperbolic ? "h" : "")
                    const key = control("trig_" + command)
                    compare(key.text, label)
                    verifyInsideWindow(key)
                    keyMetrics.font = key.font
                    keyMetrics.text = key.text
                    verify(keyMetrics.advanceWidth + 8 <= key.width, "Function label fits: " + label)
                }
                const scheme = Application.styleHints.colorScheme === Qt.Dark ? "dark" : "light"
                grabImage(application.contentItem).save("trigonometry-" + scheme + "-" + data.tag + "-" + variant + ".png")
            }
            mouseClick(control("trig_asinh"))
            tryCompare(control("trigonometryPopup"), "visible", false)
            application.width = 360
            application.height = 632
        }

        function verifyInsideWindow(item) {
            const point = item.mapToItem(application.contentItem, 0, 0)
            verify(item.visible && item.enabled)
            verify(item.width >= 44 && item.height >= 44)
            verify(point.x >= 0 && point.y >= 0)
            verify(point.x + item.width <= application.width + 1)
            verify(point.y + item.height <= application.height + 1)
            verify(item.Accessible.name.length > 0)
        }

        function test_default_degrees_sine_uses_real_scientific_core() {
            compare(control("angleUnitButton").text, "DEG")
            enter("30")
            mouseClick(control("trigonometryButton"))
            const popup = control("trigonometryPopup")
            tryCompare(popup, "opened", true)
            mouseClick(control("trig_sin"))
            tryCompare(popup, "visible", false)
            compare(result(), "0.5")
            verify(control("expressionDisplay").text.indexOf("30") >= 0)
        }

        function test_keyboard_entry_remains_available_while_flyout_is_open() {
            keyClick("3")
            mouseClick(control("trigonometryButton"))
            const popup = control("trigonometryPopup")
            tryCompare(popup, "opened", true)
            keyClick("0")
            compare(result(), "30", "The flyout keeps Scientific digit shortcuts available")
            verify(popup.opened)
            keyClick(Qt.Key_S)
            tryCompare(popup, "visible", false)
            compare(result(), "0.5")
        }

        function cleanupTestCase() { application.close() }
    }
}
