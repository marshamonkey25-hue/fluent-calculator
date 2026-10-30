# 06: 使用三角函数与角度单位

**What to build:** 用户可在科学模式中选择角度单位，使用三角、反三角、双曲及参考组合功能，得到与当前单位和按键状态一致的结果。

**Blocked by:** 04: 使用科学模式的优先级与括号。

**Status:** ready-for-agent

**Spec:** Windows 11 风格跨平台计算器。

**User stories:** 23, 24。

- [ ] 科学模式默认角度制，能够通过实际控件选择固定参考版本支持的角度单位，且当前单位清晰可见。
- [ ] 接入参考版本的三角函数、反三角函数、双曲函数及其支持的变体；相关切换状态、按钮标签与真实核心命令保持一致。
- [ ] 角度单位影响对应运算，单位切换与模式切换的状态语义遵循固定参考实现，不单独假设所有函数都接受角度参数。
- [ ] 定义域错误、不可表示结果或其他核心错误得到明确显示，并能按参考方式恢复。
- [ ] 新增界面和键盘入口沿用应用主题、可翻译文案、焦点和窗口适配规则。
- [ ] 通过真实科学模式界面验证各角度单位的已知结果、反函数、双曲功能、切换状态和错误恢复；测试使用参考用例或独立已知数学值。


## Implementation evidence (ticket 06 branch)

Status remains `ready-for-agent`; the integration reviewer owns checklist closure and resolution.

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

Focused final checks: all 35 ScientificTrigonometry outcomes passed, all 16 ScientificPrecedence outcomes passed, and the short-window check passed. Native Wayland runs passed 3/3 outcomes for the short-window case and 3/3 for the 24-function keyboard case, with no skips. QML lint passed without warnings. The standalone executable mapped a native Wayland Calculator window (`xwayland=false`); its owned smoke-test process was stopped with SIGTERM after inspection, while the native QuickTest windows closed normally.

Context7 verified Qt 6.8 Popup focus/close behavior and Instantiator's nonvisual delegate API; no documentation fallback was needed. UI guidance used the UI/UX skill's keyboard-focus/popup search and shared semantic palette, with the Microsoft layout retained. Linux/Qt 6.12 is verified; Windows/macOS remain untested. Independent integration review remains required.
