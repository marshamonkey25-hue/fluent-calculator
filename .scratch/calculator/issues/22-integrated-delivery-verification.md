# 22: 交付可复现构建并验收完整应用

**What to build:** 用户取得按说明可构建和运行的完整计算器，全部 18 个功能入口与跨模式交互经过验证，并能清楚了解平台验证情况和明确差异。

**Blocked by:** 02: 补齐标准模式按键与错误恢复; 03: 切换主题、语言并保存偏好; 05: 使用科学模式的幂、对数及扩展运算; 06: 使用三角函数与角度单位; 08: 执行位运算并操作位显示; 09: 查看、复用和清理计算历史; 10: 跨算术模式使用内存值; 12: 对日期增加或减少年月日; 14: 换算体积、面积、重量和质量; 15: 换算能量、速度、时间和压力; 16: 换算温度、功率和角度; 17: 换算数据量; 19: 离线使用汇率缓存; 21: 比较多条曲线并浏览坐标。

**Status:** resolved

**Spec:** Windows 11 风格跨平台计算器。

**User stories:** 1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12, 66, 67, 68。

- [x] 全部 18 个导航入口均有对应真实功能，分别为五种计算模式和十三种换算；不存在以空页面、固定示例值、静态曲线或未接命令按钮代替范围内功能的情况。
- [x] 集成检查覆盖跨模式切换、历史隔离、内存共享、键盘焦点、复制、错误后恢复及汇率缓存；解决功能分支组合后产生的真实问题，而非将各任务的基础验证全部推迟到本任务。
- [x] 按固定源码对照内容布局、按钮和参考交互，检查浅色/深色/跟随系统主题、中文/英文/跟随系统语言及宽窄窗口；补齐已接入页面的未翻译文案、不可辨状态和不可访问操作。
- [x] 主题、语言、最近模式和汇率缓存按约定跨启动保留，历史与内存按普通重启语义清空，且各类状态不会互相污染。
- [x] 从说明中的步骤在当前 Linux 环境实际完成构建、启动和适当自动测试，记录依赖版本、最低 Qt 要求、运行方法及必要的平台条件，交付可运行构建。
- [x] 授权与第三方说明涵盖微软核心、移植来源及实际引入的绘图/汇率等依赖，明确汇率数据来源、日期含义和服务差异。
- [x] 完成真实界面操作和必要截图对照，报告中分别说明自动测试、人工检查、软件渲染或其他实际渲染环境及已知差异；不把工具探针结果当作产品验证。
- [x] 如实列出 Windows/macOS 或其他尚未实测的系统、架构与构建组合，不声称已完成三平台验证，不扩展为安装包、签名或商店发布任务。
- [x] 将完整规格的用户故事与实际验证结果核对，绘图按已接受的函数绘图边界验收，汇率按独立每日参考数据验收；未完成项必须明确记录，不能静默缩减后宣称完成。


## Ticket 22 implementation evidence (recorded before integration validation)

Scope remains integrated delivery. The parent specification and tickets 01–21 are unchanged. The implementation report below predates independent merge validation; current Status and acceptance checkboxes above reflect the integration result appended at the end.

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


## Independent integration verification and closure

Merged source commit `53f9792319523a9d29c1b1ca409ff18de37aa9ba` with `git merge --no-ff` into the initially clean `integration/calculator` checkout as **`f37d2ea260ccf506d55223858d3b011345cc632b`**. No conflicts or integration code fixes were necessary. Review confirmed the shared arithmetic Copy menu/native string path, pinned navigation order and focus reveal, preserved application-owned calculator/converter sessions, additive CMake/test wiring, translations, source notices and all nine acceptance areas. The parent spec and other ticket files are unchanged.

