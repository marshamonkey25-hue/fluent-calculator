# Currency reference rates

Currency uses the public **Frankfurter v2 blended daily reference-rate feed**. It is independent of Microsoft's currency service and does not promise Microsoft quote parity, live trading prices, settlement amounts, or uniform observation dates across currency pairs.

The production application makes asynchronous, unauthenticated HTTPS requests to:

- `https://api.frankfurter.dev/v2/currencies` for the service's current currency catalog (no legacy `scope=all`).
- `https://api.frankfurter.dev/v2/rates?base=EUR&quotes=USD` for the selected pair, with the actual ISO codes substituted. Omitting `providers` selects the service's blended feed.

Catalog names and symbols come from the service. ISO codes remain visible; Qt supplies Simplified Chinese currency names where it has a matching current territory, with service-name fallback for other currencies. EUR/USD are the preferred initial pair when present; otherwise the first available currencies are selected. The app requests the selected pair's actual quote rather than filling missing quotes from a built-in table. Selecting the same currency still requires a valid matching service response. Reverse entry uses the reciprocal of the validated pair's rate when that reciprocal is representable.

Entering Currency attempts a refresh. **Refresh rates** retries without blocking input or navigation. A monotonically increasing request ID prevents earlier catalog, pair or refresh responses from replacing a newer selection/request. Requests have transfer and total timeouts; network, TLS, HTTP and response errors leave a recoverable status. Amount input is shared with the other converter categories, including the selected input side and per-category unit choices. Background responses preserve those choices while updating dynamic rate metadata.

A quote must contain exactly one JSON-array record with matching `base`/`quote`, a round-trippable ISO calendar `date`, and a JSON number `rate` that is finite and positive. Empty, damaged, wrong-pair, duplicate and invalid-value responses never become a quote. The UI displays an em dash when a result is unavailable, and unavailable results cannot become numeric input. A successful response uses the real Microsoft UnitConverter for decimal entry, double-based conversion and its pinned currency display formatting: fixed 15 decimal places with trailing zeroes trimmed. There is no JavaScript arithmetic path. Like the other positive-only categories, currency entry permits at most 15 digits and rejects negative amounts.

The displayed **Data date** is the observation date returned for that currency pair. **Last refresh** is the UTC response/attempt time, obtained separately from the clock; downloading does not update the observation date. A failed or invalid refresh retains an already valid observation for that same pair and displays the failure alongside its original date. Theme, language and recent mode use the existing preference system; ordinary restart starts fresh numeric input, history and memory.

## Offline cache

Validated currency metadata and pair observations are stored in `currency-rates-v1.json` beside the application's INI-format settings location, including on platforms whose native preferences use a registry. The versioned document records the Frankfurter v2 source URL, currency codes/names/symbols, and each pair's rate, observation date and successful download time. It contains no calculation input, history or memory. A missing, malformed, unsupported-version or inconsistent document is ignored; a cached currency catalog alone never supplies a quote for an unobserved pair.

Opening Currency or selecting a previously observed pair restores its own cached quote immediately, then attempts an asynchronous refresh. Input, reverse entry and navigation remain available during refresh. **Using cached rates** identifies the fallback, while the separate refresh status explains an unsuccessful attempt. The pair's original data date remains visible. Before a new response arrives, **Last refresh** shows the cached observation's successful download time; after a response it shows the latest attempt in the current session. Unsuccessful attempts do not replace the persisted successful timestamp or observation. No expiry date is invented for daily observations: users can see their actual age and explicitly refresh.

Only validated successful responses update the cache. `QSaveFile` writes a temporary sibling and atomically replaces the complete document; direct-write fallback remains disabled. Invalid responses, stale asynchronous replies and incomplete sibling files cannot overwrite a valid record or reassign it to another pair. If saving fails, the new validated quote remains usable in the current session, the prior disk cache remains intact, and **Rates could not be saved. Offline data may be older.** explains the storage failure. A subsequent successful save clears that notice. A quote for a different pair is never substituted for missing data.

## Attribution and terms

Service: [Frankfurter](https://frankfurter.dev/). API documentation: <https://frankfurter.dev/>. License, disclaimer and provider terms: <https://frankfurter.dev/license/>. These pages and the current v2 response shape were consulted on 2026-10-31 (local host date).

Frankfurter's **software, documentation and Docker images** are MIT licensed. That software license is separate from rights in reference-rate data. Frankfurter collects rates published by central banks and other official institutions; it does not grant rights that a provider does not grant. Applicable provider terms are linked on its license page. Frankfurter describes blended rates as its own calculation, free to use, rather than an official rate from any single institution; direct provider endpoints have their own terms. This app uses the blended feed and does not redistribute a fixed rate dataset or claim that every upstream provider's data shares this project's software license.

The service and rates are supplied as is, without warranty. Observations may be late, missing or revised. The service's disclaimer recommends checking a provider's own publication for tax, accounting or legal uses. Consult the linked current terms for the intended use.

## Deterministic verification

`calculator-currency-{light,dark,zh-CN}` exercises the real QML controls, shared session, currency validation/data loader and Microsoft converter. Only external network responses, time and isolated filesystem fixtures are controlled. Assertions use independently known rates/amounts (for example 10 EUR at 1.25 USD/EUR = 12.5 USD), with the pinned currency-specific fixed-15-decimal display policy. Coverage includes automatic/manual refresh, delayed/out-of-order responses and their disk-cache effects, malformed/missing/wrong-pair quotes, date/time separation, catalog failures/recovery, overflow, both entry sides, clipboard input, 15-digit limits, shared-category state, corrupt/absent caches, uncached pairs, interrupted-file remnants, a real filesystem write failure, English/Chinese, theme contrast and narrow/wide keyboard access. `calculator-currency-restart` runs four separate processes against one private storage root: save two pair observations, restore offline and reject an invalid refresh, reconnect and persist a newer observation, then restore it offline. Each restart verifies fresh input and empty Standard/Scientific histories and shared memory, with appearance/recent-mode preferences retained.

```sh
ctest --test-dir .build -R calculator-currency --output-on-failure -j2
```

These tests use the repository's offscreen/software/private-settings/private-D-Bus launcher and make no external network requests. Any live-service smoke check is reported separately and is not part of regular CTest. Linux/Qt 6.12 is the locally verified environment; Windows/macOS and native desktop rendering are unverified.
