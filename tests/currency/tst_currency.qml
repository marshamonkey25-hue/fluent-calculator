import QtQuick
import QtTest
import Calculator

Item {
    id: root
    property var application
    Component { id: windowFactory; MainWindow { systemPreferences: testSystemPreferences; currencySource: testCurrencySource } }
    TextEdit {
        id: clipboardProvider
        parent: root.application ? root.application.contentItem : root
        width: 200
        height: 30
        visible: false
    }
    TestCase {
        name: "OnlineCurrencyConversion"
        when: windowShown
        function control(name) {
            const item = findChild(application.contentItem, name)
            verify(item !== null, "Currency control: " + name)
            return item
        }
        function navigate(name) {
            mouseClick(control("navigationButton"))
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            const entry = findChild(drawer.contentItem, name)
            verify(entry !== null, "Navigation entry: " + name)
            entry.forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_Space)
            tryCompare(drawer, "visible", false)
        }
        readonly property bool chinese: Qt.locale().name.indexOf("zh") === 0
        function init() {
            testCurrencySource.reset()
            testCurrencySource.setNow("2026-04-15T12:34:56Z")
            testCurrencySource.setResponse("currencies", JSON.stringify([
                {iso_code: "EUR", name: "Euro", symbol: "€"}, {iso_code: "USD", name: "US Dollar", symbol: "$"},
                {iso_code: "GBP", name: "Pound Sterling"}
            ]))
            quote("EUR", "USD", 1.25)
            quote("GBP", "USD", 1.5)
            quote("EUR", "GBP", 0.8)
            application = windowFactory.createObject(null)
            verify(application !== null)
            application.requestActivate()
            tryCompare(application, "active", true)
        }
        function quote(base, target, rate, delay = 10, date = "2026-04-10") {
            testCurrencySource.setResponse("rates?base=" + base + "&quotes=" + target,
                JSON.stringify([{date: date, base: base, quote: target, rate: rate}]), delay)
        }
        function openCurrency() {
            navigate("mode_currency")
            tryCompare(control("converterUnit1"), "count", 3)
            tryCompare(control("converterValue2"), "text", "0")
        }
        function selectCurrency(name, code) {
            const combo = control(name)
            let index = -1
            for (let row = 0; row < combo.count; ++row)
                if (combo.textAt(row).indexOf(code + " — ") === 0) index = row
            verify(index >= 0, "Service currency is selectable: " + code)
            combo.forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_Home)
            for (let row = 0; row < index; ++row) keyClick(Qt.Key_Down)
            verify(combo.currentText.indexOf(code) === 0)
        }
        function test_refresh_updates_current_catalog_without_losing_usable_quotes() {
            testCurrencySource.setResponse("currencies", JSON.stringify([
                {iso_code: "EUR", name: "Euro"}, {iso_code: "USD", name: "US Dollar"}
            ]))
            navigate("mode_currency")
            tryCompare(control("converterUnit1"), "count", 2)
            keyClick("8")
            tryCompare(control("converterValue2"), "text", "10")
            testCurrencySource.setResponse("currencies", JSON.stringify([
                {iso_code: "EUR", name: "Euro"}, {iso_code: "USD", name: "US Dollar"},
                {iso_code: "GBP", name: "Pound Sterling"}
            ]), 300)
            quote("EUR", "USD", 1.5, 300)
            mouseClick(control("currencyRefresh"))
            compare(control("converterValue2").text, "10", "Cached observation remains usable during refresh")
            tryCompare(control("converterUnit1"), "count", 3)
            tryCompare(control("converterValue2"), "text", "12")
            selectCurrency("converterUnit2", "GBP")
            tryCompare(control("converterValue2"), "text", "6.4")
        }

        function test_refresh_rejects_stale_catalog_and_preserves_cache_on_catalog_failure() {
            openCurrency()
            keyClick("8")
            testCurrencySource.setResponse("currencies", '[{"iso_code":"JPY","name":"Yen"}]', 800)
            mouseClick(control("currencyRefresh"))
            testCurrencySource.setResponse("currencies", JSON.stringify([
                {iso_code: "EUR", name: "Euro"}, {iso_code: "USD", name: "US Dollar"},
                {iso_code: "GBP", name: "Pound Sterling"}, {iso_code: "AUD", name: "Australian Dollar"}
            ]))
            mouseClick(control("currencyRefresh"))
            tryCompare(control("converterUnit1"), "count", 4)
            tryCompare(control("currencyStatus"), "text", chinese ? "已更新" : "Up to date")
            wait(850)
            compare(control("converterUnit1").count, 4)
            compare(control("converterValue2").text, "10")
            testCurrencySource.setResponse("currencies", "[]")
            mouseClick(control("currencyRefresh"))
            tryCompare(control("currencyStatus"), "text", chinese ? "刷新失败，请重试。" : "Refresh failed. Try again.")
            compare(control("converterUnit1").count, 4)
            compare(control("converterValue2").text, "10")
            restartApplication()
            tryCompare(control("converterUnit1"), "count", 4)
            keyClick("8")
            compare(control("converterValue2").text, "10", "Failed catalog refresh preserves persisted observations")
        }

        function test_refreshed_catalog_removes_retired_currency_and_survives_restart() {
            openCurrency()
            selectCurrency("converterUnit1", "GBP")
            keyClick("8")
            tryCompare(control("converterValue2"), "text", "12")
            testCurrencySource.setResponse("currencies", '[{"iso_code":"EUR","name":"Euro"},{"iso_code":"USD","name":"US Dollar"}]')
            mouseClick(control("currencyRefresh"))
            tryCompare(control("converterUnit1"), "count", 2)
            verify(control("converterUnit1").currentText.indexOf("EUR") === 0)
            verify(control("converterUnit2").currentText.indexOf("USD") === 0)
            tryCompare(control("converterValue2"), "text", "10")
            restartApplication()
            tryCompare(control("converterUnit1"), "count", 2)
            keyClick("8")
            tryCompare(control("converterValue2"), "text", "10")
        }

        function test_auto_refresh_converts_with_observation_date_and_source() {
            openCurrency()
            verify(control("currencyRefresh").enabled)
            mouseClick(control("converterKey_clear"))
            mouseClick(control("converterKey_1"))
            mouseClick(control("converterKey_0"))
            tryCompare(control("converterValue2"), "text", "12.5")
            verify(control("currencySource").text.indexOf("Frankfurter") >= 0)
            verify(control("currencyDate").text.indexOf("2026-04-10") >= 0)
            verify(control("currencyRefreshed").text.indexOf("2026-04-15T12:34:56Z") >= 0)
        }
        function test_switching_currency_hides_previous_quote_until_current_response() {
            openCurrency()
            mouseClick(control("converterKey_1"))
            mouseClick(control("converterKey_0"))
            compare(control("converterValue2").text, "12.5")
            quote("GBP", "USD", 1.5, 350)
            selectCurrency("converterUnit1", "GBP")
            compare(control("converterValue2").text, "—", "Old pair is unavailable while the new pair loads")
            mouseClick(control("converterKey_2"))
            compare(control("converterValue1").text, "2", "Changing source currency starts a fresh entry")
            compare(control("converterValue2").text, "—", "An edit must not expose a previous pair's ratio")
            tryCompare(control("converterValue2"), "text", "3")
        }
        function test_first_catalog_failure_shows_attempt_time_and_recovers() {
            testCurrencySource.setResponse("currencies", "", 10, false)
            navigate("mode_currency")
            tryCompare(control("currencyStatus"), "text", chinese ? "刷新失败，请重试。" : "Refresh failed. Try again.")
            compare(control("converterValue2").text, "—")
            verify(control("currencyRefreshed").text.indexOf("2026-04-15T12:34:56Z") >= 0,
                   "Failed catalog download still reports the last refresh attempt")
            testCurrencySource.setResponse("currencies", JSON.stringify([
                {iso_code: "EUR", name: "Euro", symbol: "€"}, {iso_code: "USD", name: "US Dollar", symbol: "$"},
                {iso_code: "GBP", name: "Pound Sterling"}
            ]))
            mouseClick(control("currencyRefresh"))
            tryCompare(control("converterUnit1"), "count", 3)
            mouseClick(control("converterKey_clear"))
            keyClick("8")
            tryCompare(control("converterValue2"), "text", "10")
        }
        function test_runtime_translation_theme_and_currency_input_are_retained() {
            openCurrency()
            mouseClick(control("converterKey_clear"))
            keyClick("1")
            keyClick("0")
            navigate("settingsButton")
            mouseClick(control("language_zh-CN"))
            mouseClick(control("theme_dark"))
            navigate("mode_currency")
            tryCompare(control("converterValue2"), "text", "12.5")
            compare(control("pageTitle").text, "货币")
            compare(control("currencySource").text, "Frankfurter · 每日参考汇率")
            compare(control("currencyRefresh").text, "刷新汇率")
            verify(control("currencyDate").text.indexOf("数据日期：") === 0)
            verify(application.color.r < 0.25)
            navigate("settingsButton")
            mouseClick(control("language_system"))
            mouseClick(control("theme_system"))
        }
        function test_finite_quote_with_unrepresentable_amount_has_explicit_recovery() {
            quote("EUR", "USD", 1e308)
            openCurrency()
            mouseClick(control("converterKey_clear"))
            keyClick("9")
            keyClick("9")
            compare(control("converterValue2").text, "—")
            verify(!control("converterValue2").enabled, "An unavailable result cannot become numeric input")
            compare(control("converterStatus").text, chinese ? "无法显示结果" : "Result cannot be displayed")
            quote("EUR", "USD", 0.5)
            mouseClick(control("currencyRefresh"))
            tryCompare(control("converterValue2"), "text", "4.5")
            verify(!control("converterStatus").visible, "A usable refreshed quote clears the conversion error")
            keyClick(Qt.Key_Escape)
            compare(control("converterValue1").text, "0")
            compare(control("converterValue2").text, "0")
            verify(!control("converterStatus").visible)
        }
        function test_manual_refresh_changes_rate_date_and_attempt_time_without_blocking_input() {
            openCurrency()
            mouseClick(control("converterKey_clear"))
            keyClick("1")
            keyClick("0")
            quote("EUR", "USD", 1.5, 600, "2026-04-14")
            testCurrencySource.setNow("2026-04-16T09:00:00Z")
            mouseClick(control("currencyRefresh"))
            compare(control("currencyStatus").text, chinese ? "正在刷新…" : "Refreshing…")
            keyClick("2")
            compare(control("converterValue1").text, "102", "Editing continues during download")
            tryCompare(control("converterValue2"), "text", "153")
            verify(control("currencyDate").text.indexOf("2026-04-14") >= 0)
            verify(control("currencyRefreshed").text.indexOf("2026-04-16T09:00:00Z") >= 0)
            navigate("mode_standard")
            quote("EUR", "USD", 2, 10, "2026-04-15")
            navigate("mode_currency")
            tryCompare(control("converterValue2"), "text", "204", 5000, "Re-entering automatically refreshes")
        }
        function test_out_of_order_pair_and_refresh_responses_cannot_replace_current_quote() {
            openCurrency()
            mouseClick(control("converterKey_clear"))
            keyClick("1")
            keyClick("0")
            quote("EUR", "GBP", 9, 800, "2026-04-01")
            selectCurrency("converterUnit2", "GBP")
            quote("EUR", "USD", 2, 400, "2026-04-02")
            selectCurrency("converterUnit2", "USD")
            quote("GBP", "USD", 1.5, 10, "2026-04-13")
            selectCurrency("converterUnit1", "GBP")
            tryCompare(control("converterValue2"), "text", "15")
            wait(850)
            compare(control("converterValue2").text, "15")
            verify(control("currencyDate").text.indexOf("2026-04-13") >= 0)
            quote("GBP", "USD", 7, 600, "2026-04-01")
            mouseClick(control("currencyRefresh"))
            quote("GBP", "USD", 2, 10, "2026-04-14")
            mouseClick(control("currencyRefresh"))
            tryCompare(control("converterValue2"), "text", "20")
            wait(650)
            compare(control("converterValue2").text, "20")
            verify(control("currencyDate").text.indexOf("2026-04-14") >= 0)
            testCurrencySource.setResponse("rates?base=EUR&quotes=USD", "", 600, false)
            testCurrencySource.setResponse("rates?base=GBP&quotes=USD", "", 600, false)
            restartApplication()
            keyClick("1")
            keyClick("0")
            selectCurrency("converterUnit1", "GBP")
            compare(control("converterValue2").text, "20", "Stale asynchronous replies cannot contaminate the disk cache")
            verify(control("currencyDate").text.indexOf("2026-04-14") >= 0)
        }
        function test_invalid_or_missing_quote_never_becomes_a_conversion_data() {
            const good = {date: "2026-04-10", base: "EUR", quote: "USD", rate: 1.25}
            function changed(key, value) { const row = Object.assign({}, good); row[key] = value; return JSON.stringify([row]) }
            return [
                {tag: "missing-pair", body: "[]"},
                {tag: "malformed-json", body: "{"},
                {tag: "wrong-shape", body: JSON.stringify(good)},
                {tag: "null-row", body: "[null]"},
                {tag: "duplicate-pair", body: JSON.stringify([good, good])},
                {tag: "wrong-base", body: changed("base", "GBP")},
                {tag: "wrong-quote", body: changed("quote", "GBP")},
                {tag: "invalid-date", body: changed("date", "2026-02-30")},
                {tag: "no-date", body: changed("date", null)},
                {tag: "timestamp-instead-of-date", body: changed("date", "2026-04-10T00:00:00Z")},
                {tag: "zero", body: changed("rate", 0)},
                {tag: "negative", body: changed("rate", -1)},
                {tag: "null-rate", body: changed("rate", null)},
                {tag: "string-rate", body: changed("rate", "1.25")},
                {tag: "boolean-rate", body: changed("rate", true)},
                {tag: "non-finite", body: '[{"date":"2026-04-10","base":"EUR","quote":"USD","rate":1e400}]'},
                {tag: "network-error", body: "", success: false}
            ]
        }
        function test_invalid_or_missing_quote_never_becomes_a_conversion(data) {
            testCurrencySource.setResponse("rates?base=EUR&quotes=USD", data.body, 10, data.success !== false)
            navigate("mode_currency")
            tryCompare(control("converterUnit1"), "count", 3)
            const message = data.success === false ? (chinese ? "刷新失败，请重试。" : "Refresh failed. Try again.")
                : (chinese ? "此货币对暂无有效汇率，请重试。" : "No valid quote for this currency pair. Try again.")
            tryCompare(control("currencyStatus"), "text", message)
            mouseClick(control("converterKey_clear"))
            keyClick("8")
            compare(control("converterValue1").text, "8")
            compare(control("converterValue2").text, "—")
            verify(!control("converterValue2").enabled)
            verify(control("currencyDate").text.indexOf("2026-04-15") < 0, "Download date never becomes observation date")
            quote("EUR", "USD", 1.25)
            mouseClick(control("currencyRefresh"))
            tryCompare(control("converterValue2"), "text", "10")
        }
        function test_catalog_validation_and_retry_data() {
            return [
                {tag: "empty", body: "[]"},
                {tag: "object", body: '{}'},
                {tag: "invalid-iso", body: '[{"iso_code":"eur","name":"Euro"}]'},
                {tag: "missing-name", body: '[{"iso_code":"EUR"}]'},
                {tag: "duplicate", body: '[{"iso_code":"EUR","name":"Euro"},{"iso_code":"EUR","name":"Euro"}]'}
            ]
        }
        function test_catalog_validation_and_retry(data) {
            testCurrencySource.setResponse("currencies", data.body)
            navigate("mode_currency")
            tryCompare(control("currencyStatus"), "text", chinese ? "刷新失败，请重试。" : "Refresh failed. Try again.")
            compare(control("converterUnit1").count, 0, "Never substitute a built-in static currency list")
            compare(control("converterValue2").text, "—")
            testCurrencySource.setResponse("currencies", '[{"iso_code":"EUR","name":"Euro"},{"iso_code":"USD","name":"US Dollar"}]')
            mouseClick(control("currencyRefresh"))
            tryCompare(control("converterUnit1"), "count", 2)
            keyClick("4")
            tryCompare(control("converterValue2"), "text", "5")
        }
        function test_reverse_same_currency_and_input_limits_use_real_converter() {
            openCurrency()
            mouseClick(control("converterValue2"))
            keyClick("2")
            keyClick("5")
            compare(control("converterValue2").text, "25")
            compare(control("converterValue1").text, "20", "Reverse amount uses the reciprocal of the validated rate")
            quote("USD", "USD", 1)
            selectCurrency("converterUnit1", "USD")
            tryCompare(control("converterValue1"), "text", "25")
            mouseClick(control("converterKey_clear"))
            for (const digit of "1234567890123456") keyClick(digit)
            compare(control("converterValue2").text, "123,456,789,012,345")
            compare(control("converterStatus").text, chinese ? "最多输入 15 位数字" : "Maximum 15 digits")
            keyClick(Qt.Key_Backspace)
            compare(control("converterValue2").text, "12,345,678,901,234")
            keyClick(Qt.Key_Escape)
            for (const digit of "0.50") keyClick(digit)
            compare(control("converterValue2").text, "0.50")
            compare(control("converterValue1").text, "0.5")
            verify(!control("converterKey_negate").visible)
            keyClick("-")
            compare(control("converterValue2").text, "0.50")
        }
        function test_background_quote_preserves_shared_category_input_and_unit_choices() {
            openCurrency()
            keyClick("1")
            keyClick("0")
            quote("EUR", "USD", 2, 700)
            mouseClick(control("currencyRefresh"))
            navigate("mode_length")
            // Real unit selectors: metres -> centimetres.
            const first = control("converterUnit1"), second = control("converterUnit2")
            first.forceActiveFocus()
            keyClick(Qt.Key_Home)
            for (let row = 0; row < first.indexOfValue(34); ++row) keyClick(Qt.Key_Down)
            second.forceActiveFocus()
            keyClick(Qt.Key_Home)
            for (let row = 0; row < second.indexOfValue(30); ++row) keyClick(Qt.Key_Down)
            compare(control("converterValue1").text, "10")
            compare(control("converterValue2").text, "1,000")
            wait(750)
            compare(control("converterUnit1").currentValue, 34)
            compare(control("converterUnit2").currentValue, 30)
            compare(control("converterValue1").text, "10")
            compare(control("converterValue2").text, "1,000")
            navigate("mode_currency")
            tryCompare(control("converterValue2"), "text", "20")
            navigate("mode_length")
            compare(control("converterUnit1").currentValue, 34)
            compare(control("converterUnit2").currentValue, 30)
            compare(control("converterValue1").text, "10")
            compare(control("converterValue2").text, "1,000")
        }
        function paste(text) {
            clipboardProvider.visible = true
            clipboardProvider.text = text
            clipboardProvider.forceActiveFocus()
            keyClick(Qt.Key_A, Qt.ControlModifier)
            keyClick(Qt.Key_C, Qt.ControlModifier)
            clipboardProvider.visible = false
            control("converterValue1").forceActiveFocus()
            keyClick(Qt.Key_V, Qt.ControlModifier)
        }
        function test_clipboard_rejects_negative_malformed_input_and_copies_current_amount() {
            openCurrency()
            paste("-2.5")
            compare(control("converterStatus").text, chinese ? "货币金额不能为负值" : "Currency amount cannot be negative")
            paste("1.2abc")
            compare(control("converterStatus").text, chinese ? "无效输入" : "Invalid input")
            paste("12.50")
            compare(control("converterValue1").text, "12.50")
            compare(control("converterValue2").text, "15.625")
            mouseClick(control("converterValue2"))
            keyClick(Qt.Key_C, Qt.ControlModifier)
            clipboardProvider.text = ""
            clipboardProvider.visible = true
            clipboardProvider.forceActiveFocus()
            keyClick(Qt.Key_V, Qt.ControlModifier)
            compare(clipboardProvider.text, "15.625")
            clipboardProvider.visible = false
            navigate("settingsButton")
            for (const key of ["9", ".", Qt.Key_Backspace, Qt.Key_Escape]) keyClick(key)
            navigate("mode_currency")
            compare(control("converterValue1").text, "12.50", "Hidden page shortcuts do not change currency entry")
            compare(control("converterValue2").text, "15.625")
        }
        function contrastRatio(a, b) {
            function channel(c) { return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4) }
            function luminance(c) { return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b) }
            const x = luminance(a), y = luminance(b)
            return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05)
        }
        function test_layout_keyboard_focus_and_readable_status_data() {
            return [{tag: "narrow", width: 320, height: 640}, {tag: "wide", width: 900, height: 640},
                {tag: "narrow-unsaved", width: 320, height: 640, unsaved: true}]
        }
        function test_layout_keyboard_focus_and_readable_status(data) {
            openCurrency()
            if (data.unsaved) {
                verify(testCurrencySource.setCacheWritable(false))
                mouseClick(control("currencyRefresh"))
                tryCompare(control("currencyCache"), "text", chinese ? "汇率无法保存，离线数据可能较旧。" : "Rates could not be saved. Offline data may be older.")
                verify(testCurrencySource.setCacheWritable(true))
            } else {
                testCurrencySource.setResponse("rates?base=EUR&quotes=USD", "", 10, false)
                mouseClick(control("currencyRefresh"))
                tryCompare(control("currencyStatus"), "text", chinese ? "刷新失败，请重试。" : "Refresh failed. Try again.")
            }
            verify(control("currencyCache").visible)
            application.width = data.width
            application.height = data.height
            mouseClick(control("converterKey_clear"))
            for (const digit of "123456789012345") keyClick(digit)
            verify(waitForPolish(application))
            const names = ["converterValue1", "converterUnit1", "converterValue2", "converterUnit2", "currencyRefresh",
                "converterKey_clear", "converterKey_backspace", "converterKey_7", "converterKey_8", "converterKey_9",
                "converterKey_4", "converterKey_5", "converterKey_6", "converterKey_1", "converterKey_2", "converterKey_3",
                "converterKey_0", "converterKey_decimal"]
            control(names[0]).forceActiveFocus(Qt.TabFocusReason)
            for (let index = 0; index < names.length; ++index) {
                const item = control(names[index])
                if (index > 0) keyClick(Qt.Key_Tab)
                tryCompare(item, "activeFocus", true)
                verify(item.visualFocus, "Visible keyboard focus: " + names[index])
                verify(item.Accessible.name.length > 0)
                const point = item.mapToItem(application.contentItem, 0, 0)
                verify(item.visible && item.enabled && item.width >= 44 && item.height >= 32)
                verify(point.x >= 0 && point.x + item.width <= application.width + 1, names[index] + " fits width")
                verify(point.y >= 40 && point.y + item.height <= application.height + 1, names[index] + " fits height")
            }
            for (const name of ["currencySource", "currencyDate", "currencyRefreshed", "currencyStatus", "currencyCache"]) {
                const label = control(name), point = label.mapToItem(application.contentItem, 0, 0)
                verify(point.y + label.height <= application.height + 1, name + " fits height")
                verify(contrastRatio(label.color, application.color) >= 4.5, name + " text has 4.5:1 contrast")
            }
            if (data.width > 600)
                verify(control("converterValue1").width >= application.width * 0.45 && control("converterValue1").width <= application.width * 0.55)
            waitForRendering(application.contentItem)
            const scheme = application.color.r < 0.5 ? "dark" : "light"
            grabImage(application.contentItem).save("currency-" + scheme + "-" + (chinese ? "zh-CN" : "en-US") + "-" + data.tag + ".png")
        }
        function test_service_currency_symbols_are_visible_beside_amounts() {
            openCurrency()
            mouseClick(control("converterKey_clear"))
            keyClick("1")
            keyClick("0")
            compare(control("converterValue1").contentItem.text, "€ 10")
            compare(control("converterValue2").contentItem.text, "$ 12.5")
        }
        function test_corrupt_or_missing_cache_has_no_offline_quote_data() {
            const good = {version: 1, source: "https://api.frankfurter.dev/v2/",
                currencies: [{iso_code: "EUR", name: "Euro"}, {iso_code: "USD", name: "US Dollar"}],
                observations: [{base: "EUR", quote: "USD", date: "2026-04-10", rate: 1.25, refreshedAt: "2026-04-15T12:34:56Z"}]}
            function changed(field, value) {
                const fixture = JSON.parse(JSON.stringify(good))
                fixture.observations[0][field] = value
                return JSON.stringify(fixture)
            }
            return [
                {tag: "missing", contents: null},
                {tag: "truncated", contents: '{"version":1,"currencies":['},
                {tag: "wrong-shape", contents: "[]"},
                {tag: "unknown-version", contents: JSON.stringify(Object.assign({}, good, {version: 2}))},
                {tag: "wrong-source", contents: JSON.stringify(Object.assign({}, good, {source: "other-provider"}))},
                {tag: "invalid-catalog", contents: JSON.stringify(Object.assign({}, good, {currencies: [{iso_code: "eur", name: "Euro"}]}))},
                {tag: "unknown-pair", contents: changed("quote", "GBP")},
                {tag: "invalid-date", contents: changed("date", "2026-02-30")},
                {tag: "invalid-refresh", contents: changed("refreshedAt", "yesterday")},
                {tag: "zero-rate", contents: changed("rate", 0)},
                {tag: "negative-rate", contents: changed("rate", -1)},
                {tag: "string-rate", contents: changed("rate", "1.25")},
                {tag: "duplicate-observation", contents: JSON.stringify(Object.assign({}, good, {observations: [good.observations[0], good.observations[0]]}))}
            ]
        }
        function test_corrupt_or_missing_cache_has_no_offline_quote(data) {
            testCurrencySource.reset()
            if (data.contents !== null) testCurrencySource.writeCacheFixture(data.contents)
            restartApplication()
            navigate("mode_currency")
            tryCompare(control("currencyStatus"), "text", chinese ? "刷新失败，请重试。" : "Refresh failed. Try again.")
            keyClick("8")
            compare(control("converterValue2").text, "—")
            verify(!control("converterValue2").enabled)
            verify(!control("currencyCache").visible)
            compare(control("currencyDate").text, chinese ? "暂无数据日期" : "No observation date")
        }
        function test_invalid_refresh_and_unfinished_file_preserve_complete_cache_across_reopen() {
            openCurrency()
            testCurrencySource.setResponse("rates?base=EUR&quotes=USD", '[{"base":"GBP","quote":"USD","date":"2026-04-14","rate":9}]')
            mouseClick(control("currencyRefresh"))
            tryCompare(control("currencyStatus"), "text", chinese ? "此货币对暂无有效汇率，请重试。" : "No valid quote for this currency pair. Try again.")
            testCurrencySource.writeCacheFixture('{"version":1,"currencies":[', true)
            testCurrencySource.setResponse("rates?base=EUR&quotes=USD", "", 500, false)
            restartApplication()
            keyClick("8")
            compare(control("converterValue2").text, "10")
            verify(control("currencyDate").text.indexOf("2026-04-10") >= 0)
            verify(control("currencyCache").visible)
            // A catalog entry without an observation must remain unavailable.
            testCurrencySource.setResponse("rates?base=GBP&quotes=USD", "", 10, false)
            selectCurrency("converterUnit1", "GBP")
            tryCompare(control("currencyStatus"), "text", chinese ? "刷新失败，请重试。" : "Refresh failed. Try again.")
            compare(control("converterValue2").text, "—")
            compare(control("currencyDate").text, chinese ? "暂无数据日期" : "No observation date")
            verify(!control("currencyCache").visible)
        }
        function restartApplication() {
            application.close()
            application.destroy()
            application = null
            wait(0)
            application = windowFactory.createObject(null)
            verify(application !== null)
            application.requestActivate()
            tryCompare(application, "active", true)
        }
        function test_failed_atomic_save_keeps_previous_disk_observation_and_reports_unsaved_rate() {
            openCurrency()
            keyClick("8")
            compare(control("converterValue2").text, "10")
            verify(testCurrencySource.setCacheWritable(false))
            quote("EUR", "USD", 1.5, 10, "2026-04-14")
            mouseClick(control("currencyRefresh"))
            tryCompare(control("converterValue2"), "text", "12")
            verify(control("currencyCache").visible)
            compare(control("currencyCache").text, chinese ? "汇率无法保存，离线数据可能较旧。" : "Rates could not be saved. Offline data may be older.")
            verify(testCurrencySource.setCacheWritable(true))
            testCurrencySource.setResponse("rates?base=EUR&quotes=USD", "", 600, false)
            restartApplication()
            keyClick("8")
            compare(control("converterValue2").text, "10", "Failed replacement preserves the last complete disk cache")
            verify(control("currencyDate").text.indexOf("2026-04-10") >= 0)
        }
        function test_returning_to_cached_pair_keeps_its_date_and_converts_during_offline_refresh() {
            openCurrency()
            quote("EUR", "GBP", 0.8, 10, "2026-04-09")
            selectCurrency("converterUnit2", "GBP")
            tryVerify(function() { return control("currencyDate").text.indexOf("2026-04-09") >= 0 })
            testCurrencySource.setResponse("rates?base=EUR&quotes=USD", "", 600, false)
            selectCurrency("converterUnit2", "USD")
            mouseClick(control("converterKey_clear"))
            keyClick("8")
            compare(control("converterValue2").text, "10", "Selected pair's saved rate is usable during refresh")
            verify(control("currencyDate").text.indexOf("2026-04-10") >= 0)
            verify(control("currencyCache").visible)
            compare(control("currencyCache").text, chinese ? "正在使用缓存汇率" : "Using cached rates")
            tryCompare(control("currencyStatus"), "text", chinese ? "刷新失败，请重试。" : "Refresh failed. Try again.")
            compare(control("converterValue2").text, "10")
            verify(control("currencyCache").visible)
            quote("EUR", "USD", 1.5, 10, "2026-04-14")
            mouseClick(control("currencyRefresh"))
            tryCompare(control("converterValue2"), "text", "12")
            verify(!control("currencyCache").visible, "A fresh observation is distinct from cache fallback")
        }
        function test_refresh_failure_preserves_last_valid_session_observation() {
            openCurrency()
            keyClick("8")
            compare(control("converterValue2").text, "10")
            testCurrencySource.setNow("2026-04-16T13:00:00Z")
            testCurrencySource.setResponse("rates?base=EUR&quotes=USD", "", 10, false)
            mouseClick(control("currencyRefresh"))
            tryCompare(control("currencyStatus"), "text", chinese ? "刷新失败，请重试。" : "Refresh failed. Try again.")
            compare(control("converterValue2").text, "10")
            verify(control("currencyDate").text.indexOf("2026-04-10") >= 0)
            verify(control("currencyRefreshed").text.indexOf("2026-04-16T13:00:00Z") >= 0)
            selectCurrency("converterUnit1", "GBP")
            tryCompare(control("converterValue2"), "text", "12", 5000, "New pair uses its own observation")
        }
        function test_delayed_catalog_response_cannot_replace_new_catalog_request() {
            testCurrencySource.setResponse("currencies", "[]", 900)
            navigate("mode_currency")
            compare(control("converterValue2").text, "—")
            testCurrencySource.setResponse("currencies", '[{"iso_code":"EUR","name":"Euro"},{"iso_code":"USD","name":"US Dollar"}]')
            mouseClick(control("currencyRefresh"))
            tryCompare(control("converterUnit1"), "count", 2)
            keyClick("8")
            tryCompare(control("converterValue2"), "text", "10")
            wait(950)
            compare(control("converterUnit1").count, 2)
            compare(control("converterValue2").text, "10")
            compare(control("currencyStatus").text, chinese ? "已更新" : "Up to date")
        }
        function test_service_catalog_without_preferred_defaults_is_usable_data() {
            return [
                {tag: "alternate-pair", catalog: [{iso_code: "AUD", name: "Australian Dollar"}, {iso_code: "JPY", name: "Japanese Yen"}],
                    base: "AUD", target: "JPY", rate: 100, expected: "200"},
                {tag: "single-current-currency", catalog: [{iso_code: "JPY", name: "Japanese Yen"}],
                    base: "JPY", target: "JPY", rate: 1, expected: "2"}
            ]
        }
        function test_service_catalog_without_preferred_defaults_is_usable(data) {
            testCurrencySource.setResponse("currencies", JSON.stringify(data.catalog))
            quote(data.base, data.target, data.rate)
            navigate("mode_currency")
            tryCompare(control("converterUnit1"), "count", data.catalog.length)
            verify(control("converterUnit1").currentText.indexOf(data.base) === 0)
            verify(control("converterUnit2").currentText.indexOf(data.target) === 0)
            keyClick("2")
            tryCompare(control("converterValue2"), "text", data.expected)
        }
        function test_currency_output_retains_reference_fifteen_decimal_places() {
            quote("EUR", "USD", 0.123456789012345)
            openCurrency()
            mouseClick(control("converterKey_clear"))
            keyClick("1")
            compare(control("converterValue2").text, "0.123456789012345",
                    "Pinned currency formatting keeps 15 decimal places before trimming trailing zeroes")
        }
        function test_currency_navigation_has_real_converter_input() {
            navigate("mode_currency")
            compare(control("pageTitle").text, Qt.locale().name.indexOf("zh") === 0 ? "货币" : "Currency")
            mouseClick(control("converterKey_clear"))
            mouseClick(control("converterKey_1"))
            compare(control("converterValue1").text, "1")
        }
        function cleanup() {
            testCurrencySource.setCacheWritable(true)
            clipboardProvider.visible = false
            navigate("mode_standard")
            application.close()
            application.destroy()
            application = null
        }
    }
}
