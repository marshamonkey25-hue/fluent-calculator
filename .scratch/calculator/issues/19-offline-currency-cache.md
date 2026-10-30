# 19: 离线使用汇率缓存

**What to build:** 用户断网或重新打开应用后仍可使用已有有效汇率，明确区分缓存与新数据；无数据时得到真实的不可用状态。

**Blocked by:** 18: 联网获取汇率并完成货币换算。

**Status:** ready-for-agent

**Spec:** Windows 11 风格跨平台计算器。

**User stories:** 51, 52, 53。

- [ ] 成功取得的有效汇率及必要币种、来源、货币对和数据日期信息保存到本地，重新打开后可恢复并完成对应货币换算。
- [ ] 进入模式先读取可用缓存再尝试刷新，更新过程不阻塞已可用的换算；刷新失败时保留既有有效记录及原始数据日期。
- [ ] 首次离线、缓存不存在、缓存损坏或当前货币对未缓存时显示明确不可用状态，不借用不匹配报价或伪造结果。
- [ ] 界面说明离线/缓存或失败状态，并分别展示实际数据日期和刷新信息；不同货币对的观测日期不能被统一覆盖。
- [ ] 无效响应或未完成的写入不会破坏已有有效缓存；货币对切换及异步刷新不会将缓存错误关联到其他选择。
- [ ] 普通重启仍遵守历史和内存不恢复的独立规则，不能为缓存实现引入计算会话的意外持久化。
- [ ] 以固定响应、受控时间及隔离的本地存储，验证成功缓存、跨启动恢复、首次离线、已有缓存离线、缺失货币对、损坏数据、失败刷新及恢复联网；不依赖实时外网。

## Implementation evidence (merge validation owns closure)

Status remains `ready-for-agent`; checklist closure is reserved for the merger's independent validation.

- `CurrencyRates` restores a versioned, validated Frankfurter catalog and per-pair observations (rate, original observation date and successful download time). It writes `currency-rates-v1.json` alongside the INI-format application settings path using `QSaveFile`, with direct-write fallback disabled. Missing, malformed, inconsistent and unsupported cache documents remain unavailable.
- Currency selection synchronously restores only the matching pair, then refreshes without blocking numeric input. Invalid/failed/stale responses retain the prior observation and cannot overwrite its persisted date. A failed atomic replacement leaves the earlier disk file usable. English/Chinese cache and storage-failure messages inherit the existing palette, keyboard navigation and pinned converter layout.
- Approved test boundary: real `MainWindow` navigation/controls, shared `ConversionSession`, real Microsoft UnitConverter, observable values/status/dates and real isolated storage. Only external HTTPS responses/time and filesystem fixtures/permissions are controlled. All UI checks use `tests/run-ui-isolated.py`; no host desktop, input/IME, inherited bus or native GUI run is used.
- The four-process `calculator-currency-restart` journey saves two independently dated pairs, restores offline, rejects an invalid refresh, recovers online and restores the updated observation offline. It also proves fresh numeric input, empty Standard/Scientific histories and shared memory, and retained appearance/recent-mode preferences. The regular currency journeys cover missing/corrupt caches, missing pairs, incomplete sibling files, actual read-only-directory write failure and out-of-order response effects after reopening.

### TDD evidence

Three vertical red → green slices are preserved under the private `.build-ticket19` evidence directory:

1. `ticket19-red1.log`: the separate-process offline restore displayed `—` instead of a usable cached result. Persisting/validating/restoring catalog and observations made the restart test pass (`ticket19-green1.log`).
2. `ticket19-red2.log`: returning to a previously observed pair incorrectly restored the previous unit selection. Reloading the restored pair's ratios after selection, with localized cache feedback, made immediate offline conversion/date preservation and online recovery pass (`ticket19-green2.log`).
3. `ticket19-red3.log`: a real failed cache replacement did not expose a storage-failure notice. Tracking `QSaveFile` failures and showing translated feedback made the test pass while a reopened window still used the earlier disk quote (`ticket19-green3.log`).

The additional corruption/restart/async/layout assertions extend these behaviors through the same public UI seam. Context7's Qt documentation lookups succeeded for `QSaveFile::commit()`, direct-write fallback and `QSettings` INI filesystem locations; no documentation fallback was needed. The UI skill's feedback/contrast/keyboard guidance was applied to the existing Microsoft layout. Physical power-loss behavior, native desktop rendering and Windows/macOS execution are not claimed.

### Final validation

- Private Linux x86_64 Debug/Make build: `cmake -S . -B .build-ticket19 -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON`, `cmake --build .build-ticket19 -j2`, and `cmake --build .build-ticket19 --target all_qmllint -j2` pass with no compiler/lint warnings. Qt 6.12.0 / GCC 16.2.1 were used.
- After merging the latest `integration/calculator` tip (no-op at `524007e29f2840124275fbdd99699e41a0651cbc`), `ctest --test-dir .build-ticket19 --output-on-failure -j2` completed all 45 entries in **2492.38 s**. **44/45** passed; the sole failure was the new Chinese test expectation `无数据日期`, while the existing correct resource text is `暂无数据日期`. No production change was needed for that correction.
- `ctest --test-dir .build-ticket19 --rerun-failed --output-on-failure -j1` then passed **1/1** in **106.07 s**. Every registered entry has a passing final result across these runs; no single all-green full run is claimed. Currency reports **60 passed, 0 failed, 0 skipped** in each English/light, English/dark and Chinese/light configuration. The complete application suites each retain **298 passed, 0 failed, 0 skipped**. All four currency restart stages and every inherited isolation/converter/history/memory/date/graphing/Programmer entry pass.
- Full/replay output and detailed QtTest results are preserved as `.build-ticket19/ticket19-{full,replay}-{ctest,LastTest}.log`; build/lint, red/green and focused regression logs are also retained there. Offscreen captures of cached and unsaved-rate feedback at 320×640 and 900×640 were reviewed in light/dark and Chinese, with keyboard focus and 4.5:1 text contrast verified by the UI journey.
- Final integration ancestry/merge recheck is unchanged; `git diff --check` passes. Independent review and merge validation remain required before changing this ticket's status or checklist.
