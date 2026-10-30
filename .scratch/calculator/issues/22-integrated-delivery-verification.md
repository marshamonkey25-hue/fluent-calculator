# 22: 交付可复现构建并验收完整应用

**What to build:** 用户取得按说明可构建和运行的完整计算器，全部 18 个功能入口与跨模式交互经过验证，并能清楚了解平台验证情况和明确差异。

**Blocked by:** 02: 补齐标准模式按键与错误恢复; 03: 切换主题、语言并保存偏好; 05: 使用科学模式的幂、对数及扩展运算; 06: 使用三角函数与角度单位; 08: 执行位运算并操作位显示; 09: 查看、复用和清理计算历史; 10: 跨算术模式使用内存值; 12: 对日期增加或减少年月日; 14: 换算体积、面积、重量和质量; 15: 换算能量、速度、时间和压力; 16: 换算温度、功率和角度; 17: 换算数据量; 19: 离线使用汇率缓存; 21: 比较多条曲线并浏览坐标。

**Status:** ready-for-agent

**Spec:** Windows 11 风格跨平台计算器。

**User stories:** 1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12, 66, 67, 68。

- [ ] 全部 18 个导航入口均有对应真实功能，分别为五种计算模式和十三种换算；不存在以空页面、固定示例值、静态曲线或未接命令按钮代替范围内功能的情况。
- [ ] 集成检查覆盖跨模式切换、历史隔离、内存共享、键盘焦点、复制、错误后恢复及汇率缓存；解决功能分支组合后产生的真实问题，而非将各任务的基础验证全部推迟到本任务。
- [ ] 按固定源码对照内容布局、按钮和参考交互，检查浅色/深色/跟随系统主题、中文/英文/跟随系统语言及宽窄窗口；补齐已接入页面的未翻译文案、不可辨状态和不可访问操作。
- [ ] 主题、语言、最近模式和汇率缓存按约定跨启动保留，历史与内存按普通重启语义清空，且各类状态不会互相污染。
- [ ] 从说明中的步骤在当前 Linux 环境实际完成构建、启动和适当自动测试，记录依赖版本、最低 Qt 要求、运行方法及必要的平台条件，交付可运行构建。
- [ ] 授权与第三方说明涵盖微软核心、移植来源及实际引入的绘图/汇率等依赖，明确汇率数据来源、日期含义和服务差异。
- [ ] 完成真实界面操作和必要截图对照，报告中分别说明自动测试、人工检查、软件渲染或其他实际渲染环境及已知差异；不把工具探针结果当作产品验证。
- [ ] 如实列出 Windows/macOS 或其他尚未实测的系统、架构与构建组合，不声称已完成三平台验证，不扩展为安装包、签名或商店发布任务。
- [ ] 将完整规格的用户故事与实际验证结果核对，绘图按已接受的函数绘图边界验收，汇率按独立每日参考数据验收；未完成项必须明确记录，不能静默缩减后宣称完成。


## Ticket 22 implementation evidence (independent merge validation pending)

Scope remains integrated delivery. The parent specification and tickets 01–21 are unchanged. Status and acceptance checkboxes above remain for the integration reviewer.

- Added `tests/integration/tst_integrated_delivery.qml` and four isolated CTest configurations (English/Simplified Chinese × Light/Dark). The real application journey performs actual operations in all 18 modes, checks reference navigation order and focused-mode visibility at 320/900 px, exercises cross-mode history/memory/error/currency-cache isolation, and observes Copy through real clipboard paste. Existing per-feature and independent-process restart tests remain registered.
- Fixed integration gaps found through the public UI: Scientific and Programmer now copy current results through a translated context menu and all platform Copy shortcuts; Standard binds all platform Copy shortcuts; navigation restores visibility of its focused row after reopen/resize and follows the pinned Microsoft manifest order. Numeric Copy uses the existing native string path; no arithmetic/data algorithms changed.
- Updated the README's current feature/build/check overview; added `docs/delivery-verification.md` with all 68 user stories mapped to actual checks, reference-layout comparison, rendering/process distinctions and platform limits. `docs/third-party.md` inventories Microsoft notices, Qt, project-authored graphing and Frankfurter data terms. Six reviewed English/light and Chinese/dark contact sheets cover all 18 pages; automated per-page captures also cover the other language/theme combinations and wide layouts.

### Actual TDD red → green evidence

Logs are in this worktree's private `.build-ticket22` directory. Tests use real QML events, actual core/data and the approved external network/time/storage/preference seams.

1. `test_scientific_result_can_be_copied_without_precision_loss`: `red-scientific-copy.log` failed with empty clipboard output instead of `9007199254740993`; `green-scientific-copy.log` passed after adding the shared result-copy menu/shortcut to Scientific.
2. `test_programmer_result_copy_follows_current_radix`: `red-programmer-copy.log` failed because the result offered no Copy menu; `green-programmer-copy.log` passed after integrating the shared menu. The test checks `FF` from the menu and `255` from keyboard Copy after changing base. A test-only focus refinement returns focus from the clipboard receiver to the real radix control before the second Copy.
3. `test_all_eighteen_modes_perform_real_operations:angle`: `red-navigation-focus.log` reproduced a clipped focused row after resizing/reopening (`y=613`, height `40`, viewport `603`); `green-navigation-focus.log` passed after recomputing focused-row visibility on drawer open and viewport-height changes. The initial full journey reproduced the same defect in Temperature, Power, Data and Pressure.
4. `test_standard_alternate_copy_shortcut_preserves_result`: `red-standard-copy.log` failed with empty output instead of `42` for Ctrl+Insert; `green-standard-copy.log` passed after binding all StandardKey.Copy sequences. This also removes the earlier one-of-multiple-bindings warning.
5. `test_navigation_keyboard_order_matches_pinned_reference`: `red-navigation-order.log` failed at Tab focus because Programmer preceded Graphing; `green-navigation-order.log` passed after matching `Calculator.ViewModels/Common/NavCategory.cs:245–264` at the fixed revision, including converter ordering.

