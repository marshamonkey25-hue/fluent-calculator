# 08: 执行位运算并操作位显示

**What to build:** 用户可在程序员模式中执行逻辑与位操作，查看和操作参考位显示，检查不同位宽下的实际整数结果。

**Blocked by:** 07: 使用程序员模式的进制与位宽。

**Status:** resolved

**Spec:** Windows 11 风格跨平台计算器。

**User stories:** 29, 31。

- [x] 接入固定参考版本支持的逻辑、移位及其他位操作；具体操作清单与参考按键保持一致，不把不同移位或位操作合并成错误的统一语义。
- [x] 位显示及参考允许的位编辑交互反映当前整数值；位变化与各进制结果互相同步。
- [x] 当前位宽决定可见或可操作的位、有效输入和结果范围，控件禁用状态与实际行为一致。
- [x] 最高位、带符号值、移位边界及结果截断采用固定参考行为；错误输入不会破坏程序员模式后续计算。
- [x] 位面板和新增操作在合理宽窄窗口中可使用，沿用主题、可翻译说明及参考键盘规则。
- [x] 通过用户操作验证逻辑组合、参考支持的移位变体、位编辑、位宽切换和边界整数，并检查显示与真实结果一致。

## Implementation evidence (ticket 08; merge validation pending)

Status remains **ready-for-agent** for the independent integration reviewer. Scope is limited to this ticket; parent spec and other tickets are unchanged.

- Production uses the existing session-owned Microsoft manager for AND/OR/NOT/NAND/NOR/XOR, arithmetic/logical shifts, circular rotations and rotations through carry. No replacement integer arithmetic or JavaScript numeric conversion was introduced. Shift counts, signs, truncation and carry remain native-core behavior.
- The separate `ProgrammerBitPanel.qml` presents the pinned four-by-sixteen, nibble-grouped bit layout, with core-backed editing and disabled bits above the active width. Numeric values and binary representations cross the bridge only as strings; position arguments are validated before native bit commands.
- The first keypad row now matches pinned `CalculatorProgrammerRadixOperators.xaml`: A / left / right / shared C-CE / backspace. The supervisor approved correcting ticket 07's separate C/CE slots; the shared slot reads `CalculatorManager::IsInputEmpty()`, including zero entry and completed-result semantics. Escape/Delete remain independently available. Existing Programmer tests were adapted to the reference layout and retain their arithmetic/clear/translation coverage.
- New controls inherit palette/focus styling and use the shared translation catalog. Runtime Chinese translation, Settings shortcut isolation, reference keypad shortcuts remaining active in bit view, focus/Space, and 320×460 / 360×560 / 900×700 layouts are covered.
- Reference behavior/layout/shortcuts: pinned `Views/CalculatorProgrammerRadixOperators.xaml{,.cs}`, `Views/CalculatorProgrammerBitFlipPanel.xaml{,.cs}`, `Resources/{en-US,zh-CN}/Resources.resw`, `CalculatorUITests/ProgrammerModeFunctionalTests.cs`, and native `CEngine/{scifunc,scioper,sciset,scicomm}.cpp`.

### Recorded red → green cycles

Each cycle added one external QML behavior test before minimal production changes, using real navigation/controls and the actual arithmetic core:

