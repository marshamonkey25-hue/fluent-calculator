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
        function test_recent_currency_mode_and_preferences_survive_ordinary_restart() {
            testCurrencySource.setResponse("currencies", '[{"iso_code":"EUR","name":"Euro"},{"iso_code":"USD","name":"US Dollar"}]')
            testCurrencySource.setResponse("rates?base=EUR&quotes=USD", '[{"date":"2026-04-10","base":"EUR","quote":"USD","rate":1.25}]')
            application = windowFactory.createObject(null)
            verify(application !== null)
            application.requestActivate()
            tryCompare(application, "active", true)
            if (restartStage === "write") {
                navigate("settingsButton")
                mouseClick(control("theme_dark"))
                mouseClick(control("language_zh-CN"))
                navigate("mode_currency")
                tryCompare(control("converterValue2"), "text", "0")
                mouseClick(control("converterKey_8"))
                compare(control("converterValue2").text, "10")
            } else {
                compare(restartStage, "restore")
                compare(control("pageTitle").text, "货币")
                verify(application.color.r < 0.25)
                compare(control("converterValue1").text, "0", "Amounts do not persist")
                compare(control("currencyRefresh").text, "刷新汇率")
                tryCompare(control("converterValue2"), "text", "0")
                mouseClick(control("converterKey_4"))
                compare(control("converterValue2").text, "5")
                verify(control("currencyDate").text.indexOf("2026-04-10") >= 0)
            }
        }
        function cleanupTestCase() { application.close(); application.destroy() }
    }
}
