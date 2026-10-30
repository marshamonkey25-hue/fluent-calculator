# 15: 换算能量、速度、时间和压力

**What to build:** 用户可在能量、速度、时间和压力四种类别中选择单位并完成换算，结果按参考规则显示。

**Blocked by:** 13: 完成长度换算。

**Status:** ready-for-agent

**Spec:** Windows 11 风格跨平台计算器。

**User stories:** 58, 60, 61, 64。

- [ ] 提供四个实际可用的导航入口，切换后展示对应类别的参考单位和结果，不保留上一类别的错误单位配对。
- [ ] 完整采用固定参考版本中这四类单位的定义与比例，特别区分速度中的长度/时间组合和各类时间单位的实际定义。
- [ ] 真实支持输入、源/目标单位选择、同单位转换和清除，遵循各类输入位数、非负限制、舍入及显示边界。
- [ ] 复用既有换算交互，所有新单位和说明接入翻译与主题，在宽窄窗口和键盘操作下保持可用。
- [ ] 每类通过界面验证已知数值、同单位、往返转换和输入边界；使用明确数值容差，不将实现本身的比例重新计算后当作独立期望。
- [ ] 核对四类单位清单完整性，并验证反复切换类别不会使单位、结果或可用按键失配。

## Ticket 15 implementation evidence (awaiting merge validation)

The four actual navigation entries use the existing `ConverterPage` and real portable Microsoft `UnitConverter`; `ConversionSession.category` selects category-specific metadata on one MainWindow-owned session, retaining input, active-side mapping and category unit choices through the real converter. Numeric strings stay intact across QML. Length and arithmetic remain on their existing paths. The category loader preserves 35 pinned unit definitions/factors (29 selectable plus six whimsical metadata entries); all selectable IDs/order/names and all numeric factors were audited against commit `79e1ac53bba690cdf930e5dcd6ed9dbc4cbfb128`. Regional speed defaults, thermal versus food calories, kilowatt-hours, the 365.25-day year, and rounded mph/knot/Mach/mmHg factors are retained. Resource-key/name whitespace for millimeters of mercury is normalized to expose the real translated label.

The existing Microsoft converter layout/keypad/palette is reused. Shared navigation now scrolls at minimum heights and reveals focused entries; explicit StrongFocus makes its mode delegates usable with Tab/Space. New mode names, every new unit name and negative-input messages participate in the shared English/Simplified Chinese translator and theme hooks. Registry keys also use the existing recent-mode persistence mechanism.

Approved test boundary: real MainWindow/QML navigation, unit controls, mouse/key input, displayed values/status/accessibility and rendered palette/layout, using the actual production converter and metadata. Clipboard tests use a real editable control to copy/paste. No converter/core mocks, private-method tests or recomputed ratio expectations were added. `tests/energy-speed-time-pressure/tst_energy_speed_time_pressure.qml` covers every selectable unit with literal worked examples, complete localized lists, same-unit and round-trip conversion, repeated category switching, 15-digit/decimal/backspace/clear limits for both input paths, negative/malformed/overlong paste and recovery, extreme scientific output, runtime theme/language changes, reference defaults, minimum/wide layout and keyboard navigation/focus.

Actual sequential TDD red → green evidence in the private `.build-ticket15` directory:

1. `red-energy.log` failed the absent Energy navigation entry; `green-energy.log` passed calorie → joule = 4.184 after the real loader/category/navigation hook.
2. `red-speed.log` failed the absent Speed entry; `green-speed.log` passed 100 mph → 44.7 m/s using pinned rounded speed data.
3. `red-time.log` failed the absent Time entry; `green-time.log` passed 1 year → 365.25 days.
4. `red-pressure.log` failed the absent Pressure entry; `green-pressure.log` passed 1 atmosphere → 101325 pascals.
5. `red-translations.log` failed all four Chinese mode titles; `green-translations.log` passed all four complete localized unit lists after adding the pinned catalog values.
6. `red-negative.log` exposed “Length cannot be negative” in all four new categories; `green-negative.log` passed category-specific notices and input recovery after the message bindings/catalog additions.
7. `navigation-layout.log` reproduced an unreachable Pressure entry at 320×480; `green-navigation.log` passed after the navigation viewport was added.
8. `navigation-keyboard.log` initially failed to Tab from Standard to Scientific; the same test passed after explicit StrongFocus. It also checks visible focus while scrolling to Pressure and Space activation.