The integration Debug/Unix Makefiles configure and `cmake --build .build-integration -j2` pass. QML lint is warning-free. A single frozen `ctest --test-dir .build-integration --output-on-failure -j2` run passes **49/49 entries in 2687.58 seconds**, including all 45 inherited entries and all four new English/Chinese × Light/Dark delivery entries. The retained QtTest summaries total **2858 passed, 0 failed, 0 skipped**: delivery **30/0/0** per configuration, main arithmetic **298/0/0** per configuration, graphing **55/0/0** per configuration. All restart/isolation checks pass. Logs: `.build-integration/merge22-{configure,build,qmllint,ctest,LastTest}.log` and `merge22-validation-summary.log`.

The production executable `.build-integration/calculator` also remains running for three seconds without startup/import diagnostics under the repository launcher, followed by cleanup of only its verified task-owned process with SIGTERM (`merge22-standalone-startup.log`, `merge22-startup-result.log`). Normal close and fresh-process state retention/clearing are separately covered by the passing UI/restart suites. A context-aware audit finds **291 literal QML strings with no missing Chinese translations**, all delivery/source-document links resolve, and all **68 user stories** appear in the delivery traceability table (`merge22-static-audit.log`). The delivery run generates **144 per-mode captures plus 12 Copy-menu captures**; independent visual review covered committed contact sheets and fresh integration narrow/wide, English/Chinese and Light/Dark examples against the pinned reference content.

Every UI process and screenshot uses `tests/run-ui-isolated.py` before GUI construction: compose/generic/offscreen/software, private settings/data/cache/runtime and private Linux D-Bus. No active-desktop windows/input/IME/host session-bus use, remote push, PR or deployment occurred. Linux x86_64/Qt 6.12 is verified; Windows/macOS, other architectures, Qt 6.8 runtime, native desktop/hardware rendering and live host theme integration remain unverified. Accepted finite `y=f(x)` sampling and independent daily-reference currency limits remain explicit. Ticket **22 is resolved**; the parent workflow's final application-wide review remains separate.


## Final application review fixes

The final standards/spec reviews at `86ec9f8c081be10210b300b12775f5bf1dad2768` identified four behavioral gaps and two shared-code improvements. All six are addressed in the fix commit containing this note; the parent spec is unchanged. This preserves the resolved ticket on concrete implementation/regression evidence, while the parent workflow's independent review of the final fixes remains a separate gate.

- Unavailable physical results cannot become input through the UI or session boundary. The error remains visible across category changes and normal input recovers. The public Length regression repeats kilometers→Angstroms result reuse 22 times, checks disabled/error state, visits Energy and returns, changes units and clears successfully. A related boundary audit reproduced a finite-subnormal `stod` abort; a narrow documented converter portability repair now parses complete finite doubles without throwing on subnormals. A second permanent public regression repeats Angstrom→kilometer reuse 24 times, observes a finite `1e-312`, genuine underflow to zero, and ordinary input recovery. Arithmetic algorithms and the converter's double policy are preserved.
- Standard, Scientific and Programmer expose Paste through all platform Paste shortcuts and their shared result menu, with Copy before Paste as in pinned XAML. Complete text validation precedes native command replay. Tests cover exact 16/32-digit and 64-bit values, expressions, exponents, pending operations, radix/prefix/suffix/word-width rules, limits, invalid input, direct error recovery, modal isolation and translated menu text. Values do not round-trip through JavaScript numbers or floating-point arithmetic.
- Ctrl+H toggles narrow Standard/Scientific history, and Ctrl+Shift+D clears visible history in narrow/wide layouts. Public tests cover both modes, keyboard blocking behind a modal, navigation exclusion, empty state, unchanged pending arithmetic and restored calculator focus. Popup-local shortcuts handle the modal history sheet correctly.
- Currency refresh fetches the current catalog and a known pair independently. Valid additions/removals update selectors, usable observations survive failure, retired-currency observations are pruned before persistence, and stale catalog/rate replies are rejected. Added public regressions cover additions, removal/restart, stale catalog replies and catalog failure with retained observations. The existing four-stage offline/recovery restart regression also passes when catalog refresh is offline.
- `app/ProportionalRatios.h` shares source lookup and ratio construction across five metadata loaders; category-specific catalogs/defaults and the temperature offset table are preserved. `tests/restart-driver.cmake` shares private directory/isolation/process/cleanup behavior across all seven restart suites, retaining every suite's stage list and timeout.

