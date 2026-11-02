# 02: 补齐标准模式按键与错误恢复

**What to build:** 用户可以使用标准模式完整的参考按键，纠正输入、继续计算、复制结果，并在非法运算后恢复正常使用。

**Blocked by:** 01: 运行真实核心驱动的标准计算器。

**Status:** resolved

**Spec:** Windows 11 风格跨平台计算器。

**User stories:** 12, 14, 15, 16, 18, 19。

- [x] 在真实标准模式界面接入百分比、正负号、平方、平方根、倒数、退格、清除当前输入和全部清除，使用已移植核心的行为。
- [x] 以固定参考版本核对重复等号、连续运算符替换、结果后输入数字或运算符，以及百分比在不同上下文中的语义。
- [x] 输入 2 + 3 × 4 = 得到 20；输入更正操作按参考规则影响当前操作数或整个计算，不能统一当作全部重置。
- [x] 除零、非法定义域和超出范围等错误有清晰显示；用户可按参考方式恢复，恢复后不残留错误表达式或不可用按键状态。
- [x] 当前结果可复制到系统剪贴板，复制行为和错误状态下的可用性遵循参考规则。
- [x] 对应鼠标按键和参考键盘操作均可完成上述行为；新增控件沿用应用主题、可翻译文案和窗口适配规则。
- [x] 以 QML 用户操作覆盖百分比上下文、重复等号、运算符替换、各清除操作、复制和错误恢复；期望值来自固定参考行为或独立已知结果。


## Ticket 02 implementation evidence

Implementation was submitted as `ready-for-agent`; integration review and closure evidence follow below.

- Added the seven missing arithmetic/correction keys at their pinned Microsoft positions: percent, negate, square, square root, reciprocal, CE and Backspace. Both pointer actions and the pinned Resources.resw accelerators use the real session-owned CalculatorManager. Theme palette, `qsTr` labels, accessible names, focus and 320×460/900×700 adaptation are retained.
- Recovery follows `StandardCalculatorViewModel.OnButtonPressed` and `IsRecoverableCommand`: digits/decimal clear then enter; C/CE/Backspace/equals clear the failed calculation. The nine operators disabled by the upstream Standard ErrorLayout are disabled in both pointer and keyboard paths and restored on recovery.
- Copy uses QClipboard and the platform Copy shortcut or the result context menu. It preserves string precision, removes numeric grouping only, and allows copying localized errors without changing calculation state.
- Real-QML tests cover percent with +/−/×/÷ and no pending operator, repeated equals, operator replacement, result then digit/operator, CE versus C, Backspace through zero and after equals, and all five error scenarios (division by zero, undefined, invalid square-root domain, reciprocal zero, overflow) crossed with six recovery keys and both input methods. Copy is observed through a real TextEdit clipboard paste, including exact 9007199254740993, negative fractions, trailing zeroes and error text. Expectations come from the pinned manager/view-model tests or independently known results; no arithmetic mocks or JavaScript numeric round trips.
- TDD: each missing key first failed due to the absent mouse key and unchanged keyboard result. Specific keyboard reds included sign 5 versus −5, square 12 versus 144, square root 256 versus 16, reciprocal −100 versus −0.01, CE 5 versus 0 and Backspace 123 versus 12. Digit recovery failed with error still true; error-state controls failed as enabled; Copy failed with absent context menu/empty clipboard. Each passed after its minimal production change. Existing-core reference sequences were added as passing regressions and are not claimed as new reds.
- Private Debug build `.build-ticket02` with Make `-j2`; all three CTest configurations pass (122 QtTest outcomes each, zero failed/skipped), QML lint and diff whitespace checks pass. Narrow light/dark captures reviewed against the pinned Standard keypad organization. Standalone native Wayland window mapped with `xwayland=false`, normal compositor close, exit 0.
- Limits: native Wayland QuickTest cannot obtain activation on this desktop (initial `active` assertion fails despite explicit compositor focus); full automated behavior and clipboard tests are verified under offscreen/software rendering. Windows/macOS and runtime language/theme preference switching are not verified here; ticket 03 owns runtime preference hooks. No remote push, PR or deployment.

## Integration review and closure

- Merged implementation `aa3e4e65e6aa1c2f33b6fa5b03217bd5f580e4ca` into clean `integration/calculator` with `git merge --no-ff`; merge commit `5fffe783f60a0efd166a2817f1849b5945212252`. No conflicts or integration fixes were required. Existing ticket 01 navigation, resource fallback, session ownership and tests are preserved.
- Independent merger review found no blockers on either standards or ticket acceptance. Checked the command mapping, string-only Copy path, translation/theme/accessibility hooks and real-QML tests; cross-checked pinned `CalculatorManagerTestStandard`, `StandardCalculatorViewModel.OnButtonPressed`/`IsRecoverableCommand`/`GetRawDisplayValue`, and `CalculatorStandardOperators.xaml` ErrorLayout. All seven acceptance items above are fulfilled.
- Integration validation: `cmake -S . -B .build-integration -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Debug`, `cmake --build .build-integration -j2`, and `ctest --test-dir .build-integration --output-on-failure` passed. All three configurations (English/light, English/dark, Chinese engine/light) report **122 passed, 0 failed, 0 skipped** each. Tests retain ticket 01 coverage and add all ticket 02 operations, correction, Copy and recovery cases.
- `cmake --build .build-integration --target calculator_ui_qmllint -j2` and `git diff --check` passed without warnings/errors. Reviewed integration-generated light narrow and dark error screenshots: all 24 keys fit and disabled operators remain distinguishable. Logs: `.build-integration/{configure,build,ctest,qmllint}-ticket02.log` and `.build-integration/Testing/Temporary/LastTest.log`.
- Validation remains Linux/Qt 6.12 with offscreen software rendering. Native Wayland standalone evidence and native automated activation limitation are recorded above; this merge does not claim a new native Wayland behavior run or Windows/macOS validation. Runtime language/theme preferences remain ticket 03. Parent spec unchanged; no remote push, PR or deployment.
