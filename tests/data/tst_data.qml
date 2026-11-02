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
        name: "DataConversion"
        when: windowShown && application.visible

        function initTestCase() {
            application.requestActivate()
            tryCompare(application, "active", true)
        }

        function init() {
            navigate("length")
            mouseClick(control("converterValue1"))
            mouseClick(control("converterKey_clear"))
        }

        function control(name) {
            const item = findChild(application.contentItem, name)
            verify(item !== null, "Visible control: " + name)
            return item
        }

        function navigate(key) {
            mouseClick(control("navigationButton"))
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            const item = findChild(drawer.contentItem, key === "settings" ? "settingsButton" : "mode_" + key)
            verify(item !== null, "Functional navigation entry: " + key)
            const list = findChild(drawer.contentItem, "navigationList")
            for (let attempt = 0; attempt < 15 && key !== "settings"; ++attempt) {
                const point = item.mapToItem(list, 0, 0)
                if (point.y >= 0 && point.y + item.height <= list.height) break
                mouseWheel(list, list.width / 2, list.height / 2, 0, point.y < 0 ? 120 : -120)
                tryCompare(list, "moving", false)
            }
            mouseClick(item)
            tryCompare(drawer, "visible", false)
        }

        function selectUnit(side, id) {
            const combo = control("converterUnit" + side)
            const index = combo.indexOfValue(id)
            verify(index >= 0, "Reference unit is available: " + id)
            combo.forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_Home)
            for (let row = 0; row < index; ++row) keyClick(Qt.Key_Down)
            compare(combo.currentValue, id)
        }

        function enter(text, keyboard) {
            for (const character of text) {
                if (keyboard) keyClick(character)
                else mouseClick(control("converterKey_" + (character === "." ? "decimal" : character)))
            }
        }

        function closeTo(side, expected, absoluteTolerance) {
            const text = control("converterValue" + side).text
            const actual = Number(text.replace(/,/g, ""))
            // Pinned output: seven significant digits in scientific form;
            // fixed sub-unit form may round to six decimal places.
            verify(Math.abs(actual - expected) <= Math.max(absoluteTolerance || 1e-45, Math.abs(expected) * 5e-7),
                   "Known value within display tolerance: " + text + " vs " + expected)
        }

        function test_000_complete_reference_catalog_and_defaults() {
            navigate("data")
            compare(control("converterUnit1").currentValue, 14, "Pinned source defaults to Gigabytes")
            compare(control("converterUnit2").currentValue, 18, "Pinned target defaults to Megabytes")
            const ids = [11, 167, 12, 15, 149, 16, 150, 17, 151, 18, 152, 13, 147, 14, 148,
                         21, 155, 22, 156, 19, 153, 20, 154, 143, 145, 144, 146, 163, 161, 164, 162, 159, 157, 160, 158]
            const english = ["Bits", "Nibble", "Bytes", "Kilobits", "Kibibits", "Kilobytes", "Kibibytes", "Megabits", "Mebibits", "Megabytes", "Mebibytes", "Gigabits", "Gibibits", "Gigabytes", "Gibibytes", "Terabits", "Tebibits", "Terabytes", "Tebibytes", "Petabits", "Pebibits", "Petabytes", "Pebibytes", "Exabits", "Exbibits", "Exabytes", "Exbibytes", "Zetabits", "Zebibits", "Zetabytes", "Zebibytes", "Yottabits", "Yobibits", "Yottabytes", "Yobibytes"]
            const chinese = ["位", "半字节", "B", "Kb", "Kib", "KB", "KiB", "Mb", "Mib", "MB", "MiB", "Gb", "Gib", "GB", "GiB", "Tb", "Tib", "TB", "TiB", "Pb", "Pib", "PB", "PiB", "Eb", "Eib", "EB", "EiB", "Zb", "Zib", "ZB", "ZiB", "Yottabits", "Yib", "Yottabytes", "YiB"]
            const names = Qt.locale().name.indexOf("zh") === 0 ? chinese : english
            compare(control("pageTitle").text, Qt.locale().name.indexOf("zh") === 0 ? "数据" : "Data")
            for (let side = 1; side <= 2; ++side) {
                const combo = control("converterUnit" + side)
                compare(combo.count, 35, "Complete pinned selectable catalog")
                for (let row = 0; row < ids.length; ++row) {
                    compare(combo.valueAt(row), ids[row], "Pinned unit order")
                    compare(combo.textAt(row), names[row], "Pinned localized unit label")
                }
            }
        }

        function test_byte_to_bits_through_keypad() {
            navigate("data")
            selectUnit(1, 12)
            selectUnit(2, 11)
            mouseClick(control("converterKey_clear"))
            enter("1", false)
            closeTo(2, 8)
        }

        function paste(text) {
            clipboardProvider.text = text
            clipboardProvider.visible = true
            clipboardProvider.forceActiveFocus()
            keyClick(Qt.Key_A, Qt.ControlModifier)
            keyClick(Qt.Key_C, Qt.ControlModifier)
            clipboardProvider.visible = false
            control("converterValue1").forceActiveFocus()
            keyClick(Qt.Key_V, Qt.ControlModifier)
        }

        function test_negative_data_is_rejected_with_translated_feedback() {
            navigate("data")
            mouseClick(control("converterValue1"))
            selectUnit(1, 12)
            selectUnit(2, 11)
            mouseClick(control("converterKey_clear"))
            enter("12.5", true)
            paste("-2")
            compare(control("converterValue1").text, "12.5", "Rejected paste preserves valid input")
            compare(control("converterStatus").text, Qt.locale().name.indexOf("zh") === 0
                    ? "数据不能为负值" : "Data cannot be negative")
            enter("3", true)
            compare(control("converterValue1").text, "3", "Typing recovers after invalid paste")
            closeTo(2, 24)
            verify(!control("converterStatus").visible)
            keyClick("-")
            keyClick(Qt.Key_F9)
            compare(control("converterValue1").text, "3", "Data does not accept a sign")
            verify(!control("converterKey_negate").visible)
        }

        function test_reference_definitions_and_display_boundaries_data() {
            // Independent literals: decimal prefixes are powers of 1000,
            // binary prefixes powers of 1024; a byte is eight bits.
            return [
                {tag: "bit", from: 11, to: 12, input: "1", expected: 0.125},
                {tag: "nibble", from: 167, to: 11, input: "1", expected: 4},
                {tag: "byte", from: 12, to: 11, input: "0.5", expected: 4},
                {tag: "kilobit", from: 15, to: 12, input: "1", expected: 125},
                {tag: "kibibit", from: 149, to: 12, input: "1", expected: 128},
                {tag: "kilobyte", from: 16, to: 12, input: "1", expected: 1000},
                {tag: "kibibyte", from: 150, to: 12, input: "1", expected: 1024},
                {tag: "megabit", from: 17, to: 12, input: "1", expected: 125000},
                {tag: "mebibit", from: 151, to: 12, input: "1", expected: 131072},
                {tag: "megabyte", from: 18, to: 12, input: "1", expected: 1000000},
                {tag: "mebibyte", from: 152, to: 12, input: "1", expected: 1048576},
                {tag: "gigabit", from: 13, to: 12, input: "1", expected: 125000000},
                {tag: "gibibit", from: 147, to: 12, input: "1", expected: 134217728},
                {tag: "gigabyte", from: 14, to: 12, input: "1", expected: 1000000000},
                {tag: "gibibyte", from: 148, to: 12, input: "1", expected: 1073741824},
                {tag: "terabit", from: 21, to: 12, input: "1", expected: 125000000000},
                {tag: "tebibit", from: 155, to: 12, input: "1", expected: 137438953472},
                {tag: "terabyte", from: 22, to: 12, input: "1", expected: 1000000000000},
                {tag: "tebibyte", from: 156, to: 12, input: "1", expected: 1099511627776},
                {tag: "petabit", from: 19, to: 12, input: "1", expected: 125000000000000},
                {tag: "pebibit", from: 153, to: 12, input: "1", expected: 140737488355328},
                {tag: "petabyte", from: 20, to: 12, input: "1", expected: 1e15, scientific: true},
                {tag: "pebibyte", from: 154, to: 12, input: "1", expected: 1125899906842624, scientific: true},
                {tag: "exabit", from: 143, to: 12, input: "1", expected: 1.25e17, scientific: true},
                {tag: "exbibit", from: 145, to: 12, input: "1", expected: 1.44115188075855872e17, scientific: true},
                {tag: "exabyte", from: 144, to: 12, input: "1", expected: 1e18, scientific: true},
                {tag: "exbibyte", from: 146, to: 12, input: "1", expected: 1.152921504606846976e18, scientific: true},
                {tag: "zettabit", from: 163, to: 12, input: "1", expected: 1.25e20, scientific: true},
                {tag: "zebibit", from: 161, to: 12, input: "1", expected: 1.47573952589676412928e20, scientific: true},
                {tag: "zettabyte", from: 164, to: 12, input: "1", expected: 1e21, scientific: true},
                {tag: "zebibyte", from: 162, to: 12, input: "1", expected: 1.180591620717411303424e21, scientific: true},
                {tag: "yottabit", from: 159, to: 12, input: "1", expected: 1.25e23, scientific: true},
                {tag: "yobibit", from: 157, to: 12, input: "1", expected: 1.51115727451828646838272e23, scientific: true},
                {tag: "yottabyte", from: 160, to: 12, input: "1", expected: 1e24, scientific: true},
                {tag: "yobibyte", from: 158, to: 12, input: "1", expected: 1.208925819614629174706176e24, scientific: true},
                {tag: "decimal-binary-boundary", from: 16, to: 150, input: "1.024", expected: 1},
                {tag: "binary-decimal-boundary", from: 148, to: 14, input: "1", expected: 1.073741824},
                {tag: "tiny-result", from: 11, to: 158, input: "0.00000000000001", expected: 1.0339757656912846e-39, scientific: true},
                {tag: "huge-result", from: 158, to: 11, input: "999999999999999", expected: 9.671406556917024e39, scientific: true},
                {tag: "fixed-rounded", from: 12, to: 150, input: "1", expected: 0.0009765625, tolerance: 5e-7},
                {tag: "small-fixed", from: 12, to: 18, input: "0.5", expected: 0.0000005}
            ]
        }

        function test_reference_definitions_and_display_boundaries(data) {
            navigate("data")
            selectUnit(1, data.from)
            selectUnit(2, data.to)
            mouseClick(control("converterKey_clear"))
            enter(data.input, true)
            closeTo(2, data.expected, data.tolerance)
            if (data.scientific)
                verify(/e[+-][0-9]+$/.test(control("converterValue2").text), "Extreme results use scientific notation")
            verify(!control("converterStatus").visible)
        }

        function test_same_unit_round_trip_and_decimal_entry_data() {
            return [{tag: "keyboard", keyboard: true}, {tag: "keypad", keyboard: false}]
        }
        function test_same_unit_round_trip_and_decimal_entry(data) {
            navigate("data")
            selectUnit(1, 150)
            selectUnit(2, 150)
            mouseClick(control("converterKey_clear"))
            enter("1.2500", data.keyboard)
            compare(control("converterValue1").text, "1.2500")
            closeTo(2, 1.25)
            selectUnit(2, 12)
            closeTo(2, 1280)
            mouseClick(control("converterValue2"))
            enter("1280", data.keyboard)
            closeTo(1, 1.25)
            selectUnit(2, 150)
            compare(control("converterValue2").text, "1,280")
            closeTo(1, 1280)
        }

        function test_input_budget_correction_and_invalid_paste_data() {
            return [{tag: "keyboard", keyboard: true}, {tag: "keypad", keyboard: false}]
        }
        function test_input_budget_correction_and_invalid_paste(data) {
            navigate("data")
            selectUnit(1, 12)
            selectUnit(2, 12)
            mouseClick(control("converterKey_clear"))
            enter("123456789012345", data.keyboard)
            compare(control("converterValue1").text, "123,456,789,012,345")
            compare(control("converterValue2").text, "123,456,789,012,345")
            enter("6", data.keyboard)
            compare(control("converterValue1").text, "123,456,789,012,345")
            compare(control("converterStatus").text, Qt.locale().name.indexOf("zh") === 0 ? "最多输入 15 位数字" : "Maximum 15 digits")
            if (data.keyboard) keyClick(Qt.Key_Backspace)
            else mouseClick(control("converterKey_backspace"))
            compare(control("converterValue1").text, "12,345,678,901,234")
            verify(!control("converterStatus").visible)
            enter(".5", data.keyboard)
            compare(control("converterValue1").text, "12,345,678,901,234.5")
            enter("6", data.keyboard)
            compare(control("converterValue1").text, "12,345,678,901,234.5")
            if (data.keyboard) keyClick(Qt.Key_Delete)
            else mouseClick(control("converterKey_clear"))
            enter("0.50.", data.keyboard)
            compare(control("converterValue1").text, "0.50")
            paste("1..2")
            compare(control("converterStatus").text, Qt.locale().name.indexOf("zh") === 0 ? "无效输入" : "Invalid input")
            enter("2", data.keyboard)
            compare(control("converterValue1").text, "2")
            paste("1234567890123456")
            compare(control("converterValue1").text, "2", "Overlong paste cannot partially replace input")
            keyClick(Qt.Key_Escape)
            compare(control("converterValue1").text, "0")
            compare(control("converterValue2").text, "0")
        }

        function test_unit_popup_reaches_last_binary_prefix() {
            application.width = 320
            application.height = 480
            navigate("data")
            selectUnit(1, 11)
            selectUnit(2, 12)
            const selector = control("converterUnit1")
            mouseClick(selector)
            tryCompare(selector.popup, "opened", true)
            keyClick(Qt.Key_End)
            keyClick(Qt.Key_Return)
            tryCompare(selector.popup, "visible", false)
            compare(selector.currentValue, 158, "Last binary prefix can be selected through the popup")
            mouseClick(control("converterKey_clear"))
            enter("1", false)
            closeTo(2, 1.208925819614629174706176e24)
            application.width = 360
            application.height = 560
        }

        function test_category_switches_preserve_input_active_side_and_unit_pairs() {
            navigate("data")
            selectUnit(1, 150)
            selectUnit(2, 12)
            mouseClick(control("converterKey_clear"))
            enter("1.25", true)
            navigate("length")
            verify(control("converterUnit1").indexOfValue(150) < 0)
            compare(control("converterValue1").text, "1.25")
            navigate("data")
            compare(control("converterUnit1").currentValue, 150)
            compare(control("converterUnit2").currentValue, 12)
            closeTo(2, 1280)
            mouseClick(control("converterValue2"))
            enter("512", true)
            closeTo(1, 0.5)
            navigate("pressure")
            verify(control("converterUnit2").indexOfValue(12) < 0)
            compare(control("converterValue2").text, "512")
            verify(control("converterValue2").checked)
            navigate("data")
            compare(control("converterUnit1").currentValue, 150)
            compare(control("converterUnit2").currentValue, 12)
            compare(control("converterValue2").text, "512")
            verify(control("converterValue2").checked)
            closeTo(1, 0.5)
            navigate("temperature")
            mouseClick(control("converterValue1"))
            mouseClick(control("converterKey_clear"))
            enter("2.5", true)
            keyClick("-")
            compare(control("converterValue1").text, "-2.5")
            navigate("data")
            compare(control("converterValue1").text, "2.5", "Pinned category change removes a forbidden negative sign")
            // The native converter remembers source/target relative to its
            // active field; changing that field in Temperature maps Bytes first.
            compare(control("converterUnit1").currentValue, 12)
            compare(control("converterUnit2").currentValue, 150)
            closeTo(2, 0.00244140625, 5e-7)
        }

        function contrastRatio(a, b) {
            function channel(c) { return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4) }
            function luminance(c) { return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b) }
            const x = luminance(a), y = luminance(b)
            return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05)
        }

        function test_wide_narrow_layout_and_keyboard_focus_data() {
            return [{tag: "narrow", width: 320, height: 480}, {tag: "wide", width: 900, height: 600}]
        }
        function test_wide_narrow_layout_and_keyboard_focus(data) {
            application.width = data.width
            application.height = data.height
            navigate("data")
            selectUnit(1, 158)
            selectUnit(2, 11)
            mouseClick(control("converterKey_clear"))
            enter("999999999999999", true)
            verify(waitForPolish(application))
            const names = ["converterValue1", "converterUnit1", "converterValue2", "converterUnit2",
                           "converterKey_clear", "converterKey_backspace", "converterKey_7", "converterKey_8",
                           "converterKey_9", "converterKey_4", "converterKey_5", "converterKey_6", "converterKey_1",
                           "converterKey_2", "converterKey_3", "converterKey_0", "converterKey_decimal"]
            control(names[0]).forceActiveFocus(Qt.TabFocusReason)
            for (let index = 0; index < names.length; ++index) {
                const item = control(names[index])
                if (index) keyClick(Qt.Key_Tab)
                tryCompare(item, "activeFocus", true)
                verify(item.visualFocus, "Visible keyboard focus: " + names[index])
                const position = item.mapToItem(application.contentItem, 0, 0)
                verify(item.visible && item.enabled && item.width >= 44 && item.height >= 32)
                verify(position.x >= 0 && position.x + item.width <= application.width + 1)
                verify(position.y >= 40 && position.y + item.height <= application.height + 1)
                verify(item.Accessible.name.length > 0)
            }
            const value = control("converterValue1")
            verify(contrastRatio(value.palette.buttonText, application.color) >= 4.5)
            if (data.width === 900)
                verify(value.width >= application.width * 0.45 && value.width <= application.width * 0.55,
                       "Pinned landscape keeps balanced display/keypad columns")
            waitForRendering(application.contentItem, 100)
            const theme = application.color.r < 0.5 ? "dark" : "light"
            const language = Qt.locale().name.indexOf("zh") === 0 ? "zh-CN" : "en-US"
            grabImage(application.contentItem).save("ticket17-" + data.tag + "-" + theme + "-" + language + ".png")
            application.width = 360
            application.height = 560
        }

        function test_runtime_language_theme_and_unit_selection() {
            navigate("data")
            selectUnit(1, 150)
            selectUnit(2, 11)
            mouseClick(control("converterKey_clear"))
            enter("1.25", true)
            for (const variant of [{language: "zh-CN", theme: "dark"}, {language: "en-US", theme: "light"}]) {
                navigate("settings")
                mouseClick(control("language_" + variant.language))
                mouseClick(control("theme_" + variant.theme))
                navigate("data")
                const chinese = variant.language === "zh-CN"
                compare(control("pageTitle").text, chinese ? "数据" : "Data")
                compare(control("converterUnit1").currentText, chinese ? "KiB" : "Kibibytes")
                compare(control("converterUnit2").currentText, chinese ? "位" : "Bits")
                compare(control("converterValue1").text, "1.25")
                closeTo(2, 10240)
                compare(control("converterKey_clear").Accessible.name, chinese ? "清除输入" : "Clear entry")
                verify(contrastRatio(control("converterValue1").palette.buttonText, application.color) >= 4.5)
                verify(variant.theme === "dark" ? application.color.r < 0.25 : application.color.r > 0.75)
            }
            navigate("settings")
            mouseClick(control("language_system"))
            mouseClick(control("theme_system"))
            navigate("data")
        }

        function cleanupTestCase() { application.close() }
    }
}
