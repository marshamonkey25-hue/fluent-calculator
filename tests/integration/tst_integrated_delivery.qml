import QtQuick
import QtTest
import Calculator

Item {
    MainWindow { id: application; systemPreferences: testSystemPreferences; currencySource: testCurrencySource }
    TextEdit {
        id: clipboardReceiver
        parent: application.contentItem
        width: 200
        height: 30
        visible: false
    }
    TestCase {
        name: "IntegratedDelivery"
        when: windowShown && application.visible

        function control(name) {
            const item = findChild(application.contentItem, name)
            verify(item !== null, "Application control: " + name)
            return item
        }
        function openNavigation() {
            mouseClick(control("navigationButton"))
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            return drawer
        }
        function navigate(key) {
            const drawer = openNavigation()
            const entry = findChild(drawer.contentItem, key === "settings" ? "settingsButton" : "mode_" + key)
            verify(entry !== null, "Navigation entry: " + key)
            entry.forceActiveFocus(Qt.TabFocusReason)
            verify(waitForPolish(application.contentItem))
            keyClick(Qt.Key_Space)
            tryCompare(drawer, "visible", false)
        }
        function input(text) { for (const character of text) keyClick(character) }
        function initTestCase() {
            application.requestActivate()
            tryCompare(application, "active", true)
            testCurrencySource.setResponse("currencies", '[{"iso_code":"EUR","name":"Euro"},{"iso_code":"USD","name":"US Dollar"}]')
            testCurrencySource.setResponse("rates?base=EUR&quotes=USD", '[{"date":"2026-04-10","base":"EUR","quote":"USD","rate":1.25}]')
        }
        function init() {
            clipboardReceiver.visible = false
            application.width = 900
            application.height = 750
            navigate("standard")
            keyClick(Qt.Key_Escape)
        }
        function selectUnit(side, id) {
            const combo = control("converterUnit" + side)
            const index = combo.indexOfValue(id)
            verify(index >= 0, "Selectable reference unit " + id)
            combo.forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_Home)
            for (let row = 0; row < index; ++row) keyClick(Qt.Key_Down)
            compare(combo.currentValue, id)
        }
        function chooseDate(name, date) {
            const picker = control(name)
            mouseClick(picker)
            const popup = findChild(picker, "dateCalendar")
            tryCompare(popup, "opened", true)
            const year = findChild(popup.contentItem, "calendarYear")
            mouseClick(year)
            keySequence(StandardKey.SelectAll)
            input(date.substring(0, 4))
            const month = findChild(popup.contentItem, "calendarMonth")
            month.forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_Home)
            for (let index = 1; index < Number(date.substring(5, 7)); ++index) keyClick(Qt.Key_Down)
            verify(waitForPolish(application.contentItem))
            mouseClick(findChild(popup.contentItem, "dateDay_" + date))
            tryCompare(popup, "visible", false)
        }
        function test_all_eighteen_modes_perform_real_operations_data() {
            // Literal known equivalents; IDs identify units in the pinned catalog.
            return [
                {tag: "standard", key: "standard", en: "Standard", zh: "标准", input: "2+3*4=", expected: "20"},
                {tag: "scientific", key: "scientific", en: "Scientific", zh: "科学", input: "2+3*4=", expected: "14"},
                {tag: "programmer", key: "programmer", en: "Programmer", zh: "程序员", input: "7/2=", expected: "3"},
                {tag: "graphing", key: "graphing", en: "Graphing", zh: "函数绘图"},
                {tag: "date", key: "date", en: "Date calculation", zh: "日期计算"},
                {tag: "currency", key: "currency", en: "Currency", zh: "货币", input: "8", expected: 10},
                {tag: "volume", key: "volume", en: "Volume", zh: "体积", from: 67, to: 74, input: "1", expected: 1000},
                {tag: "length", key: "length", en: "Length", zh: "长度", from: 32, to: 30, input: "1", expected: 2.54},
                {tag: "weight", key: "weight", en: "Weight and Mass", zh: "重量", from: 88, to: 86, input: "1", expected: 1000},
                {tag: "temperature", key: "temperature", en: "Temperature", zh: "温度", from: 46, to: 47, input: "100", expected: 212},
                {tag: "energy", key: "energy", en: "Energy", zh: "能量", from: 24, to: 27, input: "1", expected: 4.184},
                {tag: "area", key: "area", en: "Area", zh: "面积", from: 7, to: 3, input: "1", expected: 10000},
                {tag: "speed", key: "speed", en: "Speed", zh: "速度", from: 63, to: 62, input: "100", expected: 44.7},
                {tag: "time", key: "time", en: "Time", zh: "时间", from: 56, to: 49, input: "1", expected: 365.25},
                {tag: "power", key: "power", en: "Power", zh: "功率", from: 44, to: 45, input: "1", expected: 1000},
                {tag: "data", key: "data", en: "Data", zh: "数据", from: 150, to: 12, input: "1", expected: 1024},
                {tag: "pressure", key: "pressure", en: "Pressure", zh: "压力", from: 137, to: 141, input: "1", expected: 101325},
                {tag: "angle", key: "angle", en: "Angle", zh: "角度", from: 134, to: 136, input: "180", expected: 200}
            ]
        }
        function test_all_eighteen_modes_perform_real_operations(data) {
            navigate(data.key)
            const chinese = Qt.locale().name.indexOf("zh") === 0
            compare(control("pageTitle").text, chinese ? data.zh : data.en)
            if (["standard", "scientific", "programmer"].indexOf(data.key) >= 0) {
                keyClick(Qt.Key_Escape)
                input(data.input)
                compare(control("resultDisplay").text, data.expected)
            } else if (data.key === "date") {
                chooseDate("fromDatePicker", "2024-02-28")
                chooseDate("toDatePicker", "2024-03-01")
                compare(control("dateDifferenceResult").text, chinese ? "2 天" : "2 days")
            } else if (data.key === "graphing") {
                mouseClick(control("functionInput"))
                input("2*x+1")
                keyClick(Qt.Key_Return)
                mouseClick(control("functionGraph"), control("functionGraph").width / 2, control("functionGraph").height / 2)
                keyClick(Qt.Key_Space)
                compare(control("graphCoordinates").text, "x: 0; y: 0; F1(x): 1")
            } else {
                mouseClick(control("converterValue1"))
                if (data.from !== undefined) {
                    selectUnit(1, data.from)
                    selectUnit(2, data.to)
                } else {
                    tryVerify(function() { return control("currencyDate").text.indexOf("2026-04-10") >= 0 })
                }
                mouseClick(control("converterKey_clear"))
                input(data.input)
                const actual = Number(control("converterValue2").text.replace(/,/g, ""))
                verify(Math.abs(actual - data.expected) <= Math.abs(data.expected) * 5e-7,
                       data.key + " known equivalent: " + actual + " vs " + data.expected)
            }
            for (const width of [320, 900]) {
                application.width = width
                application.height = Math.max(700, application.minimumHeight)
                verify(waitForPolish(application.contentItem))
                verify(waitForRendering(application.contentItem))
                grabImage(application.contentItem).save("delivery-" + data.key + "-" + Qt.locale().name
                    + "-" + (application.darkTheme ? "dark" : "light") + "-" + width + ".png")
                const navigation = control("navigationButton")
                navigation.forceActiveFocus(Qt.TabFocusReason)
                keyClick(Qt.Key_Space)
                const drawer = findChild(application, "navigationDrawer")
                tryCompare(drawer, "opened", true)
                const entry = findChild(drawer.contentItem, "mode_" + data.key)
                entry.forceActiveFocus(Qt.TabFocusReason)
                verify(waitForPolish(application.contentItem))
                const list = findChild(drawer.contentItem, "navigationList")
                const position = entry.mapToItem(list, 0, 0)
                verify(position.y >= 0 && position.y + entry.height <= list.height,
                       "Keyboard navigation keeps " + data.key + " visible at " + width
                       + ": y=" + position.y + " height=" + entry.height + " viewport=" + list.height + " scroll=" + list.contentY)
                keyClick(Qt.Key_Escape)
                tryCompare(drawer, "visible", false)
            }
        }
        function test_cross_mode_history_memory_errors_and_currency_cache_stay_independent() {
            for (const mode of ["scientific", "standard"]) {
                navigate(mode)
                if (control("clearHistoryButton").enabled) mouseClick(control("clearHistoryButton"))
            }
            if (control("memory_clear").enabled) mouseClick(control("memory_clear"))
            keyClick(Qt.Key_Escape)
            input("4*5=")
            compare(control("historyResult_0").text, "20")
            keyClick(Qt.Key_M, Qt.ControlModifier)
            navigate("scientific")
            compare(control("historyList").count, 0)
            input("2+3*4=")
            compare(control("historyResult_0").text, "14")
            keyClick(Qt.Key_R, Qt.ControlModifier)
            compare(control("resultDisplay").text, "20")
            navigate("programmer")
            verify(!control("historyButton").visible)
            compare(control("memoryValue_0").text, "20")
            navigate("graphing")
            mouseClick(control("functionInput"))
            input("x+1")
            keyClick(Qt.Key_Return)
            navigate("length")
            mouseClick(control("converterValue1"))
            mouseClick(control("converterKey_clear"))
            input("7")
            navigate("settings")
            mouseClick(control("theme_dark"))
            mouseClick(control("language_zh-CN"))
            navigate("scientific")
            compare(control("historyList").count, 1)
            compare(control("historyResult_0").text, "14")
            keyClick(Qt.Key_Escape)
            input("1/0=")
            compare(control("resultDisplay").text, "除数不能为零")
            input("3+4=")
            compare(control("resultDisplay").text, "7")
            compare(control("historyList").count, 2)
            navigate("currency")
            tryVerify(function() { return control("currencyDate").text.indexOf("2026-04-10") >= 0 })
            mouseClick(control("converterValue1"))
            mouseClick(control("converterKey_clear"))
            input("8")
            compare(control("converterValue2").text, "10")
            testCurrencySource.setResponse("rates?base=EUR&quotes=USD", "", 10, false)
            mouseClick(control("currencyRefresh"))
            tryCompare(control("currencyStatus"), "text", "刷新失败，请重试。")
            verify(control("currencyCache").visible)
            compare(control("converterValue2").text, "10")
            verify(control("currencyDate").text.indexOf("2026-04-10") >= 0)
            navigate("standard")
            compare(control("historyList").count, 1)
            compare(control("historyResult_0").text, "20")
            mouseClick(control("historyItem_0"))
            input("+2=")
            compare(control("resultDisplay").text, "22")
            keyClick(Qt.Key_R, Qt.ControlModifier)
            compare(control("resultDisplay").text, "20")
            navigate("settings")
            mouseClick(control("theme_system"))
            mouseClick(control("language_system"))
        }
        function test_navigation_blocks_underlying_programmer_shortcuts() {
            navigate("programmer")
            input("255")
            const drawer = openNavigation()
            keyClick(Qt.Key_F5)
            keyClick(Qt.Key_F12)
            keyClick(Qt.Key_Escape)
            tryCompare(drawer, "visible", false)
            verify(control("radix_10").checked, "Browsing navigation must preserve the input base")
            compare(control("wordWidthButton").text, "QWORD", "Browsing navigation must preserve the word width")
            input("+1=")
            compare(control("resultDisplay").text, "256")
        }
        function test_navigation_keyboard_order_matches_pinned_reference() {
            const drawer = openNavigation()
            const keys = ["standard", "scientific", "graphing", "programmer", "date", "currency", "volume", "length", "weight",
                          "temperature", "energy", "area", "speed", "time", "power", "data", "pressure", "angle"]
            findChild(drawer.contentItem, "mode_standard").forceActiveFocus(Qt.TabFocusReason)
            for (let index = 0; index < keys.length; ++index) {
                if (index > 0) keyClick(Qt.Key_Tab)
                tryCompare(findChild(drawer.contentItem, "mode_" + keys[index]), "activeFocus", true)
            }
            keyClick(Qt.Key_Escape)
            tryCompare(drawer, "visible", false)
        }
        function test_programmer_result_copy_follows_current_radix() {
            navigate("programmer")
            keyClick(Qt.Key_Escape)
            input("255")
            keyClick(Qt.Key_F5)
            compare(control("resultDisplay").text, "FF")
            mouseClick(control("resultDisplay"), 20, 20, Qt.RightButton)
            const menu = findChild(application, "resultContextMenu")
            verify(menu !== null, "Programmer offers Copy on its result")
            tryCompare(menu, "opened", true)
            mouseClick(findChild(menu.contentItem, "copyResultItem"))
            tryCompare(menu, "visible", false)
            clipboardReceiver.text = ""
            clipboardReceiver.visible = true
            clipboardReceiver.forceActiveFocus()
            keyClick(Qt.Key_V, Qt.ControlModifier)
            compare(clipboardReceiver.text, "FF")
            clipboardReceiver.visible = false
            control("radix_16").forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_F6)
            compare(control("resultDisplay").text, "255")
            keyClick(Qt.Key_C, Qt.ControlModifier)
            clipboardReceiver.text = ""
            clipboardReceiver.visible = true
            clipboardReceiver.forceActiveFocus()
            keyClick(Qt.Key_V, Qt.ControlModifier)
            compare(clipboardReceiver.text, "255", "Keyboard Copy follows the current base")
            clipboardReceiver.visible = false
        }
        function test_result_copy_menu_text_has_readable_contrast_data() {
            return [{tag: "standard", mode: "standard"}, {tag: "scientific", mode: "scientific"}, {tag: "programmer", mode: "programmer"}]
        }
        function test_result_copy_menu_text_has_readable_contrast(data) {
            navigate(data.mode)
            mouseClick(control("resultDisplay"), 20, 20, Qt.RightButton)
            const menu = findChild(application, "resultContextMenu")
            tryCompare(menu, "opened", true)
            const copy = findChild(menu.contentItem, "copyResultItem")
            compare(copy.text, Qt.locale().name.indexOf("zh") === 0 ? "复制" : "Copy")
            application.update()
            verify(waitForRendering(application.contentItem))
            const image = grabImage(application.contentItem)
            const position = copy.mapToItem(application.contentItem, 0, 0)
            const background = image.pixel(Math.round(position.x + copy.width - 12), Math.round(position.y + copy.height / 2))
            let readableText = false
            for (let x = 18; x < 60; ++x)
                for (let y = 10; y < copy.height - 10; ++y) {
                    const pixel = image.pixel(Math.round(position.x + x), Math.round(position.y + y))
                    if (contrastRatio(pixel, background) >= 4.5) readableText = true
                }
            image.save("delivery-copy-menu-" + data.mode + "-" + Qt.locale().name + "-" + (application.darkTheme ? "dark" : "light") + ".png")
            mouseClick(copy)
            tryCompare(menu, "visible", false)
            verify(readableText, "Copy text contrasts with the rendered menu surface in " + data.mode)
        }
        function contrastRatio(first, second) {
            function luminance(color) {
                function linear(channel) { return channel <= 0.04045 ? channel / 12.92 : Math.pow((channel + 0.055) / 1.055, 2.4) }
                return 0.2126 * linear(color.r) + 0.7152 * linear(color.g) + 0.0722 * linear(color.b)
            }
            const a = luminance(first), b = luminance(second)
            return (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05)
        }
        function test_scientific_copy_menu_escape_keeps_pending_calculation() {
            navigate("scientific")
            input("6*")
            mouseClick(control("resultDisplay"), 20, 20, Qt.RightButton)
            const menu = findChild(application, "resultContextMenu")
            tryCompare(menu, "opened", true)
            keyClick(Qt.Key_Escape)
            tryCompare(menu, "visible", false)
            input("7=")
            compare(control("resultDisplay").text, "42", "Escape dismisses Copy without clearing pending arithmetic")
        }
        function test_scientific_result_can_be_copied_without_precision_loss() {
            clipboardReceiver.text = "unchanged"
            clipboardReceiver.visible = true
            clipboardReceiver.forceActiveFocus()
            keySequence(StandardKey.SelectAll)
            keySequence(StandardKey.Copy)
            clipboardReceiver.visible = false
            navigate("scientific")
            keyClick(Qt.Key_Escape)
            input("9007199254740992+1=")
            compare(control("resultDisplay").text, "9,007,199,254,740,993")
            keySequence(StandardKey.Copy)
            clipboardReceiver.text = ""
            clipboardReceiver.visible = true
            clipboardReceiver.forceActiveFocus()
            keySequence(StandardKey.Paste)
            compare(clipboardReceiver.text, "9007199254740993", "Copy preserves exact native digits across modes")
            clipboardReceiver.visible = false
        }
        function test_standard_alternate_copy_shortcut_preserves_result() {
            verify(testCopyBindings.length > 0, "Platform provides at least one Copy binding")
            input("6*7=")
            for (const binding of testCopyBindings) {
                clipboardReceiver.visible = false
                control("resultDisplay").forceActiveFocus()
                keySequence(binding)
                clipboardReceiver.text = ""
                clipboardReceiver.visible = true
                clipboardReceiver.forceActiveFocus()
                keySequence(StandardKey.Paste)
                compare(clipboardReceiver.text, "42", "Platform Copy binding copies the displayed result: " + binding)
            }
            clipboardReceiver.visible = false
        }
        function cleanupTestCase() { application.close() }
    }
}
