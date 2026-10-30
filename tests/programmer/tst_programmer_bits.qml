import QtQuick
import QtTest
import Calculator

Item {
    MainWindow { id: application; systemPreferences: testSystemPreferences; width: 400; height: 760 }
    TestCase {
        name: "ProgrammerBits"
        when: windowShown && application.visible

        function item(name) {
            let control = findChild(application.contentItem, name) || findChild(application, name)
            for (const popupName of ["bitwisePopup", "bitShiftPopup"]) {
                const popup = findChild(application, popupName)
                if (!control && popup) control = findChild(popup.contentItem, name)
            }
            verify(control !== null, "Programmer control: " + name)
            return control
        }
        function click(name) {
            const control = item(name)
            control.forceActiveFocus(Qt.TabFocusReason)
            waitForRendering(application.contentItem, 100)
            mouseClick(control)
        }
        function navigate(mode) {
            click("navigationButton")
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            mouseClick(findChild(drawer.contentItem, "mode_" + mode))
            tryCompare(drawer, "visible", false)
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
        function result() { return item("resultDisplay").text.replace(/[ ,]/g, "") }

        function test_logical_operations_mouse_and_reference_shortcuts_data() {
            return [
                { tag: "or", command: "or", shortcut: "|", result: "31" },
                { tag: "not", command: "not", shortcut: "~", result: "-26" },
                { tag: "nand", command: "nand", shortcut: ".", result: "-2" },
                { tag: "nor", command: "nor", shortcut: "\\", result: "-32" },
                { tag: "xor", command: "xor", shortcut: "^", result: "30" },
                { tag: "and", command: "and", shortcut: "&", result: "1" }
            ]
        }
        function test_logical_operations_mouse_and_reference_shortcuts(data) {
            for (const keyboard of [false, true]) {
                keyClick(Qt.Key_Escape)
                keyClick("2")
                keyClick("5")
                if (keyboard) keyClick(data.shortcut)
                else {
                    click("bitwiseButton")
                    tryCompare(item("bitwisePopup"), "opened", true)
                    click("key_" + data.command)
                    tryCompare(item("bitwisePopup"), "visible", false)
                }
                if (data.command !== "not") keyClick("7")
                keyClick(Qt.Key_Return)
                compare(result(), data.result)
            }
        }

        function selectByte() {
            keyClick(Qt.Key_F12)
            compare(item("wordWidthButton").text, "BYTE")
        }
        function selectShift(mode) {
            click("bitShiftButton")
            tryCompare(item("bitShiftPopup"), "opened", true)
            click("shiftMode_" + mode)
            tryCompare(item("bitShiftPopup"), "visible", false)
        }
        function test_distinct_shift_modes_mouse_and_keyboard_data() {
            return [
                { tag: "arithmetic", mode: "arithmetic", left: "2", right: "C0", unary: false },
                { tag: "logical", mode: "logical", left: "2", right: "40", unary: false },
                { tag: "circular", mode: "circular", left: "3", right: "C0", unary: true },
                { tag: "carry", mode: "carry", left: "2", right: "40", unary: true }
            ]
        }
        function test_distinct_shift_modes_mouse_and_keyboard(data) {
            selectByte()
            keyClick(Qt.Key_F5)
            selectShift(data.mode)
            for (const keyboard of [false, true]) {
                for (const direction of ["left", "right"]) {
                    keyClick(Qt.Key_Escape)
                    keyClick("8")
                    keyClick("1")
                    if (keyboard) keyClick(direction === "left" ? "<" : ">")
                    else click("key_shift_" + direction)
                    if (!data.unary) {
                        keyClick("1")
                        keyClick(Qt.Key_Return)
                    }
                    compare(result(), data[direction])
                    if (data.mode === "carry") {
                        if (keyboard) keyClick(direction === "left" ? "<" : ">")
                        else click("key_shift_" + direction)
                        compare(result(), direction === "left" ? "5" : "A0")
                    }
                }
            }
        }

        function test_bit_editing_keeps_exact_high_bit_and_all_radices_in_sync() {
            click("bitPanelButton")
            compare(item("bit_63").checked, false)
            click("bit_63")
            compare(result(), "-9223372036854775808")
            compare(item("bit_63").checked, true)
            compare(item("radixValue_16").text.replace(/ /g, ""), "8000000000000000")
            click("bit_0")
            compare(result(), "-9223372036854775807")
            compare(item("radixValue_16").text.replace(/ /g, ""), "8000000000000001")
            compare(item("bit_0").checked, true)
            click("radix_16")
            compare(result(), "8000000000000001")
            click("bit_63")
            compare(result(), "1")
            click("fullKeypadButton")
            keyClick("+")
            keyClick("1")
            keyClick(Qt.Key_Return)
            compare(result(), "2")
            click("bitPanelButton")
            compare(item("bit_0").checked, false)
            compare(item("bit_1").checked, true)
        }

        function test_bits_follow_each_word_width_and_keyboard_space_data() {
            return [
                { tag: "64", key: Qt.Key_F2, width: 64, minimum: "-9223372036854775808", hex: "8000000000000000" },
                { tag: "32", key: Qt.Key_F3, width: 32, minimum: "-2147483648", hex: "80000000" },
                { tag: "16", key: Qt.Key_F4, width: 16, minimum: "-32768", hex: "8000" },
                { tag: "8", key: Qt.Key_F12, width: 8, minimum: "-128", hex: "80" }
            ]
        }
        function test_bits_follow_each_word_width_and_keyboard_space(data) {
            keyClick(data.key)
            click("bitPanelButton")
            for (let bit = 0; bit < 64; ++bit) {
                compare(item("bit_" + bit).enabled, bit < data.width)
                compare(item("bit_" + bit).checked, false)
            }
            const highBit = item("bit_" + (data.width - 1))
            highBit.forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_Space)
            compare(highBit.checked, true)
            compare(result(), data.minimum)
            compare(item("radixValue_16").text.replace(/ /g, ""), data.hex)
            if (data.width < 64) {
                mouseClick(item("bit_63"))
                compare(result(), data.minimum)
            }
            keyClick(Qt.Key_Space)
            compare(result(), "0")
            compare(highBit.checked, false)
        }

        function test_shift_count_boundaries_and_error_recovery_data() {
            return [
                { tag: "64", key: Qt.Key_F2, width: 64, maximumShift: "4611686018427387904" },
                { tag: "32", key: Qt.Key_F3, width: 32, maximumShift: "1073741824" },
                { tag: "16", key: Qt.Key_F4, width: 16, maximumShift: "16384" },
                { tag: "8", key: Qt.Key_F12, width: 8, maximumShift: "64" }
            ]
        }
        function test_shift_count_boundaries_and_error_recovery(data) {
            keyClick(data.key)
            keyClick("1")
            keyClick("<")
            for (const digit of String(data.width - 2)) keyClick(digit)
            keyClick(Qt.Key_Return)
            compare(result(), data.maximumShift)
            keyClick("<")
            keyClick("1")
            keyClick(Qt.Key_Return)
            verify(result().startsWith("-"), "Shifting into the sign bit uses signed decimal")
            keyClick("<")
            keyClick("1")
            keyClick(Qt.Key_Return)
            compare(result(), "0", "Shifting past the high bit truncates to zero")
            for (const mode of ["arithmetic", "logical"]) {
                selectShift(mode)
                for (const direction of ["<", ">"]) {
                    keyClick(Qt.Key_Escape)
                    keyClick("1")
                    keyClick(direction)
                    keyClick("0")
                    keyClick(Qt.Key_Return)
                    compare(result(), "1", "Zero shift leaves the integer unchanged")
                    keyClick(direction)
                    for (const digit of String(data.width)) keyClick(digit)
                    keyClick(Qt.Key_Return)
                    compare(item("errorIndicator").visible, true)
                    compare(item("resultDisplay").text, Qt.locale().name.indexOf("zh") === 0 ? "结果未定义" : "Result not defined")
                    compare(item("bitwiseButton").enabled, false)
                    compare(item("bitShiftButton").enabled, false)
                    compare(item("key_shift_left").enabled, false)
                    click("bitPanelButton")
                    for (let bit = 0; bit < 64; ++bit) compare(item("bit_" + bit).enabled, false)
                    click("fullKeypadButton")
                    keyClick(Qt.Key_Escape)
                    keyClick("6")
                    keyClick("&")
                    keyClick("3")
                    keyClick(Qt.Key_Return)
                    compare(result(), "2")
                }
            }
        }

        function test_bit_edits_and_word_width_changes_continue_real_calculation() {
            keyClick("5")
            keyClick("+")
            click("bitPanelButton")
            click("bit_0") // Reference seeds the operand from 5, then flips it to 4.
            compare(result(), "4")
            click("fullKeypadButton")
            keyClick(Qt.Key_Return)
            compare(result(), "9")
            keyClick(Qt.Key_Escape)
            keyClick(Qt.Key_F5)
            for (const digit of "123480") keyClick(digit)
            click("bitPanelButton")
            keyClick(Qt.Key_F12)
            compare(result(), "80")
            compare(item("bit_7").checked, true)
            compare(item("bit_8").enabled, false)
            keyClick(Qt.Key_F4)
            compare(result(), "FF80")
            compare(item("bit_15").checked, true)
            compare(item("bit_16").enabled, false)
            keyClick(Qt.Key_F2)
            compare(result(), "FFFFFFFFFFFFFF80")
            compare(item("bit_63").checked, true)
            click("bit_7")
            compare(result(), "FFFFFFFFFFFFFF00")
            click("radix_10")
            compare(result(), "-256")
        }

        function openSettings() {
            click("navigationButton")
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            mouseClick(findChild(drawer.contentItem, "settingsButton"))
            tryCompare(drawer, "visible", false)
        }
        function test_translation_and_settings_preserve_bits_and_disable_hidden_shortcuts() {
            openSettings()
            click("language_en-US")
            navigate("programmer")
            selectByte()
            selectShift("carry")
            keyClick("1")
            click("bitPanelButton")
            openSettings()
            click("language_zh-CN")
            item("theme_light").forceActiveFocus(Qt.TabFocusReason)
            for (const key of ["~", ".", "&", "|", "^", "\\", "<", ">", "7", Qt.Key_F2, Qt.Key_F6]) keyClick(key)
            navigate("programmer")
            compare(result(), "1")
            compare(item("wordWidthButton").text, "BYTE")
            compare(item("bitPanelButton").Accessible.name, "位切换键盘")
            compare(item("fullKeypadButton").Accessible.name, "完整键盘")
            compare(item("bit_0").Accessible.name, "最低有效位：1")
            compare(item("bit_7").Accessible.name, "最高有效位：0")
            compare(item("bit_4").Accessible.name, "第 4 位：0")
            click("fullKeypadButton")
            compare(item("key_shift_left").Accessible.name, "带进位循环左移")
            click("bitShiftButton")
            tryCompare(item("bitShiftPopup"), "opened", true)
            compare(item("shiftMode_carry").checked, true)
            compare(item("shiftMode_carry").text, "带进位循环移位")
            click("shiftMode_arithmetic")
            tryCompare(item("bitShiftPopup"), "visible", false)
            click("bitwiseButton")
            tryCompare(item("bitwisePopup"), "opened", true)
            compare(item("key_xor").Accessible.name, "异或")
            click("key_not")
            tryCompare(item("bitwisePopup"), "visible", false)
            compare(result(), "-2")
            openSettings()
            click("language_system")
            navigate("programmer")
        }

        function test_mouse_clear_slot_remains_enabled_after_error() {
            keyClick("8")
            keyClick("/")
            keyClick("0")
            keyClick(Qt.Key_Return)
            compare(item("errorIndicator").visible, true)
            const clear = findChild(application.contentItem, "key_clearEntry") || item("key_clear")
            compare(clear.enabled, true)
            click(clear.objectName)
            compare(item("errorIndicator").visible, false)
            keyClick("2")
            keyClick("+")
            keyClick("3")
            keyClick(Qt.Key_Return)
            compare(result(), "5")
        }

        function test_keypad_selector_keeps_current_selection_checked() {
            compare(item("fullKeypadButton").checked, true)
            click("fullKeypadButton")
            compare(item("fullKeypadButton").checked, true)
            compare(item("bitPanelButton").checked, false)
            click("bitPanelButton")
            compare(item("fullKeypadButton").checked, false)
            compare(item("bitPanelButton").checked, true)
            click("bitPanelButton")
            compare(item("bitPanelButton").checked, true)
            compare(item("bit_0").visible, true)
        }

        function test_every_bit_toggles_and_integer_complements_truncate() {
            click("bitPanelButton")
            for (let bit = 63; bit >= 0; --bit) click("bit_" + bit)
            compare(result(), "-1")
            compare(item("radixValue_16").text.replace(/ /g, ""), "FFFFFFFFFFFFFFFF")
            for (let bit = 0; bit < 64; ++bit) {
                compare(item("bit_" + bit).checked, true)
                click("bit_" + bit)
            }
            compare(result(), "0")
            click("fullKeypadButton")
            for (const setting of [
                { key: Qt.Key_F2, hex: "FFFFFFFFFFFFFFFF" }, { key: Qt.Key_F3, hex: "FFFFFFFF" },
                { key: Qt.Key_F4, hex: "FFFF" }, { key: Qt.Key_F12, hex: "FF" }
            ]) {
                keyClick(Qt.Key_Escape)
                keyClick(setting.key)
                keyClick("~")
                compare(result(), "-1")
                compare(item("radixValue_16").text.replace(/ /g, ""), setting.hex)
                keyClick("~")
                compare(result(), "0")
            }
            keyClick(Qt.Key_F2)
            keyClick(Qt.Key_F5)
            for (const digit of "FFFFFFFFFFFFFFFF") keyClick(digit)
            keyClick("^")
            for (const digit of "8000000000000000") keyClick(digit)
            keyClick(Qt.Key_Return)
            compare(result(), "7FFFFFFFFFFFFFFF")
            keyClick(Qt.Key_Escape)
            keyClick(Qt.Key_F6)
            for (const key of ["2", "5", "&", "7", "|", "8", "^", "3"]) keyClick(key)
            keyClick(Qt.Key_Return)
            compare(result(), "10")
        }

        function verifyFits(control) {
            const position = control.mapToItem(application.contentItem, 0, 0)
            verify(position.x >= 0 && position.x + control.width <= application.width + 1, control.objectName + " fits horizontally")
            verify(position.y >= 0 && position.y + control.height <= application.height + 1, control.objectName + " fits vertically")
        }
        function test_bit_panel_and_operation_menus_fit_and_keyboard_focus_scrolls_data() {
            return [
                { tag: "narrow", width: 320, height: 460 },
                { tag: "default", width: 360, height: 560 },
                { tag: "wide", width: 900, height: 700 }
            ]
        }
        function test_bit_panel_and_operation_menus_fit_and_keyboard_focus_scrolls(data) {
            application.width = data.width
            application.height = data.height
            click("bitPanelButton")
            item("bit_63").forceActiveFocus(Qt.TabFocusReason)
            waitForRendering(application.contentItem, 100)
            verifyFits(item("bit_63"))
            for (let bit = 62; bit >= 0; --bit) {
                keyClick(Qt.Key_Tab)
                verify(item("bit_" + bit).activeFocus, "Tab follows descending displayed bits")
                verifyFits(item("bit_" + bit))
            }
            keyClick(Qt.Key_Space)
            compare(result(), "1")
            const scheme = Application.styleHints.colorScheme === Qt.Dark ? "dark" : "light"
            grabImage(application.contentItem).save("programmer-bits-" + scheme + "-" + data.tag + ".png")
            click("fullKeypadButton")
            for (const name of ["key_shift_left", "key_shift_right", "key_clearEntry", "key_backspace"]) {
                item(name).forceActiveFocus(Qt.TabFocusReason)
                waitForRendering(application.contentItem, 100)
                verifyFits(item(name))
                verify(item(name).width >= 44 && item(name).height >= 44)
            }
            click("bitShiftButton")
            tryCompare(item("bitShiftPopup"), "opened", true)
            for (const mode of ["arithmetic", "logical", "circular", "carry"]) verifyFits(item("shiftMode_" + mode))
            grabImage(application.contentItem).save("programmer-shift-menu-" + scheme + "-" + data.tag + ".png")
            click("shiftMode_logical")
            tryCompare(item("bitShiftPopup"), "visible", false)
            compare(item("key_shift_right").Accessible.name, Qt.locale().name.indexOf("zh") === 0 ? "逻辑右移" : "Logical right shift")
            click("bitwiseButton")
            tryCompare(item("bitwisePopup"), "opened", true)
            for (const command of ["and", "or", "not", "nand", "nor", "xor"]) verifyFits(item("key_" + command))
            grabImage(application.contentItem).save("programmer-bitwise-menu-" + scheme + "-" + data.tag + ".png")
            keyClick(Qt.Key_Escape)
            tryCompare(item("bitwisePopup"), "visible", false)
            compare(result(), "1", "Dismissing a menu does not clear the calculation")
        }

        function test_reference_keyboard_remains_active_in_bit_view_and_updates_bits() {
            selectByte()
            click("bitPanelButton")
            click("bit_0")
            for (const key of ["2", "+", "3"]) keyClick(key)
            keyClick(Qt.Key_Return)
            compare(result(), "5")
            compare(item("bit_0").checked, true)
            compare(item("bit_1").checked, false)
            compare(item("bit_2").checked, true)
            keyClick("~")
            compare(result(), "-6")
            compare(item("bit_7").checked, true)
            compare(item("bit_0").checked, false)
            keyClick(Qt.Key_Escape)
            compare(result(), "0")
            for (const key of ["6", ".", "3"]) keyClick(key)
            keyClick(Qt.Key_Return)
            compare(result(), "-3")
            keyClick(Qt.Key_Escape)
            keyClick("8")
            keyClick("+")
            keyClick("9")
            keyClick(Qt.Key_Delete)
            keyClick("2")
            keyClick(Qt.Key_Return)
            compare(result(), "10")
            keyClick(Qt.Key_Escape)
            keyClick(Qt.Key_F8)
            keyClick("1")
            keyClick("9")
            compare(result(), "1", "Radix restrictions still apply in bit view")
            keyClick(Qt.Key_Backspace)
            compare(result(), "0")
            compare(item("bit_0").checked, false)
        }

        function test_reference_clear_slot_tracks_core_entry_and_preserves_pending_operand() {
            compare(item("key_clear").visible, true)
            verify(!findChild(application.contentItem, "key_clearEntry"))
            keyClick("2")
            keyClick("5")
            compare(item("key_clearEntry").visible, true)
            verify(!findChild(application.contentItem, "key_clear"))
            keyClick("+")
            keyClick("9")
            click("key_clearEntry")
            compare(item("key_clear").visible, true)
            keyClick("7")
            keyClick(Qt.Key_Return)
            compare(result(), "32")
            compare(item("key_clearEntry").visible, true)
            keyClick(Qt.Key_Escape)
            compare(result(), "0")
            compare(item("expressionDisplay").text, "")
            keyClick("0")
            compare(item("key_clear").visible, true)
            keyClick("8")
            keyClick("+")
            keyClick("9")
            keyClick(Qt.Key_Delete)
            keyClick("2")
            keyClick(Qt.Key_Return)
            compare(result(), "10")
        }

        function test_bitwise_and_from_reference_flyout() {
            keyClick("2")
            keyClick("5")
            click("bitwiseButton")
            tryCompare(item("bitwisePopup"), "opened", true)
            click("key_and")
            tryCompare(item("bitwisePopup"), "visible", false)
            keyClick("7")
            keyClick(Qt.Key_Return)
            compare(result(), "1")
            compare(item("radixValue_16").text, "1")
            compare(item("radixValue_2").text, "1")
        }
    }
}
