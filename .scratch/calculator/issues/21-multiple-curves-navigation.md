# 21: 比较多条曲线并浏览坐标

**What to build:** 用户可以添加、修改和删除多条函数，在同一坐标系比较曲线，通过平移、缩放和坐标查看探索图形。

**Blocked by:** 20: 输入函数并绘制真实曲线。

**Status:** resolved

**Spec:** Windows 11 风格跨平台计算器。

**User stories:** 41, 42, 43, 44, 45。

- [x] 用户可添加、修改和删除多条 y=f(x) 函数，函数列表与曲线之间有清晰的对应标识，选择和编辑不会误改其他函数。
- [x] 多条曲线依据各自实际表达式绘制，某一函数无效时有明确反馈，不导致其他有效曲线无法使用。
- [x] 支持平移和缩放，坐标轴、刻度、可见范围及曲线同步更新；视图操作有合理边界，不产生无效范围或卡死。
- [x] 用户可查看坐标，显示值与实际坐标变换一致；若显示曲线上的取样值，应关联正确函数并避免把无定义点伪装成有效点。
- [x] 修改函数和视图范围后重新处理无定义区间与渐近线，不因旧采样或快速交互产生错误连线或过期曲线。
- [x] 函数管理及视图操作在宽窄窗口、浅深主题下可辨可用，说明可翻译并遵循应用焦点规则。
- [x] 通过用户操作验证多函数管理、已知曲线位置、缩放/平移后的坐标读取，以及视图变化下的不连续处理；不能仅以曲线数量或截图存在作为验收。

## Ticket 21 implementation evidence (recorded before merge validation)

At implementation handoff, Status and acceptance checkboxes remained ready/open for the merger. No parent-spec or other-ticket status was changed.

- Extended the existing `FunctionGraph` and `GraphingPage`, retaining the pinned upstream 800 px view switch and 2:1 graph/equation hierarchy. Functions have independent compiled expressions, samples and feedback, stable F identifiers, theme-derived colors, visible graph labels and selectable equation rows. Add/edit/delete and invalid-function isolation use the same actual restricted evaluator as ticket 20.
- Added pan buttons, drag and focused arrow-key navigation; zoom buttons, wheel and +/− keys; reset/Home; synchronized viewport ranges, decimal grid/ticks and resampling. Span is bounded to `1e-6…1e6`, center coordinates to `±1e9`. Adaptive display precision keeps deep-zoom limits distinct after panning.
- Clicking the graph (or Space at its focused center) reports pointer coordinates and the selected function's exact evaluated double value at that x, rather than a clipped/interpolated sample. Undefined values are explicit; finite markers appear only inside the current view. Selection, expression and viewport changes refresh the inspection.
- Translated function controls, view actions, undefined values and scrollable navigation help; preserved semantic palettes, native controls, accessible labels/selection, visible graph focus and editor focus return. Rendered selected-row text and labeled-curve contrast are checked in both themes. Long expression status is limited to two visible lines while retaining its full accessible text.
- Expanded the existing real-QML seam in `tests/graphing/tst_graphing.qml`; no core/evaluator/controller mocks. Known multiple-curve positions, independent edits/deletions/stable IDs, invalid isolation, exact coordinate examples, undefined poles, repeated pan/zoom/edit discontinuities, drag/wheel/keyboard and zoom boundaries, translated help, both themes and both window sizes are covered. Existing ticket20 cases remain present. Three existing graph suites have a 180 s timeout to accommodate added public-operation coverage.

Actual red→green cycles retained in private `.build-ticket21/red-NN.log` and `green-NN.log`:

