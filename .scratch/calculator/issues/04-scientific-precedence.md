# 04: 使用科学模式的优先级与括号

**What to build:** 用户可以从导航进入科学模式，输入带括号的计算，看到表达式和结果，并获得与标准模式不同的优先级求值行为。

**Blocked by:** 01: 运行真实核心驱动的标准计算器。

**Status:** resolved

**Spec:** Windows 11 风格跨平台计算器。

**User stories:** 21, 26。

- [x] 导航可进入真实科学模式，并可返回标准模式；模式名称、显示区域和可用按键与当前模式一致。
- [x] 通过移植核心处理数字、小数、基础运算与括号，保留科学模式的表达式显示和输入语义，不以自建浮点表达式计算替代核心。
- [x] 科学模式对 2 + 3 × 4 求值得到 14，标准模式对应逐步运算得到 20；括号能够正确改变运算顺序。
- [x] 沿用科学模式的精度、输入和括号深度检查；对未闭合或不合法的输入按固定参考版本处理，并能恢复继续输入。
- [x] 科学模式与标准模式切换后不产生错误的求值策略或过期显示；页面沿用主题、可翻译文案、键盘规则和宽窄窗口布局。
- [x] 从真实 QML 操作验证模式切换、运算优先级、嵌套括号、输入边界及错误恢复；输入行为和期望结果可追溯到固定参考版本。


## Implementation evidence (awaiting integration validation)

- Implemented the actual Microsoft Scientific manager mode in the existing session; navigation selects matching pages and clears active entry/expression only on a mode change. Standard remains stepwise (`20`); Scientific precedence produces `14`; nested parentheses change the result to `20`.
- Added `qml/ScientificPage.qml` at the pinned reference's five-column/seven-row positions, preserving extension-function space for tickets 05/06. Reuses palette/focus controls and `qsTr` hooks, supports mouse/keyboard parentheses, a horizontally scrollable full expression, 320×540 and 900×700 layouts, and all visible keys at least 44×44.
- `tests/qml/tst_scientific_precedence.qml` exercises real production QML/session/core, including mode changes, nested/unfinished/invalid parentheses, implicit multiplication, 25-level and 32-digit caps, exact rational continuation, decimal entry, localized errors/clear recovery, expression dragging and keyboard focus. Sources: pinned `CalculatorManagerTestScientificParenthesis`, `CalculatorManagerTestScientificError`, `CalculatorManagerTestModeChange`, `scicomm.cpp`, `History.h` and `CalculatorManager.h`.
- TDD red→green: missing Scientific navigation → real mode/14-versus-20; absent mouse parentheses and keyboard result 14 instead of 20 → native parentheses/shortcuts and expression formatting; absent long-expression viewport → working horizontal drag/scrollbar. Core boundary tests passed as regressions, without claiming artificial failing stages.
- Linux Qt 6.12/GCC 16.2 Debug build `.build-ticket04`, Make `-j2`: all three CTest entries passed (English/light, English/dark, Chinese engine startup/light; 27 QtTest outcomes each), complete native Wayland suite passed 27/27 with no skips, QML lint passed with no warnings, and `git diff --check` passed. Reviewed both-theme narrow/wide screenshots and observed the standalone native Wayland app. Runtime preference/translation completion belongs to ticket 03; extended Scientific operations/angles belong to 05/06. Windows/macOS not verified.
- Status/checklist intentionally await the required independent merge validation. Parent spec and other tickets were not edited.


## Merge acceptance and completion evidence

- Merged source commit `da6ae60e177aac04c6956da14a473c1409bf5034` into `integration/calculator` using `git merge --no-ff`; merge commit `f10cd494c4be50505d1d18551b2eb0e741b0edb3`. Conflict review preserved tickets 02/03: Standard recovery/Copy, runtime language/theme preferences, Settings navigation, recent-mode restoration, all CMake registrations and existing tests. The parent specification was not edited.
- Integration fix commit `2311ecf` completes Scientific Chinese labels in the existing translation catalog, binds hidden Scientific shortcuts to page visibility, and aligns the test with the shared `pageTitle` and controlled system preferences. New real-QML tests first failed with English `Scientific` instead of `科学`, and result `7` instead of preserved `42` after using keys in Settings; both now pass. Runtime language changes retain a pending parenthesized calculation and translate existing errors. Two added process stages verify Scientific mode is restored with fresh entry/expression and the correct precedence after ordinary restart.
- All six criteria reviewed against production QML, session dispatch and the pinned reference. Mouse/keyboard precedence and nested parentheses, ignored unmatched close/automatic closure, 25-level parentheses and 32-digit input caps, exact rational continuation, errors/clear recovery, mode resets, translations, focus, expression scrolling and 320×540/900×700 layouts pass. Existing Standard/Settings behavior remains covered.
- Linux Qt 6.12 / GCC 16.2 Debug integration build: `cmake -S . -B .build-integration -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Debug` and `cmake --build .build-integration -j2` passed. `ctest --test-dir .build-integration --output-on-failure` passed **4/4** entries: **149 passed, 0 failed, 0 skipped** in each English/light, English/dark and Chinese/light suite; five separate restart processes each passed 3/3 outcomes. Total CTest time 121.06 seconds.
- Native Wayland Scientific QML suite passed **16/16**, with no failures/skips and normal QML window closure. `calculator_ui_qmllint` completed without warnings and `git diff --check` passed. Reviewed light/dark narrow/wide Scientific captures in the integration build directory. Evidence logs: `merge04-build.log`, `merge04-integration-red.log`, `merge04-scientific-green.log`, `merge04-final-ctest.log`, `Testing/Temporary/LastTest.log`, `merge04-qmllint.log`, `merge04-wayland.log`.
- Merger acceptance review found no ticket04 blockers. Existing Qt runtime warning about Standard's single Copy key-sequence binding remains outside this merge; its real clipboard tests pass. Windows/macOS remain unverified. Extended Scientific operations and angle/trigonometric functions remain tickets 05/06. Final application-wide review remains a later workflow gate.
