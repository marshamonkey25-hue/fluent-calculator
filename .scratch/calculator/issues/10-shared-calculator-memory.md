# 10: 跨算术模式使用内存值

**What to build:** 用户可在标准、科学和程序员模式中保存、读取及修改内存值，通过共享列表复用中间结果。

**Blocked by:** 04: 使用科学模式的优先级与括号; 07: 使用程序员模式的进制与位宽。

**Status:** resolved

**Spec:** Windows 11 风格跨平台计算器。

**User stories:** 38, 39, 40。

- [x] 接入参考内存操作，包含保存、读取、加减和清除，以及参考列表项支持的实际交互；列表数据由真实计算状态产生。
- [x] 三种算术模式共享最多 100 条内存值，新值在前，超限淘汰最旧值；不同模式对内存值的解释、显示和操作遵循固定核心行为。
- [x] 读取内存值后可继续当前计算，修改或删除内存项后控件与列表及时同步；空列表的操作可用性符合参考规则。
- [x] 普通模式切换保留内存，普通退出后重新打开不恢复内存；不能将界面偏好持久化机制误用于保存内存值。
- [x] 内存按钮和面板在宽窄窗口均可访问，沿用主题、可翻译文案和参考键盘行为。
- [x] 通过 QML 用户操作验证保存/读取/加减/清除、跨三种模式共享、空状态、100/101 条边界及普通重启；断言可观察结果而非内部容器。

## Implementation evidence (ticket 10 branch)

During implementation, Status remained **ready-for-agent** for the integration reviewer. Only this ticket was implemented on that branch; the parent spec and other tickets were unchanged.

- `CalculationSession` exposes the real Microsoft manager's session memory as strings and dispatches guarded save/recall/indexed add/subtract/delete/clear operations. The native `vector<Rational>` owns the values and the 100-item limit; neither displayed strings nor preferences become arithmetic storage. Native list callbacks publish updates; indexed delete explicitly refreshes its otherwise unannounced change.
- `MemoryBar.qml` preserves MC/MR/M+/M−/MS and the pinned Ctrl+L/R/P/Q/M shortcuts in Standard/Scientific; Programmer preserves the reference MS/list toolbar. `MemoryPanel.qml` provides actual list values, item recall, MC/M+/M−, context menus, clear-all, and empty/error states. Indexed context deletion preserves nearby keyboard focus; the final context deletion returns focus to M+ (MS for Programmer), closing a narrow sheet.
- `MainWindow.qml` supplies the 560px History/Memory sidebar with the pinned 320:240 split and 320px cap, plus a narrow bottom sheet. Controls inherit the existing palette and live English/Chinese translations. Standard scrolls focused controls when forced below its size hint; Scientific's full-keypad hint grows by its memory row to 320×676 and its 320×460 scrolling regression remains enabled.
- The primary seam is `tests/memory/tst_memory.qml`: production MainWindow, real QML buttons/keys, real session and real core, asserted through labels, list rows/counts, enabled states, focus and window geometry. Selected-item actions run in all three arithmetic modes. Known expectations cover pending `8 + MR(42) = 50`, exact `9007199254740993`, rational `1/3 × 3 = 1`, F-E formatting, native Programmer representations of stored `255.5`, empty M+/M− behavior, and 100/101 distinct values with oldest-only eviction.
- `tests/memory-restart.cmake` and `tests/memory-restart/tst_memory_restart.qml` use six separately launched processes: write/restore for Standard, Scientific and Programmer. UI-created shared memory survives ordinary navigation, then disappears after a normal close/restart while mode and appearance preferences remain. Each process uses the shared isolated launcher and private settings/data/runtime/D-Bus.
- Existing history/Standard click helpers now reveal scrolled controls before clicking; layout assertions retain their original coverage and use mapped sidebar coordinates. Trigonometry full-layout fixtures accommodate the added row. No arithmetic expectation is changed and no tests are removed/skipped.

### TDD evidence

All new behavior uses the previously approved real-QML seam; no calculator mocks or private-method assertions were added. Expected failures and subsequent greens are retained in `.build-ticket10/red-01.log` through `red-12.log`, matching `green-*.log` and the final CTest memory variants:

1. Missing memory toolbar → native save/recall/clear, continuing a pending calculation.
2. Missing M+/M− → native updates and the reference Ctrl shortcuts, including empty memory.
3. Missing memory list → actual list rows, indexed actions, delete synchronization and recall.
4. Missing memory controls in other modes → shared Scientific/Programmer UI and native mode/radix/width formatting.
5. Missing docked Memory tab → responsive shared sidebar, sheet and live translation; its failing geometry check also prevented sidebar overlap.
6. Missing item context menu → mouse and Shift+F10 actions.
7. Panel clear-all left one item during an error → preserve the reference clear-all path while arithmetic stays disabled.
8. Added row clipped Standard's final keys → scrolling and focus reveal at 320×460.
9. F-E left the list at `42` instead of `4.2e+1` → refresh formatted native memory on notation changes.
10. Docked layout still showed M▾ → hide the narrow-only list button and preserve reference toolbar sizing/alignment.
11. Final context deletion left the sheet open → close it and return keyboard focus to M+/MS.
12. Context deletion lost row focus → focus the nearest remaining item and retain keyboard recall.

Capacity, exact arithmetic and restart tests also pass as regressions of the existing native core/session design; they are not represented as newly failing arithmetic implementations. Full-suite integration failures identified additional-row geometry/click assumptions and a 260px-versus-320px sidebar; these were fixed and are retained in earlier logs rather than counted as passing runs. The isolated short-window and exact sidebar-width checks pass after the fixes.

