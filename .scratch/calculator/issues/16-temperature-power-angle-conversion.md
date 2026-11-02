# 16: 换算温度、功率和角度

**What to build:** 用户可换算温度、功率和角度，正确处理这三类允许的负值，以及温标之间的偏移量。

**Blocked by:** 13: 完成长度换算。

**Status:** resolved

**Spec:** Windows 11 风格跨平台计算器。

**User stories:** 57, 62, 65。

- [x] 提供温度、功率和角度三个真实入口及固定参考版本的完整单位集合。
- [x] 温度换算正确应用比例和偏移量，包含负温度；功率与角度按对应单位关系换算，输入符号规则与参考类别一致。
- [x] 各类允许负值，但其他输入范围和边界仍遵循参考规则，不能因允许负数而绕过位数或无效值校验。
- [x] 改变单位、修改数值及同单位转换即时产生一致结果，格式和错误恢复沿用已实现换算行为。
- [x] 参考负值输入可以通过相应屏幕操作和键盘完成；新页面沿用主题、翻译和宽窄窗口布局。
- [x] 通过界面验证零点与负温度、典型温标对应值、负功率和负角度、同单位及往返转换，避免把带偏移的温标当作纯比例换算。

## Implementation evidence (ticket 16; before integration merge)

At implementer handoff, status remained `ready-for-agent` for the independent integration reviewer. The implementation supplies all three modes through the existing production `ConverterPage` and real Microsoft `UnitConverter`; no arithmetic/converter algorithm was replaced. `app/TemperaturePowerAngleDataLoader.cpp` preserves pinned unit IDs/order/defaults, the full temperature ratio/offset matrix, all five selectable power units (plus hidden whimsical metadata), and all three angle units. All three categories enable the core's negative-input policy; Length stays nonnegative. Negate uses the reference bottom-left keypad position and `-` / F9 shortcuts. Shared category, translation, palette and mode-registry hooks supply the actual pages.

Six sequential UI red→green slices are retained in `.build-ticket16/red-01.log` through `red-06.log`, with matching `green-01.log` through `green-06.log`:

1. Missing Temperature navigation failed the zero-Celsius test; registering the category and explicit temperature matrix produced `0 °C → 32 °F`.
2. Missing negate control failed negative-temperature/pair cases; adding the real `Negate` command, screen key and reference shortcuts passed all nine unit pairs, negative temperatures, absolute-zero landmarks and boiling examples.
3. Missing Power navigation failed negative power cases; pinned metadata and registration passed known watt equivalents for every selectable power unit.
4. Missing Angle navigation failed negative angle cases; pinned metadata and registration passed degree/radian/gradian relationships and identity.
5. Negative paste returned `0` instead of `-12.50`; validating signed decimals and applying the sign through the real core passed valid input, malformed/non-finite/range/length rejection and recovery.
6. Chinese titles remained English; adding the pinned names and accessible negate translation passed runtime English/Chinese switching with numeric state intact, both themes and narrow/wide layout/focus checks.

Supplemental real-QML regressions cover the pinned minus-sign digit budget, negating a 15-digit entry, backspace/clear, signed paste at the limit, editing either side, same-unit/reverse conversions, Settings shortcut isolation, and preservation of a pending arithmetic operation across all new modes. Numeric tolerances use independent known values and the pinned formatter's larger of `5e-8` absolute or `5e-7` relative error (temperature landmark checks use tighter bounds). Early development runs also exposed a too-tight test tolerance for small fixed power output and a test resize synchronization issue; those assertions now reflect the pinned display policy and wait for the real content width before measuring layout.

Current Qt API lookup used the `find-docs` skill and Context7 (`library Qt`, then `/websites/doc_qt_io_qt-6` Loader initial properties / Shortcut context and enabling), with no fallback required. UI guidance used the `ui-ux-pro-max` visible-keyboard-focus search and its accessibility/interaction checklist while preserving the pinned layout. Every GUI command uses the repository's compose/generic/offscreen/software launcher with private data/runtime and D-Bus; no active-desktop check was attempted. Windows/macOS and native display rendering remain unverified.

### Final branch verification

