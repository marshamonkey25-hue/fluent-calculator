import QtQuick
import QtTest
import Calculator

Item {
    property var application
    Component { id: windowFactory; MainWindow { systemPreferences: testSystemPreferences; currencySource: testCurrencySource } }
    TestCase {
        name: "CurrencyRestart"
        when: windowShown
        function control(name) {
            const item = findChild(application.contentItem, name)
            verify(item !== null, name)
            return item
        }
        function navigate(name) {
            mouseClick(control("navigationButton"))
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            const item = findChild(drawer.contentItem, name)
            verify(item !== null)
            item.forceActiveFocus()
            keyClick(Qt.Key_Space)
            tryCompare(drawer, "visible", false)
        }
        function selectCurrency(name, code) {
            const combo = control(name)
            let index = -1
            for (let row = 0; row < combo.count; ++row)
                if (combo.textAt(row).indexOf(code + " — ") === 0) index = row
            verify(index >= 0)
            combo.forceActiveFocus()
            keyClick(Qt.Key_Home)
            for (let row = 0; row < index; ++row) keyClick(Qt.Key_Down)
            verify(combo.currentText.indexOf(code) === 0)
        }
        function test_recent_currency_mode_and_preferences_survive_ordinary_restart() {
            if (restartStage === "write") {
                testCurrencySource.setResponse("currencies", '[{"iso_code":"EUR","name":"Euro"},{"iso_code":"USD","name":"US Dollar"},{"iso_code":"GBP","name":"Pound Sterling"}]')
                testCurrencySource.setResponse("rates?base=EUR&quotes=USD", '[{"date":"2026-04-10","base":"EUR","quote":"USD","rate":1.25}]')
                testCurrencySource.setResponse("rates?base=GBP&quotes=USD", '[{"date":"2026-04-09","base":"GBP","quote":"USD","rate":2}]')
            } else {
                // No network fixtures: the source reports offline after a delay.
                testCurrencySource.setNow("2026-04-16T09:00:00Z")
                testCurrencySource.setResponse("rates?base=EUR&quotes=USD", "", 600, false)
                testCurrencySource.setResponse("rates?base=GBP&quotes=USD", "", 600, false)
            }
            application = windowFactory.createObject(null)
            verify(application !== null)
            application.requestActivate()
            tryCompare(application, "active", true)
            if (restartStage === "write") {
                application.width = 900
                for (const mode of ["standard", "scientific"]) {
                    navigate("mode_" + mode)
                    keyClick(Qt.Key_Escape)
                    for (const key of "6*7=") keyClick(key)
                    compare(control("historyList").count, 1)
                    keyClick(Qt.Key_M, Qt.ControlModifier)
                }
                navigate("settingsButton")
                mouseClick(control("theme_dark"))
                mouseClick(control("language_zh-CN"))
                navigate("mode_currency")
                tryCompare(control("converterValue2"), "text", "0")
                mouseClick(control("converterKey_8"))
                compare(control("converterValue2").text, "10")
                selectCurrency("converterUnit1", "GBP")
                tryVerify(function() { return control("currencyDate").text.indexOf("2026-04-09") >= 0 })
                selectCurrency("converterUnit1", "EUR")
                compare(control("converterValue2").text, "10")
            } else {
                compare(control("pageTitle").text, "货币")
                verify(application.color.r < 0.25)
                compare(control("converterValue1").text, "0", "Amounts do not persist")
                compare(control("currencyRefresh").text, "刷新汇率")
                compare(control("converterValue2").text, "0", "Cached conversion is available before the offline refresh finishes")
                mouseClick(control("converterKey_4"))
                const recovered = restartStage === "restore-recovered"
                compare(control("converterValue2").text, recovered ? "6" : "5")
                verify(control("currencyDate").text.indexOf(recovered ? "2026-04-14" : "2026-04-10") >= 0)
                verify(control("currencyRefreshed").text.indexOf(recovered ? "2026-04-16T09:00:00Z" : "2026-04-15T12:34:56Z") >= 0)
                verify(control("currencyCache").visible)
                tryCompare(control("currencyStatus"), "text", "刷新失败，请重试。")
                compare(control("converterValue2").text, recovered ? "6" : "5", "Offline refresh retains the cached quote")
                verify(control("currencyRefreshed").text.indexOf("2026-04-16T09:00:00Z") >= 0)
                selectCurrency("converterUnit1", "GBP")
                compare(control("converterValue2").text, "8")
                verify(control("currencyDate").text.indexOf("2026-04-09") >= 0, "Pair dates remain independent across launches")
                selectCurrency("converterUnit1", "EUR")
                if (restartStage === "restore") {
                    testCurrencySource.setResponse("rates?base=EUR&quotes=USD", '[{"date":"2026-04-14","base":"GBP","quote":"USD","rate":9}]')
                    mouseClick(control("currencyRefresh"))
                    tryCompare(control("currencyStatus"), "text", "此货币对暂无有效汇率，请重试。")
                    compare(control("converterValue2").text, "5")
                } else if (restartStage === "recover") {
                    testCurrencySource.setResponse("rates?base=EUR&quotes=USD", '[{"date":"2026-04-14","base":"EUR","quote":"USD","rate":1.5}]')
                    mouseClick(control("currencyRefresh"))
                    tryCompare(control("converterValue2"), "text", "6")
                    verify(!control("currencyCache").visible)
                } else {
                    compare(restartStage, "restore-recovered")
                }
                // Restoring currency observations must never restore arithmetic sessions.
                application.width = 900
                for (const mode of ["standard", "scientific"]) {
                    navigate("mode_" + mode)
                    compare(control("historyList").count, 0)
                    verify(!control("memory_list").enabled)
                }
                navigate("mode_currency")
            }
        }
        function cleanupTestCase() { application.close(); application.destroy() }
    }
}