The subsequent all-unit/input/round-trip/rounding/layout/preferences tests are regression checks of the now connected real converter; they are not claimed as additional feature reds. Fixed sub-unit rounding uses an explicit half-millionth absolute tolerance because the pinned formatter counts the leading zero among seven preferred digits (1 second → `0.016667` minutes). Scientific output and ordinary worked examples allow 0.5 ppm. No formatting algorithm was changed to satisfy a test expectation.

Skills read/applied: implement-spec; TDD including tests.md/mocking.md; ui-ux-pro-max with focused keyboard/focus guidance and its UI review references; find-docs. Context7 successfully resolved current Qt documentation and verified ComboBox value roles, data-driven QuickTest/keyClick, StrongFocus and Flickable/ScrollBar. No documentation fallback was needed. UI checks use only the shared compose/generic/offscreen/software launcher with private data/runtime/settings and D-Bus, with no host display or IME access.

Status remains `ready-for-agent` for independent merge review and closure; the parent spec and other tickets are unchanged.

Final reference review found that pinned `ApplicationViewModel.cs` retains a single converter view model, so category navigation must retain numeric input and unit choices. The supervisor explicitly approved the smallest shared-lifetime correction within ticket 15. `red-shared-converter-session.log` first showed Length → Energy incorrectly replacing input `2` with `0`; `green-shared-converter-session.log` passed after moving the ConversionSession to MainWindow and aggregating the existing metadata loaders into the real converter. Additional highest-seam regressions traverse Length and all four ticket15 categories, retain both active input sides, restore category unit selections, and assert fresh correct results. Tests that previously expected unconditional zero resets now assert the pinned retained-input behavior while preserving stale-unit/list checks. The native `SetCurrentCategory` path handles the reference negative → nonnegative transition by removing a leading minus; no alternative sign algorithm was introduced.

Shared integration contract: MainWindow owns one ConversionSession and passes its `converter` property into ConverterPage for every converter mode. ConverterPage no longer constructs a session per load. Additional metadata categories must join the composite loader/category-ID mapping in `ConversionSession.cpp` and the registry's converter-category key; retain every existing loader when merging parallel converter tickets. The original test matrix was intentionally interrupted after 21/29 passing entries to validate the approved lifetime correction with a fresh final matrix; `ctest-pre-shared-lifetime.log` is historical partial evidence, not a complete final pass.

Final feature validation uses `.build-ticket15` (Debug/Unix Makefiles, Linux x86_64, Qt 6.12.0, GCC 16.2.1, CMake 4.4.4, compile/test concurrency `-j2`). After the shared-session correction, `ctest-shared-focused.log` passed the affected English/light ticket15 and Length entries, and the final full matrix's ticket15 entries each passed **87 outcomes, 0 failed, 0 skipped** in English/light, English/dark and Simplified-Chinese/light (**261 feature outcomes**). `qmllint.log` is warning-free; `git diff --check` passes. The metadata audit matches every one of the 35 pinned IDs/double factors. Offscreen narrow/wide English/Chinese light/dark captures were reviewed; all 29 selectable units and both input sides remain functional. Native desktop rendering and Windows/macOS are unverified; independent merge validation still owns closure.

Final broad validation: `ctest --test-dir .build-ticket15 --output-on-failure -j2` passed **29/29 entries** in **1509.70 seconds** (`ctest-final-full.log`, exit 0), covering all inherited arithmetic, preferences/restarts, history, memory, Programmer, date, Length and Graphing configurations as well as ticket15. The latest `integration/calculator` merge was again a no-op at `2cbc82c3e9bc0139063f7ca8c78b2c333662071c`; ancestry is confirmed. The two final minimum-window/keyboard-navigation tests passed again in English/light, English/dark and Chinese/light (`final-navigation-*.log`, four QtTest outcomes each). Source remains confined to ticket15 metadata/UI/tests and the approved shared converter lifetime/navigation hooks. No remote push, PR, deployment or active-desktop GUI was performed.
