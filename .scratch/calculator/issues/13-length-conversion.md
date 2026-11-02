# 13: 完成长度换算

**What to build:** 用户可进入长度换算，选择源单位和目标单位，输入数值并得到格式正确的真实结果；这一完整流程成为其他换算类别的可复用交互。

**Blocked by:** 01: 运行真实核心驱动的标准计算器。

**Status:** resolved

**Spec:** Windows 11 风格跨平台计算器。

**User stories:** 46, 47, 55。

- [x] 从导航进入可用的长度换算，具备参考源/目标单位、输入、清除与结果展示，单位与比例可追溯到固定参考版本。
- [x] 改变输入或单位后计算真实结果，支持同单位转换；参考允许的输入侧切换或单位交换操作保持结果与状态一致。
- [x] 遵循长度类别的符号、输入位数和显示规则，包括小值、大值、舍入及必要的科学计数形式；换算数值策略不冒充算术核心的任意精度能力。
- [x] 非法输入和不可显示结果有明确状态，纠正后能正常换算；按钮和键盘入口遵循相同规则。
- [x] 换算交互能够复用于后续类别而不复制整套输入和格式逻辑，但本任务必须先完整交付长度换算，不能只交付抽象框架。
- [x] 页面沿用主题、可翻译单位名称与说明，以及宽窄窗口布局。
- [x] 通过真实界面验证已知比例、往返转换、同单位、小数、非法负值、输入位数和显示边界，容差按数值策略明确规定。


## Implementation evidence (ticket 13; pending merge review)

The following implementation snapshot predates integration review; final closure evidence follows below.

- `app/LengthDataLoader.cpp` ports the pinned length serialization ID, all 12 selectable units, ordering, region defaults and metre factors. Metadata is separate from `ConversionSession`, which uses the real Microsoft `UnitConverter` / `NumberFormattingUtils` noncurrency path. The selected sources retain MIT provenance; PPL/Bing currency interfaces are explicitly excluded, without stubs. See `third_party/microsoft-calculator/README.md`.
- `ConverterPage` provides the reference two value/unit pairs, selectable input side, three-column/five-row keypad, CE, Backspace and keyboard equivalents, live conversion and same-unit conversion. `ConverterValue` / `ConverterUnitSelector` share semantic palettes, visible focus and translated accessible names. The stable `length` registry entry uses existing navigation, language, theme and recent-mode hooks.
- Entry/formatting preserves the upstream converter's double policy, 15-digit cap, seven preferred display digits, adaptive precision and scientific thresholds. Numeric values cross QML as strings. Complete-decimal paste validation supplies visible negative, malformed, limit and unrepresentable-value states; new input recovers. Copy/Paste works from the selected side and the context menu. Scientific exponent zeroes are preserved when a result becomes the opposite input and same-unit conversion is selected.
- `tests/length/tst_length.qml` exercises the real QML controls and actual conversion data/core. Coverage includes every selectable unit's independently known metre equivalent, both input sides and input methods, decimal and same-unit/round-trip cases, negative/malformed/overflow input and recovery, digit caps/backspace/clear, adaptive rounding, tiny/large scientific output, exponent reuse, clipboard operations, hidden shortcuts, dropdown isolation, live English/Chinese and theme changes, readable indicator contrast, keyboard focus and 320×560 / 900×600 layouts. Approximate results use at most 0.5 ppm (seven significant digits); exact known displayed values also have literal assertions. No converter mocks or private-method tests were added.
- `tests/length-restart` and its CMake driver verify the recent Length mode and Chinese/dark preferences across ordinary separate-process restarts, with fresh entry and working conversion. All UI processes use the shared isolated launcher before QGuiApplication, private storage/runtime/D-Bus, compose/generic/offscreen/software rendering and no host display.

### TDD red → green evidence

Each numbered log pair is `/tmp/ticket13-red-N.log` and `/tmp/ticket13-green-N.log`:

1. Missing `mode_length` navigation → visible inches-to-centimeters conversion.
2. Only two units instead of 12 → complete pinned selectable catalog and known ratios.
3. Second value could not become input → mouse/Space input-side switching and reverse/same-unit conversion.
4. Missing grouped 15-digit display → non-rounding text grouping, digit-cap notice and editing recovery.
5. Missing invalid-input state/context paste → complete-decimal paste validation and translated recovery states.
6. Missing selected-value Copy → raw-text keyboard/context Copy, including scientific output.
7. Blue active-value surface → neutral reference surface, bold active value and equal landscape columns.
8. Stale “To” accessibility label → Input/Result names with the current unit after switching sides.
9. Same-unit scientific reuse changed `e-20` to `e-2` → minimal upstream trailing-zero guard for scientific text.
10. Pale dropdown indicator failed rendered 3:1 contrast → vector chevron using semantic text color.

Additional rounding/boundary and settings/navigation tests confirmed already-supported behavior and are not claimed as new red cycles. Context7 successfully verified current Qt ComboBox model roles and QuickTest image/pixel APIs; no fallback was needed. UI skill search verified visible keyboard-focus guidance; the pinned Microsoft layout remained the design baseline.

### Checked validation

Private Make/Debug build: `.build-ticket13`, Linux x86_64, Qt 6.12.0, GCC 16.2.1; compile concurrency `-j2`.