1. Missing Add function control → two independent curves, selective edit, invalid isolation and deletion.
2. Missing zoom/pan controls → known parabola positions and synchronized viewport ranges after zoom/pan/reset.
3. Missing coordinate display → transformed pointer coordinates, selected F1(x)=6.25 and undefined F2 feedback.
4. Drag leaves the viewport unchanged → drag/keyboard pan, zoom/reset and bounded zoom controls. Drag assertions allow one screen-pixel rounding; fixed button/keyboard examples use literal ranges.
5. Add function remains English under Chinese → translated function/view controls and usable narrow/wide layouts in both themes.
6. Existing long-expression regression overflows the narrow window → bounded visible status with all controls inside the allocation.
7. Deep zoom after panning renders identical x limits → adaptive precision retains distinct, correct limits.
8. Navigation help is missing → translated scrolling help and Escape/editor focus return.
9. Selected equation text fails rendered 4.5:1 contrast → semantic highlightedText fixes both themes.
10. Additional labeled-curve colors fail contrast against the graph surface → blend theme-derived hues toward the semantic foreground only as needed for 4.5:1 contrast; verify actual curves still match their readable legend colors.
11. Deep zoom at the `1e9` pan boundary halves the apparent displayed span → up to 17 significant digits and actual representable axis spans keep range labels, samples, painting and coordinate inspection aligned. The user-operation test allows `5e-8` absolute error for the `1e-6` span, accounting for double spacing at this magnitude.
12. Tab reaches a clipped function row in a narrow seven-function list → scroll focused rows fully into view, following the application's existing focus rule.

Additional stable-ID/middle-deletion, wheel, view-change discontinuity and existing mathematical cases are regression coverage, not claimed as separate red cycles. Early development logs also retain a failed full graph run for long-status overflow and a later exponent-format literal mismatch (`e-7` versus QString `e-07`); the final test compares numeric limits instead of irrelevant exponent spelling. The Chinese matrix exposed fractional-pixel center assumptions: an odd graph width makes the clicked x correctly differ from the exact mathematical center. Exact-center examples now use the documented Space operation, while direct mouse-coordinate checks retain a one-pixel tolerance; the three corrected Chinese cases pass without a production change (`chinese-pointer-rounding.log`).

Documentation: read implement-spec, TDD plus tests/mocking companions, UI/UX Pro Max and its review references, and find-docs. Context7 successfully resolved `/websites/doc_qt_io_qt-6_8` and verified MouseArea position/button/wheel handling; no quota/unavailable fallback. The first UX query had no match; a narrowed `color only indicator` query returned applicable accessibility rules (text identifiers alongside color, contrast and visible focus). The pinned upstream GraphingCalculator.xaml graph/equation hierarchy and zoom/tracing controls were inspected. No additional dependency or license was introduced.

## Final implementation validation

Linux x86_64, Qt 6.12.0, GCC 16.2.1, private Debug/Make build `.build-ticket21`, compilation limited to `-j2`. Final production build and QML lint pass with no warnings in `build-final.log` or `qmllint-final.log`; whitespace validation passes.

- `ctest --test-dir .build-ticket21 --output-on-failure -j2`: **35/37 entries passed** in **2551.36 s**. All **34 non-Graphing entries passed**, covering existing arithmetic, Programmer, history, memory, dates, converters, restart and isolation checks. The two failed entries were Graphing/light (the obsolete `e-7` versus `e-07` literal) and Graphing/Chinese (three fractional-pixel center assumptions described above). This is not claimed as a single all-green full-suite run. Frozen evidence: `ctest-full.log` and `ctest-full-LastTest.log`.
- After the fixes, `ctest --test-dir .build-ticket21 -R calculator-graphing --output-on-failure -j2`: **3/3 entries passed** in **241.70 s**, covering English/light, English/dark and Chinese/light. Each configuration reports **55 passed, 0 failed, 0 skipped**: the existing 45 outcomes plus ten new user-behavior tests. Frozen evidence: `ctest-graphing-final.log` and `ctest-graphing-final-LastTest.log`. Every current CTest entry therefore has a passing final result across the full run and affected rerun.
- Offscreen light/dark captures at 320×460 and 900×700 were inspected: two computed labeled curves, readable legend selection, actual coordinate/range text, narrow view switch and wide graph/equation split. The behavioral tests additionally verify rendered known coordinates, absent strokes across poles/domain gaps, at least 4.5:1 text/curve contrast, translated help and focus visibility in a seven-function narrow list.
- All GUI processes used `tests/run-ui-isolated.py` with offscreen/software/compose/generic settings, private settings/data/cache/runtime and private D-Bus. No desktop window/input/IME access, remote push, PR or deployment was used. Native desktop rendering and Windows/macOS remain unverified. Finite numerical sampling cannot guarantee detection of arbitrary sub-resolution features or singularities.

