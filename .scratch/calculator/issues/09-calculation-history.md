# 09: 查看、复用和清理计算历史

**What to build:** 用户可在标准和科学模式中分别查看、复用及清理本次会话的计算历史，切换模式后仍能找到相应记录。

**Blocked by:** 04: 使用科学模式的优先级与括号。

**Status:** ready-for-agent

**Spec:** Windows 11 风格跨平台计算器。

**User stories:** 35, 36, 37, 40。

- [ ] 标准与科学模式分别记录表达式和结果，每种模式最多 20 条，超出上限删除最旧记录，顺序和收录时机遵循固定参考行为。
- [ ] 历史面板展示真实计算记录，选择记录后按参考语义恢复或复用相应计算状态，用户能够继续运算。
- [ ] 提供参考允许的清理操作，清理后列表及空状态及时更新，不误删另一模式的数据。
- [ ] 普通模式切换保留各自历史，普通退出后重新打开不自动恢复；程序员模式不生成或展示计算历史。
- [ ] 宽窗口侧栏与窄窗口访问方式均可操作，显示长表达式和结果时不遮挡必要操作；沿用主题和翻译机制。
- [ ] 通过真实计算和界面操作验证历史隔离、顺序、第 20/21 条边界、记录复用、清理和普通重启行为；其他模式存在时检查导航不会错误显示历史。

## Implementation evidence (awaiting integration validation)

- Implemented a shared `HistoryPanel.qml` backed by the real Microsoft manager's separate Standard/Scientific history collectors. The UI shows newest first; the core retains its 20-entry limit and collection timing. Programmer and Settings do not expose history. A wide window uses a side panel; a narrow window uses a modal bottom sheet with an explicit Close action. Wrapped expression/result text and a scrolling list leave clearing controls accessible. Labels use the existing theme palette and English/Chinese translation mechanism.
- History reuse replays native operand/unary/binary/parenthesis commands following pinned `StandardCalculatorViewModel.GetCommandsFromExpressionCommands`, `SetHistoryExpressionDisplay` and `Recalculate`. It preserves rational precision and memory via `Reset(false)`, restores the current angle, and uses the reference's F-E double toggle instead of adding an equals/history entry. The displayed expression/result are restored, and subsequent operations continue through the actual core. Clear-all and contextual per-record Delete map newest-first UI rows to oldest-first core storage and notify the list immediately.
- `tests/history/tst_history.qml` exercises the real QML window/session/core: completed-record order, separate histories, clear/empty state, deletion, 20/21 entries in both modes, replay without duplicates, exact integer/rational/sign/unary/parenthesis continuation, modal keyboard isolation and dismissal, Programmer/Settings exclusion, live Chinese translation, and 320/900px layouts with long records. `tests/history-restart/tst_history_restart.qml` plus `tests/history-restart.cmake` run four independent processes against one isolated settings root and verify both histories are fresh after an ordinary restart while recent mode survives. Existing suites remain registered; history has separate light/dark/Chinese CTest entries to fit the existing suite's time budget.
- Seven external-behavior TDD red→green cycles: missing History entry → real newest-first records; absent Clear all → immediate isolated clearing; inert history row → native Scientific replay and continued result 15 without duplication; missing context menu → selected-record deletion; absent Close action → modal keyboard dismissal without altering a pending calculation; English History caption → live Chinese adaptive history UI; missing sidebar at the pinned 560px breakpoint → reference 320:240 columns with history capped at 320px. The precision, collection-timing, 20/21 and restart cases validate existing imported-core/session behavior without inventing failing stages.
- Read the complete spec, glossary, ADR 0001, external handoff/porting notes, implement-spec/TDD and testing/mocking companion docs, UI/UX guidance, and find-docs. Context7 successfully supplied Qt 6.8 ListView/ItemDelegate model guidance; no documentation fallback was needed. The pinned upstream history view model, XAML and history tests informed behavior. No arithmetic algorithms were replaced, and no parent spec or other ticket was edited.
- Validation evidence and final integration ancestry are recorded in the implementation handoff artifact. Ticket status and acceptance checkboxes intentionally remain pending the required independent merger validation. Windows/macOS are not verified on this Linux host.
- Final Linux Qt 6.12/GCC 16.2 Debug verification in private `.build-ticket09` (Make `-j2`): all eight CTest entries pass across the full run and retries. History is **18/18** per English/light, English/dark and Chinese/light configuration; existing regression suites are **187/187** per configuration. Four history-restart and seven existing preference-restart processes each pass **3/3**. No failures/skips remain. Shared-host load pushed the existing dark/Chinese suites beyond their former 180s budget without assertion failures; their budget is now 300s, and retries completed in 203.61/206.40s. See `ticket09-final-ctest.log`, `ticket09-retry-ctest.log`, `ticket09-full-LastTest.log` and `ticket09-retry-LastTest.log` in the private build directory.
- `calculator_ui_qmllint`, final build and `git diff --check` pass. Native Wayland 20/21-boundary and resize-layout subsets pass **4/4** and **3/3**; a standalone native app launches without diagnostics. A full native run encountered shared-desktop focus failures and was interrupted, so full native automation is not claimed. Both-theme narrow/wide history captures were reviewed. Final integration merge reports already up to date at `06ffcdfa4f0006ba36496e6210bd870b2fad2c1e`; final affected layout and lint checks were rerun afterward. Independent merger review remains required before resolving the ticket.
