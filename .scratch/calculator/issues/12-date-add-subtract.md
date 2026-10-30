# 12: 对日期增加或减少年月日

**What to build:** 用户在日期计算中选择起始日期、增加或减少以及年月日数量，得到可核对的目标日期。

**Blocked by:** 11: 计算两个日期的差值。

**Status:** ready-for-agent

**Spec:** Windows 11 风格跨平台计算器。

**User stories:** 33, 34。

- [ ] 日期模式可切换到年月日增减功能，选择起始日期、方向和各项数量后计算真实目标日期。
- [ ] 年、月、日的应用顺序、月底调整、闰日和跨年规则遵循固定参考版本，不能用固定天数替代所有月份或年份。
- [ ] 零增减、多个单位同时变化和减少日期均有明确结果，超出支持范围的请求不会产生错误日期或崩溃。
- [ ] 在日期差与日期增减功能之间切换时，控件及结果与当前功能一致，能够继续正常输入。
- [ ] 新增控件和结果沿用主题、翻译、日期显示与键盘规则，在合理窗口尺寸下保持可用。
- [ ] 通过界面操作验证月底、闰年、跨年、混合年月日、零值、减少及越界恢复，预期日期来自参考行为或独立日历事实。


## Ticket 12 implementation evidence

Status remains ready-for-agent for independent merge validation. Only ticket 12 is implemented by this change; the parent spec and other tickets are unchanged.

- `qml/DatePage.qml` extends the existing date page with the pinned function selector, a separate From calendar for date adjustments, Add/Subtract radio controls, Years/Months/Days dropdowns with the reference 0–999 range, and a live resulting-date label. Results use locale-aware long-date formatting, including weekdays for English and Simplified Chinese; picker date formatting stays unchanged. The existing difference inputs and adjustment inputs remain independent when switching functions. Navigation, the date-picker keyboard behavior, locale formatting and semantic palettes are reused. Selector labels translate without replacing the selection model, preserving the selected function across runtime language changes.
- `app/DateCalculation.*` retains Gregorian calendar dates as ISO strings at the QML boundary. Addition applies years → months → days; subtraction applies days → months → years, clipping absent dates to the destination month end at each calendar step. This follows pinned `Calculator.ViewModels/Common/DateCalculator.cs` AddDuration/SubtractDuration, `DateCalculatorViewModel.cs`, `Calculator/Views/DateCalculator.xaml`, and `Calculator.Tests/DateCalculatorTests.cs` at revision `79e1ac53bba690cdf930e5dcd6ed9dbc4cbfb128`. The adapter's source attribution and existing MIT notices remain intact.
- The supported date range remains 1601-01-01 through 9999-12-31. Invalid/noncanonical dates, invalid offset ranges and out-of-range results are rejected. The UI shows the pinned English/Chinese range message instead of a stale/incorrect date; changing the offset restores a valid result. Months and years are calendar operations, never fixed day counts or JavaScript date arithmetic.
- New strings are marked for translation and translated in `resources/ui/zh-CN.json`, using pinned date-control wording where available. The shared inline date dropdown uses palette-based arrow strokes and popup surfaces so light/dark themes stay readable under the isolated generic platform theme. Visible labels, accessible names and keyboard traversal accompany each new control.
- The primary approved seam is the real QML application: mouse/keyboard events through navigation, calendars, dropdowns, radio buttons and settings, with assertions on visible results, state and rendered surfaces. `tests/date/tst_date_add_subtract.qml` is discovered by the existing date-suite CTest entries in English/light, English/dark and Chinese/light. No controller/core mocks, private-method assertions, alternate date algorithms or network dependencies are introduced.

TDD proceeded one vertical behavior at a time:

| Cycle | Observed red | Minimal green change |
| --- | --- | --- |
| 1 | Date mode lacked the function selector. | Add the selector, start calendar, offsets and real calendar addition; 2008-01-31 + one month is 2008-02-29. |
| 2 | No subtraction choice existed. | Add Subtract and reverse the calendar operation order; 2020-03-31 minus one year/month/day is 2019-02-28. |
| 3 | An upper-range request rendered an empty result. | Validate the supported range and display Date out of Bound; reducing the offset recovers to 9999-12-31. |
| 4 | Runtime Chinese selection reset the function and lacked new translations. | Keep a stable numeric selector model and translate its displayed labels, controls and result without losing dates/offsets. |
| 5 | Light dropdown arrows sampled at brightness 244 and were nearly invisible. | Draw the arrows with the existing foreground palette role. |
| 6 | The light offset popup sampled at brightness 55, showing black text on a dark surface. | Bind date dropdown popup backgrounds to semantic base/mid palette roles. |
| 7 | The result showed February 29, 2024 without the reference long-date weekday. | Add a separate QLocale long-date result formatter, verified as Thursday, February 29, 2024 / 2024年2月29日星期四; retain picker formatting. |

Evidence is preserved in the private `.build-ticket12` directory: `red1.log`/`green1.log`, `red2.log`/`green2.log`, `red3.log`/`green3.log`, `red4.log`/`green4.log`, `red5-indicator.log`/`green5.log`, `popup-check.log`/`green6.log`, and `red7.log`/`green7-en.log`/`green7-zh.log`. The translation test was corrected to assert the visible displayText after the stable numeric model replaced translated model strings. An initial screenshot synchronization attempt timed out waiting for an already-rendered frame; the final test polishes layout and captures the application image directly. These harness corrections are not claimed as product regressions.

