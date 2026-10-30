# 01: 运行真实核心驱动的标准计算器

**What to build:** 用户能够构建并启动具有原生窗口外框、Fluent 风格 QML 内容的桌面计算器，通过鼠标和键盘完成真实的标准模式四则运算。以这一完整操作路径验证微软核心在本机的移植、界面连接与数值传递。

**Blocked by:** None (can start immediately).

**Status:** resolved

**Spec:** Windows 11 风格跨平台计算器。

**User stories:** 1, 3, 10, 11, 13, 17, 20, 66, 67。

- [x] 使用 Qt 6、QML、C++ 和 CMake 建立可在当前 Linux 环境构建、启动和关闭的应用；保留面向 Windows/macOS 的可移植结构，明确记录实际验证平台和依赖版本。
- [x] 固定并移植微软源码版本 79e1ac53bba690cdf930e5dcd6ed9dbc4cbfb128 的算术核心，保留来源、移植说明及适用版权和第三方声明；不得以独立 JavaScript 浮点计算代替真实核心。
- [x] 标准模式具备数字、小数、四则运算、等号和清空操作；计算值、表达式和错误状态通过实际应用逻辑显示，鼠标与对应键盘输入遵循同一行为。
- [x] 标准模式按步骤求值，连续输入 2 + 3 × 4 = 得到 20；核心与界面之间的数值传递保留原版精度能力。
- [x] 内容采用可扩展的 Fluent 风格基础布局和导航方式，窗口外框保持系统原生行为；后续模式可以接入，不以未实现页面冒充已完成功能。
- [x] 新界面文案可翻译、样式可随应用主题变化，合理缩放窗口时必要操作仍可访问；不要求本任务完成独立的设置页面。
- [x] 通过真实 QML 操作验证基本计算、清空和键鼠一致性，并覆盖能够发现数值桥接精度损失的参考用例；测试断言外部行为而非内部实现。
- [x] 提供从依赖准备到构建、运行和执行现有检查的说明，并记录一次实际启动及测试结果；本任务不将其他平台标记为已实测。

## Ticket 01 implementation evidence (pending merge validation)

Status remains `ready-for-agent`; the merger owns acceptance checkboxes and closure.

- Added CMake/Qt Quick application, native `ApplicationWindow` chrome, a central implemented-mode registry, shared session adapter, reusable Fluent controls and the pinned Standard number/operator positions. Only implemented Standard controls/navigation are exposed.
- Vendored the real 27-source Microsoft `CalculatorManager → CCalcEngine → Ratpack` core from `79e1ac53bba690cdf930e5dcd6ed9dbc4cbfb128`, with MIT/NOTICE, a six-file portability change inventory, and exact resource provenance/omission notes in `third_party/microsoft-calculator/README.md`.
- Arithmetic values and expressions remain `QString`/`std::wstring`. Real-QML mouse and keyboard paths prove `2 + 3 × 4 = 20`, decimal arithmetic, clear, four operations, exact `9007199254740992 + 1 = 9007199254740993`, continuation back to `1`, core input limits, expression display, division/undefined errors and recovery, navigation retention, accessible labels/Tab focus, and narrow/wide layouts.
- Five red→green cycles observed: mouse result `0` versus `20`; keyboard Escape left `4` instead of `0`; missing explicit error-state label; symbolic rather than named accessible operators; Chinese expression `5 4` missing `×`/`=` before the English resource fallback. Precision/input-limit cases were added as passing imported-core regressions, not claimed as new red cycles.
- Linux x86_64 / Qt 6.12.0 / GCC 16.2.1 / CMake 4.4.4 / Make 4.4.1: Debug configure/build and all three CTest entries passed (13 QtTest outcomes each). Native Wayland full QML suite passed (13 outcomes). `calculator_ui_qmllint` passed without warnings. Light/dark 320×460 and 900×700 screenshots were inspected. The standalone executable opened a native Wayland `Calculator` window and exited 0 on normal close.
- Reproduction commands, dependencies, theme/translation hooks, test isolation and actual platform limits are in `README.md`. Tests use a private build tree, temporary app-data/settings/cache roots, offscreen/software rendering under CTest, and the real core without mocks.
- Windows/macOS remain unverified. Settings/runtime language changes, remaining Standard operations and other modes stay with their own tickets. Independent reviewer/merge validation remains required.

## Integration completion evidence

- Merged source commit `784d02119124bca15b57b877ef3377558ad1efb3` into clean `integration/calculator` with `git merge --no-ff`; merge commit `d866c34a8117ff6451d5c11b9e56da3d2206f88e`. No conflicts or integration regressions; no existing feature was replaced. All eight criteria above were checked against the source, documentation and actual application behavior before closure.
- Fresh Linux/Qt 6.12 Debug integration build: `cmake -S . -B .build-integration -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Debug` and `cmake --build .build-integration -j2` passed. `ctest --test-dir .build-integration --output-on-failure` passed all three configurations (39 QtTest outcomes, zero failures/skips); `calculator_ui_qmllint` passed without warnings. Native Wayland suite also passed all 13 outcomes, including mouse/keyboard precision continuation, expression/error recovery, focus/navigation, responsive layouts and production-window close.
- Standalone integration executable created a native Wayland `Calculator` window (`xwayland=false`), received a normal compositor close request and exited 0. Isolated manual settings/data/cache live under the ignored integration build directory. Both narrow theme screenshots were inspected; all implemented controls remain visible/readable.
- Independent source/provenance comparison against `/tmp/calc-reference.OG9wUY` confirmed exactly the six documented portability changes, byte-identical LICENSE/NOTICE and exact 108 English / 9 Chinese engine resource values. Project-authored diff passes whitespace checks. Actual build, test and native launch logs/screenshots are in `.build-integration`; CTest detail is in `Testing/Temporary/LastTest.log`.
- Only Linux x86_64 / Qt 6.12 is verified; Windows/macOS remain untested. Remaining operations/settings/modes belong to their own tickets. Parent spec unchanged. This merger acceptance does not replace the workflow's final independent review of the completed integration branch.
