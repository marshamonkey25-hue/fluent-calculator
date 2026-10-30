import QtQuick
import QtTest
import Calculator

Item {
    MainWindow { id: application; systemPreferences: testSystemPreferences }
    TextEdit { id: clipboardProvider; parent: application.contentItem; visible: false }
    TestCase {
        name: "ArithmeticPaste"
        when: windowShown && application.visible
        function control(name) {
            const item = findChild(application.contentItem, name)
            verify(item !== null, "Arithmetic control: " + name)
            return item
        }
        function navigate(name) {
            mouseClick(control("navigationButton"))
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            const entry = findChild(drawer.contentItem, name)
            entry.forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_Space)
            tryCompare(drawer, "visible", false)
        }
        function initTestCase() {
            application.requestActivate()
            tryCompare(application, "active", true)
        }
        function init() {
            navigate("mode_standard")
            keyClick(Qt.Key_Escape)
        }
        function setClipboard(text) {
            clipboardProvider.text = text
            clipboardProvider.selectAll()
            clipboardProvider.copy()
            control("key_0").forceActiveFocus(Qt.TabFocusReason)
        }
        function paste(text) {
            setClipboard(text)
            keySequence(StandardKey.Paste)
        }
        function test_paste_shortcut_and_result_menu_data() {
            return [{tag: "standard", mode: "standard"}, {tag: "scientific", mode: "scientific"},
                    {tag: "programmer", mode: "programmer"}]
        }
        function test_paste_shortcut_and_result_menu(data) {
            navigate("mode_" + data.mode)
            paste("42")
            compare(control("resultDisplay").text, "42")
            setClipboard("73")
            const display = control("resultDisplay")
            mouseClick(display, display.width / 2, display.height / 2, Qt.RightButton)
            const menu = findChild(display, "resultContextMenu")
            tryCompare(menu, "opened", true)
            const item = findChild(menu.contentItem, "pasteResultItem")
            verify(item !== null, "Reference result menu offers Paste")
            verify(item.y > findChild(menu.contentItem, "copyResultItem").y, "Pinned menu places Copy before Paste")
            compare(item.text, Qt.locale().name.indexOf("zh") === 0 ? "粘贴" : "Paste")
            mouseClick(item)
            compare(display.text, "73")
        }
        function test_paste_precision_expressions_exponents_and_pending_operations_data() {
            return [
                {tag: "standard-exact", mode: "standard", text: "9,007,199,254,740,993", expected: "9,007,199,254,740,993", next: "-9007199254740992=", continued: "1"},
                {tag: "standard-signed-fraction", mode: "standard", text: "-0.99", expected: "-0.99"},
                {tag: "standard-order", mode: "standard", text: "2+3*4=", expected: "20"},
                {tag: "standard-pending", mode: "standard", pending: "6*", text: "7", expected: "7", next: "=", continued: "42"},
                {tag: "scientific-exact", mode: "scientific", text: "12345678901234567890123456789012", expected: "12,345,678,901,234,567,890,123,456,789,012"},
                {tag: "scientific-order", mode: "scientific", text: "2+3*4=", expected: "14"},
                {tag: "scientific-signed-parentheses", mode: "scientific", text: "-(2+3)*4=", expected: "-20"},
                {tag: "scientific-negative-operand", mode: "scientific", text: "2*-3=", expected: "-6"},
                {tag: "scientific-positive-exponent", mode: "scientific", text: "1.23e+10", expected: "1.23e+10"},
                {tag: "scientific-negative-exponent", mode: "scientific", text: "1.23E-10", expected: "1.23e-10"},
                {tag: "scientific-power", mode: "scientific", text: "2^8=", expected: "256"},
                {tag: "scientific-mod", mode: "scientific", text: "17%5=", expected: "2"},
                {tag: "localized-digits", mode: "standard", text: "٤٢", expected: "42"}
            ]
        }
        function test_paste_precision_expressions_exponents_and_pending_operations(data) {
            navigate("mode_" + data.mode)
            if (data.pending) for (const key of data.pending) keyClick(key)
            paste(data.text)
            compare(control("resultDisplay").text, data.expected)
            if (data.next) {
                for (const key of data.next) keyClick(key)
                compare(control("resultDisplay").text, data.continued)
            }
        }
        function test_invalid_paste_reports_error_and_recovers_data() {
            return [
                {tag: "malformed", mode: "standard", text: "12oops"},
                {tag: "standard-limit", mode: "standard", text: "12345678901234567"},
                {tag: "scientific-limit", mode: "scientific", text: "123456789012345678901234567890123"},
                {tag: "exponent-limit", mode: "scientific", text: "1e12345"},
                {tag: "whole-paste-limit", mode: "scientific", text: "1".repeat(513)},
                {tag: "operand-count-limit", mode: "standard", text: "1+".repeat(100) + "1="},
                {tag: "binary-digit", mode: "programmer", radix: 2, text: "102"},
                {tag: "byte-hex-overflow", mode: "programmer", radix: 16, width: 8, text: "100"},
                {tag: "signed-byte-overflow", mode: "programmer", radix: 10, width: 8, text: "128"},
                {tag: "signed-byte-underflow", mode: "programmer", radix: 10, width: 8, text: "-129"},
                {tag: "hex-byte-leading-zeroes", mode: "programmer", radix: 16, width: 8, text: "001"}
            ]
        }
        function test_invalid_paste_reports_error_and_recovers(data) {
            navigate("mode_" + data.mode)
            if (data.width) {
                const label = ({64: "QWORD", 32: "DWORD", 16: "WORD", 8: "BYTE"})[data.width]
                for (let attempt = 0; control("wordWidthButton").text !== label && attempt < 4; ++attempt)
                    mouseClick(control("wordWidthButton"))
                compare(control("wordWidthButton").text, label)
            }
            if (data.radix) mouseClick(control("radix_" + data.radix))
            paste(data.text)
            verify(control("errorIndicator").visible, "Rejected paste reports the reference Invalid input error")
            keyClick(Qt.Key_Escape)
            paste("10")
            compare(control("resultDisplay").text.replace(/ /g, ""), "10")
            verify(!control("errorIndicator").visible)
        }
        function test_programmer_paste_respects_radix_and_width_data() {
            return [
                {tag: "hex-qword", radix: 16, text: "FFFFFFFFFFFFFFFF", expected: "FFFF FFFF FFFF FFFF", decimal: "-1"},
                {tag: "hex-prefix-suffix", radix: 16, text: "0xFFuLL", expected: "FF", decimal: "255"},
                {tag: "hex-separators", radix: 16, text: "AB_CD'EF", expected: "AB CDEF", decimal: "11,259,375"},
                {tag: "binary", radix: 2, text: "0b101010", expected: "10 1010", decimal: "42"},
                {tag: "octal", radix: 8, text: "0o52", expected: "52", decimal: "42"},
                {tag: "decimal-exact", radix: 10, text: "9007199254740993", expected: "9,007,199,254,740,993", decimal: "9,007,199,254,740,993"},
                {tag: "decimal-minimum", radix: 10, text: "-9223372036854775808", expected: "-9,223,372,036,854,775,808", decimal: "-9,223,372,036,854,775,808"},
                {tag: "hex-byte-sign", radix: 16, width: 8, text: "FF", expected: "FF", decimal: "-1"},
                {tag: "decimal-byte-minimum", radix: 10, width: 8, text: "-128", expected: "-128", decimal: "-128"}
            ]
        }
        function test_programmer_paste_respects_radix_and_width(data) {
            navigate("mode_programmer")
            if (data.width) {
                const label = ({64: "QWORD", 32: "DWORD", 16: "WORD", 8: "BYTE"})[data.width]
                for (let attempt = 0; control("wordWidthButton").text !== label && attempt < 4; ++attempt)
                    mouseClick(control("wordWidthButton"))
                compare(control("wordWidthButton").text, label)
            }
            mouseClick(control("radix_" + data.radix))
            paste(data.text)
            compare(control("resultDisplay").text, data.expected)
            mouseClick(control("radix_10"))
            compare(control("resultDisplay").text, data.decimal)
        }
        function test_paste_is_blocked_by_modal_panels_and_restores_input_focus() {
            paste("42")
            setClipboard("73")
            mouseClick(control("navigationButton"))
            const navigation = findChild(application, "navigationDrawer")
            tryCompare(navigation, "opened", true)
            keySequence(StandardKey.Paste)
            compare(control("resultDisplay").text, "42")
            navigation.close()
            tryCompare(navigation, "visible", false)
            keyClick(Qt.Key_H, Qt.ControlModifier)
            const history = findChild(application, "historyDrawer")
            tryCompare(history, "opened", true)
            keySequence(StandardKey.Paste)
            compare(control("resultDisplay").text, "42")
            keyClick(Qt.Key_H, Qt.ControlModifier)
            tryCompare(history, "visible", false)
            verify(application.currentPage.activeFocus)
            keySequence(StandardKey.Paste)
            compare(control("resultDisplay").text, "73")
            navigate("settingsButton")
            keySequence(StandardKey.Paste)
            navigate("mode_standard")
            compare(control("resultDisplay").text, "73", "Hidden arithmetic shortcuts stay inactive in settings")
        }
        function test_valid_paste_recovers_directly_from_error_data() {
            return [{tag: "standard", mode: "standard"}, {tag: "scientific", mode: "scientific"},
                    {tag: "programmer", mode: "programmer"}]
        }
        function test_valid_paste_recovers_directly_from_error(data) {
            navigate("mode_" + data.mode)
            paste("invalid")
            verify(control("errorIndicator").visible)
            paste("42")
            compare(control("resultDisplay").text, "42")
            verify(!control("errorIndicator").visible)
        }
        function cleanupTestCase() { application.close() }
    }
}