Required skills read: implement-spec; TDD including tests/mocking companions; ui-ux-pro-max (targeted keyboard-focus guidance and UI review references); find-docs. Context7 resolved Qt and verified QStringList/ListView/ItemDelegate/focus APIs with official Qt documentation, without a fallback. Pinned upstream memory manager, Calculator.xaml, Memory.xaml/MemoryListItem.xaml, their handlers and shortcut resources were consulted before implementation.

### Final branch validation

Linux x86_64, Qt 6.12.0, GCC 16.2.1, Debug/Unix Makefiles, private `.build-ticket10`, compilation `-j2`. All GUI checks use the shared offscreen/software/compose/generic launcher with private settings/cache/data/runtime and a private Linux D-Bus; no active-desktop GUI, remote push, PR or deployment was used.

- Full `ctest --test-dir .build-ticket10 --output-on-failure -j2`: **16/16 passed**, 1,151.49 seconds. Each language/theme reported **298 main UI, 35 Programmer bit, 20 history and 19 memory QtTest outcomes**, zero failures/skips. All isolation and preference/history/memory restart checks passed. Logs: `accepted-ctest.log`, `accepted-LastTest.log` in the private build tree.
- Final review then replaced untyped focus-helper access with typed arithmetic-page casts and a delegate-local focus request. QML lint is now **warning-free**, and the focused context-delete tests passed. The focus-return test was expanded across all three modes without changing arithmetic expectations.
- On that final source, `ctest --test-dir .build-ticket10 -R '^calculator-memory' --output-on-failure -j2`: **4/4 passed**, 167.68 seconds; **21/21 memory outcomes** per theme/language, plus all six independent restart stages. Logs: `final-memory-ctest.log`, `type-cleanup-focus.log`, `type-cleanup-build.log`, `type-cleanup-qmllint.log`.
- Final-source targeted layout checks: **3/3** sidebar breakpoint/cap outcomes, **4/4** Standard narrow/wide layout outcomes, and **3/3** Scientific 320×460 outcomes. Logs: `final-sidebar.log`, `final-standard-layout.log`, `final-scientific-short.log`.
- English and Chinese narrow/wide offscreen captures were reviewed in both themes: `memory-narrow-{light,dark}.png`, `memory-wide-{light,dark}.png`. Both themes retain readable values, controls, and focus styling; no pixel-identical rendering claim is made.
- Latest `integration/calculator` was merged/checked before final validation and again before commit: already up to date at `d327f2de0e09bca87e02416e42374db91a506883`, confirmed ancestor of this branch. `git diff --check` passes. All intended changes are committed; the final commit is reported in the handoff artifact.

Windows/macOS and native desktop behavior are unverified. Integration review and closure evidence follows.

## Integration completion and acceptance

Merged `407fbcb5d13b4280d3cb96c13cf95f6a092f4f95` into the clean `integration/calculator` checkout with `git merge --no-ff --no-edit`, producing merge commit `b9ceb3f9ef290dc6e51318d4a17d832b183fef99`. Both the prior integration tip `d327f2d` and the ticket commit remain ancestors. The merge had no conflicts and preserved the existing arithmetic, history, navigation, translations and isolated test launcher. Independent merge review found no ticket 10 blockers or integration regressions requiring code changes.

All six acceptance criteria are fulfilled by the native memory operations and the real-QML memory/restart suites described above. In particular, integration tests verify indexed actions in all three modes, exact integer/rational recall, newest-first 100/101 eviction, pending-calculation continuation, empty/error states, reference shortcuts/context focus, translated wide/narrow/short-window controls, and six separate memory close/restart stages that preserve preferences while clearing memory.

Validation on the merged Linux/Qt 6.12 Debug source:

- `cmake -S . -B .build-integration -DCMAKE_BUILD_TYPE=Debug` and `cmake --build .build-integration -j2`: passed; application and tests linked.
- `cmake --build .build-integration --target calculator_ui_qmllint -j2`: passed without QML lint warnings.
- `ctest --test-dir .build-integration --output-on-failure -j2`: **16/16 passed**, **1,094.46 seconds**, exit 0. Each English/light, English/dark and Chinese/light configuration passed **298 application / 35 Programmer-bit / 20 history / 21 memory outcomes**, with zero failures/skips. History, preference and memory restart checks and the isolation check also passed.
- Reviewed integration-generated `memory-narrow-{light,dark}.png` and `memory-wide-{light,dark}.png`: readable values/actions in both themes and live Chinese wide-panel labels. Automated tests retain sidebar breakpoint/cap, keyboard/focus and minimum-window reachability coverage.
- Every GUI process ran through `tests/run-ui-isolated.py`: offscreen/software/compose/generic, private settings/cache/data/runtime and private Linux D-Bus. No active-desktop or host IME interaction was used.
- Merge diff whitespace and ancestry checks passed. Full logs are `.build-integration/merge10-build.log`, `.build-integration/merge10-ctest.log` and `.build-integration/Testing/Temporary/LastTest.log`. Only ticket 10 and its README completion note are changed by closure; the parent spec remains untouched.

The previously reported offscreen size-hint and Copy-shortcut runtime warnings remain; their behavior checks pass. Windows/macOS and native desktop behavior remain unverified. The final application-wide review remains part of the parent workflow. Ticket 10 is resolved based on the successful independent merge review and full integration validation.