- `cmake --build .build-ticket13 -j2`: passed; production executable and QML tests link successfully (`/tmp/ticket13-final-build.log`).
- `cmake --build .build-ticket13 --target calculator_ui_qmllint -j2`: passed without warnings (`/tmp/ticket13-final-qmllint.log`).
- Full regression invocation `ctest --test-dir .build-ticket13 --output-on-failure -j2`: all **12 existing** isolation/restart/main/Programmer-bit/history CTest entries passed. This development-time run also observed two Length failures while the final accessibility/indicator slices were being completed; it is not represented as a single all-green run (`/tmp/ticket13-ctest.log`).
- After the final integration-tip merge check and rebuild, `ctest --test-dir .build-ticket13 --output-on-failure -R '^calculator-length-' -j2`: **4/4 passed**, with **44 passed, 0 failed, 0 skipped** in each English/light, English/dark and Chinese/light suite; both independent restart stages passed. Final targeted run took 109.97 s (`/tmp/ticket13-final-length.log`; detailed outcomes in the private build's `Testing/Temporary/LastTest.log`). Together these runs check all 16 current CTest entries.
- Final English light/dark and Chinese offscreen narrow/wide captures were reviewed in the private build. `git diff --check` passed. Integration tip `d327f2de0e09bca87e02416e42374db91a506883` was merged/confirmed already present before final affected checks.

Windows/macOS and native desktop interaction are unverified. No native desktop GUI was opened, no remote push/PR/deployment occurred, and independent merge review remains required.


## Integration completion and acceptance

Merged `c4c2f5d7907c2eb156ad58f707cacac73f697f07` into the clean `integration/calculator` checkout using `git merge --no-ff`, producing `19471a93a7bc8582561cad1a62d644491ee1b044`. CMake, navigation, README and Chinese-translation conflicts preserve both the integrated memory/date features and Length. All 200 pre-merge translations and all 194 ticket-branch translations remain intact. Both parent histories remain ancestors; the existing shell, arithmetic controller, memory/date pages and isolated launcher are unchanged. The parent spec was not edited.

Independent merger review verified all seven criteria: all 12 reference units and metre factors, real input/unit updates and either input side, same-unit/round-trip conversion, pinned double formatting and limits, explicit recoverable paste errors, shared input/formatting components, and translated/theme-aware keyboard-accessible narrow/wide UI. The real-QML suites cover the required input/display boundaries and independent known ratios with their documented numeric tolerances. English/Chinese unit names were independently compared with the pinned RESW files. Offscreen English/light narrow, English/dark wide and Chinese/light narrow captures were reviewed; values, scientific output, selector arrows and keyboard focus remain readable.

Review found the source/target default flags reversed relative to the pinned `AddUnit(... isSource, isTarget ...)` definitions. Commit `a6406e6` fixes only these flags: customary regions start with centimeters → inches; SI regions start with inches → centimeters. A new real-QML startup test first failed with source ID 32 instead of 30, then passed for US and Chinese locales. The territory list already matches the pinned revision. Restart expectations were updated for the corrected US defaults. Commit `5af461a` corrects the restart's display literal to the pinned six-decimal `0.393701` for 1 cm → inches; no production rounding algorithm changed.

Integration validation on Linux x86_64 / Qt 6.12 / GCC 16.2.1:

- `cmake -S . -B .build-integration -G 'Unix Makefiles' -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON` and `cmake --build .build-integration -j2`: passed, including the production executable and real-QML test binary. Logs: `.build-integration/merge-13-configure.log`, `merge-13-build.log` and `merge-13-build-fixed.log`.
- `cmake --build .build-integration --target calculator_ui_qmllint -j2`: passed without warnings; `.build-integration/merge-13-lint.log`.
- `ctest --test-dir .build-integration --output-on-failure -j2`: **22/23 passed**, **1,252.60 seconds**. All **19 pre-existing entries** and all three Length suites pass. Per language/theme: **298 application / 35 Programmer-bit / 20 history / 21 memory / 28 date / 45 Length outcomes**, zero failures/skips. The sole failing entry was the new restart literal noted above (`0.393701` actual versus `0.3937008` expected). Original summary/details are preserved in `.build-integration/merge-13-ctest.log` and `merge-13-full-LastTest.log`.
- After correcting only that test literal, `ctest --test-dir .build-integration --rerun-failed --output-on-failure -j2`: **1/1 passed**, **2.22 seconds**. Both separate-process Length write/restore stages report **3 passed / 0 failed / 0 skipped**. Logs: `.build-integration/merge-13-restart-rerun.log` and `merge-13-restart-LastTest.log`. Every registered entry's final result is passing across these runs; no single all-green full invocation is claimed.
- US/Chinese startup regression red/green logs: `.build-integration/merge-13-defaults-red.log`, `merge-13-defaults-green.log`, `merge-13-defaults-zh-green.log`. Translation/ancestry/preserved-module checks: `.build-integration/merge-13-integrity.log`. `git diff --check` passes, and the index is empty after commits.

All GUI checks used the shared offscreen/software/compose/generic launcher, private settings/cache/data/runtime roots and a fresh private Linux D-Bus. Running test environments independently confirmed absent desktop/IME selectors and private bus sockets. No active-desktop GUI, push, PR or deployment occurred. Known pre-existing Standard Copy-shortcut and offscreen size-hint warnings remain; checked behavior passes. Windows/macOS and native rendering remain unverified. Independent merge review found no remaining ticket 13 blocker; final application-wide review remains part of the parent workflow. Ticket 13 is resolved on the evidence above.
