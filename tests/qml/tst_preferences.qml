import QtQuick
import QtTest
import Calculator

Item {
    MainWindow { id: application; systemPreferences: testSystemPreferences }
    TestCase {
        name: "CalculatorPreferences"
        when: windowShown && application.visible

        function initTestCase() {
            application.requestActivate()
            tryCompare(application, "active", true)
            navigate("settingsButton")
            mouseClick(findChild(application.contentItem, "language_en-US"))
            navigate("mode_standard")
        }

        function navigate(name) {
            mouseClick(findChild(application.contentItem, "navigationButton"))
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            const target = findChild(drawer.contentItem, name)
            verify(target !== null, "Navigation entry: " + name)
            mouseClick(target)
            tryCompare(drawer, "visible", false)
        }

        function test_current_and_future_errors_follow_language_without_clearing_state() {
            navigate("mode_standard")
            for (const command of ["clear", "8", "divide", "0", "equals"])
                mouseClick(findChild(application.contentItem, "key_" + command))
            compare(findChild(application.contentItem, "resultDisplay").text, "Cannot divide by zero")
            navigate("settingsButton")
            mouseClick(findChild(application.contentItem, "language_zh-CN"))
            navigate("mode_standard")
            compare(findChild(application.contentItem, "resultDisplay").text, "除数不能为零")
            compare(findChild(application.contentItem, "errorIndicator").text, "错误")
            for (const command of ["clear", "0", "divide", "0", "equals"])
                mouseClick(findChild(application.contentItem, "key_" + command))
            compare(findChild(application.contentItem, "resultDisplay").text, "结果未定义")
            navigate("settingsButton")
            mouseClick(findChild(application.contentItem, "language_en-US"))
            navigate("mode_standard")
            compare(findChild(application.contentItem, "resultDisplay").text, "Result is undefined")
            for (const command of ["clear", "9", "divide", "3", "equals"])
                mouseClick(findChild(application.contentItem, "key_" + command))
            compare(findChild(application.contentItem, "resultDisplay").text, "3")
        }

        function test_language_changes_without_discarding_pending_calculation() {
            navigate("mode_standard")
            for (const command of ["clear", "6", "multiply"])
                mouseClick(findChild(application.contentItem, "key_" + command))
            navigate("settingsButton")
            const chinese = findChild(application.contentItem, "language_zh-CN")
            verify(chinese !== null, "Simplified Chinese is selectable")
            mouseClick(chinese)
            compare(findChild(application.contentItem, "pageTitle").text, "设置")
            compare(findChild(application.contentItem, "theme_light").text, "浅色")
            navigate("mode_standard")
            compare(findChild(application.contentItem, "pageTitle").text, "标准")
            compare(findChild(application.contentItem, "key_multiply").Accessible.name, "乘")
            mouseClick(findChild(application.contentItem, "key_7"))
            mouseClick(findChild(application.contentItem, "key_equals"))
            compare(findChild(application.contentItem, "resultDisplay").text, "42")
            compare(findChild(application.contentItem, "expressionDisplay").text, "6 × 7 =")
            navigate("settingsButton")
            mouseClick(findChild(application.contentItem, "language_en-US"))
            compare(findChild(application.contentItem, "pageTitle").text, "Settings")
        }

        function test_settings_keyboard_controls_remain_visible_data() {
            return [
                { tag: "light-English", theme: "light", language: "en-US" },
                { tag: "dark-Chinese", theme: "dark", language: "zh-CN" }
            ]
        }

        function test_settings_keyboard_controls_remain_visible(data) {
            navigate("settingsButton")
            mouseClick(findChild(application.contentItem, "theme_" + data.theme))
            mouseClick(findChild(application.contentItem, "language_" + data.language))
            waitForRendering(application.contentItem)
            application.width = 320
            application.height = 460
            const first = findChild(application.contentItem, "theme_light")
            first.forceActiveFocus(Qt.TabFocusReason)
            const names = ["theme_light", "theme_dark", "theme_system", "language_en-US", "language_zh-CN", "language_system"]
            for (let i = 0; i < names.length; ++i) {
                const control = findChild(application.contentItem, names[i])
                if (i !== 0) keyClick(Qt.Key_Tab)
                tryCompare(control, "activeFocus", true)
                waitForRendering(application.contentItem)
                const position = control.mapToItem(application.contentItem, 0, 0)
                verify(control.width >= 44 && control.height >= 44, names[i] + " has a usable size")
                verify(position.x >= 0 && position.x + control.width <= application.width, names[i] + " fits width")
                verify(position.y >= 44 && position.y + control.height <= application.height, names[i] + " stays visible when focused")
                verify(control.Accessible.name.length > 0)
            }
            const scheme = data.theme
            grabImage(application.contentItem).save("settings-" + scheme + "-narrow.png")
            application.width = 900
            application.height = 700
            waitForRendering(application.contentItem)
            verify(contrastRatio(findChild(application.contentItem, "pageTitle").color, application.color) >= 4.5,
                   "Page heading has readable contrast after layout and language changes")
            grabImage(application.contentItem).save("settings-" + scheme + "-wide.png")
            keyClick(Qt.Key_Space)
            tryCompare(findChild(application.contentItem, "language_system"), "activeFocus", true)
            application.width = 360
            application.height = 560
            navigate("mode_standard")
            navigate("settingsButton")
            mouseClick(findChild(application.contentItem, "language_en-US"))
            waitForRendering(application.contentItem)
        }

        function test_system_choices_follow_controlled_platform_and_explicit_choices_win() {
            application.systemPreferences = testSystemPreferences
            navigate("settingsButton")
            mouseClick(findChild(application.contentItem, "theme_system"))
            testSystemPreferences.setSystemTheme("dark")
            tryCompare(Application.styleHints, "colorScheme", Qt.Dark)
            mouseClick(findChild(application.contentItem, "theme_light"))
            testSystemPreferences.setSystemTheme("light")
            testSystemPreferences.setSystemTheme("dark")
            tryCompare(Application.styleHints, "colorScheme", Qt.Light)
            mouseClick(findChild(application.contentItem, "theme_system"))
            tryCompare(Application.styleHints, "colorScheme", Qt.Dark)
            mouseClick(findChild(application.contentItem, "language_system"))
            testSystemPreferences.setSystemLanguage("zh-CN")
            compare(findChild(application.contentItem, "pageTitle").text, "设置")
            waitForRendering(application.contentItem)
            mouseClick(findChild(application.contentItem, "language_en-US"))
            waitForRendering(application.contentItem)
            compare(findChild(application.contentItem, "pageTitle").text, "Settings")
            testSystemPreferences.setSystemLanguage("fr-FR")
            testSystemPreferences.setSystemLanguage("zh-CN")
            compare(findChild(application.contentItem, "pageTitle").text, "Settings")
            mouseClick(findChild(application.contentItem, "language_system"))
            compare(findChild(application.contentItem, "pageTitle").text, "设置")
            waitForRendering(application.contentItem)
            testSystemPreferences.setSystemLanguage("fr-FR")
            compare(findChild(application.contentItem, "pageTitle").text, "Settings")
            testSystemPreferences.setSystemLanguage("zh-TW")
            compare(findChild(application.contentItem, "pageTitle").text, "Settings")
            mouseClick(findChild(application.contentItem, "language_en-US"))
        }

        function contrastRatio(a, b) {
            function channel(c) { return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4) }
            function luminance(c) { return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b) }
            const x = luminance(a), y = luminance(b)
            return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05)
        }

        function test_theme_keeps_visible_headings_readable_data() {
            return [{ tag: "light", theme: "light" }, { tag: "dark", theme: "dark" }]
        }

        function test_theme_keeps_visible_headings_readable(data) {
            navigate("settingsButton")
            mouseClick(findChild(application.contentItem, "theme_" + data.theme))
            waitForRendering(application.contentItem)
            const heading = findChild(application.contentItem, "pageTitle")
            verify(contrastRatio(heading.color, application.color) >= 4.5, "Page heading has readable theme contrast")
            navigate("mode_standard")
            const result = findChild(application.contentItem, "resultDisplay")
            verify(contrastRatio(result.color, application.color) >= 4.5, "Result has readable theme contrast")
        }

        function test_user_can_switch_theme_in_settings() {
            application.requestActivate()
            tryCompare(application, "active", true)
            mouseClick(findChild(application.contentItem, "navigationButton"))
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            const settings = findChild(drawer.contentItem, "settingsButton")
            verify(settings !== null, "Settings is reachable from navigation")
            mouseClick(settings)
            tryCompare(drawer, "visible", false)
            const dark = findChild(application.contentItem, "theme_dark")
            verify(dark !== null, "Dark theme can be selected")
            mouseClick(dark)
            tryCompare(Application.styleHints, "colorScheme", Qt.Dark)
            compare(dark.checked, true)
            mouseClick(findChild(application.contentItem, "theme_light"))
            tryCompare(Application.styleHints, "colorScheme", Qt.Light)
            compare(dark.checked, false)
        }
        function cleanupTestCase() { application.close() }
    }
}
