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
        name: "VolumeAreaMassConversion"
        when: windowShown && application.visible

        function initTestCase() {
            application.requestActivate()
            tryCompare(application, "active", true)
        }

        function init() {
            navigate("mode_volume")
            mouseClick(control("converterValue1"))
            mouseClick(control("converterKey_clear"))
        }

        function control(name) {
            const item = findChild(application.contentItem, name)
            verify(item !== null, "Converter control: " + name)
            return item
        }

        function navigate(mode) {
            mouseClick(control("navigationButton"))
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            const entry = findChild(drawer.contentItem, mode)
            verify(entry !== null, "Navigation entry: " + mode)
            const list = findChild(drawer.contentItem, "navigationList")
            for (let attempt = 0; attempt < 12 && list && mode !== "settingsButton"; ++attempt) {
                const point = entry.mapToItem(list, 0, 0)
                if (point.y >= 0 && point.y + entry.height <= list.height) break
                mouseWheel(list, list.width / 2, list.height / 2, 0, point.y < 0 ? 120 : -120)
                tryCompare(list, "moving", false)
            }
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

        function enter(text, keyboard) {
            for (const character of text) {
                if (keyboard) keyClick(character)
                else mouseClick(control("converterKey_" + (character === "." ? "decimal" : character)))
            }
        }

        function test_volume_cubic_meters_to_liters() {
            navigate("mode_volume")
            compare(control("converterUnit1").count, 20)
            selectUnit("converterUnit1", 67)
            selectUnit("converterUnit2", 74)
            mouseClick(control("converterKey_clear"))
            enter("1", false)
            compare(control("converterValue2").text, "1,000")
        }

        function test_area_square_meters_to_square_centimeters() {
            navigate("mode_area")
            compare(control("converterUnit1").count, pyeongRegion ? 11 : 10)
            selectUnit("converterUnit1", 7)
            selectUnit("converterUnit2", 3)
            mouseClick(control("converterKey_clear"))
            enter("1", true)
            compare(control("converterValue2").text, "10,000")
        }

        function test_weight_pounds_to_kilograms() {
            navigate("mode_weight")
            compare(control("converterUnit1").count, 14)
            selectUnit("converterUnit1", 92)
            selectUnit("converterUnit2", 88)
            mouseClick(control("converterKey_clear"))
            enter("1", false)
            const actual = Number(control("converterValue2").text)
            verify(Math.abs(actual - 0.45359237) <= 0.0000005, "Pinned seven-digit display of 1 lb in kg: " + actual)
        }

        readonly property bool chinese: Qt.locale().name.indexOf("zh") === 0
        readonly property bool pyeongRegion: /^(ja_JP|zh_TW|ko_KR|ko_KP)$/.test(Qt.locale().name)

        function cases() {
            return [{tag: "volume", mode: "volume", from: 67, to: 74, result: "1,000", title: chinese ? "体积" : "Volume",
                     negative: chinese ? "体积不能为负值" : "Volume cannot be negative"},
                    {tag: "area", mode: "area", from: 7, to: 3, result: "10,000", title: chinese ? "面积" : "Area",
                     negative: chinese ? "面积不能为负值" : "Area cannot be negative"},
                    {tag: "weight", mode: "weight", from: 88, to: 86, result: "1,000", title: chinese ? "重量" : "Weight and Mass",
                     negative: chinese ? "重量和质量不能为负值" : "Weight and mass cannot be negative"}]
        }

        function test_000_reference_defaults_data() { return cases() }
        function test_000_reference_defaults(data) {
            navigate("mode_" + data.mode)
            const customary = Qt.locale().name === "en_US"
            const defaults = {volume: customary ? [75, 79] : [79, 75],
                              area: customary ? [7, 4] : [4, 7],
                              weight: customary ? [88, 92] : [92, 88]}
            compare(control("converterUnit1").currentValue, defaults[data.mode][0])
            compare(control("converterUnit2").currentValue, defaults[data.mode][1])
        }

        function test_reference_unit_catalog_and_ratios_data() {
            // Independent published equivalents in mL, m² and kg. The pinned
            // converter uses six decimal places below 1 (15 below 1e-6),
            // and seven preferred digits above 1. Tolerances account for that
            // fixed display resolution, rather than assuming Ratpack precision.
            const catalogs = [
                {mode: "volume", base: 75, count: 20, units: [
                    [75, 1, "Milliliters", "毫升"], [64, 1, "Cubic centimeters", "立方厘米"],
                    [74, 1000, "Liters", "升"], [67, 1000000, "Cubic meters", "立方米"],
                    [79, 4.92892159375, "Teaspoons (US)", "茶匙（美制）"],
                    [78, 14.78676478125, "Tablespoons (US)", "汤匙（美制）"],
                    [71, 29.5735295625, "Fluid ounces (US)", "液盎司（美制）"],
                    [69, 236.588237, "Cups (US)", "杯（美制）"], [77, 473.176473, "Pints (US)", "品脱（美制）"],
                    [81, 946.352946, "Quarts (US)", "夸脱（美制）"], [73, 3785.411784, "Gallons (US)", "加仑（美制）"],
                    [66, 16.387064, "Cubic inches", "立方英寸"], [65, 28316.846592, "Cubic feet", "立方英尺"],
                    [68, 764554.857984, "Cubic yards", "立方码"],
                    [115, 5.919388020833333, "Teaspoons (UK)", "茶匙（英制）"],
                    [116, 17.7581640625, "Tablespoons (UK)", "汤匙（英制）"],
                    [70, 28.4130625, "Fluid ounces (UK)", "液盎司（英制）"],
                    [76, 568.26125, "Pints (UK)", "品脱（英制）"], [80, 1136.5225, "Quarts (UK)", "夸脱（英制）"],
                    [72, 4546.09, "Gallons (UK)", "加仑（英制）"]]},
                {mode: "area", base: 7, count: pyeongRegion ? 11 : 10, units: [
                    [9, 0.000001, "Square millimeters", "平方毫米"], [3, 0.0001, "Square centimeters", "平方厘米"],
                    [7, 1, "Square meters", "平方米"], [2, 10000, "Hectares", "公顷"],
                    [6, 1000000, "Square kilometers", "平方公里"], [5, 0.00064516, "Square inches", "平方英寸"],
                    [4, 0.09290304, "Square feet", "平方英尺"], [10, 0.83612736, "Square yards", "平方码"],
                    [1, 4046.8564224, "Acres", "英亩"], [8, 2589988.110336, "Square miles", "平方英里"]]},
                {mode: "weight", base: 88, count: 14, units: [
                    [82, 0.0002, "Carats", "克拉"], [90, 0.000001, "Milligrams", "毫克"],
                    [83, 0.00001, "Centigrams", "厘克"], [84, 0.0001, "Decigrams", "分克"],
                    [86, 0.001, "Grams", "克"], [85, 0.01, "Dekagrams", "十克"],
                    [87, 0.1, "Hectograms", "百克"], [88, 1, "Kilograms", "千克"],
                    [95, 1000, "Metric tonnes", "公吨"], [91, 0.028349523125, "Ounces", "盎司"],
                    [92, 0.45359237, "Pounds", "磅"], [94, 6.35029318, "Stone", "英石"],
                    [93, 907.18474, "Short tons (US)", "短吨（美制）"], [89, 1016.0469088, "Long tons (UK)", "长吨(英制)"]]}
            ]
            if (pyeongRegion) catalogs[1].units.push([165, 3.305785123966942, "Pyeong", "坪"])
            const rows = []
            for (const catalog of catalogs) {
                for (let index = 0; index < catalog.units.length; ++index) {
                    const unit = catalog.units[index]
                    rows.push({tag: catalog.mode + "-" + unit[2], mode: catalog.mode, base: catalog.base,
                               id: unit[0], expected: unit[1], name: chinese ? unit[3] : unit[2],
                               index: index, count: catalog.count})
                }
            }
            return rows
        }

        function test_reference_unit_catalog_and_ratios(data) {
            navigate("mode_" + data.mode)
            compare(control("converterUnit1").count, data.count, "Complete reference selector, without whimsical suggestions")
            compare(control("converterUnit2").count, data.count)
            selectUnit("converterUnit1", data.id)
            compare(control("converterUnit1").currentIndex, data.index, "Pinned unit ordering")
            compare(control("converterUnit1").currentText, data.name)
            selectUnit("converterUnit2", data.base)
            mouseClick(control("converterValue1"))
            mouseClick(control("converterKey_clear"))
            enter("1", false)
            const actual = Number(control("converterValue2").text.replace(/,/g, ""))
            const tolerance = data.expected < 1e-6 ? 5e-15 : Math.max(5e-7, Math.abs(data.expected) * 5e-7)
            verify(Math.abs(actual - data.expected) <= tolerance,
                   data.tag + " has the known ratio: " + actual)
        }

        function test_identity_round_trip_and_category_switch_data() { return cases() }
        function test_identity_round_trip_and_category_switch(data) {
            navigate("mode_" + data.mode)
            compare(control("pageTitle").text, data.title)
            selectUnit("converterUnit1", data.from)
            selectUnit("converterUnit2", data.to)
            mouseClick(control("converterValue1"))
            mouseClick(control("converterKey_clear"))
            enter("1", true)
            compare(control("converterValue2").text, data.result)
            mouseClick(control("converterValue2"))
            enter(data.result.replace(/,/g, ""), true)
            compare(control("converterValue1").text, "1", "Input on second side performs the inverse")
            selectUnit("converterUnit1", data.to)
            compare(control("converterValue1").text, data.result, "Same-unit result")
            const other = data.mode === "volume" ? "area" : "volume"
            navigate("mode_" + other)
            verify(control("converterValue2").checked, "Active input side survives category changes")
            compare(control("converterValue2").text, data.result, "Shared converter retains current numeric input")
            verify(control("converterUnit1").indexOfValue(data.from) < 0, "Previous category units cannot leak")
            navigate("mode_" + data.mode)
            compare(control("converterUnit1").currentValue, data.to, "First unit selection is restored")
            compare(control("converterUnit2").currentValue, data.to, "Second unit selection is restored")
            compare(control("converterValue2").text, data.result)
            selectUnit("converterUnit1", data.from)
            selectUnit("converterUnit2", data.to)
            mouseClick(control("converterValue1"))
            mouseClick(control("converterKey_clear"))
            enter("1", false)
            compare(control("converterValue2").text, data.result, "Round trip remains usable after navigation")
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

        function test_input_limits_clear_format_and_negative_recovery_data() { return cases() }
        function test_input_limits_clear_format_and_negative_recovery(data) {
            navigate("mode_" + data.mode)
            selectUnit("converterUnit1", data.from)
            selectUnit("converterUnit2", data.from)
            mouseClick(control("converterValue1"))
            mouseClick(control("converterKey_clear"))
            enter("1234567890123456", true)
            compare(control("converterValue1").text, "123,456,789,012,345", "15 digit input limit")
            compare(control("converterValue2").text, "123,456,789,012,345")
            compare(control("converterStatus").text, chinese ? "最多输入 15 位数字" : "Maximum 15 digits")
            keyClick(Qt.Key_Backspace)
            compare(control("converterValue1").text, "12,345,678,901,234")
            verify(!control("converterStatus").visible)
            keyClick(Qt.Key_Escape)
            compare(control("converterValue1").text, "0")
            compare(control("converterValue2").text, "0")
            enter("0.500", false)
            enter(".", false)
            compare(control("converterValue1").text, "0.500")
            compare(control("converterValue2").text, "0.5")
            keyClick("-")
            compare(control("converterValue1").text, "0.500", "No negative sign shortcut in positive-only categories")
            paste("-1")
            verify(control("converterStatus").visible)
            compare(control("converterStatus").text, data.negative)
            enter("2", true)
            compare(control("converterValue1").text, "2", "New digit recovers from rejected negative input")
            verify(!control("converterStatus").visible)
            mouseClick(control("converterKey_backspace"))
            compare(control("converterValue1").text, "0")
            mouseClick(control("converterKey_clear"))
            compare(control("converterValue2").text, "0")
        }

        function test_scientific_output_boundaries_data() {
            return [
                {tag: "volume-small", mode: "volume", from: 75, to: 67, input: "0.00000000000001", expected: 1e-20},
                {tag: "volume-large", mode: "volume", from: 67, to: 75, input: "999999999999999", expected: 9.99999999999999e20},
                {tag: "area-small", mode: "area", from: 9, to: 6, input: "0.00000000000001", expected: 1e-26},
                {tag: "area-large", mode: "area", from: 6, to: 9, input: "999999999999999", expected: 9.99999999999999e26},
                {tag: "weight-small", mode: "weight", from: 90, to: 95, input: "0.00000000000001", expected: 1e-23},
                {tag: "weight-large", mode: "weight", from: 89, to: 90, input: "999999999999999", expected: 1.016046908799999e24}
            ]
        }
        function test_scientific_output_boundaries(data) {
            navigate("mode_" + data.mode)
            selectUnit("converterUnit1", data.from)
            selectUnit("converterUnit2", data.to)
            mouseClick(control("converterKey_clear"))
            enter(data.input, true)
            const text = control("converterValue2").text
            verify(/e[+-][0-9]+$/.test(text), "Extreme result uses scientific notation: " + text)
            verify(Math.abs(Number(text) - data.expected) <= Math.abs(data.expected) * 5e-7)
            verify(!control("converterStatus").visible)
        }

        function test_runtime_theme_language_and_layout_data() {
            const rows = []
            for (const data of cases()) {
                for (const layout of [{name: "narrow", width: 320, height: 480}, {name: "wide", width: 900, height: 600}])
                    rows.push({tag: data.tag + "-" + layout.name, mode: data.mode, from: data.from, to: data.to,
                               result: data.result, width: layout.width, height: layout.height})
            }
            return rows
        }
        function contrastRatio(a, b) {
            function channel(c) { return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4) }
            function luminance(c) { return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b) }
            const x = luminance(a), y = luminance(b)
            return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05)
        }
        function test_runtime_theme_language_and_layout(data) {
            application.width = data.width
            application.height = data.height
            navigate("mode_" + data.mode)
            selectUnit("converterUnit1", data.from)
            selectUnit("converterUnit2", data.to)
            mouseClick(control("converterKey_clear"))
            enter("1", false)
            for (const setting of [{language: "zh-CN", theme: "dark"}, {language: "en-US", theme: "light"}]) {
                navigate("settingsButton")
                mouseClick(control("language_" + setting.language))
                mouseClick(control("theme_" + setting.theme))
                navigate("mode_" + data.mode)
                const zh = setting.language === "zh-CN"
                const labels = {volume: zh ? "体积" : "Volume", area: zh ? "面积" : "Area", weight: zh ? "重量" : "Weight and Mass"}
                compare(control("pageTitle").text, labels[data.mode])
                compare(control("converterUnit1").currentValue, data.from)
                compare(control("converterUnit2").currentValue, data.to)
                compare(control("converterUnit1").currentText, data.mode === "volume" ? (zh ? "立方米" : "Cubic meters")
                    : data.mode === "area" ? (zh ? "平方米" : "Square meters") : (zh ? "千克" : "Kilograms"))
                compare(control("converterValue1").text, "1")
                compare(control("converterValue2").text, data.result)
                compare(control("converterKey_clear").Accessible.name, zh ? "清除输入" : "Clear entry")
                verify(setting.theme === "dark" ? application.color.r < 0.25 : application.color.r > 0.75)
                verify(contrastRatio(control("converterValue1").palette.buttonText, application.color) >= 4.5)
                const names = ["converterValue1", "converterUnit1", "converterValue2", "converterUnit2",
                               "converterKey_clear", "converterKey_backspace", "converterKey_7", "converterKey_8",
                               "converterKey_9", "converterKey_4", "converterKey_5", "converterKey_6",
                               "converterKey_1", "converterKey_2", "converterKey_3", "converterKey_0", "converterKey_decimal"]
                verify(waitForPolish(application))
                control(names[0]).forceActiveFocus(Qt.TabFocusReason)
                for (let index = 0; index < names.length; ++index) {
                    const item = control(names[index])
                    if (index > 0) keyClick(Qt.Key_Tab)
                    tryCompare(item, "activeFocus", true)
                    verify(item.visualFocus, "Visible keyboard focus: " + names[index])
                    const point = item.mapToItem(application.contentItem, 0, 0)
                    verify(item.visible && item.enabled && item.width >= 44 && item.height >= 32)
                    verify(point.x >= 0 && point.x + item.width <= application.width + 1, names[index] + " fits width")
                    verify(point.y >= 40 && point.y + item.height <= application.height + 1, names[index] + " fits height")
                    verify(item.Accessible.name.length > 0)
                }
                waitForRendering(application.contentItem)
                grabImage(application.contentItem).save("ticket14-" + data.tag + "-" + setting.theme + "-" + setting.language + ".png")
            }
            navigate("settingsButton")
            mouseClick(control("language_system"))
            mouseClick(control("theme_system"))
            application.width = 360
            application.height = 560
        }

        function cleanup() { clipboardProvider.visible = false }
        function cleanupTestCase() { application.close() }
    }
}
