# 21: 比较多条曲线并浏览坐标

**What to build:** 用户可以添加、修改和删除多条函数，在同一坐标系比较曲线，通过平移、缩放和坐标查看探索图形。

**Blocked by:** 20: 输入函数并绘制真实曲线。

**Status:** ready-for-agent

**Spec:** Windows 11 风格跨平台计算器。

**User stories:** 41, 42, 43, 44, 45。

- [ ] 用户可添加、修改和删除多条 y=f(x) 函数，函数列表与曲线之间有清晰的对应标识，选择和编辑不会误改其他函数。
- [ ] 多条曲线依据各自实际表达式绘制，某一函数无效时有明确反馈，不导致其他有效曲线无法使用。
- [ ] 支持平移和缩放，坐标轴、刻度、可见范围及曲线同步更新；视图操作有合理边界，不产生无效范围或卡死。
- [ ] 用户可查看坐标，显示值与实际坐标变换一致；若显示曲线上的取样值，应关联正确函数并避免把无定义点伪装成有效点。
- [ ] 修改函数和视图范围后重新处理无定义区间与渐近线，不因旧采样或快速交互产生错误连线或过期曲线。
- [ ] 函数管理及视图操作在宽窄窗口、浅深主题下可辨可用，说明可翻译并遵循应用焦点规则。
- [ ] 通过用户操作验证多函数管理、已知曲线位置、缩放/平移后的坐标读取，以及视图变化下的不连续处理；不能仅以曲线数量或截图存在作为验收。

## Ticket 21 implementation evidence (pending independent merge validation)

Status and acceptance checkboxes intentionally remain ready/open for the merger. No parent-spec or other-ticket status was changed.

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

Additional stable-ID/middle-deletion, wheel, view-change discontinuity and existing mathematical cases are regression coverage, not claimed as separate red cycles. Early development logs also retain a failed full graph run for long-status overflow and a later exponent-format literal mismatch (`e-7` versus QString `e-07`); the final test compares numeric limits instead of irrelevant exponent spelling.

Documentation: read implement-spec, TDD plus tests/mocking companions, UI/UX Pro Max and its review references, and find-docs. Context7 successfully resolved `/websites/doc_qt_io_qt-6_8` and verified MouseArea position/button/wheel handling; no quota/unavailable fallback. The first UX query had no match; a narrowed `color only indicator` query returned applicable accessibility rules (text identifiers alongside color, contrast and visible focus). The pinned upstream GraphingCalculator.xaml graph/equation hierarchy and zoom/tracing controls were inspected. No additional dependency or license was introduced.
