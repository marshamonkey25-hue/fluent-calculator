import QtQuick
import QtTest
import Calculator

Item {
    MainWindow { id: application; systemPreferences: testSystemPreferences }
    TestCase {
        name: "DateAddSubtract"
        when: windowShown && application.visible

        readonly property bool chinese: Qt.locale().name.indexOf("zh") === 0

        function initTestCase() {
            application.requestActivate()
            tryCompare(application, "active", true)
        }

        function selectMode(mode) {
            mouseClick(findChild(application.contentItem, "navigationButton"))
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            mouseClick(findChild(drawer.contentItem, "mode_" + mode))
            tryCompare(drawer, "visible", false)
        }

        function init() {
            selectMode("standard")
            selectMode("date")
        }

        function setChoice(name, value) {
            const control = findChild(application.contentItem, name)
            verify(control !== null, "Date mode offers " + name)
            control.forceActiveFocus(Qt.TabFocusReason)
            keyClick(value > 500 ? Qt.Key_End : Qt.Key_Home)
            if (value > 500) {
                for (let i = 999; i > value; --i) keyClick(Qt.Key_Up)
            } else {
                for (let i = 0; i < value; ++i) keyClick(Qt.Key_Down)
            }
            compare(control.currentIndex, value)
        }

        function chooseDate(pickerName, date) {
            const picker = findChild(application.contentItem, pickerName)
            verify(picker !== null, "Date mode offers " + pickerName)
            mouseClick(picker)
            const popup = findChild(picker, "dateCalendar")
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

        function test_add_month_clips_to_leap_day() {
            setChoice("dateCalculationOption", 1)
            chooseDate("startDatePicker", "2008-01-31")
            setChoice("dateMonthsOffset", 1)
            compare(findChild(application.contentItem, "dateOffsetResult").text,
                    chinese ? "2008年2月29日星期五" : "Friday, February 29, 2008")
        }

        function test_subtract_mixed_units_uses_days_then_months_then_years() {
            setChoice("dateCalculationOption", 1)
            chooseDate("startDatePicker", "2020-03-31")
            setChoice("dateYearsOffset", 1)
            setChoice("dateMonthsOffset", 1)
            setChoice("dateDaysOffset", 1)
            const subtract = findChild(application.contentItem, "dateSubtractOption")
            verify(subtract !== null, "User can choose subtraction")
            mouseClick(subtract)
            compare(findChild(application.contentItem, "dateOffsetResult").text,
                    chinese ? "2019年2月28日星期四" : "Thursday, February 28, 2019")
        }

        function test_out_of_range_result_is_explained_and_recovers() {
            setChoice("dateCalculationOption", 1)
            chooseDate("startDatePicker", "9999-12-30")
            setChoice("dateDaysOffset", 2)
            const result = findChild(application.contentItem, "dateOffsetResult")
            compare(result.text, chinese ? "超出日期" : "Date out of Bound")
            setChoice("dateDaysOffset", 1)
            compare(result.text, chinese ? "9999年12月31日星期五" : "Friday, December 31, 9999")
        }

        function openSettings() {
            mouseClick(findChild(application.contentItem, "navigationButton"))
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            mouseClick(findChild(drawer.contentItem, "settingsButton"))
            tryCompare(drawer, "visible", false)
        }

        function test_runtime_translation_preserves_offset_controls_and_result() {
            setChoice("dateCalculationOption", 1)
            chooseDate("startDatePicker", "2020-02-29")
            setChoice("dateYearsOffset", 1)
            openSettings()
            mouseClick(findChild(application.contentItem, "language_zh-CN"))
            selectMode("date")
            compare(findChild(application.contentItem, "dateCalculationOption").displayText, "添加或减去天数")
            compare(findChild(application.contentItem, "dateAddOption").text, "添加")
            compare(findChild(application.contentItem, "dateSubtractOption").text, "减去")
            for (const field of [["dateYearsOffset", "年"], ["dateMonthsOffset", "月"], ["dateDaysOffset", "天"]])
                compare(findChild(application.contentItem, field[0]).Accessible.name, field[1])
            compare(findChild(application.contentItem, "dateOffsetResult").text, "2021年2月28日星期日")
            openSettings()
            mouseClick(findChild(application.contentItem, "language_en-US"))
            selectMode("date")
            compare(findChild(application.contentItem, "dateCalculationOption").displayText, "Add or subtract days")
            compare(findChild(application.contentItem, "dateOffsetResult").text, "Sunday, February 28, 2021")
            openSettings()
            mouseClick(findChild(application.contentItem, "language_system"))
            selectMode("date")
        }

        function test_date_surfaces_follow_theme_data() {
            return [{tag: "light", theme: "light"}, {tag: "dark", theme: "dark"}]
        }

        function test_date_surfaces_follow_theme(data) {
            setChoice("dateCalculationOption", 1)
            chooseDate("startDatePicker", "2008-01-31")
            setChoice("dateMonthsOffset", 1)
            openSettings()
            mouseClick(findChild(application.contentItem, "theme_" + data.theme))
            selectMode("date")
            verify(waitForPolish(application))
            const image = grabImage(application.contentItem)
            image.save("date-offset-" + data.theme + ".png")
            for (const name of ["dateCalculationOption", "dateYearsOffset", "dateMonthsOffset", "dateDaysOffset"]) {
                const control = findChild(application.contentItem, name)
                const point = control.mapToItem(application.contentItem, control.width - 12, control.height - 6)
                const brightness = image.red(point.x, point.y)
                verify(data.theme === "light" ? brightness > 180 : brightness < 100,
                        name + " visible surface follows " + data.theme + ": " + brightness)
            }
            openSettings()
            mouseClick(findChild(application.contentItem, "theme_system"))
            selectMode("date")
        }

        function test_combo_indicators_have_visible_contrast() {
            setChoice("dateCalculationOption", 1)
            openSettings()
            mouseClick(findChild(application.contentItem, "theme_light"))
            selectMode("date")
            verify(waitForPolish(application))
            const image = grabImage(application.contentItem)
            for (const name of ["dateCalculationOption", "dateYearsOffset", "dateMonthsOffset", "dateDaysOffset"]) {
                const control = findChild(application.contentItem, name)
                const indicator = control.indicator
                const point = indicator.mapToItem(application.contentItem, 0, 0)
                let darkest = 255
                for (let y = 0; y < indicator.height; ++y)
                    for (let x = 0; x < indicator.width; ++x)
                        darkest = Math.min(darkest, image.red(point.x + x, point.y + y))
                verify(darkest < 140, name + " has a visible light-theme dropdown indicator: " + darkest)
            }
            openSettings()
            mouseClick(findChild(application.contentItem, "theme_system"))
            selectMode("date")
        }

        function test_offset_controls_fit_window_data() {
            return [
                {tag: "narrow", width: 320, height: 460, fontSize: 14},
                {tag: "wide", width: 900, height: 700, fontSize: 14},
                {tag: "large-text", width: 320, height: 560, fontSize: 22}
            ]
        }

        function test_offset_controls_fit_window(data) {
            application.width = data.width
            application.height = data.height
            application.font.pixelSize = data.fontSize
            setChoice("dateCalculationOption", 1)
            chooseDate("startDatePicker", "2024-09-25")
            setChoice("dateYearsOffset", 999)
            verify(waitForPolish(application))
            for (const name of ["dateCalculationOption", "startDatePicker", "dateAddOption", "dateSubtractOption",
                                "dateYearsOffset", "dateMonthsOffset", "dateDaysOffset", "dateOffsetResult"]) {
                const control = findChild(application.contentItem, name)
                verify(control.visible, name + " is visible")
                const point = control.mapToItem(application.contentItem, 0, 0)
                verify(point.x >= 0 && point.x + control.width <= application.width, name + " horizontal bounds")
                verify(point.y >= 0 && point.y + control.height <= application.height, name + " vertical bounds")
                if (name.indexOf("Offset") !== -1 || name === "dateCalculationOption")
                    verify(!control.contentItem || !control.contentItem.truncated, name + " text is fully readable")
            }
            grabImage(application.contentItem).save("date-offset-" + data.tag + ".png")
            application.font.pixelSize = 14
            application.width = 360
            application.height = 560
        }

        function test_reference_calendar_cases_data() {
            // Pinned DateCalculatorTests.cs and independent Gregorian calendar facts.
            return [
                {tag: "zero-add", start: "2024-02-29", en: "Thursday, February 29, 2024", zh: "2024年2月29日星期四"},
                {tag: "zero-subtract", start: "2024-02-29", subtract: true, en: "Thursday, February 29, 2024", zh: "2024年2月29日星期四"},
                {tag: "clipped-year", start: "2020-02-29", years: 1, en: "Sunday, February 28, 2021", zh: "2021年2月28日星期日"},
                {tag: "subtract-leap-year", start: "2020-02-29", years: 1, subtract: true, en: "Thursday, February 28, 2019", zh: "2019年2月28日星期四"},
                {tag: "century-not-leap", start: "2096-02-29", years: 4, en: "Sunday, February 28, 2100", zh: "2100年2月28日星期日"},
                {tag: "cross-year-add", start: "2023-12-31", days: 1, en: "Monday, January 1, 2024", zh: "2024年1月1日星期一"},
                {tag: "cross-year-subtract", start: "2024-01-01", days: 1, subtract: true, en: "Sunday, December 31, 2023", zh: "2023年12月31日星期日"},
                {tag: "add-order-clips-year-before-month", start: "2020-02-29", years: 1, months: 1, days: 1, en: "Monday, March 29, 2021", zh: "2021年3月29日星期一"},
                {tag: "pinned-add-month-and-days", start: "2008-03-31", months: 1, days: 10, en: "Saturday, May 10, 2008", zh: "2008年5月10日星期六"},
                {tag: "pinned-add-clipped-month-and-days", start: "2008-01-31", months: 1, days: 10, en: "Monday, March 10, 2008", zh: "2008年3月10日星期一"},
                {tag: "pinned-subtract-month", start: "2008-03-31", months: 1, subtract: true, en: "Friday, February 29, 2008", zh: "2008年2月29日星期五"},
                {tag: "pinned-subtract-days-before-month", start: "2008-03-10", months: 1, days: 10, subtract: true, en: "Tuesday, January 29, 2008", zh: "2008年1月29日星期二"},
                {tag: "pinned-subtract-nonleap", start: "2007-03-10", months: 1, days: 10, subtract: true, en: "Sunday, January 28, 2007", zh: "2007年1月28日星期日"},
                {tag: "months-over-twelve", start: "2023-01-31", months: 13, en: "Thursday, February 29, 2024", zh: "2024年2月29日星期四"},
                {tag: "days-are-not-a-year", start: "2023-03-01", days: 365, en: "Thursday, February 29, 2024", zh: "2024年2月29日星期四"},
                {tag: "dst-forward-add", start: "2019-03-10", days: 1, en: "Monday, March 11, 2019", zh: "2019年3月11日星期一"},
                {tag: "dst-backward-subtract", start: "2019-11-04", days: 1, subtract: true, en: "Sunday, November 3, 2019", zh: "2019年11月3日星期日"},
                {tag: "maximum-years-offset", start: "9000-01-01", years: 999, en: "Friday, January 1, 9999", zh: "9999年1月1日星期五"},
                {tag: "maximum-years-subtract", start: "2600-01-01", years: 999, subtract: true, en: "Monday, January 1, 1601", zh: "1601年1月1日星期一"},
                {tag: "maximum-months-offset", start: "2000-01-31", months: 999, en: "Friday, April 30, 2083", zh: "2083年4月30日星期五"},
                {tag: "maximum-days-offset", start: "2000-01-01", days: 999, en: "Thursday, September 26, 2002", zh: "2002年9月26日星期四"}
            ]
        }

        function test_reference_calendar_cases(data) {
            setChoice("dateCalculationOption", 1)
            chooseDate("startDatePicker", data.start)
            setChoice("dateYearsOffset", data.years || 0)
            setChoice("dateMonthsOffset", data.months || 0)
            setChoice("dateDaysOffset", data.days || 0)
            if (data.subtract) {
                const subtract = findChild(application.contentItem, "dateSubtractOption")
                subtract.forceActiveFocus(Qt.TabFocusReason)
                keyClick(Qt.Key_Space)
            }
            compare(findChild(application.contentItem, "dateOffsetResult").text, chinese ? data.zh : data.en)
        }

        function test_range_limits_recover_data() {
            return [
                {tag: "upper-years", start: "9999-12-31", field: "dateYearsOffset", en: "Friday, December 31, 9999", zh: "9999年12月31日星期五"},
                {tag: "upper-months", start: "9999-12-31", field: "dateMonthsOffset", en: "Friday, December 31, 9999", zh: "9999年12月31日星期五"},
                {tag: "upper-days", start: "9999-12-31", field: "dateDaysOffset", en: "Friday, December 31, 9999", zh: "9999年12月31日星期五"},
                {tag: "lower-years", start: "1601-01-01", subtract: true, field: "dateYearsOffset", en: "Monday, January 1, 1601", zh: "1601年1月1日星期一"},
                {tag: "lower-months", start: "1601-01-01", subtract: true, field: "dateMonthsOffset", en: "Monday, January 1, 1601", zh: "1601年1月1日星期一"},
                {tag: "lower-days", start: "1601-01-01", subtract: true, field: "dateDaysOffset", en: "Monday, January 1, 1601", zh: "1601年1月1日星期一"}
            ]
        }

        function test_range_limits_recover(data) {
            setChoice("dateCalculationOption", 1)
            chooseDate("startDatePicker", data.start)
            if (data.subtract) mouseClick(findChild(application.contentItem, "dateSubtractOption"))
            setChoice(data.field, 1)
            const result = findChild(application.contentItem, "dateOffsetResult")
            compare(result.text, chinese ? "超出日期" : "Date out of Bound")
            setChoice(data.field, 0)
            compare(result.text, chinese ? data.zh : data.en)
        }

        function test_switch_functions_keeps_independent_inputs_and_keyboard_order() {
            chooseDate("fromDatePicker", "2024-12-31")
            chooseDate("toDatePicker", "2025-01-01")
            const option = findChild(application.contentItem, "dateCalculationOption")
            mouseClick(option)
            tryCompare(option.popup, "opened", true)
            keyClick(Qt.Key_Down)
            keyClick(Qt.Key_Return)
            tryCompare(option.popup, "visible", false)
            compare(option.currentIndex, 1)
            verify(!findChild(application.contentItem, "fromDatePicker").visible)
            verify(!findChild(application.contentItem, "dateDifferenceResult").visible)
            chooseDate("startDatePicker", "2008-01-31")
            setChoice("dateMonthsOffset", 1)
            setChoice("dateCalculationOption", 0)
            verify(!findChild(application.contentItem, "startDatePicker").visible)
            verify(!findChild(application.contentItem, "dateOffsetResult").visible)
            compare(findChild(application.contentItem, "dateDifferenceResult").text, chinese ? "1 天" : "1 day")
            chooseDate("toDatePicker", "2025-01-02")
            compare(findChild(application.contentItem, "dateDifferenceResult").text, chinese ? "2 天" : "2 days")
            setChoice("dateCalculationOption", 1)
            compare(findChild(application.contentItem, "dateOffsetResult").text,
                    chinese ? "2008年2月29日星期五" : "Friday, February 29, 2008")
            const years = findChild(application.contentItem, "dateYearsOffset")
            years.forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_Tab)
            verify(findChild(application.contentItem, "dateMonthsOffset").activeFocus)
            keyClick(Qt.Key_Tab)
            verify(findChild(application.contentItem, "dateDaysOffset").activeFocus)
            keyClick(Qt.Key_End)
            compare(findChild(application.contentItem, "dateDaysOffset").currentIndex, 999)
            keyClick(Qt.Key_Down)
            compare(findChild(application.contentItem, "dateDaysOffset").currentIndex, 999)
            keyClick(Qt.Key_Home)
            keyClick(Qt.Key_Up)
            compare(findChild(application.contentItem, "dateDaysOffset").currentIndex, 0)
        }

        function test_offset_popup_follows_theme_data() {
            return [{tag: "light", theme: "light"}, {tag: "dark", theme: "dark"}]
        }

        function test_offset_popup_follows_theme(data) {
            setChoice("dateCalculationOption", 1)
            openSettings()
            mouseClick(findChild(application.contentItem, "theme_" + data.theme))
            selectMode("date")
            const control = findChild(application.contentItem, "dateYearsOffset")
            mouseClick(control)
            tryCompare(control.popup, "opened", true)
            verify(waitForPolish(application))
            const image = grabImage(application.contentItem)
            image.save("date-offset-popup-" + data.theme + ".png")
            const point = control.popup.background.mapToItem(application.contentItem,
                    control.popup.background.width - 8, control.popup.background.height - 8)
            const brightness = image.red(point.x, point.y)
            verify(data.theme === "light" ? brightness > 180 : brightness < 100,
                    "Offset popup visibly follows " + data.theme + ": " + brightness)
            keyClick(Qt.Key_Escape)
            tryCompare(control.popup, "visible", false)
            openSettings()
            mouseClick(findChild(application.contentItem, "theme_system"))
            selectMode("date")
        }

        function test_result_uses_localized_long_date_with_weekday() {
            setChoice("dateCalculationOption", 1)
            chooseDate("startDatePicker", "2024-02-29")
            compare(findChild(application.contentItem, "dateOffsetResult").text,
                    chinese ? "2024年2月29日星期四" : "Thursday, February 29, 2024")
            compare(findChild(application.contentItem, "startDatePicker").text,
                    chinese ? "2024年2月29日" : "February 29, 2024")
        }

        function cleanup() {
            for (const name of ["dateCalculationOption", "dateYearsOffset", "dateMonthsOffset", "dateDaysOffset"]) {
                const control = findChild(application.contentItem, name)
                if (control && control.popup.visible) {
                    control.popup.close()
                    tryCompare(control.popup, "visible", false)
                }
            }
            application.font.pixelSize = 14
            application.width = 360
            application.height = 560
        }

        function cleanupTestCase() { application.close() }
    }
}
