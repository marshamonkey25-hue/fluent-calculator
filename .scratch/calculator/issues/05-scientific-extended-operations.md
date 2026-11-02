# 05: 使用科学模式的幂、对数及扩展运算

**What to build:** 用户能在科学模式中使用幂、根、指数、对数、常数、阶乘和取模等参考操作，并理解非法输入或范围错误。

**Blocked by:** 04: 使用科学模式的优先级与括号。

**Status:** resolved

**Spec:** Windows 11 风格跨平台计算器。

**User stories:** 22, 25, 26。

- [x] 对照固定源码列出并接入科学模式中本任务涵盖的幂、根、指数、对数、常数、阶乘、取模及其参考变体；三角函数和角度单位由任务 06 负责。
- [x] 各操作通过真实核心执行，显示、表达式和输入状态与操作同步更新；常数与中间结果不因界面桥接丢失原版数值能力。
- [x] 相关二级功能或切换控件使用参考交互，按钮内容与实际命令一致，不能只有标签而无对应运算。
- [x] 沿用核心指数输入、定义域、精度和范围限制；错误出现后用户能继续纠正或清空计算。
- [x] 新增操作支持参考键盘入口，沿用应用主题、可翻译文案和窗口适配规则。
- [x] 通过用户可见输入和结果验证代表性的幂根、对数、常数、阶乘、取模组合以及边界和恢复流程；必要的批量精度用例可通过核心公开命令补充，不检查私有实现。


## Implementation evidence

The implementation was submitted with `ready-for-agent` status; independent integration review and closure are recorded below.

Pinned-source inventory (revision `79e1ac53bba690cdf930e5dcd6ed9dbc4cbfb128`): `Calculator/Views/CalculatorScientificOperators.xaml` and `.xaml.cs`, `CalculatorScientificAngleButtons.xaml` and `.xaml.cs`, en-US `Resources.resw`, `Calculator.ViewModels/StandardCalculatorViewModel.cs`, and `CalcManager/Command.h`. Command names below are the real Microsoft manager commands, with their `Command` prefix omitted for readability.

| UI operation / reference variant | Core commands |
| --- | --- |
| x² / x³ | SQR / CUB |
| √x / ∛x | SQRT / CUBEROOT |
| xʸ / ʸ√x | PWR / ROOT |
| 10ˣ / 2ˣ | POW10 / POW2 |
| log / logᵧx | LOG / LogBaseY |
| ln / eˣ | LN / POWE |
| π / e | PI / Euler |
| n! / mod / 1/x / absolute value | FAC / MOD / REC / Abs |
| exp entry / F-E result format | EXP / FE |
| Function flyout | Abs / Floor / Ceil / Rand / DMS / Degrees |
| Correction / sign | CLEAR / CENTR / BACK / SIGN |

