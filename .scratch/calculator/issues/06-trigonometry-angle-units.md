# 06: 使用三角函数与角度单位

**What to build:** 用户可在科学模式中选择角度单位，使用三角、反三角、双曲及参考组合功能，得到与当前单位和按键状态一致的结果。

**Blocked by:** 04: 使用科学模式的优先级与括号。

**Status:** resolved

**Spec:** Windows 11 风格跨平台计算器。

**User stories:** 23, 24。

- [x] 科学模式默认角度制，能够通过实际控件选择固定参考版本支持的角度单位，且当前单位清晰可见。
- [x] 接入参考版本的三角函数、反三角函数、双曲函数及其支持的变体；相关切换状态、按钮标签与真实核心命令保持一致。
- [x] 角度单位影响对应运算，单位切换与模式切换的状态语义遵循固定参考实现，不单独假设所有函数都接受角度参数。
- [x] 定义域错误、不可表示结果或其他核心错误得到明确显示，并能按参考方式恢复。
- [x] 新增界面和键盘入口沿用应用主题、可翻译文案、焦点和窗口适配规则。
- [x] 通过真实科学模式界面验证各角度单位的已知结果、反函数、双曲功能、切换状态和错误恢复；测试使用参考用例或独立已知数学值。


## Implementation evidence (ticket 06 branch)

The implementation branch left status `ready-for-agent` for integration review; the verified integration closure below supersedes that handoff status.

- `CalculationSession` allowlists all 24 pinned Trigonometry-flyout commands: sin/cos/tan/sec/csc/cot, their inverse forms, the six hyperbolic forms, and their inverses. Each goes through the real `CalculatorManager`, including its native composite inverse commands. Arithmetic values remain strings across the Qt/QML boundary.
- The Scientific unit control defaults to DEG, cycles DEG/RAD/GRAD, and supports F3/F4/F5 selection. Unit changes preserve the entry; Clear and mode return retain the cached Scientific engine's unit. Circular/inverse results use that unit; hyperbolic results are independent of it.
- The pinned four-column/two-row flyout has 2nd/hyp toggles and six function positions. Labels, accessible names and commands change together. Selecting a function clears both toggles; dismissal preserves them. S/O/T/U/I/J shortcuts support Shift, Ctrl, and Ctrl+Shift variants. Scientific shortcuts remain inactive in Settings and function/unit controls are disabled during errors.
- Popup focus follows visual row order, Escape dismisses without clearing the calculation, and focus returns to the opener. English/Simplified Chinese names and palette-based light/dark visuals use the existing hooks. The complete keypad requests 320×632 minimum; a ScrollView and focus reveal also handle compositors allocating a shorter window. Existing full-keypad size checks use 632 px; the new actual-UI short-window case exercises 320×460.
- `tests/qml/tst_scientific_trigonometry.qml` covers all 24 mouse functions and keyboard equivalents, all three units, inverse outputs, hyperbolic unit independence, toggle reset/dismissal, mode/clear retention, 12 localized domain/singularity/range errors with recovery, hidden shortcuts, runtime translation, focus and all label variants at narrow/wide sizes. Known trigonometric values and ln(3) identities provide independent expectations; pinned `CalculatorManagerTestScientific2`, `scifunc.cpp` and Ratpack checks supply reference behavior.
- `tests/qml/tst_scientific_short_window.qml` exercises the real MainWindow under a short allocation, scroll/focus reveal, actual angle controls, flyout dismissal and continued calculation.

