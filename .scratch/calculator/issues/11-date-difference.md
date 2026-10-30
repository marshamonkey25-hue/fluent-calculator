# 11: 计算两个日期的差值

**What to build:** 用户可从导航进入日期计算，选择两个日期并查看符合参考规则的差值结果。

**Blocked by:** 01: 运行真实核心驱动的标准计算器。

**Status:** ready-for-agent

**Spec:** Windows 11 风格跨平台计算器。

**User stories:** 32, 34。

- [x] 提供真实日期计算入口和起止日期选择，输入变化后更新差值与必要说明，不使用静态示例结果。
- [x] 结果的单位、组合格式及同日和反向日期处理以固定参考版本为准，不能自行将所有日期差简化为近似月数或年数。
- [x] 正确处理跨月、跨年与闰日；使用日历日期语义，避免因时区或夏令时将一天误计为不同天数。
- [x] 无效或超出支持范围的日期有明确且可恢复的状态，日期控件不允许不可解释的输入。
- [x] 日期页面沿用 Fluent 风格、主题和可翻译文案，键盘可操作日期控件，宽窄窗口均可访问结果和输入。
- [x] 从界面选择日期并验证同日、反向、跨月、跨年和闰年差值；使用固定日期数据，不依赖测试运行当天。

## Ticket 11 implementation evidence (merge validation pending)

Implementation is limited to date difference. Status remains `ready-for-agent` for the integration reviewer.

- `qml/DatePage.qml` preserves the pinned stacked Difference between dates / From / To / Difference layout; `qml/DatePicker.qml` provides real, keyboard-accessible calendar popups with selectable month, year and day, focus restoration, and a recoverable inline year-range error. Date text wraps at larger font sizes. Navigation, recent-mode preference, live translation and the existing semantic theme palette are reused.
- `app/DateCalculation.*` uses Gregorian `QDate` calendar arithmetic over 1601-01-01 through 9999-12-31. ISO date strings cross the QML boundary; dates are never converted through timestamps. Reverse order is normalized; complete years, months, weeks and remaining days are shown in that order, with total days shown only when the breakdown includes larger units. Equal dates show the pinned Same dates wording. Native setters reject invalid/noncanonical/out-of-range dates; calendar controls prevent selecting impossible dates.
- Behavioral sources: pinned `Calculator.ViewModels/Common/DateCalculator.cs`, `Calculator.ViewModels/DateCalculatorViewModel.cs`, `Calculator/Views/DateCalculator.xaml` and `.xaml.cs`, `Calculator.Tests/DateCalculatorTests.cs`, and English/Chinese `Resources.resw` at revision `79e1ac53bba690cdf930e5dcd6ed9dbc4cbfb128`. The existing upstream MIT license and notice are retained; the calendar adapter records its source. From/To translations use the pinned 开始日期/结束日期 labels. The supported locale defaults use the reference comma-plus-space list separator.
- Agreed seam: real QML navigation and date-control mouse/keyboard events, the production Qt controller and visible result/state. No core/controller mocks, private-method assertions or alternate test calculations are used. `tests/date/tst_date_difference.qml` is registered for English/light, English/dark and Chinese/light with the shared isolated launcher, as a separate suite following existing history/bit-suite registration.

TDD was executed vertically, one new failing behavior then its minimal implementation:

| Cycle | Observed red | Green change |
| --- | --- | --- |
| 1 | Navigation lacked Date calculation. | Register the date page with initial real calendar dates and the same-date result. |
| 2 | Date buttons did not open a calendar. | Add real month/year/day selection; fixed 2024-02-28 and leap-day selection updates the visible result. |
| 3 | 2008-02-29 → 2008-03-31 displayed only 31 days. | Show 1 month, 2 days plus 31 days, with the same positive result after reversing dates. |
| 4 | Invalid-year entry lacked an inline explanation. | Explain 1601–9999, disable invalid-date selection and recover to a valid year through keyboard input. |
| 5 | A selected date was truncated at 320 px with a 22 px font. | Wrap the date-button label and retain accessible input/result bounds. |
| 6 | Light calendar surface check failed; the screenshot showed dark Fluent assets behind black text. | Use semantic palette backgrounds for the popup/year/month fields. The final pixel assertion samples the application image at mapped control coordinates, avoiding Qt's popup-child capture-coordinate issue. |
| 7 | The selected day had only 1.80:1 text contrast in the dark theme. | Bind the day label to the existing `highlightedText` palette role. Both light/dark contrast rows now pass; the month chevron also follows the foreground palette. |

Additional fixed-date regression rows cover same/reversed dates, month/year boundaries, leap/non-leap centuries, clipped month ends, weeks/days, both DST transitions, 9999 upper-bound cases and the full supported range. The independently known full-range total is 3,067,670 days. Both DST cases also pass with the test process's `TZ=America/New_York`. Runtime English/Chinese and dark/light/system setting changes preserve selected dates and recompute translated displays. Narrow 320×460, wide 900×700 and larger-text 320×560 layouts are exercised.

Qt API documentation was checked with the `find-docs` Context7 workflow (Qt 6.8 docs for `QDate::daysTo/addYears/addMonths` and `MonthGrid`/`DayOfWeekRow`). No documentation fallback was required. UI guidance used the verified Fluent 2 style and keyboard-focus/date-format search results; the pinned Microsoft layout remains the design baseline.

Validation uses the private `.build-ticket11` Debug/Make directory with `-j2` compilation. All GUI processes use compose/generic/offscreen/software, fresh private D-Bus and isolated settings/cache/data/runtime roots through `tests/run-ui-isolated.py`. No native desktop activation, remote push, PR or deployment was performed. Windows/macOS and native platform rendering remain unverified. Final matrix results follow.


Final validation on Linux x86_64 / Qt 6.12:

- `cmake --build .build-ticket11 -j2` builds the production application and real-QML test executable; `cmake --build .build-ticket11 --target calculator_ui_qmllint -j2` completes without warnings. Final rebuild/lint logs: `.build-ticket11/build-final.log`, `qmllint-final.log`.
- `ctest --test-dir .build-ticket11 --output-on-failure -j2`: **15/15 pass**, 1048.86 seconds. Each locale/theme reports 298 main UI outcomes, 35 bit-operation outcomes, 20 history outcomes and 26 date outcomes, with zero failures/skips; isolation and restart entries also pass. Full evidence is preserved in `.build-ticket11/ctest-final.log` and `ctest-full-details.log`.
- After the final local date-label/chevron palette correction, rebuilt and ran `ctest --test-dir .build-ticket11 --output-on-failure -j2 -R "^calculator-date-"`: **3/3 pass**, **28 passed / 0 failed / 0 skipped per configuration**, 188.73 seconds. This includes both selected-day contrast rows in every configuration. Evidence: `.build-ticket11/ctest-date-final.log`, `Testing/Temporary/LastTest.log` and `green7.log`; cycle reds/greens remain in `red1.log` through `red7.log` and the corresponding green logs.
- Both fixed DST transition rows also pass with `TZ=America/New_York`; see `.build-ticket11/timezone-dst.log`. Reviewed final offscreen light/dark calendar captures, translated page captures, narrow/wide captures and larger text. Dark selected-day text and light calendar surfaces are readable after the palette corrections.
- Earlier tool-limited direct runs and an interrupted initial full run are retained as non-passing evidence; the completed full matrix and final affected-suite rerun supersede them. No acceptance checks were skipped.
- `git diff --check` passes. The checkout started exactly at integration tip `d327f2de0e09bca87e02416e42374db91a506883`; pre-report merge checks reported Already up to date. Independent integration review remains required before changing this ticket's Status.