`integration/calculator` at `f79735813e1680d03d940a7fb1098fc7edbf7667` was an ancestor before implementation and was merged again before final build/lint/Graphing validation (`Already up to date`). The transport recovery found the checkout clean at source/test commit `ff16ee2c8129ed330f0a1acc04feb0c79ad2f374`, verified the preserved successful final rerun, and re-merged the same current integration tip without a source change. No repeat of the 37-entry run was needed; recovery only appends this evidence. Independent reviewer/merger validation and ticket closure remain pending; Status and checkboxes stay ready/open as instructed.


## Independent integration merge validation and closure

Merged source commit `7d82c687becdd5ed970da33eef4391bb39214d4a` into `integration/calculator` with `git merge --no-ff`; merge commit **`620d608192bc32b6d815ac050ed3faecd9b8fe7e`**, based on clean integration tip `3135f5e87d29bcda9a5a09d6a6cd7d14e4c890c0`. The sole README conflict was resolved by retaining both the existing Currency section and the new Graphing section. All existing translation keys/values, application shell, navigation, arithmetic/conversion controllers, 45 registered CTest entries and isolated launcher were preserved. No integration production-code fixes were necessary.

Independent source/spec review and real integration tests fulfill all seven acceptance criteria:

- Multiple evaluated curves retain stable IDs and distinct legend/curve identifiers; selective edit, middle/last deletion and invalid-function isolation pass through actual QML controls.
- Known line/parabola/reciprocal coordinates, pan/zoom/reset, drag/wheel/keyboard, bounded extreme view ranges and selected-function coordinate/undefined readout pass.
- Repeated expression/view changes recompute curves and omit reciprocal poles and undefined domain gaps; no stale sample or false connection appears in the covered cases.
- Translation, semantic themes, rendered text/curve contrast, narrow/wide layouts, syntax/help focus return and visible keyboard focus in a scrolling multi-function list pass. Four integrated 320×460/900×700 light/dark captures were independently inspected.
- The implementation's twelve preserved red/green log pairs were inspected and each contains an actual failure followed by a successful focused run. No new test seam or mock was introduced by the merge.

Linux x86_64 / Qt 6.12.0 / GCC 16.2.1, existing private Debug/Make integration build, compilation limited to `-j2`:

- `cmake -S . -B .build-integration -DCMAKE_BUILD_TYPE=Debug`: pass.
- `cmake --build .build-integration -j2`: pass; production application and QML test executable built, no warnings.
- `cmake --build .build-integration --target calculator_ui_qmllint -j2`: pass, no warnings.
- `ctest --test-dir .build-integration -R '^calculator-(graphing-|ui-|currency-|test-isolation$)' --output-on-failure -j2`: **11/11 passed in 770.95 s**. All three Graphing variants report **55 passed, 0 failed, 0 skipped**; all three shared main UI variants report **298/0/0**; all three Currency variants report **43/0/0**. Currency restart passes both independent-process write/restore stages; isolation passes. This is the relevant 11-entry integration regression subset, not a claim that all 45 entries were rerun during this merge.
- Final whitespace/index/checkout checks pass. The parent spec and other tickets are unchanged.

Frozen logs: `.build-integration/merge21-configure.log`, `merge21-build.log`, `merge21-qmllint.log`, `merge21-ctest.log`, `merge21-LastTest.log`; captures: `.build-integration/graphing-multiple-{light,dark}-{320,900}.png`. All GUI execution and capture used `tests/run-ui-isolated.py` with compose/generic/offscreen/software settings, private config/data/cache/runtime and private D-Bus. The live test environments were checked to confirm absent desktop/IME inheritance and task-private session buses. No user-desktop input/window/IME access, delegation, remote push, PR or deployment occurred.

No ticket-21 acceptance blockers remain; Status is resolved and all fulfilled boxes are checked. Finite numerical sampling retains its documented sub-resolution limitation. Windows/macOS and native-desktop rendering remain unverified; application-wide final review is still separate from this completed ticket merge.