Real TDD cycles, in order (logs under this worktree's ignored `.build-ticket06`):

| Slice | Observed red | Green evidence |
| --- | --- | --- |
| Default degrees and sin | `angleUnitButton` absent | `green-01.txt`: sin(30°) = 0.5 |
| Unit state | DEG failed to cycle to RAD | `green-02.txt`: RAD/GRAD/DEG values, input/clear/mode retention |
| Circular family | cos/tan/sec/csc/cot absent | `green-03.txt`: six known circular results |
| Inverse family | inverse toggle absent; popup hit area too narrow | `green-04.txt`: six inverse results and reset behavior |
| Hyperbolic family | hyp toggle absent | `green-05.txt`: six functions in all three units |
| Inverse hyperbolic | asinh left the input unchanged | `green-06.txt`: six inverse hyperbolic results |
| Keyboard | S left 30 unchanged | `green-07.txt`: all 24 shortcuts and F3/F4/F5 |
| Flyout focus | initial focus absent, then Tab order wrong | `green-08.txt`: focus/Tab/Space/Escape and dismissal state |
| Translation | Chinese control still named Trigonometry | `green-09.txt`: live Chinese/English labels and retained input |
| Narrow labels | sech⁻¹ exceeded its button width | `green-10.txt`: every label fits at both widths |
| Short window | scrollable Scientific keypad absent | `green-11.txt`: actual UI scroll and continued calculation |
| Keyboard inside flyout | typing 0 left 3 unchanged | `green-12.txt` / `isolated-popup-green.txt`: entry reaches 30, S computes 0.5, Escape preserves entry |
| Navigation input | keys behind the drawer changed 3 to 0.5 | `green-13.txt`: drawer preserves 3/DEG; after dismissal 0 and S compute 0.5 |

Final focused checks use the supplied shared isolation launcher, `QT_QPA_PLATFORMTHEME=generic`, compose input, offscreen/software rendering, private D-Bus and private runtime/settings/cache/data roots. The three Scientific test files passed **56/56 outcomes in English and 56/56 in Simplified Chinese**, each with normal exit 0, no failures and no skips (`focused-navigation-en.txt`, `focused-navigation-zh.txt`, and `focused-navigation-results.json`). This includes all 37 ScientificTrigonometry outcomes, 16 ScientificPrecedence outcomes and 3 short-window outcomes. The per-window shortcuts remain available while the flyout owns focus; Clear/Escape alone yields to popup dismissal. MainWindow disables its calculator-page loader while navigation is visible, and Scientific accelerators honor inherited enabled state, so input cannot mutate a calculation behind the drawer. QML lint passed without warnings.

Earlier, before the desktop/IME/session-bus isolation constraints were tightened, complete English/light and English/dark configurations passed 225/225 outcomes each, and the later Chinese configuration passed 226/226. The actual light/dark narrow/wide flyout captures were reviewed; the subsequent shortcut-context change preserves those palette hooks. Earlier native Wayland short-window and keyboard checks passed 3/3 each. The standalone executable mapped a native Wayland Calculator window and its owned smoke-test process was stopped with SIGTERM; native QuickTest windows closed normally. These are historical observations, not claims of native validation under the current constraints. No task-owned native/visible process remains.

The final fully isolated **whole-application suite is not green**: with the inherited GTK platform theme it cannot start without DISPLAY; with the display-free generic platform theme, `QStyleHints::colorScheme` remains Unknown. PreferencesRestart restore fails (0 versus expected Dark=2); the isolated English main configuration reports 220 passed and 6 existing preference/appearance failures. The remaining full run was stopped through a verified owned CTest PID/birth/cwd/ancestry after the supervisor assigned the shared appearance fallback to ticket 05 and authorized focused ticket-06 validation. No assertions were removed or weakened for that failure. An earlier separate run was externally terminated by SIGTERM and is preserved in `ctest-final.log`.

The merger must retain ticket 05's repository isolation launcher, early Qt test setup and appearance fallback, then run the complete integrated suite successfully before resolving ticket 06. All future UI validation must use the shared launcher; do not reconnect tests to the user's display, IME or session bus. The exact safe focused invocations are recorded in `focused-navigation-results.json`; the currently supplied launcher is `/tmp/calc-implementation-notes/run-ui-isolated.sh`.

Runtime diagnosis: the representative hyperbolic group took 16.14 seconds with default input delays and 15.42 seconds with zero input delays. Popup/drawer transitions and their explicit event/render waits dominate, rather than arithmetic execution. Removed an unnecessary Standard-to-Scientific round trip in each setup while adding an explicit fresh-session DEG assertion; the final focused groups finish in about 100–105 seconds per language. The expanded whole-suite budget is 600 seconds after observed complete configurations took 339–346 seconds.

Context7 verified Qt 6.8 Popup focus/close behavior and Instantiator's nonvisual delegate API; no documentation fallback was needed. UI guidance used the UI/UX skill's keyboard-focus/popup search and shared semantic palette, with the Microsoft layout retained. Linux/Qt 6.12 is verified; Windows/macOS remain untested. Independent integration review remains required.

The shared navigation input change also passed existing Standard navigation/keyboard regression checks (4/4 outcomes) and Programmer navigation/defaults/reference-shortcut checks (4/4), each through the approved isolated launcher with normal exit and no skips. No Standard or Programmer test source was changed for this regression.


## Verified integration closure

Merged source commit `36530f28602e6cb95015d314bf45d75c0b4326bc` with `git merge --no-ff` as `d4ba32241726c4761aa2e3bb6c07e32dad1717d8`, preserving tickets 01–05 and 07. CMake retains the repository isolation launcher and early test setup. The controller retains both extended Scientific operations and all 24 trigonometric commands. The two-row header combines DEG/F-E and Trigonometry/Function above the existing full keypad; the result remains visible while short windows scroll the controls. The C/CE-aware tests use the public Escape shortcut for full clearing. Added a real-QML regression for extended operations while Trigonometry owns focus, and navigation now blocks extended and trigonometric accelerators together.

Integration screenshot review found two additional issues despite the first passing English runs: the moved Function popup could extend outside a narrow window, and unchecked Trigonometry toggles had poor contrast on the generic platform's native popup background. Red real-QML checks reproduced both (`.build-integration/merge06-popup-red.log`). Fix commit `27c0435` constrains both popups with window margins and inherited semantic backgrounds, and uses the shared CalculatorButton for toggles so checked/unchecked text colors follow the application palette. All-state rendered contrast and all six Function controls' narrow-window bounds pass in both themes. Updated narrow/wide light/dark captures for both flyouts were reviewed under isolation. The initial run was interrupted through verified task-owned process handles after the visual discovery; it is not counted as final validation.

Final validation on Linux x86_64, Qt 6.12.0/GCC 16.2.1:

- Debug configure/build with `cmake -S . -B .build-integration -G 'Unix Makefiles' -DCMAKE_BUILD_TYPE=Debug` and `cmake --build .build-integration -j2`: passed.
- `python3 tests/run-ui-isolated.py cmake --build .build-integration --target calculator_ui_qmllint -j2`: passed without lint warnings.
- `ctest --test-dir .build-integration --output-on-failure -j2`: **5/5 passed**, normal exit 0, 618.67 seconds. English/light and English/dark each passed **298 outcomes, 0 failed, 0 skipped** (330.18/330.23 seconds); Chinese/light also passed **298/0/0** (288.49 seconds). This includes all existing Standard, preferences, Programmer, Scientific precedence/extended operations and new Trigonometry/short-window/combined-popup regressions. Three child-process isolation checks and all seven independent restart stages passed.
- Every final GUI process used the repository launcher: offscreen/software, compose, generic platform theme, private settings/cache/data/runtime, no inherited DISPLAY/WAYLAND_DISPLAY/IME variables, and a private D-Bus. No native desktop validation is claimed.
- Evidence: `.build-integration/merge06-final-ctest.log`, `merge06-final-ctest.exit` (0), `merge06-final-last-test.log`, `merge06-popup-{build,qmllint}.log`, and `merge06-popup-green-{light,dark}.log`. Reviewed captures and focused normal-exit logs are under `.build-integration/merge06-visuals-{light,dark}/`.

All six acceptance criteria above are fulfilled. No ticket-06 integration blockers remain. The inherited Standard Copy shortcut warning is unchanged, with real clipboard behavior passing. Windows/macOS and native desktop behavior remain unverified here; final application-wide independent review remains part of the parent workflow. The parent spec was not edited; no remote push, PR or deployment was performed.