- Private `.build-ticket16` CMake/Make build on Linux x86_64, Qt 6.12.0 and GCC 16.2.1; compilation uses `-j2`. Production application and test targets build successfully. `calculator_ui_qmllint` passes without warnings.
- `ctest --test-dir .build-ticket16 --output-on-failure -j2` passes **29/29 entries** in **1727.47 seconds** (`.build-ticket16/ctest-full.log`), preserving all existing arithmetic, Programmer, preferences/restarts, isolation, History, Memory, Date, Length and Graphing checks. Ticket 16 contributes **40 outcomes** in each English/light, English/dark and Chinese/light configuration, with no failures/skips.
- After the final no-op `git merge --no-edit integration/calculator` and a successful ancestry check, the production build and lint pass again (`final-build.log`, `final-lint.log`). The integration tip remains `2cbc82c3e9bc0139063f7ca8c78b2c333662071c`.
- The newly registered `calculator-temperature-power-angle-restart` passes separately, **1/1 entry** in **26.21 seconds** (`ctest-restart-03.log`, detailed `restart-stages.log`). All six write/restore processes report **3 passed, 0 failed, 0 skipped**. Earlier restart-only attempts exposed a helper that sent keyboard selection before a real click established window focus; the final helper clicks the input, verifies focus/selection and passes. This changed only the test. Its US Celsius default label was also corrected to match the pinned region policy. All **30 currently registered entries** therefore have passing final results across the two runs; no single all-30 run is claimed.
- Offscreen English/light and Chinese/dark captures were reviewed for all three pages at 320×560 and 900×600. Numeric values, unit captions and the bottom-left negate key remain readable; automated focus, geometry and 4.5:1 text contrast checks pass. Files use `<temperature|power|angle>-<en-US|zh-CN>-<320|900>.png` in the private build directory.
- No production code changed after the all-green 29-entry run. Whitespace checks pass. Only this ticket and its required converter/navigation/translation/test/documentation hooks changed; the parent spec and other tickets are untouched. No remote push, PR, deployment or active-desktop GUI was used. Independent integration review and status closure remain with the merger.


## Independent integration completion — 2026-10-30

Merged source `f5c93f9ea643884b66488201c9adc8e6cbcc9c62` with `--no-ff` into `integration/calculator` as **`57acfcac85fb02cea59434faf9e2ea324353326c`**, preserving the existing application-owned composite converter, every ticket 14/15 category, navigation, translations and test registration. The new signed categories use that same session; category switches retain current input, active side and unit choices, and the reference core removes a minus when entering a positive-only category.

All six acceptance criteria are fulfilled: the complete 3/5/3 selectable unit sets, explicit temperature scales/offsets, signed mouse/keyboard entry, validated paste and digit limits, live edits/identity/reverse conversion, and translated responsive pages are exercised through the real QML controls and Microsoft converter. Merge review found no blockers. The signed suites now scroll the expanded navigation and explicitly clear shared input during setup. Eight additional cross-category cases verify signed-to-signed preservation, sign removal across all eight positive-only categories, both active sides, remembered unit pairs and disabled hidden negate shortcuts. The older positive-only check now verifies that negation is absent or hidden, preserving its user-visible assertion.

- `cmake -S . -B .build-integration -DBUILD_TESTING=ON`, `cmake --build .build-integration -j2`, and `calculator_ui_qmllint` all pass without warnings/errors on Linux/Qt 6.12/GCC 16.2.1.
- `ctest --test-dir .build-integration --output-on-failure -j2`: **37/37 entries passed**, **2090.26 seconds**, exit 0. Every inherited suite passes. Temperature/Power/Angle reports **48 passed, 0 failed, 0 skipped** in each light/dark/Chinese configuration; its six restart stages each report **3 passed, 0 failed, 0 skipped**. Logs: `.build-integration/merge16-ctest-full.log` and `Testing/Temporary/LastTest.log`.
- Focused merge checks reproduce the navigation/shared-state/hidden-control test mismatches before correction and pass afterward (11 signed and 6 positive-only outcomes); evidence is in `.build-integration/merge16-{red,green}-*.log`. Fresh integration screenshots at 320×560 and 900×600 confirm readable values/unit labels, the negate key and visible focus. Current Shortcut documentation was verified with Context7; no fallback was needed.
- All GUI processes, including restart helpers and captures, use the unchanged private compose/generic/offscreen/software launcher and private D-Bus. Native desktop behavior and Windows/macOS remain unverified. Parent spec is unchanged; no remote push, PR or deployment occurred. Whitespace checks and the integration worktree/staging state are clean after committing closure.
