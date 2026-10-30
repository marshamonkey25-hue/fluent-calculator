# 14: 换算体积、面积、重量和质量

**What to build:** 用户可在体积、面积、重量和质量三个类别中选择参考单位并完成真实换算。

**Blocked by:** 13: 完成长度换算。

**Status:** ready-for-agent

**Spec:** Windows 11 风格跨平台计算器。

**User stories:** 54, 56, 59。

- [ ] 导航提供体积、面积、重量和质量三个真实可用入口；类别切换后单位集合、输入和结果属于当前类别。
- [ ] 各类别单位名称、定义和换算关系来自固定参考版本，覆盖参考范围内的公制及其他单位，不能仅实现一对示例单位。
- [ ] 每类均支持选择源/目标单位、输入、同单位转换及参考的清除和格式行为，禁止不适用的负值。
- [ ] 面积和体积按各自的定义换算，不能把长度比例直接当作面积或体积比例；重量和质量类别沿用参考命名与单位定义。
- [ ] 三类页面复用已工作的换算交互，沿用主题、可翻译文案、键盘行为和窗口适配。
- [ ] 每类通过界面验证至少一组独立已知比例、同单位、跨单位往返及输入边界，并核对单位清单覆盖和切换后无状态串用。


## Implementation evidence (worker; integration validation pending)

Status remains `ready-for-agent` for the merger. The six original acceptance checkboxes are left for independent merge validation.

- Added real Volume, Area and Weight and Mass navigation, sharing the existing ConverterPage and Microsoft UnitConverter. Category changes reset input/selection and use disjoint reference catalogs; settings preserve the current conversion.
- `app/MeasurementDataLoader.cpp` ports the pinned IDs, selectable order, names, abbreviations, dimensioned ratios and regional defaults. Coverage: all 20 volume units, all 10 ordinary area units, regional Pyeong, and all 14 weight/mass units; US/UK liquid measures and short/long tons remain distinct. English/Chinese resource values are traced to the pinned RESW files. Whimsical metadata remains outside selectors, as in Length.
- Real QML tests verify every selectable unit's name, ordering and known ratio; each category has identity/reverse/round-trip conversion, category isolation, positive-only input and recovery, 15-digit boundary, decimal/clear/backspace behavior and scientific extremes. Runtime English/Chinese and light/dark settings preserve data, with visible keyboard focus, accessibility labels and all controls fitting 320×480 and 900×600 windows.
- TDD cycle 1: the cubic-meters-to-liters test failed at missing `mode_volume` (`.build-ticket14/red-volume.log`), then passed with the complete volume catalog and shared category selection (`green-volume.log`, 3/3 outcomes).
- TDD cycle 2: square-meters-to-square-centimeters failed at missing `mode_area` (`red-area.log`), then passed with the area catalog (`green-area.log`, 4/4 outcomes).
- TDD cycle 3: pounds-to-kilograms failed at missing `mode_weight` (`red-weight.log`), then passed with the weight/mass catalog (`green-weight.log`, 5/5 outcomes). The initial numeric tolerance was corrected to the pinned six-decimal display policy for values below 1; the expected mathematical value remains 0.45359237 kg/lb. Further catalog assertions use explicit display-resolution tolerances documented in the test and converter provenance notes.
- The four dedicated CTest entries passed in the first expanded run: English/light, English/dark and Chinese/light each have 70/70 outcomes; Japanese-region catalog/default checks have 50/50, including Pyeong. `ctest --test-dir .build-ticket14 -R calculator-volume-area-mass --output-on-failure -j2` passed 4/4 in 193.97 seconds. `cmake --build .build-ticket14 --target all_qmllint -j2` passed without warnings.
- Twelve offscreen captures in `.build-ticket14/ticket14-*.png` cover all categories at narrow/wide sizes in English/light and Chinese/dark. Reviewed representative captures for all three categories; the inherited pinned keypad and equal landscape columns remain intact.
- Required skills were read: implement-spec; TDD and both companion documents; ui-ux-pro-max and its UI references; find-docs. The relevant keyboard/focus UX search succeeded. Context7 resolved Qt and returned official Qt 6.8 ComboBox model-role/currentValue documentation; no fallback was needed. All UI runs use the existing isolated offscreen/software/private-D-Bus launcher with private settings/data roots. No active-desktop launch occurred. Windows/macOS and native-display rendering remain unverified.

- Final validation against integration tip `2cbc82c3e9bc0139063f7ca8c78b2c333662071c`: production/test build and warning-free QML lint pass; the complete isolated matrix passes **30/30 CTest entries** in **1777.01 seconds** (`ctest --test-dir .build-ticket14 --output-on-failure -j2`, `.build-ticket14/full-ctest.log` and `Testing/Temporary/LastTest.log`). This includes all 26 pre-existing entries and all four added converter entries. The added entries contain 260 passing QtTest outcomes in aggregate (70 each in English/light, English/dark and Chinese/light; 50 regional catalog/default outcomes).
- Integration was verified as an ancestor before implementation and merged before the final build/full run; it remained unchanged during validation. No parent specification, other ticket, global agent configuration, remote, PR or deployment was modified. Independent review/merge validation remains the next step.
