import QtQuick
import QtTest
import Calculator

Item {
    MainWindow { id: application; systemPreferences: testSystemPreferences }
    TestCase {
        name: "DateDifference"
        when: windowShown && application.visible

        function initTestCase() {
            application.requestActivate()
            tryCompare(application, "active", true)
        }

        function selectMode(mode) {
            mouseClick(findChild(application.contentItem, "navigationButton"))
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            const entry = findChild(drawer.contentItem, "mode_" + mode)
            verify(entry !== null, "Navigation contains " + mode)
            mouseClick(entry)
            tryCompare(drawer, "visible", false)
        }

        function selectDateMode() {
            selectMode("standard")
            selectMode("date")
        }

        function test_date_navigation_opens_from_to_and_same_date_result() {
            selectDateMode()
            verify(findChild(application.contentItem, "fromDatePicker") !== null)
            verify(findChild(application.contentItem, "toDatePicker") !== null)
            compare(findChild(application.contentItem, "dateDifferenceResult").text,
                    Qt.locale().name.indexOf("zh") === 0 ? "相同日期" : "Same dates")
            compare(findChild(application.contentItem, "dateDifferenceDays").text, "")
        }

        function chooseDate(pickerName, date) {
            const picker = findChild(application.contentItem, pickerName)
            mouseClick(picker)
            const popup = findChild(picker, "dateCalendar")
            verify(popup !== null, "Date button opens a calendar")
            tryCompare(popup, "opened", true)
            const year = findChild(popup.contentItem, "calendarYear")
            mouseClick(year)
            keyClick(Qt.Key_A, Qt.ControlModifier)
            for (const digit of date.substring(0, 4)) keyClick(digit)
            const month = findChild(popup.contentItem, "calendarMonth")
            month.forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_Home)
            for (let i = 1; i < Number(date.substring(5, 7)); ++i) keyClick(Qt.Key_Down)
            verify(waitForPolish(application))
            const day = findChild(popup.contentItem, "dateDay_" + date)
            verify(day !== null && day.enabled, "Calendar offers " + date)
            mouseClick(day)
            tryCompare(popup, "visible", false)
        }

        function test_select_fixed_dates_updates_result() {
            selectDateMode()
            chooseDate("fromDatePicker", "2024-02-28")
            chooseDate("toDatePicker", "2024-02-28")
            compare(findChild(application.contentItem, "dateDifferenceResult").text,
                    Qt.locale().name.indexOf("zh") === 0 ? "相同日期" : "Same dates")
            chooseDate("toDatePicker", "2024-02-29")
            compare(findChild(application.contentItem, "dateDifferenceResult").text,
                    Qt.locale().name.indexOf("zh") === 0 ? "1 天" : "1 day")
            compare(findChild(application.contentItem, "dateDifferenceDays").text, "")
        }

        function test_calendar_months_and_reversed_dates_match_reference() {
            selectDateMode()
            chooseDate("fromDatePicker", "2008-02-29")
            chooseDate("toDatePicker", "2008-03-31")
            const chinese = Qt.locale().name.indexOf("zh") === 0
            compare(findChild(application.contentItem, "dateDifferenceResult").text,
                    chinese ? "1 月, 2 天" : "1 month, 2 days")
            compare(findChild(application.contentItem, "dateDifferenceDays").text,
                    chinese ? "31 天" : "31 days")
            chooseDate("fromDatePicker", "2008-03-31")
            chooseDate("toDatePicker", "2008-02-29")
            compare(findChild(application.contentItem, "dateDifferenceResult").text,
                    chinese ? "1 月, 2 天" : "1 month, 2 days")
            compare(findChild(application.contentItem, "dateDifferenceDays").text,
                    chinese ? "31 天" : "31 days")
        }

        function test_invalid_year_is_explained_and_recovers_with_keyboard() {
            selectDateMode()
            chooseDate("fromDatePicker", "2000-02-28")
            chooseDate("toDatePicker", "2000-03-01")
            const result = findChild(application.contentItem, "dateDifferenceResult")
            const before = result.text
            const picker = findChild(application.contentItem, "fromDatePicker")
            picker.forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_Space)
            const popup = findChild(picker, "dateCalendar")
            tryCompare(popup, "opened", true)
            const year = findChild(popup.contentItem, "calendarYear")
            mouseClick(year)
            keyClick(Qt.Key_A, Qt.ControlModifier)
            for (const digit of "1600") keyClick(digit)
            const error = findChild(popup.contentItem, "calendarYearError")
            verify(error !== null && error.visible, "Out-of-range year has an inline explanation")
            compare(error.text, Qt.locale().name.indexOf("zh") === 0
                ? "请输入 1601 到 9999 之间的年份。" : "Enter a year from 1601 to 9999.")
            compare(result.text, before, "Invalid edit preserves the last selected date")
            keyClick(Qt.Key_A, Qt.ControlModifier)
            keyClick(Qt.Key_Backspace)
            verify(error.visible)
            for (const digit of "2001") keyClick(digit)
            verify(!error.visible)
            verify(waitForPolish(application))
            const missingLeapDay = findChild(popup.contentItem, "dateDay_2001-02-29")
            verify(missingLeapDay === null || !missingLeapDay.enabled, "Non-leap years offer no February 29")
            const day = findChild(popup.contentItem, "dateDay_2001-02-28")
            day.forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_Space)
            tryCompare(popup, "visible", false)
            verify(picker.activeFocus, "Closing the calendar restores keyboard focus")
            verify(picker.text.indexOf("2001") !== -1)
            verify(result.text !== before)
        }

        function test_fixed_calendar_cases_data() {
            return [
                {tag: "same-fixed-date", from: "2024-02-29", to: "2024-02-29", en: "Same dates", zh: "相同日期", days: ""},
                {tag: "cross-year", from: "2023-12-31", to: "2024-01-01", en: "1 day", zh: "1 天", days: ""},
                {tag: "whole-year", from: "2023-01-01", to: "2024-01-01", en: "1 year", zh: "1 年", days: "365"},
                {tag: "leap-century", from: "2000-02-28", to: "2000-03-01", en: "2 days", zh: "2 天", days: ""},
                {tag: "nonleap-century", from: "1900-02-28", to: "1900-03-01", en: "1 day", zh: "1 天", days: ""},
                {tag: "clipped-month-end", from: "2024-01-31", to: "2024-02-29", en: "1 month", zh: "1 月", days: "29"},
                {tag: "clipped-leap-year", from: "2020-02-29", to: "2021-02-28", en: "1 year", zh: "1 年", days: "365"},
                {tag: "weeks-and-days", from: "2019-03-10", to: "2019-03-20", en: "1 week, 3 days", zh: "1 周, 3 天", days: "10"},
                {tag: "dst-forward", from: "2019-03-10", to: "2019-03-11", en: "1 day", zh: "1 天", days: ""},
                {tag: "dst-backward", from: "2019-11-03", to: "2019-11-04", en: "1 day", zh: "1 天", days: ""},
                {tag: "reverse-long-range", from: "2008-03-10", to: "2007-05-10", en: "10 months", zh: "10 月", days: "305"},
                {tag: "reference-upper-bound", from: "2008-01-31", to: "9999-12-31", en: "7991 years, 11 months", zh: "7991 年, 11 月", days: "2918987"},
                {tag: "last-year", from: "9998-12-31", to: "9999-12-31", en: "1 year", zh: "1 年", days: "365"},
                {tag: "full-supported-range", from: "1601-01-01", to: "9999-12-31", en: "8398 years, 11 months, 4 weeks, 2 days", zh: "8398 年, 11 月, 4 周, 2 天", days: "3067670"}
            ]
        }

        function test_fixed_calendar_cases(data) {
            selectDateMode()
            chooseDate("fromDatePicker", data.from)
            chooseDate("toDatePicker", data.to)
            const chinese = Qt.locale().name.indexOf("zh") === 0
            compare(findChild(application.contentItem, "dateDifferenceResult").text, chinese ? data.zh : data.en)
            compare(findChild(application.contentItem, "dateDifferenceDays").text,
                    data.days === "" ? "" : data.days + (chinese ? " 天" : " days"))
        }

        function test_date_controls_and_result_fit_window_data() {
            return [
                {tag: "narrow", width: 320, height: 460, fontSize: 14},
                {tag: "wide", width: 900, height: 700, fontSize: 14},
                {tag: "large-text", width: 320, height: 560, fontSize: 22}
            ]
        }

        function test_date_controls_and_result_fit_window(data) {
            selectDateMode()
            application.width = data.width
            application.height = data.height
            application.font.pixelSize = data.fontSize
            chooseDate("fromDatePicker", "2024-09-25")
            chooseDate("toDatePicker", "2025-12-31")
            verify(waitForPolish(application))
            for (const name of ["fromDatePicker", "toDatePicker", "dateDifferenceResult", "dateDifferenceDays"]) {
                const item = findChild(application.contentItem, name)
                verify(item.visible)
                const position = item.mapToItem(application.contentItem, 0, 0)
                verify(position.x >= 0 && position.x + item.width <= application.width, name + " horizontal bounds")
                verify(position.y >= 0 && position.y + item.height <= application.height, name + " vertical bounds")
                if (name.indexOf("Picker") !== -1) {
                    const label = findChild(item, "label")
                    verify(!label.truncated, "Selected date is fully readable with " + data.tag)
                }
            }
            const from = findChild(application.contentItem, "fromDatePicker")
            from.forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_Tab)
            verify(findChild(application.contentItem, "toDatePicker").activeFocus, "Tab follows From then To")
            const scheme = application.color.r < 0.5 ? "dark" : "light"
            grabImage(application.contentItem).save("date-" + scheme + "-" + data.tag + ".png")
            application.font.pixelSize = 14
            application.width = 360
            application.height = 560
        }

        function openSettings() {
            mouseClick(findChild(application.contentItem, "navigationButton"))
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            mouseClick(findChild(drawer.contentItem, "settingsButton"))
            tryCompare(drawer, "visible", false)
        }

        function test_runtime_language_and_theme_preserve_selected_dates() {
            selectDateMode()
            chooseDate("fromDatePicker", "2008-02-29")
            chooseDate("toDatePicker", "2008-03-31")
            openSettings()
            mouseClick(findChild(application.contentItem, "language_zh-CN"))
            mouseClick(findChild(application.contentItem, "theme_dark"))
            selectMode("date")
            compare(findChild(application.contentItem, "pageTitle").text, "日期计算")
            compare(findChild(application.contentItem, "dateDifferenceResult").text, "1 月, 2 天")
            compare(findChild(application.contentItem, "dateDifferenceDays").text, "31 天")
            const picker = findChild(application.contentItem, "fromDatePicker")
            verify(picker.text.indexOf("2008年2月29日") !== -1)
            verify(picker.palette.window.r < 0.5, "Date controls inherit the dark palette")
            grabImage(application.contentItem).save("date-runtime-dark-zh.png")
            mouseClick(picker)
            const popup = findChild(picker, "dateCalendar")
            tryCompare(popup, "opened", true)
            compare(findChild(popup.contentItem, "calendarYear").Accessible.name, "年")
            compare(findChild(popup.contentItem, "calendarMonth").Accessible.name, "月")
            grabImage(application.contentItem).save("date-calendar-dark-zh.png")
            keyClick(Qt.Key_Escape)
            tryCompare(popup, "visible", false)
            openSettings()
            mouseClick(findChild(application.contentItem, "language_en-US"))
            mouseClick(findChild(application.contentItem, "theme_light"))
            selectMode("date")
            compare(findChild(application.contentItem, "dateDifferenceResult").text, "1 month, 2 days")
            compare(findChild(application.contentItem, "dateDifferenceDays").text, "31 days")
            verify(picker.palette.window.r > 0.5, "Date controls inherit the light palette")
            mouseClick(picker)
            tryCompare(popup, "opened", true)
            compare(findChild(popup.contentItem, "calendarYear").Accessible.name, "Year")
            grabImage(application.contentItem).save("date-calendar-light-en.png")
            keyClick(Qt.Key_Escape)
            tryCompare(popup, "visible", false)
            openSettings()
            mouseClick(findChild(application.contentItem, "language_system"))
            mouseClick(findChild(application.contentItem, "theme_system"))
            selectMode("date")
        }

        function test_calendar_surfaces_follow_theme_data() {
            return [{tag: "light", theme: "light"}, {tag: "dark", theme: "dark"}]
        }

        function test_calendar_surfaces_follow_theme(data) {
            selectDateMode()
            chooseDate("fromDatePicker", "2008-02-29")
            openSettings()
            mouseClick(findChild(application.contentItem, "theme_" + data.theme))
            selectMode("date")
            const picker = findChild(application.contentItem, "fromDatePicker")
            mouseClick(picker)
            const popup = findChild(picker, "dateCalendar")
            tryCompare(popup, "opened", true)
            verify(waitForRendering(popup.contentItem))
            const image = grabImage(application.contentItem)
            for (const surface of [popup.contentItem, findChild(popup.contentItem, "calendarYear"), findChild(popup.contentItem, "calendarMonth")]) {
                const point = surface.mapToItem(application.contentItem, surface.width - 12, surface.height - 6)
                const brightness = image.red(point.x, point.y)
                verify(data.theme === "light" ? brightness > 180 : brightness < 100,
                       "Calendar surface visibly follows " + data.theme + ": " + surface.objectName + " = " + brightness)
            }
            keyClick(Qt.Key_Escape)
            tryCompare(popup, "visible", false)
            openSettings()
            mouseClick(findChild(application.contentItem, "theme_system"))
            selectMode("date")
        }

        function cleanup() {
            for (const name of ["fromDatePicker", "toDatePicker"]) {
                const picker = findChild(application.contentItem, name)
                if (picker) {
                    const popup = findChild(picker, "dateCalendar")
                    if (popup && popup.visible) {
                        popup.close()
                        tryCompare(popup, "visible", false)
                    }
                }
            }
        }

        function test_selected_calendar_day_has_readable_contrast_data() {
            return [{tag: "light", theme: "light"}, {tag: "dark", theme: "dark"}]
        }

        function test_selected_calendar_day_has_readable_contrast(data) {
            selectDateMode()
            chooseDate("fromDatePicker", "2008-02-29")
            openSettings()
            mouseClick(findChild(application.contentItem, "theme_" + data.theme))
            selectMode("date")
            const picker = findChild(application.contentItem, "fromDatePicker")
            mouseClick(picker)
            const popup = findChild(picker, "dateCalendar")
            tryCompare(popup, "opened", true)
            const day = findChild(popup.contentItem, "dateDay_2008-02-29")
            function channel(c) { return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4) }
            function luminance(c) { return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b) }
            const foreground = luminance(day.contentItem.color)
            const background = luminance(day.palette.highlight)
            const ratio = (Math.max(foreground, background) + 0.05) / (Math.min(foreground, background) + 0.05)
            verify(ratio >= 4.5, "Selected calendar day has readable contrast in " + data.theme + ": " + ratio)
            keyClick(Qt.Key_Escape)
            tryCompare(popup, "visible", false)
            openSettings()
            mouseClick(findChild(application.contentItem, "theme_system"))
            selectMode("date")
        }

        function cleanupTestCase() { application.close() }
    }
}