1. AND flyout: missing `bitwiseButton` → native AND with 25 AND 7 = 1 and synchronized radix displays.
2. Logical operations and pinned accelerators: missing remaining controls / keyboard input yielding 257 → all six native operations, reference two-row flyout, and `& | ~ . \\ ^` shortcuts.
3. Shared C/CE: both independent controls present → core entry-state binding, reference shared position, pending-operand CE versus full Escape clear and Delete semantics.
4. Shift variants: missing shift selector → four separately mapped modes, both directions by mouse and `<`/`>`, including Byte 81 circular versus arithmetic/logical differences and carried-out-bit reuse.
5. Bit editing: missing bit-panel control → real bit 63/0 edits preserving exact signed 64-bit values, radix synchronization and continued arithmetic.
6. Live translation: English bit-panel name after choosing Chinese → shared page/panel catalogs preserving current bits/shift mode and blocking hidden Settings shortcuts.
7. Mouse error recovery: shared clear slot disabled during error → actual command determines enabled state; mouse clear and subsequent 2 + 3 = 5 pass.
8. Selector state: clicking the current keypad selector unchecked it → exclusive selectors preserve selected state and visible panel.
9. Final keyboard-reference audit: a new bit-view keyboard calculation displayed 0 instead of 5 → digit, arithmetic, logical, shift and C/CE shortcuts remain active in bit view and update the same bits. The earlier expectation that hidden keypad shortcuts should be disabled was corrected against `OperatorsPanel.xaml` (hidden but still enabled) and `KeyboardShortcutManager.cs` (dispatches by IsEnabled). Settings remains isolated. This is a documented reference correction, not a change in scope.

Logs `tdd-01-{red,green}.log` through `tdd-09-{red,green}.log` are retained in the implementer's private `.build-ticket08/`. Early cycles used `tests/qml/tst_programmer_bits.qml`; the final suite lives at `tests/programmer/tst_programmer_bits.qml` with separate theme/language CTest entries. Boundary cases that already passed imported-core behavior are regression evidence, not claimed new red cycles. A preliminary shift-error assertion was corrected against the pinned resource table ("Result not defined" / "结果未定义"); that expectation correction is not a production red/green claim.

### Validation and platform notes

- Private Debug build: Qt 6.12.0, GCC 16.2.1, CMake/Make, `-j2`, isolated settings/data/cache, offscreen/software rendering. Focused new suite: **31 passed, 0 failed, 0 skipped**; existing Programmer suite: **38 passed, 0 failed, 0 skipped**. QML lint is warning-free.
- All 64 bits, each width and sign bit, exact high-bit integers, logical combinations, complement masks, all shift modes/carry, zero/count-at-width boundaries, error guards/recovery, truncation/sign extension and pending-operand bit edits are exercised through real QML controls.
- Native Wayland selected high-bit and four shift-mode checks: **7 passed, 0 failed, 0 skipped**. A broader native run lost activation to an unrelated desktop Chrome window after resizing (7 passed / 24 failed); it is recorded as failed, not treated as acceptance evidence. Deterministic full behavior verification uses offscreen.
- Standalone executable was observed as native Wayland (`xwayland=false`) with isolated Programmer preferences; a normal compositor close exited **0** with no application diagnostics.
- Context7 resolved Qt and verified Qt 6.8 Popup/AbstractButton APIs; no documentation fallback was needed. The UI skill's targeted keyboard-focus search supported visible focus and focus-reveal behavior; no new design direction was introduced.
- The first combined CTest attempt hit the former 180-second main-suite timeout without preceding assertion failures. Main/specialized UI limits are now 300 seconds for the growing combined suite; final full validation is recorded below.
- Windows/macOS remain unverified. The existing Standard Copy-key-sequence runtime warning is unchanged; clipboard regressions remain in the main suite. Independent review and integration merge validation remain required before closing this ticket.

### Final implementation validation

The final corrected build passes **all 7 CTest entries** (`ctest -j2 --output-on-failure`): each English/light, English/dark and Chinese/light main suite reports **187 passed / 0 failed / 0 skipped**; each separate Programmer bit suite reports **32 passed / 0 failed / 0 skipped**. All seven independent restart stages also pass. Final total CTest elapsed time: **498.40 seconds**; main entries completed in 185–207 seconds and bit suites in 99–108 seconds, within the measured 300-second limits. Full logs are `.build-ticket08/ctest-full.log` and `.build-ticket08/Testing/Temporary/LastTest.log`.

The final bit-view keyboard correction additionally passes native Wayland (**3/3**, `.build-ticket08/wayland-keyboard.log`), supplementing the earlier **7/7** selected native high-bit/shift checks. Light/dark narrow/default/wide captures and final Chinese menu/bit captures were reviewed; no pixel-equivalence or three-platform validation claim is made. Final QML lint and whitespace checks pass. No tests or acceptance items were silently dropped; the initial native focus failure and timeout remain documented above.