The six 2nd variants reset the toggle after selection and restore focus to it. The three-by-two Function flyout closes after selection. Reference keyboard commands (including hidden variants and the constructor's E exponent override) are exercised through actual window key events. Trigonometry and angle-unit selection remain ticket 06. `CalculationSession` restricts new Scientific-only commands to that mode and keeps operands/results as strings. No vendor algorithms changed.

The C/CE slot uses the public manager `IsInputEmpty` state, rather than display-text inference. The core ignores a leading zero, treats a decimal point as input and exposes a completed nonzero result as nonempty. CE/backspace preserve pending arithmetic. Focus/scroll changes keep the fixed expression/result visible, preserve the pinned grid, and reveal every 44×44 control at narrow sizes. Theme and runtime Chinese labels use the existing shared hooks; Settings disables all Scientific shortcuts.

TDD was performed at the approved production QML → session → real manager/CEngine/Ratpack seam, one failing external behavior test then minimal code per slice. Logs reside in private `.build-ticket05`:

- `red-01-square.log` lacked Square; `green-01-square.log` verifies 12² → 144 → √ → 12 with synchronized expressions.
- `red-02-second.log` lacked 2nd; `green-02-second.log` verifies cube/cube-root and auto reset. Stable delegates keep input/focus intact when labels change.
- `red-03-power.log` lacked power; `green-03-power.log` verifies precedence and the negative odd nth root.
- `red-04-log-exp.log` lacked all six logarithm/exponential entries; `green-04-log-exp.log` verifies independent integer identities and pinned 32-digit ln(10)/exp(2) results.
- `red-05-factorial.log` lacked factorial; `green-05-factorial.log` verifies 5! Mod 7 = 1 and reciprocal. Expression capitalization follows pinned `CEngineStrings.resw` (`Mod`).
- `red-06-constants.log` lacked constants; `green-06-constants.log` verifies full-precision π/e, π−π = 0 and ln(e) = 1.
- `red-07-correction.log` lacked dynamic CE; `green-07-correction.log` verifies the actual core input state, backspace and CE preserving 6 × 7 = 42.
- `red-08-exp-entry.log` lacked exp; `green-08-exp-entry.log` verifies four exponent digits, ignored fifth digit, sign/backspace correction and arithmetic continuation.
- `red-09-function.log` lacked Function; `green-09-function.log` verifies all six flyout operations and dismissal. Random values are checked by the public [0,1) contract, without a fixed/random mock expectation.
- `red-10-notation.log` lacked F-E; `green-10-notation.log` verifies result-format toggling, clear-entry format reset and mode return. CE retains repeat-equals behavior; the test uses an explicit addition to avoid assuming CE resets the whole calculation.
- `red-11-errors.log` exposed enabled invalid operations during seven domain/range errors; `green-11-errors.log` verifies disabled controls and successful recovery. The range case comes from pinned `CalculatorManagerTestScientific` commands13.
- `red-12-keyboard.log` exposed 22 missing accelerator behaviors; `green-12-keyboard.log` passes all 25 rows, including closed secondary/flyout controls.
- `red-13-translation.log` exposed untranslated Power; `green-13-translation.log` verifies live Chinese captions, calculation retention and live error translation.
- `red-14-focus.log` exposed missing reference focus return; `green-14-focus.log` verifies 2nd → Tab → π → Space.
- `regression-extended.log` exposed clipped narrow rows; `green-15-layout.log` verifies scroll/focus access at both sizes. `precedence-regression.log` then exposed the hidden horizontal expression viewport; `green-16-sticky-display.log` verifies expression dragging after keeping the display fixed outside the scrolling controls.

Additional regression cases cover digit/decimal/equals/backspace/Escape error recovery, direct absolute value, random keyboard entry, popup Tab/Space/Escape, hidden Settings accelerators and both themes/languages. Existing Scientific reset/layout and independent restart tests were adapted to the completed keypad behavior, with no tests skipped.

Qt API verification used the `find-docs` skill and Context7 (`library Qt`, then `/websites/doc_qt_io_qt-6` for Shortcut sequences/enabled and AbstractButton toggled); no unavailable-doc fallback. The `ui-ux-pro-max` focus-state search and desktop checklist guided keyboard focus, accessible labels, semantic palette reuse and narrow layout; the pinned Microsoft design remains the visual baseline.

- `red-17-error-notation-mode.log` reproduced F-E's UI flag being cleared while CEngine ignored FE during an error (return showed `4.2e+1` instead of `42`). `green-17-error-notation-mode.log` verifies clearing the error before resetting notation keeps the actual core format and toggle synchronized across mode changes.
- Final Scientific/restart click helpers use verified Qt `waitForPolish(window)` checks before focusing/clicking layout-dependent keys. The fresh restored Scientific page initially accepted only the last click before its Loader layout settled; `restart-polished.log` verifies all seven independent stages after fixing the test synchronization. Frame waits were removed because unchanged controls do not necessarily request another frame.
- The existing Programmer→Scientific cross-mode test also used the old always-C slot; it now sends reference Escape before its second calculation. `cross-mode-validation.log` verifies the complete integer/Scientific/Programmer round trip, with all original result assertions retained.


## Explicit shared test-isolation correction

The user's mid-run instruction assigned this ticket the shared runtime-isolation fix. `tests/run-ui-isolated.py` adapts the tested external launcher contract using Python 3.8+ standard-library subprocesses and argument lists. Every CTest entry and each restart child uses it. It forces offscreen/software, compose IME, generic platform theme and Fluent controls; removes display, IME, inherited session/accessibility-bus and legacy theme variables; creates private 0700 settings/cache/data/runtime roots; and removes them after normal exit. Linux requires `dbus-run-session` with a private socket/config and no host activation directories, with system-bus access pointed at an unavailable private path. Missing D-Bus isolation refuses to launch the child. Direct QuickTest invocation validates/re-enters the launcher before constructing QGuiApplication, including before setup callbacks. The production executable's IME configuration is unchanged.

The public subprocess boundary tests seed invalid inherited variables, verify storage permissions/cleanup and shared restart-fixture preservation, authenticate only the private D-Bus socket (no host bus query), verify direct executable bootstrap, and prove missing isolation cannot fall back to running a child. `red-18-isolation.log` lacked the launcher; `green-18-isolation.log` verifies its first environment/bus contract. `red-19-direct-isolation.log` exposed the old Qt startup path before the guard (GTK tried to initialize after display removal); `green-19-direct-isolation.log` verifies safe pre-GUI re-entry. `red-21-legacy-environment.log` exposed inherited accessibility-bus configuration; `green-21-legacy-environment.log` verifies its removal along with legacy theme overrides.

Generic Qt can ignore scheme overrides or report Unknown while changing native colors. The supervisor approved a narrow production appearance fallback through the existing preferences seam: SystemPreferences reports the raw scheme, AppPreferences resolves explicit choices and a stable Light fallback for Unknown, and MainWindow supplies inherited Fluent semantic palette roles. Ordinary native system following remains available when reported; no desktop portal/IME discovery or production IME override was added. `red-20-generic-theme.log` exposed unreadable heading contrast under generic; `green-20-generic-theme.log` verifies actual dark/light appearance. The existing preferences and independent restart tests now assert visible background/foreground/contrast and persistence, including controlled Unknown fallback, instead of unsupported Qt global hint values. No assertions or test cases were suppressed.

The final validation policy is offscreen/compose/private D-Bus only. Earlier native observations predate that user instruction and are historical evidence, not a claim of current native validation. An earlier parallel full run received an externally sent SIGTERM and was not counted as a pass. The sequential isolated runs and their durable exit records distinguish normal passing exits from those interruptions. Narrow-layout checks poll unchanged geometry bounds after focus/resize layout settles; the initial dark run exposed an immediate-snapshot race in both the new and older Scientific geometry checks, which are retained with bounded waits.


Final source audit: pinned `OperatorsPanel.xaml.cs:EnsureScientificOps` caches the Scientific operator control, and its 2nd toggle is reset only by secondary selection. `red-22-second-navigation.log` reproduced losing an unused selection across Standard→Scientific navigation; `green-22-second-navigation.log` verifies session-owned UI state retains it, executes the actual cube operation, then resets the toggle. Ordinary restart still creates fresh session state. This adds one UI case to the final combined suite (255 outcomes per theme/language configuration).


Final validation: private Debug/Make `.build-ticket05`, Linux x86_64, Qt 6.12/GCC 16.2, compilation `-j2`. `python3 tests/run-ui-isolated.py ctest --test-dir .build-ticket05 -j1 -V --output-on-failure` exited **0**, all **5/5** entries passing. Each of English/light, English/dark and Chinese/light reports **255 passed, 0 failed, 0 skipped**; process isolation has **3 passed**, and all **7** independent restart stages pass. The final durable record is `.build-ticket05/ctest-final-checked.log` and `.exit` (0). Full configurations completed in 186.67s, 171.11s and 180.54s; total 545.49s. QML lint is warning-free (`lint-second-navigation.log`), and `git diff --check` passes. Final screenshot review used only offscreen rendering, including Chinese/light narrow layout and dark secondary controls. All final test processes used compose/generic/offscreen/software, private storage/runtime and private Linux D-Bus; no final native desktop validation. Windows/macOS are unverified. The inherited Standard Copy shortcut warning is unchanged; clipboard tests pass.

Immediately before committing, integration/calculator was still `06ffcdfa4f0006ba36496e6210bd870b2fad2c1e`; merge was already up to date and both integration/calculator and main were confirmed ancestors. No parent-spec or other ticket status/closure changes were made. At implementation submission, status/checklist were left for the required independent merge reviewer.

## Integration review and completion

Merged `c8108b5df3cd9d0ede7d60e0129058d5398296f8` into the clean `integration/calculator` checkout with `git merge --no-ff`, producing `459f5a1ef06e2a5ccfb9b44cc075ea1576e1cbec`. No conflicts or integration regressions were found. Reviewed all six criteria against the pinned Scientific controls, real-core command dispatch and public QML tests; verified representative implementer red/green logs. Existing Standard, Scientific precedence, Programmer, navigation, translations and settings remain covered. The shared offscreen/compose/generic launcher, private storage and Linux D-Bus isolation are preserved.

Integration validation on Linux/Qt 6.12 in `.build-integration`: Debug configure and `cmake --build .build-integration -j2` pass; `calculator_ui_qmllint` passes without warnings. `python3 tests/run-ui-isolated.py ctest --test-dir .build-integration -j1 -V --output-on-failure` exits **0**, **5/5** entries pass in **571.33 s**: English/light **255**, English/dark **255**, Chinese/light **255** outcomes, each with **0 failed/0 skipped**; **3** process-isolation tests and all **7** independent restart stages pass. Evidence: `merge-05-build.log`, `merge-05-qmllint.log`, `merge-05-ctest.log`, `merge-05-ctest.exit` (0). Reviewed offscreen narrow primary and settled wide secondary/flyout captures in both themes; no native desktop validation. The first primary wide PNG can capture the previous render size during resize, so wide visual evidence uses the settled secondary/flyout images and geometry checks. The inherited Standard Copy shortcut warning remains, with clipboard behavior passing. Windows/macOS remain unverified. All six fulfilled criteria are checked; ticket **resolved**. Parent specification unchanged.
