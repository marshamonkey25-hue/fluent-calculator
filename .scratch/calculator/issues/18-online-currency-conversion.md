# 18: 联网获取汇率并完成货币换算

**What to build:** 用户可进入货币换算，选择当前可用货币，获取每日参考汇率并转换金额，查看来源、数据日期和刷新状态。

**Blocked by:** 13: 完成长度换算。

**Status:** ready-for-agent

**Spec:** Windows 11 风格跨平台计算器。

**User stories:** 48, 49, 50。

- [ ] 按已批准的任务方案采用规格建议的 Frankfurter v2 混合每日参考汇率，以 HTTPS 无密钥请求取得当前有效币种和实际可用的货币对。
- [ ] 进入货币模式时尝试取得数据，并可手动刷新；界面保持响应，源/目标货币或请求变化后不将过期响应错误应用到新选择。
- [ ] 根据有效响应进行真实金额换算；只接受结构正确、货币对匹配、日期可解释且汇率为有限正值的数据，不能生成虚构报价补足缺失值。
- [ ] 显示来源、该货币对的数据日期和最近刷新状态/时间，明确每日参考汇率性质；不能把下载日期当作数据日期或声称与微软报价一致。
- [ ] 当前无有效报价、服务失败或货币对不可用时显示明确可恢复状态，不使用静态示例数值作为正式结果。跨启动持久化缓存由任务 19 完成。
- [ ] 记录服务及数据来源的适用条款和归属信息，避免把软件 MIT 授权直接当作所有上游数据的统一许可。
- [ ] 页面沿用换算输入规则、主题、翻译和键盘操作；测试可替换网络响应和时间，生产与测试经过同一应用逻辑。
- [ ] 使用固定数据验证转换、自动/手动刷新、日期显示、快速切换货币、缺失报价及无效响应。若进行真实连接检查，单独报告，不使常规测试依赖外网。


## Ticket 18 implementation evidence (merge validation pending)

Status remains `ready-for-agent`; the integration reviewer owns checklist closure.

Implementation uses the application-owned shared `ConversionSession`, real Microsoft `UnitConverter`, a `CurrencyRates` data loader/validator and the asynchronous `CurrencySource` HTTPS/time boundary. `ConverterPage` retains the pinned two-value/selector and three-column keypad layout, adds currency symbols/source/date/refresh controls, and shares existing English/Chinese, theme, keyboard, clipboard and recent-mode hooks. There is no built-in quote table, JavaScript numeric calculation or durable cache. See `docs/currency-rates.md` for service/API/data-rights details and ticket 19's persistence boundary.

Actual TDD red→green logs are in the private `.build-ticket18` tree:

1. `red01-navigation.log` → `green01-navigation.log`: Currency navigation absent → reachable real shared converter input.
2. `red02-online.log` → `green02-online.log`: missing Refresh control → fixed-network catalog, 10 EUR at 1.25 = 12.5 USD, source/observation date/independent UTC refresh time.
3. `red03-catalog-time.log` → `green03-catalog-time.log`: first catalog failure omitted attempt time → visible attempt time and working retry.
4. `red04-translation.log` → `green04-translation.log`: currency source/status stayed English → live Chinese controls and retained amount/theme behavior.
5. `red05-overflow.log` → `green05-overflow.log`: an extreme finite rate displayed `inf` → explicit unavailable result and clear recovery.
6. `red06-unavailable-input.log` → `green06-unavailable-input.log`: unavailable result remained selectable → disabled result with a guarded input boundary.
7. `red07-symbols.log` → `green07-symbols.log`: source-provided symbols were absent → visible symbols beside the formatted amounts.
8. `red08-refresh-recovery.log` → `green08-refresh-recovery.log`: a usable refreshed rate retained a prior conversion error → result and status recover together.

Additional full-QML regressions cover manual/automatic refresh on re-entry, current catalog/retry, out-of-order catalog/pair/same-pair refreshes, missing/wrong-pair/malformed/duplicate/invalid-date/nonpositive/nonfinite/non-numeric quotes, previous valid session observation after failure, both input sides, same-currency service response, sign/digit/decimal/backspace limits, Copy/Paste, Settings shortcut isolation, shared category input/unit preservation, contrast, visual keyboard focus, 320×640/900×640 layouts and ordinary restart preferences/fresh input. Tests replace only network responses, time and isolated settings roots; production and tests use the same application validation/conversion path.

Separate live production-QML smoke: `.build-ticket18/live-connection.log` passed 3/3 outcomes through the actual HTTPS source with the service's current catalog and EUR→USD amount **1.118**, observation **2026-10-30**, refresh **2026-10-30T16:21:39Z**. This external-network check is not registered in regular CTest and does not define deterministic expected quotes. Direct documentation/API shape probes also succeeded. Context7 verified Qt 6.8 async request/reply/timeout APIs; no fallback was necessary. UI skill's verified Fluent 2 result was applied with the existing palette/layout. No desktop window or host bus/IME was used. Windows/macOS and native rendering remain unverified.

Final merge/build/lint/regression results will be appended after the frozen validation run.
