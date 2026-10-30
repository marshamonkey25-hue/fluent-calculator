import QtQuick
import QtTest
import Calculator

Item {
    MainWindow { id: application; systemPreferences: testSystemPreferences }
    TextEdit {
        id: clipboardProvider
        parent: application.contentItem
        width: 200; height: 30; visible: false
    }
    TestCase {
        name: "TemperaturePowerAngleConversion"
        when: windowShown && application.visible

        function initTestCase() {
            application.requestActivate()
            tryCompare(application, "active", true)
        }
        function control(name) {
            const item = findChild(application.contentItem, name)
            verify(item !== null, "Visible control: " + name)
            return item
        }
        function navigate(name) {
            mouseClick(control("navigationButton"))
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            const entry = findChild(drawer.contentItem, name)
            verify(entry !== null, "Navigation entry: " + name)
            mouseClick(entry)
            tryCompare(drawer, "visible", false)
        }
        function selectUnit(name, id) {
            const combo = control(name)
            const index = combo.indexOfValue(id)
            verify(index >= 0, "Reference unit is available: " + id)
            combo.forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_Home)
            for (let row = 0; row < index; ++row) keyClick(Qt.Key_Down)
            compare(combo.currentValue, id)
        }
        function test_000_reference_defaults() {
            const chinese = Qt.locale().name.indexOf("zh") === 0
            navigate("mode_temperature")
            compare(control("converterUnit1").currentValue, chinese ? 47 : 46)
            compare(control("converterUnit2").currentValue, chinese ? 46 : 47)
            navigate("mode_power")
            compare(control("converterUnit1").currentValue, 44)
            compare(control("converterUnit2").currentValue, 43)
            navigate("mode_angle")
            compare(control("converterUnit1").currentValue, 134)
            compare(control("converterUnit2").currentValue, 135)
        }
        function test_temperature_freezing_point_uses_offset() {
            navigate("mode_temperature")
            selectUnit("converterUnit1", 46)
            selectUnit("converterUnit2", 47)
            mouseClick(control("converterKey_clear"))
            compare(control("converterValue1").text, "0")
            compare(control("converterValue2").text, "32", "Zero Celsius is 32 Fahrenheit")
        }
        function enter(text, keyboard) {
            for (const character of text) {
                if (keyboard) keyClick(character)
                else mouseClick(control("converterKey_" + (character === "." ? "decimal" : character)))
            }
        }
        function test_negative_temperature_and_offset_pairs_data() {
            return [
                {tag: "mouse-negative-C-to-F", from: 46, to: 47, input: "40", negative: true, expected: -40},
                {tag: "keyboard-negative-C-to-K", from: 46, to: 48, input: "273.15", negative: true, expected: 0, keyboard: true},
                {tag: "keyboard-negative-F-to-C", from: 47, to: 46, input: "40", negative: true, expected: -40, keyboard: true},
                {tag: "mouse-negative-F-to-K", from: 47, to: 48, input: "459.67", negative: true, expected: 0},
                {tag: "C-to-C", from: 46, to: 46, input: "25", negative: true, expected: -25},
                {tag: "F-to-F", from: 47, to: 47, input: "40", negative: true, expected: -40},
                {tag: "K-to-K", from: 48, to: 48, input: "1", negative: true, expected: -1},
                {tag: "K-to-C", from: 48, to: 46, input: "0", expected: -273.15},
                {tag: "K-to-F", from: 48, to: 47, input: "0", expected: -459.67},
                {tag: "boiling-C-to-F", from: 46, to: 47, input: "100", expected: 212},
                {tag: "boiling-F-to-K", from: 47, to: 48, input: "212", expected: 373.15}
            ]
        }
        function test_negative_temperature_and_offset_pairs(data) {
            navigate("mode_temperature")
            mouseClick(control("converterValue1"))
            selectUnit("converterUnit1", data.from)
            selectUnit("converterUnit2", data.to)
            mouseClick(control("converterKey_clear"))
            enter(data.input, data.keyboard)
            const negate = control("converterKey_negate")
            verify(negate.visible && negate.enabled)
            if (data.negative) {
                if (data.keyboard) keyClick("-")
                else mouseClick(negate)
                verify(control("converterValue1").text.startsWith("-"))
            }
            compare(control("converterUnit1").count, 3)
            const actual = Number(control("converterValue2").text.replace(/,/g, ""))
            verify(Math.abs(actual - data.expected) <= Math.max(1e-9, Math.abs(data.expected) * 5e-7),
                   "Known temperature within converter display tolerance: " + actual)
        }
        function test_negative_power_reference_units_data() {
            return [
                {tag: "watts", id: 45, expected: -1},
                {tag: "kilowatts", id: 44, expected: -1000, keyboard: true},
                {tag: "horsepower-US", id: 43, expected: -745.69987158227022},
                {tag: "foot-pounds-per-minute", id: 42, expected: -0.0225969658055233, keyboard: true},
                {tag: "BTUs-per-minute", id: 41, expected: -17.58426666666667}
            ]
        }
        function test_negative_power_reference_units(data) {
            navigate("mode_power")
            selectUnit("converterUnit1", data.id)
            selectUnit("converterUnit2", 45)
            mouseClick(control("converterValue1"))
            mouseClick(control("converterKey_clear"))
            enter("1", data.keyboard)
            if (data.keyboard) keyClick(Qt.Key_F9)
            else mouseClick(control("converterKey_negate"))
            compare(control("converterUnit1").count, 5, "Complete reference power set")
            const actual = Number(control("converterValue2").text.replace(/,/g, ""))
            verify(Math.abs(actual - data.expected) <= Math.max(5e-8, Math.abs(data.expected) * 5e-7),
                   "Known watt equivalent within display precision: " + actual)
        }
        function test_negative_angle_reference_units_data() {
            return [
                {tag: "degrees-to-radians", from: 134, to: 135, input: "180", expected: -3.141592653589793},
                {tag: "gradians-to-degrees", from: 136, to: 134, input: "200", expected: -180, keyboard: true},
                {tag: "radians-to-gradians", from: 135, to: 136, input: "1", expected: -63.66197723675813},
                {tag: "identity", from: 135, to: 135, input: "12.5", expected: -12.5, keyboard: true}
            ]
        }
        function test_negative_angle_reference_units(data) {
            navigate("mode_angle")
            selectUnit("converterUnit1", data.from)
            selectUnit("converterUnit2", data.to)
            mouseClick(control("converterValue1"))
            mouseClick(control("converterKey_clear"))
            enter(data.input, data.keyboard)
            if (data.keyboard) keyClick("-")
            else mouseClick(control("converterKey_negate"))
            compare(control("converterUnit1").count, 3, "Complete reference angle set")
            const actual = Number(control("converterValue2").text.replace(/,/g, ""))
            verify(Math.abs(actual - data.expected) <= Math.max(5e-8, Math.abs(data.expected) * 5e-7),
                   "Known angle equivalent within display precision: " + actual)
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
        function test_signed_paste_keeps_validation_and_recovery_data() {
            return [{tag: "temperature", mode: "temperature", unit: 46},
                    {tag: "power", mode: "power", unit: 45},
                    {tag: "angle", mode: "angle", unit: 134}]
        }
        function test_signed_paste_keeps_validation_and_recovery(data) {
            navigate("mode_" + data.mode)
            selectUnit("converterUnit1", data.unit)
            selectUnit("converterUnit2", data.unit)
            paste("-12.50")
            compare(control("converterValue1").text, "-12.50")
            compare(control("converterValue2").text, "-12.5")
            verify(!control("converterStatus").visible)
            for (const invalid of ["--12", "-1..2", "-NaN", "-Infinity", "-1e3"]) {
                paste(invalid)
                verify(control("converterStatus").visible, "Malformed signed input is rejected")
                enter("2", true)
                compare(control("converterValue1").text, "2", "Valid input clears the error")
                verify(!control("converterStatus").visible)
            }
            paste("-1234567890123456")
            compare(control("converterStatus").text, Qt.locale().name.indexOf("zh") === 0 ? "最多输入 15 位数字" : "Maximum 15 digits")
            compare(control("converterValue1").text, "2", "Too many digits do not replace the current value")
            paste("-" + "9".repeat(309))
            compare(control("converterStatus").text, Qt.locale().name.indexOf("zh") === 0 ? "无法显示结果" : "Result cannot be displayed")
            paste("-000.50")
            compare(control("converterValue1").text, "-0.50", "Leading zero normalization preserves the sign")
            compare(control("converterValue2").text, "-0.5")
            verify(!control("converterStatus").visible)
        }
        function contrastRatio(a, b) {
            function channel(c) { return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4) }
            function luminance(c) { return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b) }
            const x = luminance(a), y = luminance(b)
            return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05)
        }
        function test_translation_theme_and_layout_data() {
            return [
                {tag: "temperature", mode: "temperature", title: "Temperature", chineseTitle: "温度", from: 46, to: 47,
                 english: ["Celsius", "Fahrenheit", "Kelvin"], chinese: ["摄氏度", "华氏度", "开尔文"], result: "9.5"},
                {tag: "power", mode: "power", title: "Power", chineseTitle: "功率", from: 45, to: 44,
                 english: ["Watts", "Kilowatts", "Horsepower (US)", "Foot-pounds/minute", "BTUs/minute"],
                 chinese: ["瓦特", "千瓦", "马力(美制)", "英尺磅/分钟", "BTU/分钟"], result: "-0.0125"},
                {tag: "angle", mode: "angle", title: "Angle", chineseTitle: "角度", from: 134, to: 136,
                 english: ["Degrees", "Radians", "Gradians"], chinese: ["度", "弧度", "百分度"], result: "-13.88889"}
            ]
        }
        function test_translation_theme_and_layout(data) {
            navigate("mode_" + data.mode)
            selectUnit("converterUnit1", data.from)
            selectUnit("converterUnit2", data.to)
            mouseClick(control("converterValue1"))
            mouseClick(control("converterKey_clear"))
            enter("12.5", false)
            mouseClick(control("converterKey_negate"))
            for (const language of ["zh-CN", "en-US"]) {
                navigate("settingsButton")
                mouseClick(control("language_" + language))
                mouseClick(control(language === "zh-CN" ? "theme_dark" : "theme_light"))
                navigate("mode_" + data.mode)
                const chinese = language === "zh-CN"
                compare(control("pageTitle").text, chinese ? data.chineseTitle : data.title)
                const units = control("converterUnit1")
                const expected = chinese ? data.chinese : data.english
                compare(units.count, expected.length)
                for (let row = 0; row < expected.length; ++row) compare(units.textAt(row), expected[row])
                compare(control("converterKey_negate").Accessible.name, chinese ? "正负" : "Positive negative")
                compare(control("converterValue1").text, "-12.5")
                compare(control("converterValue2").text, data.result)
                verify(chinese ? application.color.r < 0.25 : application.color.r > 0.75)
                verify(contrastRatio(control("converterValue1").palette.buttonText, application.color) >= 4.5)
                verify(contrastRatio(control("converterKey_negate").palette.buttonText, control("converterKey_negate").palette.button) >= 4.5)
                for (const size of [{width: 320, height: 560}, {width: 900, height: 600}]) {
                    application.width = size.width
                    application.height = size.height
                    tryCompare(application.contentItem, "width", size.width)
                    verify(waitForPolish(application.currentPage))
                    for (const name of ["converterValue1", "converterUnit1", "converterValue2", "converterUnit2",
                                        "converterKey_clear", "converterKey_backspace", "converterKey_negate",
                                        "converterKey_0", "converterKey_decimal"]) {
                        const item = control(name)
                        item.forceActiveFocus(Qt.TabFocusReason)
                        verify(item.visualFocus, "Visible keyboard focus for " + name)
                        const position = item.mapToItem(application.contentItem, 0, 0)
                        verify(item.visible && item.enabled && item.width >= 44 && item.height >= 32)
                        verify(position.x >= 0 && position.x + item.width <= application.width + 1, name + " fits width: " + position.x + " + " + item.width + " <= " + application.width)
                        verify(position.y >= 40 && position.y + item.height <= application.height + 1, name + " fits height")
                        verify(item.Accessible.name.length > 0)
                    }
                    waitForRendering(application.contentItem)
                    grabImage(application.contentItem).save(data.mode + "-" + language + "-" + size.width + ".png")
                }
            }
            application.width = 360
            application.height = 560
            navigate("settingsButton")
            mouseClick(control("language_system"))
            mouseClick(control("theme_system"))
        }
        function test_signed_limits_backspace_and_clear_data() {
            const rows = []
            for (const mode of ["temperature", "power", "angle"])
                for (const keyboard of [false, true])
                    rows.push({tag: mode + (keyboard ? "-keyboard" : "-mouse"), mode: mode,
                               unit: mode === "temperature" ? 46 : mode === "power" ? 45 : 134, keyboard: keyboard})
            return rows
        }
        function test_signed_limits_backspace_and_clear(data) {
            navigate("mode_" + data.mode)
            selectUnit("converterUnit1", data.unit)
            selectUnit("converterUnit2", data.unit)
            mouseClick(control("converterValue1"))
            mouseClick(control("converterKey_clear"))
            enter("123456789012345", data.keyboard)
            if (data.keyboard) keyClick(Qt.Key_F9)
            else mouseClick(control("converterKey_negate"))
            compare(control("converterValue1").text, "-123,456,789,012,345")
            enter("6", data.keyboard)
            compare(control("converterValue1").text, "-123,456,789,012,345", "Negation cannot bypass the digit cap")
            verify(control("converterStatus").visible)
            if (data.keyboard) keyClick(Qt.Key_Escape)
            else mouseClick(control("converterKey_clear"))
            enter("12345678901234", data.keyboard)
            if (data.keyboard) keyClick("-")
            else mouseClick(control("converterKey_negate"))
            enter("5", data.keyboard)
            // Pinned SendCommand counts the minus in its 15-character input
            // budget; toggling sign after entering 15 digits is also supported.
            compare(control("converterValue1").text, "-12,345,678,901,234")
            verify(control("converterStatus").visible)
            if (data.keyboard) keyClick(Qt.Key_Backspace)
            else mouseClick(control("converterKey_backspace"))
            compare(control("converterValue1").text, "-1,234,567,890,123")
            verify(!control("converterStatus").visible)
            enter("4", data.keyboard)
            compare(control("converterValue1").text, "-12,345,678,901,234")
            if (data.keyboard) keyClick(Qt.Key_Escape)
            else mouseClick(control("converterKey_clear"))
            compare(control("converterValue1").text, "0")
            compare(control("converterValue2").text, "0")
            paste("-123456789012345")
            compare(control("converterValue1").text, "-123,456,789,012,345")
            compare(control("converterValue2").text, "-123,456,789,012,345")
            verify(!control("converterStatus").visible)
        }
        function test_signed_values_round_trip_and_edit_from_either_side_data() {
            return [
                {tag: "temperature", mode: "temperature", from: 46, to: 47, input: "10", first: "-10", second: "14"},
                {tag: "power", mode: "power", from: 44, to: 45, input: "1", first: "-1", second: "-1,000"},
                {tag: "angle", mode: "angle", from: 134, to: 136, input: "180", first: "-180", second: "-200"}
            ]
        }
        function test_signed_values_round_trip_and_edit_from_either_side(data) {
            navigate("mode_" + data.mode)
            selectUnit("converterUnit1", data.from)
            selectUnit("converterUnit2", data.to)
            mouseClick(control("converterValue1"))
            mouseClick(control("converterKey_clear"))
            enter(data.input, true)
            keyClick("-")
            compare(control("converterValue1").text, data.first)
            compare(control("converterValue2").text, data.second)
            control("converterValue2").forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_Space)
            verify(control("converterValue2").checked)
            selectUnit("converterUnit1", data.to)
            compare(control("converterValue1").text, data.second, "Identity preserves a selected signed result")
            selectUnit("converterUnit1", data.from)
            compare(control("converterValue1").text, data.first, "Reverse conversion returns to the original value")
            compare(control("converterValue2").text, data.second)
            keyClick(Qt.Key_F9)
            keyClick(Qt.Key_F9)
            compare(control("converterValue2").text, data.second, "Repeated negation is reversible on either side")
            mouseClick(control("converterKey_clear"))
            enter("1", false)
            mouseClick(control("converterKey_negate"))
            compare(control("converterValue2").text, "-1", "The second side accepts new signed input")
            selectUnit("converterUnit1", data.to)
            compare(control("converterValue1").text, "-1")
            keyClick("2")
            compare(control("converterValue2").text, "-12", "Editing updates identity conversion immediately")
            compare(control("converterValue1").text, "-12")
        }
        function test_converter_navigation_preserves_arithmetic_and_sign_rules() {
            navigate("mode_standard")
            for (const command of ["clear", "6", "multiply"]) mouseClick(control("key_" + command))
            for (const mode of ["temperature", "power", "angle"]) {
                navigate("mode_" + mode)
                enter("12", true)
                keyClick("-")
                verify(control("converterValue1").text.startsWith("-"))
                verify(!control("historyButton").visible)
                navigate("settingsButton")
                for (const key of ["9", "-", Qt.Key_F9]) keyClick(key)
                navigate("mode_" + mode)
                compare(control("converterValue1").text, "-12", "Settings shortcuts leave the converter unchanged")
            }
            navigate("mode_length")
            verify(!control("converterKey_negate").visible, "Length still disallows sign input")
            enter("12", true)
            keyClick("-")
            keyClick(Qt.Key_F9)
            compare(control("converterValue1").text, "12")
            paste("-1")
            verify(control("converterStatus").visible, "Length still rejects negative paste")
            navigate("mode_standard")
            mouseClick(control("key_7"))
            mouseClick(control("key_equals"))
            compare(control("resultDisplay").text, "42", "Converters leave the real arithmetic session intact")
        }
        function cleanup() { clipboardProvider.visible = false }
        function cleanupTestCase() { application.close() }
    }
}
