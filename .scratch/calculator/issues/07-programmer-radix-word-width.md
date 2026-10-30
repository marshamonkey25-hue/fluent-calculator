# 07: 使用程序员模式的进制与位宽

**What to build:** 用户可进入程序员模式，在不同进制下输入和计算整数，查看对应表示，并切换整数位宽。

**Blocked by:** 01: 运行真实核心驱动的标准计算器。

**Status:** ready-for-agent

**Spec:** Windows 11 风格跨平台计算器。

**User stories:** 27, 28, 30。

- [ ] 导航可进入真实程序员模式，默认十进制和 64 位，支持二、八、十、十六进制及 64/32/16/8 位选择。
- [ ] 进制转换、整数基础运算和不同进制的显示使用原版核心行为；非当前进制的数字不能通过按钮或键盘绕过输入限制。
- [ ] 位宽变化、符号解释、边界整数和溢出处理遵循固定源码，不将显示值强制转为会损失 64 位整数精度的 JavaScript 数值。
- [ ] 模式、进制和位宽的选中状态清晰可见，切换后显示与可操作状态立即一致；程序员模式不引入计算历史面板。
- [ ] 页面沿用应用主题、可翻译文案、参考键盘操作和窗口适配规则。
- [ ] 通过 QML 操作验证各进制往返、所有位宽、最高位与符号边界、非法数字、模式切换，以及足以发现整数桥接精度损失的用例。

## Implementation evidence (pending integration review)

Implemented in the ticket 07 worktree; Status deliberately remains `ready-for-agent` until merge validation. The checklist above is left for the merger/reviewer.

- `qml/ProgrammerPage.qml` registers a real Programmer page through the existing navigation registry and shared `CalculationSession`. Defaults are decimal/QWORD; four live radix rows and the QWORD/DWORD/WORD/BYTE selector use Microsoft core commands and string results. No arithmetic algorithm or integer value conversion to JavaScript Number was added, and no Programmer history panel is created.
- Input restrictions cover both disabled keys/shortcuts and the validated C++ dispatcher. The real core supplies integer arithmetic, modulo, parentheses, two’s-complement signs, overflow, narrowing/sign extension and digit limits. Reference shortcuts are F5–F8 for radix, F2/F3/F4/F12 for width, F9 for negate, Delete/Backspace/Escape for editing. New captions use `qsTr` and existing palette/theme hooks.
- `tests/qml/tst_programmer.qml` uses the real application window, navigation, mouse/keyboard and core. Its 31 behavior rows cover all radices and widths, exact `9007199254740993` round trips, signed maximum + 1 and minimum − 1 for every width, all-ones limits, truncation/sign extension, illegal digits, editing and precedence, division errors/recovery, mode defaults/reselection, row-order Tab navigation and small/default/wide layouts. Existing Standard tests remain included.
- TDD red → green slices: absent Programmer navigation; absent radix rows; inactive width selector; enabled illegal digits; incorrect/missing reference function-key shortcuts; absent editing/parenthesis/modulo commands; operators enabled after errors; hidden small-window keyboard focus; absent disabled decimal key; Tab traversing A–F vertically instead of keypad rows. Each test failed before its associated minimal production change and passed afterward. Input-limit/sign-extension tests characterize the already imported real core and are not claimed as new failing implementation tests.
- Verification uses `.build-ticket07`, Qt 6.12/GCC 16, `-j2`, offscreen/software rendering and the existing per-process temporary settings/data roots. All three CTest configurations (light, dark, Chinese engine) and QML lint pass. Screenshots were inspected in light/dark at 320×460, 360×560 and 900×700; short windows scroll and reveal keyboard focus. `README.md` documents use and shortcuts.
- The standalone executable mapped a native Wayland Calculator window (`xwayland=false`). Full native Wayland automation could not obtain compositor activation; offscreen tests are the behavioral evidence. Standalone launch cleanup used SIGTERM; ordinary window close is covered by the QML suites. Windows/macOS remain untested. Bitwise/bit-editing functionality remains ticket 08.
- Read full spec/GLOSSARY/ADR 0001, external handoff/porting notes, TDD and companion testing/mocking docs, UI/UX and find-docs skills. Context7 resolved Qt and supplied current Shortcut/Button/ScrollView API references; no fallback was needed. Layout and keyboard mappings were checked against pinned upstream Programmer XAML, Resources.resw and manager/core sources.