6. `test_result_copy_menu_text_has_readable_contrast`: `red-copy-contrast.log` failed all three arithmetic modes against rendered menu pixels in Light theme (less than 4.5:1 contrast); `green-copy-contrast.log` passes after sharing the palette-backed, sensibly sized/positioned menu across Standard, Scientific and Programmer. A focused screenshot review found this after the broader run had started; the final affected suites are replayed separately.
7. `test_scientific_copy_menu_escape_keeps_pending_calculation`: `red-copy-escape.log` failed because Escape left Copy visible and invoked Scientific Clear; `green-copy-escape.log` passes after letting the result menu handle Escape, preserving pending `6 × 7 = 42`.

8. The broad Dark graph configuration exposed `FunctionGraphing::test_view_changes_resample_discontinuities_and_preserve_other_functions` timing out at `waitForRendering` before its curve assertions. The two waits now explicitly request a window frame, as the existing `draw()` helper already does; `green-graph-render-wait.log` passes the exact scenario. Curve-coordinate and discontinuity assertions are unchanged. Context7 confirms that `QQuickWindow::update()` schedules a frame even when the scene is already up to date; all three graph configurations are included in the final replay.

The modal-navigation regression passed against existing code and is retained as regression evidence, not counted as a red. The cross-mode test's initial single-record Standard expectation was corrected to use a single `4 × 5` calculation, since the reference stepwise `2 + 3 × 4` legitimately records an intermediate result. No production change was made to alter reference history behavior.

### Verified environment and checks

- Started from a clean managed worktree with `integration/calculator` an ancestor of HEAD; initial and pre-validation integration tip `c839f1660e640806202430199a74a3bed1c51f45` merged as already up to date.
- Clean private Debug/Unix Makefiles configure and `cmake --build .build-ticket22 -j2` pass on Linux x86_64, Qt 6.12.0, GCC 16.2.1, CMake 4.4.4, Python 3.14.8. Selected Qt minimum remains 6.8; other versions/platforms are not newly verified.
- `cmake --build .build-ticket22 --target calculator_ui_qmllint -j2` passes without warnings. `git diff --check` and the QML Chinese catalog audit pass; all 68 story IDs are accounted for and new documentation's local links resolve.
- The actual `.build-ticket22/calculator` production executable remained running for three seconds without QML/import/startup errors under `tests/run-ui-isolated.py`, then its verified task-owned smoke process was terminated with SIGTERM. This is startup evidence, separate from the normal window-close/restart tests.
- Explicit `TZ=America/New_York` isolated checks of both date-difference DST cases and both add/subtract DST cases pass: **8 outcomes, 0 failures, 0 skips** (`date-dst.log`).
- Context7 lookup succeeded for current Qt QuickTest event/focus/image APIs; no documentation fallback was needed. UI/UX guidance was applied to visible focus, readable inherited palettes and reference-layout consistency. Screenshot review compares actual captured product content with pinned XAML and the upstream Standard screenshot, without claiming pixel equivalence.

All UI runs, captures and helper/restart processes use the repository's compose/generic/offscreen/software launcher with private settings/data/cache/runtime and private D-Bus. There is no native-desktop manual interaction, host input/IME/session-bus access, remote push, PR, packaging or deployment. Windows/macOS/native rendering remain unverified. Graphing and daily currency rates retain the explicitly accepted scope and documented numerical/service differences.


### Final validation outcome

- Full broad matrix: `ctest --test-dir .build-ticket22 --output-on-failure -j2` completed **47/49 entries** in **2696.39 s**, preserving two failed entries in `final-ctest.log`, `broad-LastTest.log` and `broad-LastTestsFailed.log`. The Dark arithmetic failure was four mouse-Copy checks during intermediate menu sizing work; the Dark graph failure was the frame-wait issue described above. Neither result is hidden or counted as passing.
- Final affected replay: `ctest --test-dir .build-ticket22 --output-on-failure -R 'calculator-integrated-delivery|^calculator-ui-|^calculator-graphing-' -j2` passes **10/10 entries** in **703.49 s** on final code. Each of four integrated-delivery entries reports **30 passed / 0 failed / 0 skipped**; each main arithmetic entry reports **298 / 0 / 0**; each graph entry reports **55 / 0 / 0**. Logs: `final-affected-ctest.log` and `final-affected-LastTest.log`.
- Thus all **49 registered entries** have passing final results across the broad run and replay, with all affected entries rerun on final code. No claim is made of one frozen all-green 49-entry run. No test or functional assertion was skipped, removed or weakened; the graph change requests a frame while retaining every coordinate/gap assertion.
- Final production build and warning-free lint pass after merging the latest integration tip (still `c839f1660e640806202430199a74a3bed1c51f45`, already up to date). The final production executable also passes a fresh isolated three-second startup smoke, followed by task-owned SIGTERM cleanup. New documentation links resolve, the Chinese QML catalog has no missing owned UI strings, and all 68 user stories are mapped. Eight committed captures/contact sheets cover the 18 pages and Copy contrast in both themes; all 144 per-mode captures are reproducible from the delivery tests.
- The implementation satisfies this ticket's nine acceptance areas through the linked delivery report and executable tests. Independent integration review still owns the checklist and Status transition; this ticket remains **ready-for-agent**. Windows/macOS, other architectures, Qt 6.8 runtime/native desktop/hardware rendering are unverified; accepted graph-sampling and daily-reference-rate differences remain explicit. No remote push, PR, installer, deployment or parent-spec edit was performed.
