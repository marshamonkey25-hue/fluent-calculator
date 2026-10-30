# 16: 换算温度、功率和角度

**What to build:** 用户可换算温度、功率和角度，正确处理这三类允许的负值，以及温标之间的偏移量。

**Blocked by:** 13: 完成长度换算。

**Status:** ready-for-agent

**Spec:** Windows 11 风格跨平台计算器。

**User stories:** 57, 62, 65。

- [ ] 提供温度、功率和角度三个真实入口及固定参考版本的完整单位集合。
- [ ] 温度换算正确应用比例和偏移量，包含负温度；功率与角度按对应单位关系换算，输入符号规则与参考类别一致。
- [ ] 各类允许负值，但其他输入范围和边界仍遵循参考规则，不能因允许负数而绕过位数或无效值校验。
- [ ] 改变单位、修改数值及同单位转换即时产生一致结果，格式和错误恢复沿用已实现换算行为。
- [ ] 参考负值输入可以通过相应屏幕操作和键盘完成；新页面沿用主题、翻译和宽窄窗口布局。
- [ ] 通过界面验证零点与负温度、典型温标对应值、负功率和负角度、同单位及往返转换，避免把带偏移的温标当作纯比例换算。

## Implementation evidence (ticket 16; merge validation pending)

Status intentionally remains `ready-for-agent` for the independent integration reviewer. The implementation supplies all three modes through the existing production `ConverterPage` and real Microsoft `UnitConverter`; no arithmetic/converter algorithm was replaced. `app/TemperaturePowerAngleDataLoader.cpp` preserves pinned unit IDs/order/defaults, the full temperature ratio/offset matrix, all five selectable power units (plus hidden whimsical metadata), and all three angle units. All three categories enable the core's negative-input policy; Length stays nonnegative. Negate uses the reference bottom-left keypad position and `-` / F9 shortcuts. Shared category, translation, palette and mode-registry hooks supply the actual pages.

Six sequential UI red→green slices are retained in `.build-ticket16/red-01.log` through `red-06.log`, with matching `green-01.log` through `green-06.log`:

1. Missing Temperature navigation failed the zero-Celsius test; registering the category and explicit temperature matrix produced `0 °C → 32 °F`.
2. Missing negate control failed negative-temperature/pair cases; adding the real `Negate` command, screen key and reference shortcuts passed all nine unit pairs, negative temperatures, absolute-zero landmarks and boiling examples.
3. Missing Power navigation failed negative power cases; pinned metadata and registration passed known watt equivalents for every selectable power unit.
4. Missing Angle navigation failed negative angle cases; pinned metadata and registration passed degree/radian/gradian relationships and identity.
5. Negative paste returned `0` instead of `-12.50`; validating signed decimals and applying the sign through the real core passed valid input, malformed/non-finite/range/length rejection and recovery.
6. Chinese titles remained English; adding the pinned names and accessible negate translation passed runtime English/Chinese switching with numeric state intact, both themes and narrow/wide layout/focus checks.

Supplemental real-QML regressions cover the pinned minus-sign digit budget, negating a 15-digit entry, backspace/clear, signed paste at the limit, editing either side, same-unit/reverse conversions, Settings shortcut isolation, and preservation of a pending arithmetic operation across all new modes. Numeric tolerances use independent known values and the pinned formatter's larger of `5e-8` absolute or `5e-7` relative error (temperature landmark checks use tighter bounds). Early development runs also exposed a too-tight test tolerance for small fixed power output and a test resize synchronization issue; those assertions now reflect the pinned display policy and wait for the real content width before measuring layout.

Current Qt API lookup used the `find-docs` skill and Context7 (`library Qt`, then `/websites/doc_qt_io_qt-6` Loader initial properties / Shortcut context and enabling), with no fallback required. UI guidance used the `ui-ux-pro-max` visible-keyboard-focus search and its accessibility/interaction checklist while preserving the pinned layout. Every GUI command uses the repository's compose/generic/offscreen/software launcher with private data/runtime and D-Bus; no active-desktop check was attempted. Windows/macOS and native display rendering remain unverified.