Additional UI coverage includes zero changes in both directions, leap-day/year/month clipping, non-leap centuries, cross-year changes, mixed units, the pinned add/subtract examples, months above twelve, 365 days versus a calendar year, 999 for every offset unit, upper/lower range errors and recovery for every unit, function switching with independent state, keyboard input limits and tab order, live Chinese/English translation, both themes, and narrow 320×460 / wide 900×700 / enlarged-text 320×560 layouts. Expected dates are pinned examples or independent Gregorian calendar facts. Literal weekday fixtures were cross-checked with Python datetime, independently of the production Qt formatter. The dedicated long-date test asserts the known Thursday for 2024-02-29 in both locales and separately checks that the picker still omits the weekday. Offscreen screenshot review confirms readable popup surfaces, arrows, selected values, large text and results.

Qt APIs were verified with the required find-docs Context7 library resolution and Qt 6.8 documentation for QDate addYears/addMonths clipping ComboBox displayText/activation behavior, and QLocale long-date formatting; no fallback was needed. The UI/UX skill's form-label and visible-focus recommendations were applied to the existing pinned layout rather than generating a new design.

Validation uses the private `.build-ticket12` Debug/Make build with `-j2`. All GUI checks use `tests/run-ui-isolated.py`: offscreen/software/compose/generic, fresh private D-Bus and isolated settings/cache/data/runtime roots, with desktop/IME selectors removed before QGuiApplication. No active-desktop GUI, host IME access, remote push, PR or deployment was used. Windows/macOS and native platform rendering remain unverified. The complete pre-long-date matrix passed 26/26 entries in 1783.04 seconds. The display-only long-date correction is followed by the affected date/theme/language and preference-restart checks; final results follow below. This separates broad regression evidence from checks against the final formatter. Locale-specific punctuation and weekday placement follow Qt locale data, preserving the pinned long-date intent without claiming identical Windows locale data or retail pixels.


Final implementation validation on Linux x86_64 / Qt 6.12:

- `cmake -S . -B .build-ticket12 -G 'Unix Makefiles' -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON` and `cmake --build .build-ticket12 -j2` pass, building both the production application and real-QML tests. Final source build evidence: `.build-ticket12/build7.log`; initial configuration: `configure.log`.
- `cmake --build .build-ticket12 --target calculator_ui_qmllint -j2` passes without warnings; `qmllint-final.log`.
- Before the display-only long-date correction, `ctest --test-dir .build-ticket12 --output-on-failure -j2` passed **26/26 entries**, **1783.04 seconds**. Each English/light, English/dark and Chinese/light configuration passed 298 application, 35 Programmer-bit, 45 Length, 45 graphing, 20 history, 21 memory and 70 date outcomes, with zero failures/skips; isolation and all four restart entries passed. Frozen evidence: `ctest-full.log` and `ctest-pre-longdate-details.log`.
- After the long-date formatter and weekday fixtures landed, `ctest --test-dir .build-ticket12 --output-on-failure -j2 -R '^calculator-(date-|preferences-restart$)'` passed **4/4 entries**, **366.16 seconds**. Every date configuration passed **71 outcomes / 0 failures / 0 skips**: 43 date-adjustment outcomes and 28 existing date-difference outcomes. This includes fixed English/Chinese weekdays, unchanged picker formatting, runtime language/theme changes, all calendar/range cases and all window-size rows. The preference restart stages passed too. Final evidence: `ctest-final-affected.log` and `ctest-final-affected-details.log`.
- `TZ=America/New_York python3 ../tests/run-ui-isolated.py ./calculator_ui_tests -input ../tests/date DateAddSubtract::test_reference_calendar_cases:dst-forward-add DateAddSubtract::test_reference_calendar_cases:dst-backward-subtract` from the private build passed **4 outcomes / 0 failures / 0 skips**, including setup/cleanup. Both adjustments remain one civil calendar day across the DST transitions; `timezone-dst.log`.
- Reviewed the final offscreen long-date result in English/dark and Chinese/light, including enlarged text, plus both popup palettes and visible dropdown arrows. Automatic narrow/wide/enlarged-text layout checks pass. Qt locale punctuation and weekday order are reported as Qt rendering of the pinned long-date intent, not Windows locale-data or retail-pixel identity.
- The checkout started exactly at integration tip `2cbc82c3e9bc0139063f7ca8c78b2c333662071c`. Repeated pre-report `git merge integration/calculator` checks reported Already up to date; integration ancestry is preserved. `git diff --check` passes. The parent spec, other tickets, global configuration and existing modules outside the necessary date/translation seams are unchanged.

No ticket 12 implementation blocker remains. Independent review/merge validation still owns checklist closure and the status change. Existing offscreen size-hint and Copy-shortcut warnings remain, with their behavior checks passing. Windows/macOS and native platform rendering remain unverified under the user's isolated-testing constraint. No remote push, PR, deployment, active-desktop window or host IME operation was performed.