### Review-fix TDD and validation evidence

Private builds: `.build-review-fixes` and `.build-subnormal`, Debug/Unix Makefiles, Linux x86_64, Qt 6.12.0, GCC 16.2.1, CMake 4.4.4, Python 3.14.8. Compilation uses `-j2`. Test seams are the already-approved real QML controls/visible state, actual native cores, clipboard, and external currency/time/private-storage fixtures. No private methods, internal call counts or mocked application modules are tested.

Actual red/green evidence in `.build-review-fixes`:

- `fixes-length-red.log` → `fixes-length-green.log`: unavailable result enabled → guarded/disabled input with recovery.
- `fixes-category-status-red.log` → `fixes-category-status-green.log`: category return erased the unavailable explanation → retained explanation/recovery. A transient test-object reference after page destruction was corrected by reacquiring the visible control; no production assertion was relaxed.
- `fixes-history-red.log` → `fixes-history-green.log`: Ctrl+H did not open history → toggle/clear/modal/focus tests pass in both modes. The initial red process was bounded by the tool timeout after recording the missing-toggle failure; final tests complete normally.
- `fixes-currency-red.log` → `fixes-currency-final-targeted.log`: catalog stayed at two choices after adding GBP → current catalog and stale/cache/restart cases pass. The first broader attempt exposed blocked quote recovery during catalog failure; the independent catalog/pair refresh correction is checked by `fixes-currency-restart-green.log` and the final matrix.
- `fixes-paste-red.log` → `fixes-paste-green-1.log`: all three modes ignored Paste → shortcut/menu work. `fixes-paste-red-2.log` records validation/expression failures before native string replay; `fixes-paste-green-2.log` completes 37 outcomes. `fixes-paste-red-3.log` → `fixes-paste-green-3.log` adds the reference Programmer leading-zero length rejection. `fixes-menu-order-red.log` → `fixes-menu-order-green.log` fixes Copy/Paste order. Final complete arithmetic suites include every added case.
- `fixes-subnormal-red.log` records SIGABRT / `std::out_of_range: stod` through public operations; `fixes-subnormal-green.log` and `fixes-subnormal-final-{light,dark,zh}.log` pass the corrected finite-subnormal/underflow/recovery path. The permanent regression is in `tests/length/tst_length.qml`.

Checked commands/results:

- `cmake -S . -B .build-review-fixes -DBUILD_TESTING=ON -DCMAKE_BUILD_TYPE=Debug`, `cmake --build .build-review-fixes -j2` and `cmake --build .build-review-fixes --target calculator_ui_qmllint -j2`: pass. The final subnormal build and final rebuilt main executable also pass without compiler/lint warnings.
- `ctest --test-dir .build-review-fixes --output-on-failure -j4`: **49/49 pass in 1735.27 seconds**, **3002 QtTest outcomes passed, 0 failed, 0 skipped**. Arithmetic **340/0/0** and History **22/0/0** per English/light, English/dark and Chinese/light configuration. This broad run predates the last subnormal parsing repair. Preserved logs: `fixes-full-ctest.log`, `fixes-full-LastTest.log`.
- After the final converter repair: `ctest --test-dir .build-subnormal --output-on-failure -j4 -R '^calculator-(currency|data|energy-speed-time-pressure|volume-area-mass|temperature-power-angle|length)(-|$)'`: **20/23 pass in 760.22 seconds**. Only the three Currency entries hit their unchanged 180-second harness limit during overlap with the broad matrix, without an assertion failure. These failures remain recorded in `fixes-final-converters-ctest.log` / `fixes-final-converters-LastTest.log`.
- `ctest --test-dir .build-review-fixes --output-on-failure -j1 -R '^calculator-currency-(light|dark|zh-CN)$'`: **3/3 pass in 357.84 seconds**, **63/0/0** each, on the final parsing code. Logs: `fixes-final-currency-retry.log`, `fixes-final-currency-LastTest.log`.
- `ctest --test-dir .build-subnormal --output-on-failure -j1 -R '^calculator-length-(light|dark|zh-CN)$'`: **3/3 pass in 153.23 seconds**, **47/0/0** each, including the permanent subnormal case. Logs: `fixes-final-length-ctest.log`, `fixes-final-length-LastTest.log`.
- Every affected converter entry therefore has a passing final result across the replay/retry; no single frozen final 49-entry run including the last portability repair is claimed. No test was removed, disabled, skipped or weakened and no timeout was increased. Earlier interrupted attempts are retained separately.
- Literal Chinese QML audit reports zero missing translations. Fresh offscreen English/light and Chinese/dark Copy/Paste captures were reviewed against pinned XAML; menu order and text/surfaces are readable. The final production executable remains running for three seconds without diagnostics under `tests/run-ui-isolated.py`, then only its task-owned process group is terminated (exit 143), recorded in `fixes-final-production-startup.log`.

Initial integration ancestry and final `git merge integration/calculator` checks confirm `86ec9f8c081be10210b300b12775f5bf1dad2768` is included; no reset or other-checkout write occurred. All UI executions, captures and restart stages use compose/generic/offscreen/software, private config/data/cache/runtime and private Linux D-Bus. No active-desktop window/input/IME/host session bus, remote push, PR or deployment was used. Windows/macOS, Qt 6.8 runtime, native/hardware rendering and live service availability remain unverified in this task.


## Final integration acceptance and workflow cleanup — 2026-10-31

Finalizer merged review fix `9909494be79ec60c191be95fe2698f3ae7c9351a` without conflicts as `94c9c42a0439347ee4913f1186fc5a886b707287`, inspected both supplied review axes and all 22 tickets' 144 checked criteria, and found no remaining acceptance blocker. The two Standards findings and four Spec findings are fixed; the finite-subnormal regression is included.

Fresh root `.build-integration` configure/build and warning-free QML lint pass. `python3 tests/run-ui-isolated.py ctest --test-dir .build-integration --output-on-failure -j2` passes **49/49 in one frozen run, 2820.55 seconds**, exit 0: **3005 QtTest outcomes passed, 0 failed, 0 skipped**, all 31 restart stages, plus three process-isolation checks. This final run includes the last subnormal repair. No assertion/test/timeout was weakened. All GUI execution used compose/generic/offscreen/software with private D-Bus and storage through the repository launcher.

All four integrated-delivery configurations pass. The finalizer visually inspected fresh contact sheets for all 18 modes in English/light and Chinese/dark, wide converter/graph/history layouts and both Copy/Paste menu themes. The 144 per-mode captures, six contact sheets and other fresh images are preserved in `.build-integration/final-acceptance/screenshots/`; current light/dark menu captures are committed. The standalone production process stays alive for three seconds under isolation without diagnostics, then its owned process group is stopped (143); no native visible-window observation is claimed. The retained root executable is `.build-integration/calculator`.

All 23 workflow worktrees were checked for ownership, cleanliness and captured integration ancestry, their 3854 useful evidence files archived with verified SHA256 hashes, then safely removed. Only the root integration checkout remains; all branch refs are retained. Final logs/audits, archive and original-path manifest are in `.build-integration/final-acceptance/`. The parent spec is now resolved with the final evidence. Windows/macOS, Qt 6.8 runtime, native desktop/hardware rendering and current live-service availability remain explicitly unverified. No desktop input/IME/session bus, remote push, PR or deployment was used.
