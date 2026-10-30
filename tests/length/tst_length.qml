import QtQuick
import QtTest
import Calculator

Item {
    MainWindow { id: application; systemPreferences: testSystemPreferences }
    TextEdit {
        id: clipboardProvider
        parent: application.contentItem
        width: 200
        height: 30
        visible: false
    }
    TestCase {
        name: "LengthConversion"
        when: windowShown && application.visible

        function initTestCase() {
            application.requestActivate()
            tryCompare(application, "active", true)
        }

        function init() {
            navigate("mode_length")
            mouseClick(control("converterValue1"))
            mouseClick(control("converterKey_clear"))
        }

        function navigate(name) {
            mouseClick(findChild(application.contentItem, "navigationButton"))
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            const entry = findChild(drawer.contentItem, name)
            verify(entry !== null, "Navigation entry: " + name)
            entry.forceActiveFocus(Qt.TabFocusReason)
            mouseClick(entry)
            tryCompare(drawer, "visible", false)
        }

        function control(name) {
            const item = findChild(application.contentItem, name)
            verify(item !== null, "Converter control: " + name)
            return item
        }

        function selectUnit(name, id) {
            const combo = control(name)
            const index = combo.indexOfValue(id)
            verify(index >= 0, "Reference unit is available: " + id)
            combo.forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_Home)
            for (let row = 0; row < index; ++row)
                keyClick(Qt.Key_Down)
            compare(combo.currentValue, id)
        }

        function test_000_reference_region_defaults() {
            const chinese = Qt.locale().name.indexOf("zh") === 0
            compare(control("converterUnit1").currentValue, chinese ? 32 : 30,
                    "Pinned SI regions start with inches; US starts with centimeters")
            compare(control("converterUnit2").currentValue, chinese ? 30 : 32,
                    "Pinned SI regions target centimeters; US targets inches")
        }

        function test_inches_to_centimeters_through_navigation_and_keypad() {
            const chinese = Qt.locale().name.indexOf("zh") === 0
            compare(control("pageTitle").text, chinese ? "长度" : "Length")
            selectUnit("converterUnit1", 32)
            selectUnit("converterUnit2", 30)
            mouseClick(control("converterKey_clear"))
            mouseClick(control("converterKey_1"))
            compare(control("converterValue1").text, "1")
            compare(control("converterValue2").text, "2.54")
        }

        // Independent known metre equivalents; result precision follows the pinned
        // converter (7 preferred digits, up to 15). No arithmetic-core exactness.
        function test_reference_units_convert_to_meters_data() {
            return [
                {tag: "angstrom", id: 168, meters: 1e-10},
                {tag: "nanometer", id: 38, meters: 1e-9},
                {tag: "micron", id: 35, meters: 1e-6},
                {tag: "millimeter", id: 37, meters: 0.001},
                {tag: "centimeter", id: 30, meters: 0.01},
                {tag: "meter", id: 34, meters: 1},
                {tag: "kilometer", id: 33, meters: 1000},
                {tag: "inch", id: 32, meters: 0.0254},
                {tag: "foot", id: 31, meters: 0.3048},
                {tag: "yard", id: 40, meters: 0.9144},
                {tag: "mile", id: 36, meters: 1609.344},
                {tag: "nautical-mile", id: 39, meters: 1852}
            ]
        }

        function test_reference_units_convert_to_meters(data) {
            compare(control("converterUnit1").count, 12, "All reference selectable length units")
            selectUnit("converterUnit1", data.id)
            selectUnit("converterUnit2", 34)
            mouseClick(control("converterKey_clear"))
            mouseClick(control("converterKey_1"))
            const actual = Number(control("converterValue2").text.replace(/,/g, ""))
            verify(Math.abs(actual - data.meters) <= Math.max(1e-15, Math.abs(data.meters) * 5e-7),
                   "Known length ratio within converter display tolerance: " + actual)
        }

        function enter(text, keyboard) {
            for (const character of text) {
                if (keyboard) keyClick(character)
                else mouseClick(control("converterKey_" + (character === "." ? "decimal" : character)))
            }
        }

        function test_either_value_can_be_input_without_changing_unit_positions_data() {
            return [{tag: "mouse", keyboard: false}, {tag: "keyboard", keyboard: true}]
        }

        function test_either_value_can_be_input_without_changing_unit_positions(data) {
            selectUnit("converterUnit1", 32)
            selectUnit("converterUnit2", 30)
            mouseClick(control("converterKey_clear"))
            enter("12.5", data.keyboard)
            compare(control("converterValue2").text, "31.75")
            if (data.keyboard) {
                control("converterValue2").forceActiveFocus(Qt.TabFocusReason)
                keyClick(Qt.Key_Space)
            } else mouseClick(control("converterValue2"))
            verify(control("converterValue2").checked, "Second value becomes the input")
            compare(control("converterValue1").text, "12.5", "Switching preserves visible values")
            compare(control("converterValue2").text, "31.75")
            enter("2.54", data.keyboard)
            compare(control("converterValue1").text, "1", "Input on the second side reverses conversion")
            compare(control("converterValue2").text, "2.54", "First keystroke replaces the previous result")
            const chinese = Qt.locale().name.indexOf("zh") === 0
            compare(control("converterValue2").Accessible.name, chinese ? "输入：2.54 厘米" : "Input: 2.54 Centimeters")
            compare(control("converterValue1").Accessible.name, chinese ? "结果：1 英寸" : "Result: 1 Inches")
            compare(control("converterUnit1").currentValue, 32)
            compare(control("converterUnit2").currentValue, 30)
            selectUnit("converterUnit1", 30)
            compare(control("converterValue1").text, "2.54", "Same-unit conversion")
            mouseClick(control("converterValue1"))
            selectUnit("converterUnit1", 32)
            mouseClick(control("converterKey_clear"))
            enter("12.5", data.keyboard)
            compare(control("converterValue2").text, "31.75", "Round trip remains consistent")
        }

        function test_input_digit_limit_and_backspace_match_for_mouse_and_keyboard_data() {
            return [{tag: "mouse", keyboard: false}, {tag: "keyboard", keyboard: true}]
        }

        function test_input_digit_limit_and_backspace_match_for_mouse_and_keyboard(data) {
            mouseClick(control("converterValue1"))
            selectUnit("converterUnit1", 34)
            selectUnit("converterUnit2", 34)
            mouseClick(control("converterKey_clear"))
            enter("123456789012345", data.keyboard)
            compare(control("converterValue1").text, "123,456,789,012,345")
            enter("6", data.keyboard)
            compare(control("converterValue1").text, "123,456,789,012,345", "Sixteenth digit is rejected")
            compare(control("converterValue2").text, "123,456,789,012,345", "Identity retains 15 digits")
            verify(control("converterStatus").visible)
            compare(control("converterStatus").text, Qt.locale().name.indexOf("zh") === 0 ? "最多输入 15 位数字" : "Maximum 15 digits")
            if (data.keyboard) keyClick(Qt.Key_Backspace)
            else mouseClick(control("converterKey_backspace"))
            compare(control("converterValue1").text, "12,345,678,901,234")
            verify(!control("converterStatus").visible, "Editing clears the limit notice")
            enter(".5", data.keyboard)
            compare(control("converterValue1").text, "12,345,678,901,234.5", "Decimal separator does not consume a digit")
            enter("6", data.keyboard)
            compare(control("converterValue1").text, "12,345,678,901,234.5")
            if (data.keyboard) keyClick(Qt.Key_Escape)
            else mouseClick(control("converterKey_clear"))
            compare(control("converterValue1").text, "0")
            compare(control("converterValue2").text, "0")
            enter("0.50", data.keyboard)
            enter(".", data.keyboard)
            compare(control("converterValue1").text, "0.50", "Typed zero and redundant decimal behavior follow the core")
            compare(control("converterValue2").text, "0.5")
        }

        function paste(text, menu) {
            clipboardProvider.text = text
            clipboardProvider.visible = true
            clipboardProvider.forceActiveFocus()
            keyClick(Qt.Key_A, Qt.ControlModifier)
            keyClick(Qt.Key_C, Qt.ControlModifier)
            clipboardProvider.visible = false
            const value = control("converterValue1")
            value.forceActiveFocus()
            if (menu) {
                mouseClick(value, value.width / 2, value.height / 2, Qt.RightButton)
                const popup = findChild(application, "converterContextMenu")
                verify(popup !== null, "Value context menu is available")
                tryCompare(popup, "opened", true)
                mouseClick(findChild(popup.contentItem, "converterPaste"))
                tryCompare(popup, "visible", false)
            } else keyClick(Qt.Key_V, Qt.ControlModifier)
        }

        function test_invalid_input_is_explicit_and_correcting_input_recovers_data() {
            return [
                {tag: "negative-keyboard-paste", input: "-12.5", menu: false, kind: "negative"},
                {tag: "negative-menu-paste", input: "-12.5", menu: true, kind: "negative"},
                {tag: "malformed", input: "1.2abc", menu: false, kind: "invalid"},
                {tag: "non-finite", input: "NaN", menu: true, kind: "invalid"},
                {tag: "duplicate-decimal", input: "1..2", menu: false, kind: "invalid"},
                {tag: "overflow", input: "9".repeat(309), menu: false, kind: "unavailable"}
            ]
        }

        function test_invalid_input_is_explicit_and_correcting_input_recovers(data) {
            mouseClick(control("converterValue1"))
            selectUnit("converterUnit1", 32)
            selectUnit("converterUnit2", 30)
            mouseClick(control("converterKey_clear"))
            enter("1", false)
            paste(data.input, data.menu)
            const chinese = Qt.locale().name.indexOf("zh") === 0
            const messages = chinese
                ? {negative: "长度不能为负值", invalid: "无效输入", unavailable: "无法显示结果"}
                : {negative: "Length cannot be negative", invalid: "Invalid input", unavailable: "Result cannot be displayed"}
            verify(control("converterStatus").visible, "Invalid input has an explicit visible state")
            compare(control("converterStatus").text, messages[data.kind])
            enter("2", false)
            compare(control("converterValue1").text, "2", "New input recovers from the error")
            compare(control("converterValue2").text, "5.08")
            verify(!control("converterStatus").visible)
            paste("12.5", data.menu)
            compare(control("converterValue1").text, "12.5", "Valid paste uses the same converter input")
            compare(control("converterValue2").text, "31.75")
        }

        function test_copy_uses_selected_value_and_preserves_scientific_result_data() {
            return [{tag: "keyboard", menu: false}, {tag: "context-menu", menu: true}]
        }

        function test_copy_uses_selected_value_and_preserves_scientific_result(data) {
            mouseClick(control("converterValue1"))
            selectUnit("converterUnit1", 168)
            selectUnit("converterUnit2", 33)
            mouseClick(control("converterKey_clear"))
            enter("0.00000000000001", true)
            const result = control("converterValue2").text
            verify(/e-27$/.test(result), "Tiny output uses scientific notation")
            verify(Math.abs(Number(result) - 1e-27) <= 5e-34, "Scientific display within 7-digit tolerance")
            mouseClick(control("converterValue2"))
            if (data.menu) {
                const value = control("converterValue2")
                mouseClick(value, value.width / 2, value.height / 2, Qt.RightButton)
                const popup = findChild(application, "converterContextMenu")
                tryCompare(popup, "opened", true)
                const copy = findChild(popup.contentItem, "converterCopy")
                verify(copy !== null, "Copy action is available")
                mouseClick(copy)
                tryCompare(popup, "visible", false)
            } else keyClick(Qt.Key_C, Qt.ControlModifier)
            clipboardProvider.text = ""
            clipboardProvider.visible = true
            clipboardProvider.forceActiveFocus()
            keyClick(Qt.Key_V, Qt.ControlModifier)
            compare(clipboardProvider.text, result, "Copy retains the selected scientific result")
            clipboardProvider.visible = false
        }

        function cleanup() { clipboardProvider.visible = false }

        function test_display_rounding_and_scientific_boundaries_data() {
            return [
                {tag: "preferred-seven-digits", from: 34, to: 32, input: "1", expected: 39.37007874015748, text: "39.37008"},
                {tag: "adaptive-nine-digits", from: 34, to: 33, input: "123456789", expected: 123456.789, text: "123,456.789"},
                {tag: "small-fixed", from: 168, to: 34, input: "1", expected: 1e-10, text: "0.0000000001"},
                {tag: "small-scientific", from: 168, to: 33, input: "0.00000000000001", expected: 1e-27, scientific: true},
                {tag: "large-scientific", from: 39, to: 168, input: "999999999999999", expected: 1.852e28, scientific: true},
                {tag: "large-fixed", from: 33, to: 168, input: "1", expected: 1e13, text: "10,000,000,000,000"},
                {tag: "identity-trailing-zeroes", from: 34, to: 34, input: "123.4500", expected: 123.45, text: "123.45"},
                {tag: "zero", from: 39, to: 168, input: "0", expected: 0, text: "0"}
            ]
        }

        function test_display_rounding_and_scientific_boundaries(data) {
            selectUnit("converterUnit1", data.from)
            selectUnit("converterUnit2", data.to)
            mouseClick(control("converterKey_clear"))
            enter(data.input, true)
            const text = control("converterValue2").text
            const actual = Number(text.replace(/,/g, ""))
            // Fixed ratios use double. Scientific output has seven significant
            // digits; permit at most 0.5 ppm of the independently known value.
            verify(Math.abs(actual - data.expected) <= Math.max(1e-40, Math.abs(data.expected) * 5e-7),
                   "Display tolerance for " + data.tag + ": " + text)
            if (data.scientific) verify(/e[+-][0-9]+$/.test(text))
            else compare(text, data.text)
            verify(!control("converterStatus").visible)
        }

        function test_unit_dropdown_keeps_converter_shortcuts_inactive() {
            selectUnit("converterUnit1", 32)
            selectUnit("converterUnit2", 30)
            enter("12", false)
            const combo = control("converterUnit1")
            mouseClick(combo)
            tryCompare(combo.popup, "opened", true)
            keyClick("2")
            keyClick(Qt.Key_Escape)
            tryCompare(combo.popup, "visible", false)
            compare(control("converterValue1").text, "12", "Dropdown input does not change the entered number")
            compare(control("converterValue2").text, "30.48")
        }

        function contrastRatio(a, b) {
            function channel(c) { return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4) }
            function luminance(c) { return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b) }
            const x = luminance(a), y = luminance(b)
            return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05)
        }

        function test_runtime_language_and_theme_preserve_conversion_data() {
            return [{tag: "English-light", language: "en-US", theme: "light"},
                    {tag: "Chinese-dark", language: "zh-CN", theme: "dark"}]
        }

        function test_runtime_language_and_theme_preserve_conversion(data) {
            selectUnit("converterUnit1", 32)
            selectUnit("converterUnit2", 30)
            enter("12.5", false)
            navigate("settingsButton")
            mouseClick(control("language_" + data.language))
            mouseClick(control("theme_" + data.theme))
            navigate("mode_length")
            const chinese = data.language === "zh-CN"
            compare(control("pageTitle").text, chinese ? "长度" : "Length")
            compare(control("converterUnit1").currentText, chinese ? "英寸" : "Inches")
            compare(control("converterUnit2").currentText, chinese ? "厘米" : "Centimeters")
            compare(control("converterKey_clear").Accessible.name, chinese ? "清除输入" : "Clear entry")
            compare(control("converterValue1").text, "12.5")
            compare(control("converterValue2").text, "31.75")
            verify(contrastRatio(control("converterValue1").palette.buttonText, application.color) >= 4.5)
            verify(data.theme === "dark" ? application.color.r < 0.25 : application.color.r > 0.75)
            navigate("settingsButton")
            mouseClick(control("language_system"))
            mouseClick(control("theme_system"))
        }

        function test_layout_and_keyboard_focus_data() {
            return [{tag: "narrow", width: 320, height: 560}, {tag: "wide", width: 900, height: 600}]
        }

        function test_layout_and_keyboard_focus(data) {
            application.width = data.width
            application.height = data.height
            selectUnit("converterUnit1", 39)
            selectUnit("converterUnit2", 168)
            enter("999999999999999", true)
            verify(waitForPolish(application))
            const names = ["converterValue1", "converterUnit1", "converterValue2", "converterUnit2",
                           "converterKey_clear", "converterKey_backspace", "converterKey_7", "converterKey_8",
                           "converterKey_9", "converterKey_4", "converterKey_5", "converterKey_6",
                           "converterKey_1", "converterKey_2", "converterKey_3", "converterKey_0", "converterKey_decimal"]
            control(names[0]).forceActiveFocus(Qt.TabFocusReason)
            for (let index = 0; index < names.length; ++index) {
                const item = control(names[index])
                if (index > 0) keyClick(Qt.Key_Tab)
                tryCompare(item, "activeFocus", true)
                verify(item.visualFocus, "Keyboard focus has a visual state: " + names[index])
                const position = item.mapToItem(application.contentItem, 0, 0)
                verify(item.visible && item.enabled && item.width >= 44 && item.height >= 32)
                verify(position.x >= 0 && position.x + item.width <= application.width + 1, names[index] + " fits width")
                verify(position.y >= 40 && position.y + item.height <= application.height + 1, names[index] + " fits height")
                verify(item.Accessible.name.length > 0)
            }
            const scheme = application.color.r < 0.5 ? "dark" : "light"
            const language = Qt.locale().name.indexOf("zh") === 0 ? "zh-CN" : "en-US"
            waitForRendering(application.contentItem, 100)
            grabImage(application.contentItem).save("length-" + scheme + "-" + language + "-" + data.tag + ".png")
            application.width = 360
            application.height = 560
        }

        function test_navigation_and_hidden_shortcuts_preserve_arithmetic() {
            navigate("mode_standard")
            for (const command of ["clear", "6", "multiply"])
                mouseClick(control("key_" + command))
            navigate("mode_length")
            enter("12", false)
            verify(findChild(application.contentItem, "historyButton").visible === false)
            navigate("settingsButton")
            for (const key of ["9", ".", Qt.Key_Backspace, Qt.Key_Escape]) keyClick(key)
            navigate("mode_length")
            compare(control("converterValue1").text, "12", "Hidden converter ignores settings input")
            navigate("mode_standard")
            mouseClick(control("key_7"))
            mouseClick(control("key_equals"))
            compare(control("resultDisplay").text, "42", "Conversion input leaves the arithmetic core unchanged")
        }

        function test_selected_input_keeps_reference_surface_and_balanced_landscape() {
            application.width = 900
            application.height = 600
            mouseClick(control("converterValue1"))
            control("converterKey_clear").forceActiveFocus(Qt.TabFocusReason)
            verify(waitForPolish(application))
            waitForRendering(application.contentItem)
            const value = control("converterValue1")
            const point = value.mapToItem(application.contentItem, 8, 8)
            const pixel = grabImage(application.contentItem).pixel(Math.round(point.x), Math.round(point.y))
            verify(Math.abs(pixel.r - application.color.r) < 0.02 && Math.abs(pixel.g - application.color.g) < 0.02
                   && Math.abs(pixel.b - application.color.b) < 0.02,
                   "Selected input uses the neutral reference surface, with bold text as its active indicator")
            verify(value.width >= application.width * 0.45 && value.width <= application.width * 0.55,
                   "Landscape uses the pinned equal display/keypad columns")
            application.width = 360
            application.height = 560
        }

        function test_unavailable_physical_result_cannot_become_input_and_recovers() {
            selectUnit("converterUnit1", 33)
            selectUnit("converterUnit2", 168)
            enter("999999999999999", true)
            let side = 1
            for (let cycle = 0; cycle < 22; ++cycle) {
                side = side === 1 ? 2 : 1
                mouseClick(control("converterValue" + side))
                selectUnit("converterUnit" + side, 33)
                selectUnit("converterUnit" + (side === 1 ? 2 : 1), 168)
            }
            const resultSide = side === 1 ? 2 : 1
            const result = control("converterValue" + resultSide)
            compare(result.text, "—")
            verify(!result.enabled, "Unavailable physical results cannot become numeric input")
            verify(control("converterStatus").visible)
            mouseClick(result)
            verify(control("converterValue" + side).checked)
            selectUnit("converterUnit" + resultSide, 38)
            navigate("mode_energy")
            selectUnit("converterUnit1", side === 1 ? 166 : 25)
            selectUnit("converterUnit2", side === 1 ? 25 : 166)
            compare(control("converterValue" + resultSide).text, "—")
            verify(control("converterStatus").visible)
            navigate("mode_length")
            navigate("mode_energy")
            compare(control("converterValue" + resultSide).text, "—")
            verify(control("converterStatus").visible, "Category return preserves the unavailable-result explanation")
            verify(!control("converterValue" + resultSide).enabled)
            navigate("mode_length")
            mouseClick(control("converterKey_clear"))
            keyClick("2")
            compare(control("converterValue" + side).text, "2")
            compare(control("converterValue" + resultSide).text, "2,000,000,000,000")
            verify(!control("converterStatus").visible)
            mouseClick(control("converterValue1"))
        }

        function test_scientific_result_stays_consistent_when_reused_on_the_other_side() {
            selectUnit("converterUnit1", 168)
            selectUnit("converterUnit2", 33)
            enter("0.0000001", true)
            const tiny = Number(control("converterValue2").text)
            verify(Math.abs(tiny - 1e-20) < 5e-27)
            mouseClick(control("converterValue2"))
            selectUnit("converterUnit1", 33)
            verify(Math.abs(Number(control("converterValue1").text) - 1e-20) < 5e-27,
                   "Same-unit reuse retains the exponent, including trailing zeroes")
            compare(control("converterValue1").text, control("converterValue2").text)
            enter("2", true)
            compare(control("converterValue1").text, "2", "New input replaces the scientific value")
            compare(control("converterValue2").text, "2")
        }

        function test_unit_selector_indicator_has_readable_theme_contrast() {
            selectUnit("converterUnit1", 34)
            control("converterValue1").forceActiveFocus(Qt.TabFocusReason)
            waitForRendering(application.contentItem, 100)
            const combo = control("converterUnit1")
            const point = combo.mapToItem(application.contentItem, 0, 0)
            const image = grabImage(application.contentItem)
            let readable = 0
            for (let x = combo.width - 24; x < combo.width - 8; ++x) {
                for (let y = Math.round(combo.height / 2) - 5; y < Math.round(combo.height / 2) + 5; ++y) {
                    if (contrastRatio(image.pixel(Math.round(point.x + x), Math.round(point.y + y)), application.color) >= 3)
                        ++readable
                }
            }
            verify(readable >= 8, "Unit dropdown indicator has at least 3:1 contrast in the visible theme")
        }

        function test_subnormal_result_reuse_preserves_finite_values_and_recovers() {
            selectUnit("converterUnit1", 168)
            selectUnit("converterUnit2", 33)
            enter("1", true)
            let side = 1
            for (let cycle = 0; cycle < 24; ++cycle) {
                side = side === 1 ? 2 : 1
                mouseClick(control("converterValue" + side))
                selectUnit("converterUnit" + side, 168)
                selectUnit("converterUnit" + (side === 1 ? 2 : 1), 33)
            }
            verify(Math.abs(Number(control("converterValue" + side).text) - 1e-312) < 5e-319,
                   "Finite subnormal results remain usable within the converter display tolerance")
            compare(control("converterValue" + (side === 1 ? 2 : 1)).text, "0", "Genuine double underflow rounds to zero")
            mouseClick(control("converterKey_clear"))
            keyClick("2")
            compare(control("converterValue" + side).text, "2")
            verify(Math.abs(Number(control("converterValue" + (side === 1 ? 2 : 1)).text) - 2e-13) < 1e-19)
            verify(!control("converterStatus").visible)
            mouseClick(control("converterValue1"))
        }

        function cleanupTestCase() { application.close() }
    }
}
