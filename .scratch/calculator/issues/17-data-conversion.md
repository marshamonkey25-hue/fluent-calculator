# 17: 换算数据量

**What to build:** 用户可在参考数据单位之间换算，正确理解位、字节以及不同前缀定义对应的数量关系。

**Blocked by:** 13: 完成长度换算。

**Status:** resolved

**Spec:** Windows 11 风格跨平台计算器。

**User stories:** 63。

- [x] 导航可进入真实数据换算，提供固定参考版本的数据单位集合、源/目标选择、输入及结果展示。
- [x] 单位名称、位与字节关系、十进制或二进制前缀的处理以参考定义为准；不根据缩写自行猜测所有单位采用同一倍率。
- [x] 支持同单位、跨单位和小数输入等参考行为，遵循非负限制、输入位数及显示格式，较大结果不因中间整数截断而错误。
- [x] 新单位和说明可翻译，页面沿用主题、键盘输入和宽窄窗口布局，退出再进入不会出现其他类别的单位状态。
- [x] 通过真实界面验证位/字节、参考前缀边界、同单位、往返及大/小数值，采用独立已知比例和明确容差。

## Implementation evidence (ticket 17; before integration merge)

- Added `app/DataConversionDataLoader.cpp` with the pinned Data category ID 13, 35 selectable units in reference order, three hidden whimsical definitions, Gigabytes→Megabytes defaults, and explicit megabyte factors for bits/bytes/nibbles and decimal/binary prefixes through yotta/yobi. English and Simplified Chinese labels follow the pinned RESW tables. The existing real Microsoft converter handles all input, arithmetic and output formatting.
- Registered Data in the existing navigation, shared MainWindow-owned conversion session, translations and category-specific nonnegative feedback. Preserved current input, active-side mapping, native source/target memory, shared Fluent layouts and semantic theme colors. No other ticket or parent spec changed.
- TDD at the approved real-QML boundary: byte→bits first failed on missing Data navigation, then passed; reference catalog/defaults first failed with Bits instead of Gigabytes, then passed in both languages; negative paste first displayed Length feedback, then passed with translated Data feedback. Logs are under the private `.build-ticket17` directory (`tdd-cycle1-*`, `tdd-cycle2-*`, `tdd-cycle3-*`).
- `tests/data/tst_data.qml` covers all 35 selectable units with literal independently known values, decimal/binary boundaries, same-unit/reverse/fractional conversion, 15-digit limits, clear/backspace/paste recovery, positive-only behavior, extreme large/small scientific output, selector popup reachability, category navigation, runtime language/theme changes and visible Tab focus at 320×480 / 900×600. Display comparisons use 0.5 ppm; explicitly rounded fixed sub-unit cases allow 0.5e-6 absolute error. `tests/data-restart` checks remembered mode/preferences and fresh input across actual processes.
- Offscreen screenshots show both narrow/wide Microsoft-style converter layouts, readable long numeric results, both themes and Chinese labels. All UI checks use `tests/run-ui-isolated.py`, private settings/data/runtime roots, software rendering and a private D-Bus session. Native desktop, Windows and macOS remain unverified.

At implementer handoff, status remained ready-for-agent for independent merge validation.

Implementer validation: `cmake -S . -B .build-ticket17 -DCMAKE_BUILD_TYPE=Debug` and `cmake --build .build-ticket17 -j2` passed with Qt 6.12/GCC on Linux. The full isolated `ctest --test-dir .build-ticket17 --output-on-failure -j2` run passed 38 entries; the three existing signed-conversion variants reached their old 180-second budget without assertion failures. Their budget now matches the existing 600-second broad UI suites; `ctest --test-dir .build-ticket17 --rerun-failed --output-on-failure -j2` passed all three (181.28s light, 182.84s dark, 154.50s Chinese). Thus all 41 registered tests are validated, including the four new Data entries. Each Data UI variant reported 55 passed / 0 failed / 0 skipped. The real production executable also stayed running through an isolated three-second startup smoke check with a clean log. Latest integration tip `f79735813e1680d03d940a7fb1098fc7edbf7667` was merged before final build/reruns (already up to date). No push, PR or deployment was performed.

## Independent integration completion

Merged `ed530f29e5c52c1b55828d72df5a48d3dcf55ef1` with `--no-ff` into the initially clean `integration/calculator` checkout as **`a226e4d78e50eec1c5eac6e2fd05e865454f9d16`**. No conflicts or integration fixes were needed. All existing categories, the application-owned conversion session, navigation, translations and 37 inherited CTest entries are preserved. Review found no blockers; all five acceptance criteria above are fulfilled.

- Independent comparison against the pinned C# loader and English/Chinese RESW tables matched all 38 Data IDs, stable order, names/abbreviations, defaults/flags, explicit megabyte factors and Chinese fallback labels (`.build-integration/merge17-metadata-audit.log`). The original three red→green logs were inspected and confirm the reported navigation, default-unit and negative-feedback failures and fixes.
- `cmake -S . -B .build-integration -DCMAKE_BUILD_TYPE=Debug`, `cmake --build .build-integration -j2` and `cmake --build .build-integration --target calculator_ui_qmllint -j2` pass on Linux/Qt 6.12/GCC, with clean lint output. Logs use `.build-integration/merge17-{configure,build,qmllint}.log`.
- `ctest --test-dir .build-integration --output-on-failure -j2` passes **41/41 entries in one run**, **2355.47 seconds**, exit 0. Each Data light/dark/Chinese variant reports **55 passed, 0 failed, 0 skipped**; both Data restart processes report **3 passed, 0 failed, 0 skipped**. Logs: `.build-integration/merge17-ctest.log` and `.build-integration/merge17-LastTest.log`. No tests were omitted or weakened.
- Fresh integration captures at 320×480 and 900×600 were inspected in light/dark and Chinese; long numeric values, unit labels and keyboard focus remain readable. Captures are `.build-integration/ticket17-*.png`. The production executable also passed a three-second isolated startup smoke check with empty diagnostics (`merge17-production-{smoke,output}.log`).
- All 41 CTest commands and every GUI/helper/capture process use `tests/run-ui-isolated.py`, compose/generic/offscreen/software rendering, private configuration/data/cache/runtime roots and private D-Bus. No desktop windows/input, host IME or inherited session bus were used. Windows/macOS and native desktop rendering remain unverified. Parent spec is unchanged; no push, PR or deployment occurred.
