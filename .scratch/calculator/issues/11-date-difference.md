# 11: 计算两个日期的差值

**What to build:** 用户可从导航进入日期计算，选择两个日期并查看符合参考规则的差值结果。

**Blocked by:** 01: 运行真实核心驱动的标准计算器。

**Status:** resolved

**Spec:** Windows 11 风格跨平台计算器。

**User stories:** 32, 34。

- [x] 提供真实日期计算入口和起止日期选择，输入变化后更新差值与必要说明，不使用静态示例结果。
- [x] 结果的单位、组合格式及同日和反向日期处理以固定参考版本为准，不能自行将所有日期差简化为近似月数或年数。
- [x] 正确处理跨月、跨年与闰日；使用日历日期语义，避免因时区或夏令时将一天误计为不同天数。
- [x] 无效或超出支持范围的日期有明确且可恢复的状态，日期控件不允许不可解释的输入。
- [x] 日期页面沿用 Fluent 风格、主题和可翻译文案，键盘可操作日期控件，宽窄窗口均可访问结果和输入。
- [x] 从界面选择日期并验证同日、反向、跨月、跨年和闰年差值；使用固定日期数据，不依赖测试运行当天。

## Ticket 11 implementation evidence

Implementation is limited to date difference. Independent integration closure evidence follows below.

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
- `git diff --check` passes. The checkout started exactly at integration tip `d327f2de0e09bca87e02416e42374db91a506883`; pre-report merge checks reported Already up to date. These implementation checks were followed by the independent integration review below.

## Integration completion and acceptance

Merged `dacc9431f33903727201e8b97de0e251b3dd6167` into the clean `integration/calculator` checkout with `git merge --no-ff`, producing merge commit `4611465b237adfcc53b3f57197c5b28884def550`. Both the prior integration tip `a08e249eda7ab4cabf68f9ec58d403fd661e3f63` and the ticket commit remain ancestors. CMake and Chinese-translation conflicts were resolved by preserving both the existing memory feature and the new date feature; every pre-merge translation remains intact. No older shell replaced the integrated application.

Independent merger review verified all six criteria against the production date controller, calendar controls, pinned reference behavior, and real-QML acceptance cases. Gregorian calendar dates, normalized reverse order, complete years/months/weeks/days, supported-range guards and recoverable year entry satisfy the date semantics. Keyboard selection/focus, live English/Chinese translation, both themes, and narrow/wide/enlarged-text layouts satisfy the interface criteria. The fixed-date UI cases cover same day, reversed dates, month/year boundaries, leap centuries, clipped month ends, DST dates and the full supported range.

The merge exposed an arithmetic-memory connection warning when loading the non-arithmetic date page. Commit `6e56828` fixes this by allowing the dynamic `Connections` target to expose different signal sets. A real-QML date-navigation regression first failed on the `onMemoryRequested` warning, then passed after the fix. The full final log contains no such warning; existing memory operations and restart checks still pass.

Validation on the merged Linux x86_64 / Qt 6.12 Debug source:

- `cmake -S . -B .build-integration -G 'Unix Makefiles' -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON` and `cmake --build .build-integration -j2`: passed; production app and UI tests linked. Final build log: `.build-integration/merge-11-build-fixed.log`.
- `cmake --build .build-integration --target calculator_ui_qmllint -j2`: passed without warnings; `.build-integration/merge-11-lint-fixed.log`.
- `ctest --test-dir .build-integration --output-on-failure -j2`: **19/19 passed**, **1,256.60 seconds**, exit 0. Each English/light, English/dark and Chinese/light configuration passed **298 application / 35 Programmer-bit / 20 history / 21 memory / 28 date outcomes**, with zero failures/skips. Isolation and memory/history/preferences restart checks also passed. Summary: `.build-integration/merge-11-ctest.log`; frozen details: `.build-integration/merge-11-LastTest.log`.
- `TZ=America/New_York python3 tests/run-ui-isolated.py .build-integration/calculator_ui_tests -input tests/date DateDifference::test_fixed_calendar_cases:dst-forward DateDifference::test_fixed_calendar_cases:dst-backward`: **4 passed / 0 failed / 0 skipped**, including setup/cleanup. Both DST transitions remain exactly one calendar day; `.build-integration/merge-11-dst.log`.
- Reviewed integration-generated light/English and dark/Chinese calendar captures, both narrow pages, a wide page and an enlarged-text Chinese page. Dates, result units, selected-day text and focus remain readable. These are offscreen content-area checks, not native-platform rendering claims.
- Every GUI check used `tests/run-ui-isolated.py` with offscreen/software/compose/generic, private settings/cache/data/runtime roots and a fresh private Linux D-Bus. Active process environments independently confirmed absent desktop/IME selectors and task-owned bus sockets. No active-desktop activation or host IME access was used.
- The initial integration matrix was deliberately interrupted after identifying the connection warning; the complete final matrix above supersedes it. The warning regression's red/green logs are `.build-integration/merge-11-memory-connection-red.log` and `merge-11-memory-connection-green.log`.
- Merge ancestry, preserved translations, `git diff --check`, unchanged parent spec and an empty index were verified. Closure edits affect only this ticket; no push, PR or deployment occurred.

Independent merge review found no remaining ticket 11 blocker. Known offscreen size-hint and existing Copy-shortcut warnings remain; their behavior checks pass. Windows/macOS builds and native platform rendering are unverified. The final application-wide review remains part of the parent workflow. Ticket 11 is resolved on the evidence above.
