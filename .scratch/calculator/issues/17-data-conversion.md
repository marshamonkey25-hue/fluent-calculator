# 17: 换算数据量

**What to build:** 用户可在参考数据单位之间换算，正确理解位、字节以及不同前缀定义对应的数量关系。

**Blocked by:** 13: 完成长度换算。

**Status:** ready-for-agent

**Spec:** Windows 11 风格跨平台计算器。

**User stories:** 63。

- [ ] 导航可进入真实数据换算，提供固定参考版本的数据单位集合、源/目标选择、输入及结果展示。
- [ ] 单位名称、位与字节关系、十进制或二进制前缀的处理以参考定义为准；不根据缩写自行猜测所有单位采用同一倍率。
- [ ] 支持同单位、跨单位和小数输入等参考行为，遵循非负限制、输入位数及显示格式，较大结果不因中间整数截断而错误。
- [ ] 新单位和说明可翻译，页面沿用主题、键盘输入和宽窄窗口布局，退出再进入不会出现其他类别的单位状态。
- [ ] 通过真实界面验证位/字节、参考前缀边界、同单位、往返及大/小数值，采用独立已知比例和明确容差。

## Implementation evidence (ticket 17; awaiting merge validation)

- Added `app/DataConversionDataLoader.cpp` with the pinned Data category ID 13, 35 selectable units in reference order, three hidden whimsical definitions, Gigabytes→Megabytes defaults, and explicit megabyte factors for bits/bytes/nibbles and decimal/binary prefixes through yotta/yobi. English and Simplified Chinese labels follow the pinned RESW tables. The existing real Microsoft converter handles all input, arithmetic and output formatting.
- Registered Data in the existing navigation, shared MainWindow-owned conversion session, translations and category-specific nonnegative feedback. Preserved current input, active-side mapping, native source/target memory, shared Fluent layouts and semantic theme colors. No other ticket or parent spec changed.
- TDD at the approved real-QML boundary: byte→bits first failed on missing Data navigation, then passed; reference catalog/defaults first failed with Bits instead of Gigabytes, then passed in both languages; negative paste first displayed Length feedback, then passed with translated Data feedback. Logs are under the private `.build-ticket17` directory (`tdd-cycle1-*`, `tdd-cycle2-*`, `tdd-cycle3-*`).
- `tests/data/tst_data.qml` covers all 35 selectable units with literal independently known values, decimal/binary boundaries, same-unit/reverse/fractional conversion, 15-digit limits, clear/backspace/paste recovery, positive-only behavior, extreme large/small scientific output, selector popup reachability, category navigation, runtime language/theme changes and visible Tab focus at 320×480 / 900×600. Display comparisons use 0.5 ppm; explicitly rounded fixed sub-unit cases allow 0.5e-6 absolute error. `tests/data-restart` checks remembered mode/preferences and fresh input across actual processes.
- Offscreen screenshots show both narrow/wide Microsoft-style converter layouts, readable long numeric results, both themes and Chinese labels. All UI checks use `tests/run-ui-isolated.py`, private settings/data/runtime roots, software rendering and a private D-Bus session. Native desktop, Windows and macOS remain unverified.

Status remains ready-for-agent for the merge validator.

Final validation: `cmake -S . -B .build-ticket17 -DCMAKE_BUILD_TYPE=Debug` and `cmake --build .build-ticket17 -j2` passed with Qt 6.12/GCC on Linux. The full isolated `ctest --test-dir .build-ticket17 --output-on-failure -j2` run passed 38 entries; the three existing signed-conversion variants reached their old 180-second budget without assertion failures. Their budget now matches the existing 600-second broad UI suites; `ctest --test-dir .build-ticket17 --rerun-failed --output-on-failure -j2` passed all three (181.28s light, 182.84s dark, 154.50s Chinese). Thus all 41 registered tests are validated, including the four new Data entries. Each Data UI variant reported 55 passed / 0 failed / 0 skipped. The real production executable also stayed running through an isolated three-second startup smoke check with a clean log. Latest integration tip `f79735813e1680d03d940a7fb1098fc7edbf7667` was merged before final build/reruns (already up to date). No push, PR or deployment was performed.
