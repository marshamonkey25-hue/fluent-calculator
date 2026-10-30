import QtQuick
import QtTest
import Calculator

Item {
    MainWindow { id: application; systemPreferences: testSystemPreferences; width: 400; height: 760 }
    TestCase {
        name: "ProgrammerCalculator"
        when: windowShown && application.visible

        function item(name) {
            const control = findChild(application.contentItem, name)
            verify(control !== null, "Visible programmer control: " + name)
            return control
        }
        function navigate(mode) {
            mouseClick(item("navigationButton"))
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            const entry = findChild(drawer.contentItem, "mode_" + mode)
            verify(entry !== null, "Navigation entry: " + mode)
            mouseClick(entry)
            tryCompare(drawer, "visible", false)
        }
        function clickCommands(commands) {
            for (const command of commands)
                mouseClick(item("key_" + command))
        }
        function initTestCase() {
            application.requestActivate()
            tryCompare(application, "active", true)
        }
        function init() { navigate("programmer") }
        function cleanup() {
            application.width = 400
            application.height = 760
            navigate("standard")
        }
        function cleanupTestCase() { application.close() }

        function test_all_radices_round_trip_exact_integers_data() {
            return [
                { tag: "decimal", radix: 10, input: "9007199254740993", hex: "20000000000001", dec: "9007199254740993", oct: "400000000000000001", bin: "100000000000000000000000000000000000000000000000000001" },
                { tag: "hexadecimal", radix: 16, input: "FF", hex: "FF", dec: "255", oct: "377", bin: "11111111" },
                { tag: "octal", radix: 8, input: "377", hex: "FF", dec: "255", oct: "377", bin: "11111111" },
                { tag: "binary", radix: 2, input: "11111111", hex: "FF", dec: "255", oct: "377", bin: "11111111" }
            ]
        }
        function ungroup(text) { return text.replace(/[ ,]/g, "") }
        function test_all_radices_round_trip_exact_integers(data) {
            mouseClick(item("radix_" + data.radix))
            for (const digit of data.input)
                mouseClick(item("key_" + digit))
            const expected = { 16: data.hex, 10: data.dec, 8: data.oct, 2: data.bin }
            for (const radix of [16, 10, 8, 2, data.radix]) {
                mouseClick(item("radix_" + radix))
                compare(item("radix_" + radix).checked, true)
                compare(ungroup(item("resultDisplay").text), expected[radix])
                compare(ungroup(item("radixValue_" + radix).text), expected[radix])
            }
        }

        function selectWidth(label) {
            for (let attempts = 0; item("wordWidthButton").text !== label && attempts < 4; ++attempts)
                mouseClick(item("wordWidthButton"))
            compare(item("wordWidthButton").text, label)
        }
        function test_word_width_signed_boundary_and_wrap_data() {
            return [
                { tag: "64-bit", width: "QWORD", max: "7FFFFFFFFFFFFFFF", high: "8000000000000000", min: "-9223372036854775808", signedMax: "9223372036854775807" },
                { tag: "32-bit", width: "DWORD", max: "7FFFFFFF", high: "80000000", min: "-2147483648", signedMax: "2147483647" },
                { tag: "16-bit", width: "WORD", max: "7FFF", high: "8000", min: "-32768", signedMax: "32767" },
                { tag: "8-bit", width: "BYTE", max: "7F", high: "80", min: "-128", signedMax: "127" }
            ]
        }
        function test_word_width_signed_boundary_and_wrap(data) {
            selectWidth(data.width)
            mouseClick(item("radix_16"))
            for (const digit of data.max) mouseClick(item("key_" + digit))
            clickCommands(["add", "1", "equals"])
            compare(ungroup(item("resultDisplay").text), data.high)
            mouseClick(item("radix_10"))
            compare(ungroup(item("resultDisplay").text), data.min)
            clickCommands(["subtract", "1", "equals"])
            compare(ungroup(item("resultDisplay").text), data.signedMax)
        }

        function test_radix_restricts_buttons_and_keyboard_data() {
            return [
                { tag: "binary", radix: 2, allowed: "1", rejected: "23456789ABCDEF" },
                { tag: "octal", radix: 8, allowed: "7", rejected: "89ABCDEF" },
                { tag: "decimal", radix: 10, allowed: "9", rejected: "ABCDEF" }
            ]
        }
        function test_radix_restricts_buttons_and_keyboard(data) {
            mouseClick(item("radix_" + data.radix))
            for (const digit of data.rejected) {
                compare(item("key_" + digit).enabled, false)
                mouseClick(item("key_" + digit))
                keyClick(digit)
                compare(item("resultDisplay").text, "0")
            }
            keyClick(".")
            compare(item("resultDisplay").text, "0")
            compare(item("key_" + data.allowed).enabled, true)
            keyClick(data.allowed)
            compare(item("resultDisplay").text, data.allowed)
            mouseClick(item("radix_16"))
            compare(item("key_F").enabled, true)
            keyClick("F")
            // Changing radix completes the current entry in the pinned core.
            compare(ungroup(item("resultDisplay").text), "F")
        }

        function test_reference_keyboard_radix_and_width_shortcuts() {
            for (const setting of [
                { key: Qt.Key_F12, label: "BYTE" }, { key: Qt.Key_F4, label: "WORD" },
                { key: Qt.Key_F3, label: "DWORD" }, { key: Qt.Key_F2, label: "QWORD" }
            ]) {
                keyClick(setting.key)
                compare(item("wordWidthButton").text, setting.label)
            }
            keyClick(Qt.Key_F5)
            compare(item("radix_16").checked, true)
            keyClick("F")
            keyClick("F")
            keyClick(Qt.Key_F6)
            compare(item("radix_10").checked, true)
            compare(ungroup(item("resultDisplay").text), "255")
            keyClick(Qt.Key_F7)
            compare(item("radix_8").checked, true)
            compare(ungroup(item("resultDisplay").text), "377")
            keyClick(Qt.Key_F8)
            compare(item("radix_2").checked, true)
            compare(ungroup(item("resultDisplay").text), "11111111")
        }

        function test_integer_editing_parentheses_and_remainder_data() {
            return [{ tag: "mouse", keyboard: false }, { tag: "keyboard", keyboard: true }]
        }
        function test_integer_editing_parentheses_and_remainder(data) {
            const keys = { backspace: Qt.Key_Backspace, negate: Qt.Key_F9, add: "+", clearEntry: Qt.Key_Delete,
                           equals: Qt.Key_Return, mod: "%", clear: Qt.Key_Escape, open: "(", close: ")", multiply: "*" }
            function enter(commands) {
                for (const command of commands) {
                    if (data.keyboard) keyClick(keys[command] || command)
                    else mouseClick(item("key_" + command))
                }
            }
            enter(["1", "2", "backspace", "negate", "add", "9", "clearEntry", "8", "equals"])
            compare(item("resultDisplay").text, "7")
            enter(["mod", "3", "equals"])
            compare(item("resultDisplay").text, "1")
            enter(["clear", "open", "2", "add", "3", "close", "multiply", "4", "equals"])
            compare(item("resultDisplay").text, "20")
            enter(["clear", "2", "add", "3", "multiply", "4", "equals"])
            compare(item("resultDisplay").text, "14")
        }

        function test_error_disables_integer_operations_and_clear_recovers() {
            clickCommands(["8", "divide", "0", "equals"])
            compare(item("errorIndicator").visible, true)
            const chinese = Qt.locale().name.indexOf("zh") === 0
            compare(item("resultDisplay").text, chinese ? "除数不能为零" : "Cannot divide by zero")
            compare(item("wordWidthButton").enabled, false)
            for (const radix of [16, 10, 8, 2]) {
                compare(item("radix_" + radix).enabled, false)
                compare(item("radixValue_" + radix).text, "")
            }
            for (const command of ["add", "subtract", "multiply", "divide", "mod", "negate", "open", "close"])
                compare(item("key_" + command).enabled, false)
            clickCommands(["clear", "7", "multiply", "6", "equals"])
            compare(item("errorIndicator").visible, false)
            compare(item("resultDisplay").text, "42")
            compare(item("wordWidthButton").enabled, true)
        }

        function test_word_width_limits_decimal_and_hex_entry_data() {
            return [
                { tag: "64-bit", width: "QWORD", decimal: "9223372036854775807", hex: "FFFFFFFFFFFFFFFF" },
                { tag: "32-bit", width: "DWORD", decimal: "2147483647", hex: "FFFFFFFF" },
                { tag: "16-bit", width: "WORD", decimal: "32767", hex: "FFFF" },
                { tag: "8-bit", width: "BYTE", decimal: "127", hex: "FF" }
            ]
        }
        function test_word_width_limits_decimal_and_hex_entry(data) {
            selectWidth(data.width)
            for (const digit of data.decimal) keyClick(digit)
            keyClick("9")
            compare(ungroup(item("resultDisplay").text), data.decimal)
            keyClick(Qt.Key_Escape)
            keyClick(Qt.Key_F5)
            for (const digit of data.hex) keyClick(digit)
            keyClick("F")
            compare(ungroup(item("resultDisplay").text), data.hex)
            keyClick(Qt.Key_F6)
            compare(item("resultDisplay").text, "-1")
        }

        function test_width_changes_truncate_and_sign_extend() {
            mouseClick(item("radix_16"))
            for (const digit of "12345678") keyClick(digit)
            selectWidth("BYTE")
            compare(item("resultDisplay").text, "78")
            mouseClick(item("radix_10"))
            compare(item("resultDisplay").text, "120")
            keyClick(Qt.Key_Escape)
            mouseClick(item("radix_16"))
            keyClick("8")
            keyClick("1")
            selectWidth("WORD")
            compare(ungroup(item("resultDisplay").text), "FF81")
            selectWidth("QWORD")
            compare(ungroup(item("resultDisplay").text), "FFFFFFFFFFFFFF81")
            mouseClick(item("radix_10"))
            compare(item("resultDisplay").text, "-127")
        }

        function test_navigation_restores_mode_defaults_and_keeps_current_entry_on_reselect() {
            mouseClick(item("radix_16"))
            selectWidth("BYTE")
            clickCommands(["F", "F"])
            navigate("programmer")
            compare(item("radix_16").checked, true)
            compare(item("wordWidthButton").text, "BYTE")
            compare(item("resultDisplay").text, "FF")
            navigate("standard")
            compare(item("resultDisplay").text, "0")
            clickCommands(["2", "add", "3", "multiply", "4", "equals"])
            compare(item("resultDisplay").text, "20")
            navigate("programmer")
            compare(item("radix_10").checked, true)
            compare(item("wordWidthButton").text, "QWORD")
            compare(item("resultDisplay").text, "0")
            verify(findChild(application.contentItem, "historyPanel") === null)
        }

        function test_small_window_keyboard_focus_stays_visible() {
            application.width = 320
            application.height = 460
            waitForRendering(application.contentItem)
            item("wordWidthButton").forceActiveFocus(Qt.TabFocusReason)
            for (let steps = 0; !item("key_equals").activeFocus && steps < 30; ++steps)
                keyClick(Qt.Key_Tab)
            verify(item("key_equals").activeFocus)
            const key = item("key_equals")
            const position = key.mapToItem(application.contentItem, 0, 0)
            verify(position.y >= 0 && position.y + key.height <= application.height + 1,
                   "The focused equals key must be visible in the small window")
            application.width = 400
            application.height = 760
        }

        function test_window_layout_and_integer_only_keypad_data() {
            return [
                { tag: "narrow", width: 320, height: 460 },
                { tag: "default", width: 360, height: 560 },
                { tag: "wide", width: 900, height: 700 }
            ]
        }
        function test_window_layout_and_integer_only_keypad(data) {
            application.width = data.width
            application.height = data.height
            mouseClick(item("radix_16"))
            for (const digit of "FFFFFFFFFFFFFFFF") keyClick(digit)
            compare(item("key_decimal").enabled, false)
            compare(item("key_decimal").Accessible.name, Qt.locale().name.indexOf("zh") === 0 ? "小数点" : "Decimal separator")
            for (const name of ["radix_16", "radix_10", "radix_8", "radix_2", "wordWidthButton",
                                "key_A", "key_clearEntry", "key_backspace", "key_divide", "key_0", "key_equals"]) {
                const control = item(name)
                control.forceActiveFocus(Qt.TabFocusReason)
                waitForRendering(application.contentItem)
                const position = control.mapToItem(application.contentItem, 0, 0)
                verify(position.x >= 0 && position.x + control.width <= application.width + 1, name + " fits horizontally")
                verify(position.y >= 0 && position.y + control.height <= application.height + 1, name + " can be reached vertically")
            }
            const scheme = Application.styleHints.colorScheme === Qt.Dark ? "dark" : "light"
            grabImage(application.contentItem).save("programmer-" + scheme + "-" + data.tag + "-keypad.png")
            const scroll = item("programmerScroll")
            mouseWheel(scroll, scroll.width / 2, scroll.height / 2, 0, 2400)
            tryCompare(scroll.contentItem, "contentY", 0)
            waitForRendering(application.contentItem)
            grabImage(application.contentItem).save("programmer-" + scheme + "-" + data.tag + "-radices.png")
        }

        function test_integer_arithmetic_uses_active_radix_data() {
            return [
                { tag: "binary", radix: 2, left: "101", right: "11", result: "1000" },
                { tag: "octal", radix: 8, left: "77", right: "1", result: "100" },
                { tag: "decimal", radix: 10, left: "99", right: "1", result: "100" },
                { tag: "hexadecimal", radix: 16, left: "FF", right: "1", result: "100" }
            ]
        }
        function test_integer_arithmetic_uses_active_radix(data) {
            mouseClick(item("radix_" + data.radix))
            for (const digit of data.left) keyClick(digit)
            keyClick("+")
            for (const digit of data.right) keyClick(digit)
            keyClick(Qt.Key_Return)
            compare(ungroup(item("resultDisplay").text), data.result)
            keyClick("-")
            for (const digit of data.right) keyClick(digit)
            keyClick(Qt.Key_Return)
            compare(ungroup(item("resultDisplay").text), data.left)
        }

        function test_hexadecimal_tab_order_follows_keypad_rows() {
            mouseClick(item("radix_16"))
            item("key_A").forceActiveFocus(Qt.TabFocusReason)
            for (const command of ["clearEntry", "clear", "backspace", "B", "open", "close", "mod", "divide", "C", "7"]) {
                keyClick(Qt.Key_Tab)
                verify(item("key_" + command).activeFocus, "Tab reaches " + command + " in visual order")
            }
        }

        function openSettings() {
            mouseClick(item("navigationButton"))
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            mouseClick(findChild(drawer.contentItem, "settingsButton"))
            tryCompare(drawer, "visible", false)
        }

        function test_runtime_translation_preserves_programmer_calculation() {
            openSettings()
            mouseClick(item("language_en-US"))
            navigate("programmer")
            mouseClick(item("radix_16"))
            selectWidth("BYTE")
            clickCommands(["A", "add"])
            openSettings()
            mouseClick(item("language_zh-CN"))
            navigate("programmer")
            compare(item("pageTitle").text, "程序员")
            compare(item("wordWidthButton").Accessible.name, "字长：8 位")
            compare(item("radix_16").Accessible.name, "十六进制：A")
            compare(item("key_mod").Accessible.name, "模")
            compare(item("key_open").Accessible.name, "左括号")
            compare(item("key_decimal").Accessible.name, "小数点")
            compare(item("radix_16").checked, true)
            compare(item("wordWidthButton").text, "BYTE")
            clickCommands(["1", "equals"])
            compare(item("resultDisplay").text, "B")
            clickCommands(["clear", "1", "divide", "0", "equals"])
            compare(item("resultDisplay").text, "除数不能为零")
            compare(item("errorIndicator").text, "错误")
            openSettings()
            mouseClick(item("language_en-US"))
            navigate("programmer")
            compare(item("resultDisplay").text, "Cannot divide by zero")
            compare(item("wordWidthButton").Accessible.name, "Word size: 8 bits")
            openSettings()
            mouseClick(item("language_system"))
            navigate("programmer")
        }

        function test_settings_keep_hidden_programmer_shortcuts_inactive_data() {
            return [
                { tag: "keypad", keys: ["7", "+", Qt.Key_Escape, Qt.Key_Return], radix: 16, width: "BYTE" },
                { tag: "radix", keys: [Qt.Key_F6, Qt.Key_F7, Qt.Key_F8], radix: 16, width: "BYTE" },
                { tag: "width", keys: [Qt.Key_F2, Qt.Key_F3, Qt.Key_F4], radix: 16, width: "BYTE" }
            ]
        }
        function test_settings_keep_hidden_programmer_shortcuts_inactive(data) {
            mouseClick(item("radix_16"))
            selectWidth("BYTE")
            clickCommands(["A", "add"])
            openSettings()
            item("theme_light").forceActiveFocus(Qt.TabFocusReason)
            for (const key of data.keys) keyClick(key)
            navigate("programmer")
            compare(item("radix_" + data.radix).checked, true)
            compare(item("wordWidthButton").text, data.width)
            clickCommands(["1", "equals"])
            compare(item("resultDisplay").text, "B", "Settings preserves the pending integer calculation")
        }

        function test_scientific_and_programmer_keep_their_own_input_rules() {
            clickCommands(["7", "divide", "2", "equals"])
            compare(item("resultDisplay").text, "3")
            navigate("scientific")
            clickCommands(["7", "divide", "2", "equals"])
            compare(item("resultDisplay").text, "3.5")
            clickCommands(["clear", "openParenthesis", "2", "add", "3", "closeParenthesis", "multiply", "4", "equals"])
            compare(item("resultDisplay").text, "20")
            navigate("programmer")
            compare(item("radix_10").checked, true)
            compare(item("wordWidthButton").text, "QWORD")
            compare(item("resultDisplay").text, "0")
            compare(item("key_decimal").enabled, false)
        }

        function test_programmer_defaults_and_integer_arithmetic() {
            compare(item("radix_10").checked, true)
            compare(item("wordWidthButton").text, "QWORD")
            clickCommands(["7", "divide", "2", "equals"])
            compare(item("resultDisplay").text, "3")
            verify(findChild(application.contentItem, "historyPanel") === null)
        }
    }
}