Latest `integration/calculator` tip **06ffcdfa4f0006ba36496e6210bd870b2fad2c1e** was merged/checked before the final full run and rechecked after it (already up to date). The integration tip is an ancestor; no conflicts or unrelated changes were discarded. Independent reviewer acceptance and integration merge validation remain the closure gate; **Status stays ready-for-agent**.

## Merge acceptance and completion evidence

- Merged source `111b6f6638986f59bde023052c30dbebc2f306f0` with `git merge --no-ff` into the initially clean root `integration/calculator` checkout; merge commit `28ad9676e8e78660b7780881d01195bb8da506aa`. CMake/header/catalog/README conflicts were combined, preserving tickets 05/06, the shared isolated launcher, all earlier translations, and the 600-second integration UI limit. Existing navigation, Scientific pages, test bootstrap/launcher and system appearance code remain byte-for-byte unchanged from pre-merge `c2a7b90`.
- All six criteria are fulfilled by the native core commands, string-only integer/radix state, guarded bit edits and real-QML tests. Coverage includes all logical/shift variants and carry, every bit and word width, exact signed high-bit values, count boundaries, truncation/sign extension, recovery, translation, navigation/Settings shortcut isolation, focus and 320×460 / 360×560 / 900×700 layouts. All 50 Programmer translation source strings are present in the Chinese catalog.
- Integration fixes `8688a156e24c7a4d7f0af6788b00f8844575b772` and `140d28f495fbd7c6d5a96ffa166de9dadf022380` retain readable selected Keypad/Bits text with the shared theme fallback, give both flyouts palette-backed surfaces, and keep complete popup backgrounds inside narrow windows. Actual real-QML reds reproduced dark selector contrast, light shift-menu contrast and 320-pixel popup clipping before the respective fixes; focused light/dark checks then passed **7/7 each**. Additional navigation and shift-state contrast regressions are retained; previously green checks are not claimed as new red cycles. Capture names now follow visible application colors rather than unsupported platform hints.
- Linux x86_64 / Qt 6.12 / GCC 16.2 Debug/Make configure, `cmake --build .build-integration -j2`, and QML lint pass. Final frozen `ctest --test-dir .build-integration --output-on-failure -j2` passes **8/8 entries** in **615.16 seconds**: **298 passed / 0 failed / 0 skipped** in each main configuration, **35 / 0 / 0** in each Programmer-bit configuration, all seven restart stages (**21 QtTest outcomes**) and three isolation checks. Main configurations completed in 269.87–274.77 seconds; bit configurations in 109.29–116.05 seconds. No functionality, tests or assertions were skipped.
- Evidence is in `.build-integration/merge08-{configure,build,build-final,build-menus}.log`, `merge08-selector-{red,green}.log`, `merge08-menu-bounds-red.log`, `merge08-menus-green-{light,dark}.log`, `merge08-ctest-accepted.log`, `Testing/Temporary/LastTest.log`, and `merge08-qmllint-menus.log`. Earlier interrupted/regression runs remain in `merge08-ctest-initial.log` and `merge08-ctest-final.log`; they are not final acceptance passes. Corrected narrow/wide light/dark and Chinese bit/menu captures were reviewed. Context7 verified Qt 6.8 ToolButton customization, palette roles and Popup margins; no documentation fallback was needed.
- Every GUI run/capture in this merge used compose/generic/offscreen/software, private settings/cache/data/runtime roots and a private Linux D-Bus through the repository launcher before GUI construction. No active-desktop/native validation was performed. Windows/macOS and native desktop behavior remain unverified; the inherited Standard Copy warning remains with clipboard tests passing. Merger review found no remaining ticket 08 blockers; final application-wide independent review remains pending. Parent spec and other tickets are unchanged; no remote push, PR or deployment occurred.
