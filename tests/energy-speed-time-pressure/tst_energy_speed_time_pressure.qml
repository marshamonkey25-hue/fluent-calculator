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
        name: "EnergySpeedTimePressureConversion"
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
            for (let attempt = 0; attempt < 12 && list && key !== "settings"; ++attempt) {
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
            // Default examples permit 0.5 ppm; sub-unit fixed output can
            // explicitly allow half a millionth (the pinned six decimal places).
            verify(Math.abs(actual - expected) <= Math.max(absoluteTolerance || 1e-45, Math.abs(expected) * 5e-7),
                   "Known value within display tolerance: " + text + " vs " + expected)
        }

        function test_energy_calorie_to_joules() {
            navigate("energy")
            selectUnit(1, 24)
            selectUnit(2, 27)
            mouseClick(control("converterKey_clear"))
            enter("1", false)
            closeTo(2, 4.184)
        }

        function test_speed_uses_pinned_miles_per_hour_definition() {
            navigate("speed")
            selectUnit(1, 63)
            selectUnit(2, 62)
            mouseClick(control("converterKey_clear"))
            enter("100", true)
            closeTo(2, 44.7)
        }

        function test_time_year_uses_365_and_a_quarter_days() {
            navigate("time")
            selectUnit(1, 56)
            selectUnit(2, 49)
            mouseClick(control("converterKey_clear"))
            enter("1", false)
            closeTo(2, 365.25)
        }

        function test_pressure_atmosphere_to_pascals() {
            navigate("pressure")
            selectUnit(1, 137)
            selectUnit(2, 141)
            mouseClick(control("converterKey_clear"))
            enter("1", true)
            closeTo(2, 101325)
        }

        function categories() {
            return [
                {tag: "energy", key: "energy", title: "Energy", chineseTitle: "能量", from: 24, to: 27,
                 ids: [25, 27, 29, 24, 28, 26, 23, 166],
                 names: ["Electron volts", "Joules", "Kilojoules", "Thermal calories", "Food calories", "Foot-pounds", "British thermal units", "Kilowatt-hours"],
                 chineseNames: ["电子伏特", "焦耳", "千焦耳", "热卡路里", "食物卡路里", "英尺磅", "英国热量单位", "千瓦时"]},
                {tag: "speed", key: "speed", title: "Speed", chineseTitle: "速度", from: 62, to: 57,
                 ids: [57, 62, 59, 58, 63, 60, 61],
                 names: ["Centimeters per second", "Meters per second", "Kilometers per hour", "Feet per second", "Miles per hour", "Knots", "Mach"],
                 chineseNames: ["厘米/秒", "米/秒", "公里/小时", "英尺/秒", "英里/小时", "节", "马赫"]},
                {tag: "time", key: "time", title: "Time", chineseTitle: "时间", from: 50, to: 53,
                 ids: [51, 52, 54, 53, 50, 49, 55, 56],
                 names: ["Microseconds", "Milliseconds", "Seconds", "Minutes", "Hours", "Days", "Weeks", "Years"],
                 chineseNames: ["微秒", "毫秒", "秒", "分钟", "小时", "天", "周", "年"]},
                {tag: "pressure", key: "pressure", title: "Pressure", chineseTitle: "压力", from: 137, to: 141,
                 ids: [137, 138, 139, 140, 141, 142],
                 names: ["Atmospheres", "Bars", "Kilopascals", "Millimeters of mercury", "Pascals", "Pounds per square inch"],
                 chineseNames: ["大气压", "巴", "千帕", "毫米汞柱", "帕", "磅每平方英寸"]}
            ]
        }

        function test_complete_localized_reference_unit_lists_data() { return categories() }
        function test_complete_localized_reference_unit_lists(data) {
            navigate(data.key)
            const chinese = Qt.locale().name.indexOf("zh") === 0
            compare(control("pageTitle").text, chinese ? data.chineseTitle : data.title)
            for (let side = 1; side <= 2; ++side) {
                const combo = control("converterUnit" + side)
                compare(combo.count, data.ids.length, "Complete selectable unit list")
                for (let row = 0; row < data.ids.length; ++row) {
                    compare(combo.valueAt(row), data.ids[row], "Pinned selectable order")
                    compare(combo.textAt(row), chinese ? data.chineseNames[row] : data.names[row])
                }
            }
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

        function test_negative_input_names_current_category_and_recovers_data() { return categories() }
        function test_negative_input_names_current_category_and_recovers(data) {
            navigate(data.key)
            mouseClick(control("converterValue1"))
            selectUnit(1, data.from)
            selectUnit(2, data.from)
            mouseClick(control("converterKey_clear"))
            enter("12.5", true)
            paste("-2")
            compare(control("converterValue1").text, "12.5", "Rejected paste leaves the last valid input")
            compare(control("converterStatus").text, Qt.locale().name.indexOf("zh") === 0
                    ? data.chineseTitle + "不能为负值" : data.title + " cannot be negative")
            enter("3", true)
            compare(control("converterValue1").text, "3", "New input recovers from rejected negative paste")
            compare(control("converterValue2").text, "3")
            verify(!control("converterStatus").visible)
            keyClick("-", Qt.NoModifier)
            compare(control("converterValue1").text, "3", "Minus key cannot enter a negative quantity")
            verify(findChild(application.contentItem, "converterKey_negate") === null)
        }

        function test_navigation_entries_remain_reachable_at_minimum_window() {
            application.width = 320
            application.height = 480
            navigate("length")
            mouseClick(control("navigationButton"))
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            const list = findChild(drawer.contentItem, "navigationList")
            const entry = findChild(drawer.contentItem, "mode_pressure")
            verify(entry !== null)
            for (let attempt = 0; attempt < 12; ++attempt) {
                const point = entry.mapToItem(list, 0, entry.height)
                if (point.y <= list.height) break
                mouseWheel(list, list.width / 2, list.height / 2, 0, -120)
                tryCompare(list, "moving", false)
            }
            const position = entry.mapToItem(list, 0, 0)
            verify(position.y >= 0 && position.y + entry.height <= list.height,
                   "Pressure entry is visible in the narrow navigation drawer")
            verify(entry.height >= 32, "Navigation entries retain a usable desktop target")
            mouseClick(entry)
            tryCompare(drawer, "visible", false)
            compare(control("converterUnit1").count, 6)
            verify(control("converterUnit1").indexOfValue(137) >= 0, "Pressure units are active")
            application.width = 360
            application.height = 560
        }

        function test_reference_unit_values_data() {
            // Literal worked examples use the pinned unit definitions, including
            // rounded mph, knot and mmHg definitions; no factors are recomputed here.
            return [
                {tag: "electron-volt", key: "energy", from: 25, to: 27, input: "1", expected: 1.602176565e-19},
                {tag: "joule", key: "energy", from: 27, to: 27, input: "2", expected: 2},
                {tag: "kilojoule", key: "energy", from: 29, to: 27, input: "2", expected: 2000},
                {tag: "thermal-calorie", key: "energy", from: 24, to: 27, input: "2", expected: 8.368},
                {tag: "food-calorie", key: "energy", from: 28, to: 27, input: "2", expected: 8368},
                {tag: "foot-pound", key: "energy", from: 26, to: 27, input: "10", expected: 13.558179483314},
                {tag: "BTU", key: "energy", from: 23, to: 27, input: "2", expected: 2110.112},
                {tag: "kilowatt-hour", key: "energy", from: 166, to: 27, input: "0.5", expected: 1800000},
                {tag: "cm-per-second", key: "speed", from: 57, to: 62, input: "100", expected: 1},
                {tag: "m-per-second", key: "speed", from: 62, to: 62, input: "2", expected: 2},
                {tag: "km-per-hour", key: "speed", from: 59, to: 62, input: "36", expected: 10},
                {tag: "feet-per-second", key: "speed", from: 58, to: 62, input: "10", expected: 3.048},
                {tag: "miles-per-hour", key: "speed", from: 63, to: 62, input: "100", expected: 44.7},
                {tag: "knot", key: "speed", from: 60, to: 62, input: "100", expected: 51.44},
                {tag: "mach", key: "speed", from: 61, to: 62, input: "2", expected: 680.6},
                {tag: "microsecond", key: "time", from: 51, to: 54, input: "1000000", expected: 1},
                {tag: "millisecond", key: "time", from: 52, to: 54, input: "1000", expected: 1},
                {tag: "second", key: "time", from: 54, to: 54, input: "2", expected: 2},
                {tag: "minute", key: "time", from: 53, to: 54, input: "2", expected: 120},
                {tag: "hour", key: "time", from: 50, to: 54, input: "2", expected: 7200},
                {tag: "day", key: "time", from: 49, to: 54, input: "2", expected: 172800},
                {tag: "week", key: "time", from: 55, to: 54, input: "2", expected: 1209600},
                {tag: "year", key: "time", from: 56, to: 54, input: "1", expected: 31557600},
                {tag: "atmosphere", key: "pressure", from: 137, to: 139, input: "1", expected: 101.325},
                {tag: "bar", key: "pressure", from: 138, to: 139, input: "1", expected: 100},
                {tag: "kilopascal", key: "pressure", from: 139, to: 139, input: "2", expected: 2},
                {tag: "mmHg", key: "pressure", from: 140, to: 139, input: "1000", expected: 133.3},
                {tag: "pascal", key: "pressure", from: 141, to: 139, input: "1000", expected: 1},
                {tag: "psi", key: "pressure", from: 142, to: 139, input: "10", expected: 68.94757293168}
            ]
        }

        function test_reference_unit_values(data) {
            navigate(data.key)
            mouseClick(control("converterValue1"))
            selectUnit(1, data.from)
            selectUnit(2, data.to)
            mouseClick(control("converterKey_clear"))
            enter(data.input, true)
            closeTo(2, data.expected)
            verify(!control("converterStatus").visible)
        }

        function test_same_unit_round_trip_and_repeated_category_switches_data() { return categories() }
        function test_same_unit_round_trip_and_repeated_category_switches(data) {
            for (let repetition = 0; repetition < 3; ++repetition) {
                navigate("length")
                mouseClick(control("converterValue1"))
                selectUnit(1, 39)
                selectUnit(2, 168)
                mouseClick(control("converterKey_clear"))
                enter("99", false)
                navigate(data.key)
                compare(control("converterUnit1").count, data.ids.length)
                verify(control("converterUnit1").indexOfValue(39) < 0, "No stale length units")
                verify(control("converterValue1").checked, "Active input side survives category changes")
                compare(control("converterValue1").text, "99", "Current numeric input survives category changes")
                selectUnit(1, data.from)
                selectUnit(2, data.from)
                mouseClick(control("converterKey_clear"))
                enter("12.500", repetition % 2 === 0)
                compare(control("converterValue1").text, "12.500")
                closeTo(2, 12.5)
                selectUnit(2, data.to)
                const converted = control("converterValue2").text.replace(/,/g, "")
                mouseClick(control("converterValue2"))
                verify(control("converterValue2").checked)
                enter(converted, true)
                closeTo(1, 12.5)
                compare(control("converterUnit1").currentValue, data.from)
                compare(control("converterUnit2").currentValue, data.to)
                keyClick(Qt.Key_Escape)
                compare(control("converterValue1").text, "0")
                compare(control("converterValue2").text, "0")
                verify(!control("converterStatus").visible)
            }
        }

        function test_input_limits_clear_and_backspace_data() {
            const rows = []
            for (const category of categories()) {
                for (const keyboard of [false, true])
                    rows.push({tag: category.key + (keyboard ? "-keyboard" : "-mouse"),
                               key: category.key, unit: category.from, keyboard: keyboard})
            }
            return rows
        }
        function test_input_limits_clear_and_backspace(data) {
            navigate(data.key)
            mouseClick(control("converterValue1"))
            selectUnit(1, data.unit)
            selectUnit(2, data.unit)
            mouseClick(control("converterKey_clear"))
            enter("123456789012345", data.keyboard)
            compare(control("converterValue1").text, "123,456,789,012,345")
            compare(control("converterValue2").text, "123,456,789,012,345")
            enter("6", data.keyboard)
            compare(control("converterValue1").text, "123,456,789,012,345", "Sixteenth digit is rejected")
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
            compare(control("converterValue1").text, "0")
            compare(control("converterValue2").text, "0")
            enter("0.50.", data.keyboard)
            compare(control("converterValue1").text, "0.50")
            closeTo(2, 0.5)
            paste("1..2")
            compare(control("converterStatus").text, Qt.locale().name.indexOf("zh") === 0 ? "无效输入" : "Invalid input")
            enter("2", data.keyboard)
            compare(control("converterValue1").text, "2")
            paste("1234567890123456")
            compare(control("converterValue1").text, "2", "Overlong paste preserves prior input")
            verify(control("converterStatus").visible)
        }

        function test_display_rounding_and_scientific_limits_data() {
            return [
                {tag: "energy-rounded", key: "energy", from: 27, to: 24, input: "1", expected: 0.2390057361376673},
                {tag: "energy-small", key: "energy", from: 27, to: 166, input: "0.00000000000001", expected: 2.777777777777778e-21, scientific: true},
                {tag: "energy-large", key: "energy", from: 166, to: 27, input: "999999999999999", expected: 3.6e21, scientific: true},
                {tag: "speed-rounded", key: "speed", from: 62, to: 63, input: "1", expected: 2.237136465324385},
                {tag: "speed-small", key: "speed", from: 57, to: 61, input: "0.00000000000001", expected: 2.938583602703497e-19, scientific: true},
                {tag: "speed-large", key: "speed", from: 61, to: 57, input: "999999999999999", expected: 3.403e19, scientific: true},
                {tag: "time-rounded", key: "time", from: 54, to: 53, input: "1", expected: 0.01666666666666667},
                {tag: "time-small", key: "time", from: 51, to: 56, input: "0.00000000000001", expected: 3.168808781402895e-28, scientific: true},
                {tag: "time-large", key: "time", from: 56, to: 51, input: "999999999999999", expected: 3.15576e28, scientific: true},
                {tag: "pressure-rounded", key: "pressure", from: 137, to: 142, input: "1", expected: 14.69594877551345},
                {tag: "pressure-small", key: "pressure", from: 141, to: 137, input: "0.00000000000001", expected: 9.869232667160128e-20, scientific: true},
                {tag: "pressure-large", key: "pressure", from: 137, to: 141, input: "999999999999999", expected: 1.01325e20, scientific: true}
            ]
        }
        function test_display_rounding_and_scientific_limits(data) {
            navigate(data.key)
            mouseClick(control("converterValue1"))
            selectUnit(1, data.from)
            selectUnit(2, data.to)
            mouseClick(control("converterKey_clear"))
            enter(data.input, true)
            closeTo(2, data.expected, data.scientific ? 1e-45 : 5e-7)
            if (data.scientific)
                verify(/e[+-][0-9]+$/.test(control("converterValue2").text), "Extreme output uses scientific notation")
            else verify(!control("converterValue2").text.includes("e"))
            verify(!control("converterStatus").visible)
        }

        function contrastRatio(a, b) {
            function channel(c) { return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4) }
            function luminance(c) { return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b) }
            const x = luminance(a), y = luminance(b)
            return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05)
        }

        function test_wide_narrow_layout_and_keyboard_focus_data() {
            const rows = []
            for (const category of categories()) {
                for (const wide of [false, true])
                    rows.push({tag: category.key + (wide ? "-wide" : "-narrow"),
                               key: category.key, unit: category.from, width: wide ? 900 : 320, height: wide ? 600 : 480})
            }
            return rows
        }
        function test_wide_narrow_layout_and_keyboard_focus(data) {
            application.width = data.width
            application.height = data.height
            navigate(data.key)
            selectUnit(1, data.unit)
            selectUnit(2, data.unit)
            mouseClick(control("converterKey_clear"))
            enter("123456789012345", true)
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
                verify(position.x >= 0 && position.x + item.width <= application.width + 1, "Fits window width: " + names[index])
                verify(position.y >= 40 && position.y + item.height <= application.height + 1, "Fits window height: " + names[index])
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
            grabImage(application.contentItem).save("ticket15-" + data.tag + "-" + theme + "-" + language + ".png")
            application.width = 360
            application.height = 560
        }

        function test_runtime_language_theme_and_conversion_state_data() { return categories() }
        function test_runtime_language_theme_and_conversion_state(data) {
            navigate(data.key)
            mouseClick(control("converterValue1"))
            selectUnit(1, data.from)
            selectUnit(2, data.to)
            mouseClick(control("converterKey_clear"))
            enter("12.5", true)
            const converted = control("converterValue2").text
            for (const variant of [{language: "zh-CN", theme: "dark"}, {language: "en-US", theme: "light"}]) {
                navigate("settings")
                mouseClick(control("language_" + variant.language))
                mouseClick(control("theme_" + variant.theme))
                navigate(data.key)
                const chinese = variant.language === "zh-CN"
                compare(control("pageTitle").text, chinese ? data.chineseTitle : data.title)
                compare(control("converterUnit1").currentText,
                        (chinese ? data.chineseNames : data.names)[data.ids.indexOf(data.from)])
                compare(control("converterUnit2").currentText,
                        (chinese ? data.chineseNames : data.names)[data.ids.indexOf(data.to)])
                compare(control("converterValue1").text, "12.5")
                compare(control("converterValue2").text, converted)
                compare(control("converterKey_clear").Accessible.name, chinese ? "清除输入" : "Clear entry")
                verify(contrastRatio(control("converterValue1").palette.buttonText, application.color) >= 4.5)
                verify(variant.theme === "dark" ? application.color.r < 0.25 : application.color.r > 0.75)
            }
            navigate("settings")
            mouseClick(control("language_system"))
            mouseClick(control("theme_system"))
            navigate(data.key)
        }

        function test_keyboard_navigation_scrolls_focused_modes_into_view() {
            application.width = 320
            application.height = 480
            navigate("length")
            mouseClick(control("navigationButton"))
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            const list = findChild(drawer.contentItem, "navigationList")
            const keys = ModeRegistry.modes.map(mode => mode.key)
            findChild(drawer.contentItem, "mode_" + keys[0]).forceActiveFocus(Qt.TabFocusReason)
            for (let index = 0; index <= keys.indexOf("pressure"); ++index) {
                if (index) keyClick(Qt.Key_Tab)
                const entry = findChild(drawer.contentItem, "mode_" + keys[index])
                tryCompare(entry, "activeFocus", true, 1000, "Mode " + keys[index] + "; actual focus " + application.activeFocusItem.objectName)
                verify(entry.visualFocus)
                const point = entry.mapToItem(list, 0, 0)
                verify(point.y >= -1 && point.y + entry.height <= list.height + 1,
                       "Keyboard focus is visible for " + keys[index])
            }
            keyClick(Qt.Key_Space)
            tryCompare(drawer, "visible", false)
            compare(control("converterUnit1").count, 6)
            verify(control("converterUnit1").indexOfValue(137) >= 0, "Pressure units are active")
            application.width = 360
            application.height = 560
        }

        function test_000_reference_category_defaults_data() {
            const chinese = Qt.locale().name.indexOf("zh") === 0
            return [
                {tag: "energy", key: "energy", from: 27, to: 28},
                {tag: "speed", key: "speed", from: chinese ? 63 : 59, to: chinese ? 59 : 63},
                {tag: "time", key: "time", from: 50, to: 53},
                {tag: "pressure", key: "pressure", from: 137, to: 138}
            ]
        }
        function test_000_reference_category_defaults(data) {
            navigate(data.key)
            compare(control("converterUnit1").currentValue, data.from)
            compare(control("converterUnit2").currentValue, data.to)
            compare(control("converterValue1").text, "0")
            compare(control("converterValue2").text, "0")
        }

        function test_session_input_survives_converter_category_navigation() {
            navigate("length")
            mouseClick(control("converterValue1"))
            selectUnit(1, 32)
            selectUnit(2, 30)
            mouseClick(control("converterKey_clear"))
            enter("2", false)
            closeTo(2, 5.08)
            navigate("energy")
            compare(control("converterValue1").text, "2", "Pinned converter keeps current input across categories")
            selectUnit(1, 24)
            selectUnit(2, 27)
            closeTo(2, 8.368)
            navigate("speed")
            compare(control("converterValue1").text, "2")
            selectUnit(1, 62)
            selectUnit(2, 57)
            closeTo(2, 200)
            navigate("time")
            compare(control("converterValue1").text, "2")
            selectUnit(1, 50)
            selectUnit(2, 53)
            closeTo(2, 120)
            navigate("pressure")
            compare(control("converterValue1").text, "2")
            selectUnit(1, 137)
            selectUnit(2, 141)
            closeTo(2, 202650)
            navigate("length")
            compare(control("converterUnit1").currentValue, 32, "Pinned converter retains category unit selections")
            compare(control("converterUnit2").currentValue, 30)
            compare(control("converterValue1").text, "2")
            closeTo(2, 5.08)
            navigate("energy")
            compare(control("converterUnit1").currentValue, 24)
            compare(control("converterUnit2").currentValue, 27)
            closeTo(2, 8.368)
        }

        function test_selected_second_input_and_unit_pairs_survive_category_navigation() {
            navigate("length")
            selectUnit(1, 32)
            selectUnit(2, 30)
            mouseClick(control("converterKey_clear"))
            enter("1", false)
            mouseClick(control("converterValue2"))
            enter("5.08", true)
            closeTo(1, 2)
            navigate("energy")
            verify(control("converterValue2").checked, "Active side follows the pinned source mapping")
            compare(control("converterValue2").text, "5.08")
            selectUnit(2, 24)
            selectUnit(1, 27)
            closeTo(1, 21.25472)
            navigate("pressure")
            verify(control("converterValue2").checked)
            compare(control("converterValue2").text, "5.08")
            selectUnit(2, 137)
            selectUnit(1, 141)
            closeTo(1, 514731)
            navigate("length")
            compare(control("converterUnit1").currentValue, 32)
            compare(control("converterUnit2").currentValue, 30)
            compare(control("converterValue2").text, "5.08")
            closeTo(1, 2)
        }

        function cleanupTestCase() { application.close() }
    }
}
