# Currency reference rates

Currency uses the public **Frankfurter v2 blended daily reference-rate feed**. It is independent of Microsoft's currency service and does not promise Microsoft quote parity, live trading prices, settlement amounts, or uniform observation dates across currency pairs.

The production application makes asynchronous, unauthenticated HTTPS requests to:

- `https://api.frankfurter.dev/v2/currencies` for the service's current currency catalog (no legacy `scope=all`).
- `https://api.frankfurter.dev/v2/rates?base=EUR&quotes=USD` for the selected pair, with the actual ISO codes substituted. Omitting `providers` selects the service's blended feed.

Catalog names and symbols come from the service. ISO codes remain visible; Qt supplies Simplified Chinese currency names where it has a matching current territory, with service-name fallback for other currencies. EUR/USD are the preferred initial pair when present; otherwise the first available currencies are selected. The app requests the selected pair's actual quote rather than filling missing quotes from a built-in table. Selecting the same currency still requires a valid matching service response. Reverse entry uses the reciprocal of the validated pair's rate when that reciprocal is representable.

Entering Currency attempts a refresh. **Refresh rates** retries without blocking input or navigation. A monotonically increasing request ID prevents earlier catalog, pair or refresh responses from replacing a newer selection/request. Requests have transfer and total timeouts; network, TLS, HTTP and response errors leave a recoverable status. Amount input is shared with the other converter categories, including the selected input side and per-category unit choices. Background responses preserve those choices while updating dynamic rate metadata.

A quote must contain exactly one JSON-array record with matching `base`/`quote`, a round-trippable ISO calendar `date`, and a JSON number `rate` that is finite and positive. Empty, damaged, wrong-pair, duplicate and invalid-value responses never become a quote. The UI displays an em dash when a result is unavailable, and unavailable results cannot become numeric input. A successful response uses the real Microsoft UnitConverter for decimal entry, double-based conversion and its pinned currency display formatting: fixed 15 decimal places with trailing zeroes trimmed. There is no JavaScript arithmetic path. Like the other positive-only categories, currency entry permits at most 15 digits and rejects negative amounts.

The displayed **Data date** is the observation date returned for that currency pair. **Last refresh** is the UTC response/attempt time, obtained separately from the clock; downloading does not update the observation date. A failed refresh retains an already valid observation for that same selection during the session and displays the failure alongside its original date. Changing the pair clears that selection's available quote until its response validates. Ticket 18 stores no rate data on disk: persistent/offline caching is ticket 19. Theme, language and recent mode use the existing preference system; ordinary restart starts fresh numeric input.

## Attribution and terms

Service: [Frankfurter](https://frankfurter.dev/). API documentation: <https://frankfurter.dev/>. License, disclaimer and provider terms: <https://frankfurter.dev/license/>. These pages and the current v2 response shape were consulted on 2026-10-31 (local host date).

Frankfurter's **software, documentation and Docker images** are MIT licensed. That software license is separate from rights in reference-rate data. Frankfurter collects rates published by central banks and other official institutions; it does not grant rights that a provider does not grant. Applicable provider terms are linked on its license page. Frankfurter describes blended rates as its own calculation, free to use, rather than an official rate from any single institution; direct provider endpoints have their own terms. This app uses the blended feed and does not redistribute a fixed rate dataset or claim that every upstream provider's data shares this project's software license.

The service and rates are supplied as is, without warranty. Observations may be late, missing or revised. The service's disclaimer recommends checking a provider's own publication for tax, accounting or legal uses. Consult the linked current terms for the intended use.

## Deterministic verification

`calculator-currency-{light,dark,zh-CN}` exercises the real QML controls, shared session, currency validation/data loader and Microsoft converter. Only `CurrencySource`'s external network responses and clock are replaced with fixed fixtures. Assertions use independently known rates/amounts (for example 10 EUR at 1.25 USD/EUR = 12.5 USD), with the pinned currency-specific fixed-15-decimal display policy. Coverage includes automatic/manual refresh, delayed/out-of-order responses, malformed/missing/wrong-pair quotes, date/time separation, catalog failures/recovery, overflow, both entry sides, clipboard input, 15-digit limits, shared-category state, English/Chinese, theme contrast and narrow/wide keyboard access. `calculator-currency-restart` verifies recent mode/preferences and fresh input across two isolated processes.

```sh
ctest --test-dir .build -R calculator-currency --output-on-failure -j2
```

These tests use the repository's offscreen/software/private-settings/private-D-Bus launcher and make no external network requests. Any live-service smoke check is reported separately and is not part of regular CTest. Linux/Qt 6.12 is the locally verified environment; Windows/macOS and native desktop rendering are unverified.
