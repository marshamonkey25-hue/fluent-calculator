# Integrated delivery verification — ticket 22

## Final integration acceptance — 2026-10-31

The final review fix `9909494be79ec60c191be95fe2698f3ae7c9351a` is integrated without conflicts by merge `94c9c42a0439347ee4913f1186fc5a886b707287`. The parent specification and all **22 tickets / 144 checked acceptance criteria** are resolved. The story-by-story mapping below remains applicable; the following final results include the last subnormal parsing repair and supersede the earlier verification snapshots.

The actual root Debug configure/build and warning-free QML lint pass on Linux x86_64, Qt 6.12.0, GCC 16.2.1, CMake 4.4.4 and Python 3.14.8. One frozen complete matrix passes **49/49 entries in 2820.55 seconds**, exit 0: **3005 QtTest outcomes passed, 0 failed, 0 skipped, 0 blacklisted**, plus three process-isolation checks. All 31 independent restart stages pass. No test, assertion or timeout was removed, weakened or increased during finalization.

```sh
cmake -S . -B .build-integration -DBUILD_TESTING=ON -DCMAKE_BUILD_TYPE=Debug
cmake --build .build-integration -j2
cmake --build .build-integration --target calculator_ui_qmllint -j2
python3 tests/run-ui-isolated.py ctest --test-dir .build-integration --output-on-failure -j2
```

The retained executable is `/hdd/calc/.build-integration/calculator`; normal user launch is `./.build-integration/calculator`. The actual isolated production startup command was `python3 tests/run-ui-isolated.py .build-integration/calculator`: the process stayed running for three seconds with empty diagnostics, then only its owned process group was terminated (exit 143). Normal QML window close and independent restart behavior are covered by the passing suites. No native visible-window observation is claimed.

**Standards review.** The supplied review found no hard documented-standard violation and two nonblocking duplication findings. Both are fixed: `app/ProportionalRatios.h` shares ratio construction across five metadata loaders, and `tests/restart-driver.cmake` shares seven suites' private storage/isolation/stage/cleanup orchestration. Finalizer inspection confirms preserved catalogs, temperature offsets, stage lists and limits; all category and restart tests pass. No remaining Standards blocker was found.

**Spec review.** All four supplied findings are fixed and covered through actual QML operations: unavailable physical results cannot become input; arithmetic Paste preserves native precision and radix/width rules; Ctrl+H/Ctrl+Shift+D implement the reference history actions with modal/focus behavior; Currency refreshes the current catalog while retaining valid observations and rejecting stale replies. The related finite-subnormal converter crash is also fixed and covered. Main arithmetic reports 340, History 22, Currency 63 and Length 47 passing outcomes per configuration. No remaining Spec blocker or unapproved scope addition was found in the finalizer review.

Fresh captures include **144 per-mode images** across both languages/themes at 320/900 px, preserved with 184 other fresh images and six contact sheets in `.build-integration/final-acceptance/screenshots/`. Visual inspection covered all 18 modes in the six `final-delivery-{calculators,physical-converters,other-converters}-{en_US-light,zh_CN-dark}.png` contact sheets, both Copy/Paste menu themes, wide history, a wide converter and a wide graph. Values, required controls, selected states, focus and graph coordinates are readable; the content hierarchy/key order matches the pinned reference. Font metrics, symbols and platform styling remain documented differences. The current [Light](screenshots/delivery-copy-menu-programmer-en_US-light.png) and [Dark](screenshots/delivery-copy-menu-programmer-en_US-dark.png) menu images are committed. Visual review of software-rendered content, automated behavior and standalone startup are separate evidence; native chrome/GPU fidelity remains unverified.

All final UI processes use `tests/run-ui-isolated.py` before Qt GUI construction: compose/generic/offscreen/software, private settings/data/cache/runtime and private Linux D-Bus. The manifest confirms all 49 entries use it and none are disabled. A live process audit confirmed absent desktop/IME selectors and task-private buses. The literal translation audit finds zero missing entries across 307 QML `qsTr` occurrences. No desktop windows/input, host IME, host session bus or compositor commands were used.

Root evidence is `.build-integration/final-acceptance/{configure,build,qmllint,ctest,LastTest}.log`, the corresponding exit records, `final-test-summary.json`, `ticket-acceptance-audit.json`, `translation-audit.json`, `ctest-manifest.json`, `active-isolation-audit.json`, `screenshot-manifest.json`, `visual-review.json` and `production-startup.json`. Before cleanup, all **23 workflow worktrees** had verified ownership, clean tracked state and HEAD ancestry captured by integration. **3854 useful evidence files** were archived and each SHA256 verified in `workflow-worktree-evidence.tar.gz` (archive SHA256 `894c17091502dbf65e40b801de3d679c9f9caf4cea4437549f4fb8a40288587f`); `workflow-worktree-evidence-manifest.json` preserves original paths and hashes. The before/after audits and `worktree-cleanup-results.json` prove their safe removal. Two orphaned ticket-17 offscreen/private-bus processes were identity-verified and stopped through pidfds before removing that worktree. Only the root checkout remains; source branch refs are retained.

Windows/macOS, other architectures, Qt 6.8 runtime, native desktop and hardware rendering, actual host theme/IME integration, and current live-service availability remain explicitly unverified. Graphing retains its accepted explicit-function/finite-sampling limits; Currency retains independent daily reference data and pair-specific dates. No remote push, PR, deployment or installer work was performed.


This delivery contains all 18 functional entries. Arithmetic uses the pinned Microsoft CalculatorManager → CEngine → Ratpack; the 13 converters use its portable UnitConverter with actual category metadata or validated Frankfurter observations. Date operations use civil calendar dates. Graphing evaluates and samples editable functions, including multiple curves, domain gaps, pan/zoom and coordinate inspection. No page is backed by a fixed demonstration result.

The [ticket evidence](../.scratch/calculator/issues/22-integrated-delivery-verification.md) records the commands, results and TDD evidence. Ticket 22 is resolved after independent integration validation: the combined Debug build and warning-free QML lint pass, followed by one frozen **49/49 CTest run in 2687.58 seconds** with **2858 QtTest outcomes passed, 0 failed and 0 skipped**. Integration logs and startup/capture evidence are recorded in the ticket; the implementation-branch results below remain historical evidence. This report describes verification of the implemented product, separately from older tool probes and incremental ticket reports.

## Recorded results

The broad `ctest --test-dir .build-ticket22 --output-on-failure -j2` run completed **47/49 entries** in **2696.39 seconds**. It retained two failures: Dark arithmetic's mouse-Copy checks during intermediate menu sizing work, and Dark graphing's wait for a frame before curve assertions. Their logs are preserved; this is not reported as an all-green frozen full run.

After the fixes, the final affected replay completed **10/10 entries** in **703.49 seconds**:

```sh
ctest --test-dir .build-ticket22 --output-on-failure \
  -R 'calculator-integrated-delivery|^calculator-ui-|^calculator-graphing-' -j2
```

That final replay reports **30 passed / 0 failed / 0 skipped** in each of four delivery configurations, **298 / 0 / 0** in each of three main arithmetic configurations, and **55 / 0 / 0** in each of three graph configurations. Every registered entry has a passing final result across the broad run and replay; all affected entries pass on final code. No test was removed, disabled or relaxed. The eight restart/isolation entries, complete converter catalogs and remaining feature checks passed in the broad run. An additional explicit New York DST check passed **8 / 0 / 0**. Production build, warning-free QML lint and the final isolated standalone startup smoke also pass.

Detailed retained evidence is in the private build directory: `final-ctest.log`, `broad-LastTest.log`, `broad-LastTestsFailed.log`, `final-affected-ctest.log`, `final-affected-LastTest.log`, `final-build.log`, `final-qmllint.log`, `date-dst.log` and `standalone-startup.log`. The local build is `.build-ticket22/calculator`. These build outputs are intentionally untracked; source, test definitions, instructions and the representative screenshots are committed.

## Reproduce the local build and checks

From the source checkout, with the dependencies in [README](../README.md#dependencies):

```sh
cmake -S . -B .build -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Debug
cmake --build .build -j2
cmake --build .build --target calculator_ui_qmllint -j2
ctest --test-dir .build --output-on-failure -j2
```

The executable is `.build/calculator`. For normal interactive use, run it with the Qt platform plugin for the local desktop. For acceptance validation, run only the isolated tests above. A focused real-QML delivery check is:

```sh
ctest --test-dir .build -R calculator-integrated-delivery --output-on-failure -j2
```

There are four delivery configurations: English/light, English/dark, Simplified Chinese/light and Simplified Chinese/dark. They use real production QML and actual core/data. They replace only external system-preference input, currency HTTPS responses/clock and private storage fixtures. They do not substitute arithmetic, dates, unit ratios or graph evaluation. The full CTest matrix also runs all previously delivered feature and restart tests.

Every UI process, screenshot and restart helper runs through `tests/run-ui-isolated.py` **before QGuiApplication construction**. Qt uses `compose`, `generic`, `offscreen` and software rendering. Display/Wayland/IME variables are removed, settings/data/cache/runtime roots are private, and Linux gets a private D-Bus configuration/socket without host service activation. No desktop input, IME service, host session bus or compositor control is used. The generic platform's Unknown theme has the application's documented Light fallback; controlled system-theme changes verify the observable follow-system behavior without consulting the host desktop.

The clean private build used `.build-ticket22`, CMake 4.4.4, GNU Make, GCC 16.2.1, Python 3.14.8 and Qt 6.12.0 on Linux x86_64 (Omarchy/Arch, kernel 7.2.8-9-omarchy). The selected minimum is CMake 3.21, C++17 and Qt 6.8. Qt 6.8 itself has not been tested here. Missing Vulkan development headers did not prevent the software/offscreen build. No UWP SDK, PPL package, network source download or proprietary graphing engine is required.

The actual standalone production executable was also started under the same isolated launcher: it remained running for three seconds without a QML/import/startup error. Its task-owned process was then terminated with SIGTERM. This startup smoke is distinct from normal window-close coverage: real-QML suites call the production window's `close()`, and restart suites reopen independent processes. No successful native-desktop launch or hardware-rendering check is claimed for ticket 22.

## User stories and observable evidence

Paths below refer to tests under `tests/`. Assertions act on real QML controls and displayed state. The table accounts for all 68 stories in the parent specification; groups use its original numbering.

| User stories | Implemented behavior and actual check boundary |
| --- | --- |
| 1–3 | Qt/C++/QML source and native `ApplicationWindow` frame design. Current Linux build/startup, reference-content comparison and software-rendered screenshots are verified. Windows/macOS and native chrome/compositor rendering are explicitly unverified; no three-platform execution claim. |
| 4–5 | `integration/tst_integrated_delivery.qml::test_all_eighteen_modes_perform_real_operations`: actual navigation into five calculator modes and 13 converter categories, independent arithmetic/date/coordinate/ratio results. `test_navigation_keyboard_order_matches_pinned_reference` verifies all 18 entries in reference order through Tab focus. |
| 6 | Delivery captures at 320 and 900 px; mode-specific layout/focus tests in `qml`, `programmer`, `date`, `history`, `memory`, `graphing` and each converter suite exercise narrow/short/wide windows and scroll focused controls into view. Scientific has a larger full-keypad minimum and separate 320×460 scroll coverage. |
| 7–9 | `qml/tst_preferences.qml` verifies explicit and controlled system theme/language changes, fallback, visible colors/contrast and live errors without clearing pending arithmetic. `restart/tst_preferences_restart.qml` verifies independent-process retention and invalid-setting defaults. Converter and currency restart suites verify recent modes. |
| 10–12 | Real mouse/key paths, Tab/Space and clipboard paste in `qml/tst_standard.qml` and other mode suites. Delivery tests add exact Scientific Copy, Programmer Copy in the current radix via menu and keyboard, and Standard's alternate platform Copy binding. Rendered Copy-menu contrast/translation and Scientific Escape dismissal are checked through the same UI. Converter suites cover real Copy/Paste. `qml/tst_arithmetic_paste.qml` additionally verifies arithmetic Paste shortcuts/context menus in all three modes, exact digits, expressions/exponents, Programmer radix/width validation, localized errors, pending operations, modal isolation and recovery. Navigation modal isolation and keyboard visibility are checked. |
| 13–15 | Standard/Scientific/Programmer display, expression/error separation, C/CE/backspace and error recovery in the three arithmetic suites; delivery cross-mode journey verifies translated division-error recovery after graph/converter/settings navigation. |
| 16–20 | Standard suite covers stepwise 20, all ordinary/unary/percent keys, repeated equals, operator replacement, result continuation, precision sentinel `9007199254740992 + 1`, rational/decimal behavior and input limits. Delivery independently compares 20 with Scientific 14. |
| 21–22 | `qml/tst_scientific_precedence.qml` and `tst_scientific_extended.qml`: precedence, nested parentheses, powers/roots, constants, logarithms/exponentials, secondary functions and known results through actual controls/core. |
| 23–26 | `qml/tst_scientific_trigonometry.qml`, `tst_scientific_extended.qml` and `tst_scientific_short_window.qml`: circular/inverse/hyperbolic families, DEG/RAD/GRAD, factorial/modulo, domains/range recovery, exponent entry, 25-level parentheses, all function controls and shortcuts. |
| 27–31 | `qml/tst_programmer.qml` and `programmer/tst_programmer_bits.qml`: radix round trips, DEC/QWORD startup, 64/32/16/8-bit signed boundaries, truncation/wraparound, legal digits, bitwise operations, all shift variants, carry and editable bit display. |
| 32–34 | `date/tst_date_difference.qml` and `tst_date_add_subtract.qml`: same/reversed dates, leap days/centuries, month ends, cross-year dates, add/subtract year/month/day order, range errors and recovery through calendar/offset UI. Date-only DST boundaries are included. |
| 35–37 | `history/tst_history.qml`: Standard/Scientific separation, expression/result ordering, reuse with native precision/angle/notation, clear/delete, Ctrl+H toggle/Ctrl+Shift+D clear with modal/focus checks, and 20/21 eviction boundary. Delivery journey reuses Standard history after Scientific, Programmer, graph, converter and settings visits. |
| 38–40 | `memory/tst_memory.qml`: real shared rational memory, toolbar/list/context actions, recall into pending arithmetic, current radix/width formatting, native precision and 100/101 eviction. History/memory restart suites verify no ordinary restoration; delivery and currency restart tests also verify state boundaries. |
| 41–45 | `graphing/tst_graphing.qml`: editable multi-curve known coordinates and rendered pixels, independent edit/delete, stable labels, pan/zoom/drag/wheel/keyboard, inspection, parser/domain errors, bounded sampling, undefined intervals and reciprocal/tangent asymptote gaps. This is the accepted explicit `y=f(x)` scope. |
| 46–47 | Every converter suite exercises selectors, active-side/reverse entry, real keypad/key input, same-unit ratios, permitted/rejected signs, 15-digit limits and fixed/scientific display policies. Shared category-session lifetime and per-category units are covered. |
| 48–50 | `currency/tst_currency.qml`: current catalog additions/removals after refresh and restart, retained observations on catalog failure, validated pair conversion, automatic/manual asynchronous refresh, source and pair observation date, attempt time, unavailable status and out-of-order responses using deterministic external fixtures. |
| 51–53 | Currency suite plus `currency-restart/tst_currency_restart.qml`: first offline, cached offline, missing/corrupt/wrong-pair/invalid data, retained valid quotes, atomic-save failure/interruption, recovery and four independent restart stages. Preferences/rates persist while input/history/memory start fresh. |
| 54 | `volume-area-mass/tst_volume_area_mass.qml`: all 20 selectable volume units, US/UK distinctions, actual cubic-meter/liter example and limits/sign rules. |
| 55 | `length/tst_length.qml`: all 12 selectable units, actual ratios, same/reverse conversion, scientific display, paste validation, unavailable-result reuse prevention, subnormal reuse/underflow and correction. |
| 56 | Volume/area/mass suite: all 14 weight/mass units, grams/kilograms and short/long tons, reverse conversion and positive-only entry. |
| 57 | `signed-conversions/tst_temperature_power_angle.qml`: all temperature pairs/offset orders, zero/boiling/negative landmarks and signed input, including Celsius/Fahrenheit/Kelvin. |
| 58 | `energy-speed-time-pressure/tst_energy_speed_time_pressure.qml`: all energy units, thermal/food calories, joules and kilowatt-hours. |
| 59 | Volume/area/mass suite: all 10 ordinary area units and Pyeong regional variant (`ja-JP` entry), independent area equivalents. |
| 60–61 | Energy/speed/time/pressure suite: every speed/time unit, pinned rounded mph/knot/Mach factors and 365.25-day year, reverse/identity conversions and boundaries. |
| 62 | Signed converter suite: all five power units, permitted negative entry, exact watt/kilowatt example and reference factors. |
| 63 | `data/tst_data.qml`: all 35 selectable units, decimal/binary prefixes, bits/bytes/nibbles, large/small/scientific results and sign/input limits. |
| 64 | Energy/speed/time/pressure suite: all six pressure units, atmosphere/pascal and pinned mmHg definition. |
| 65 | Signed converter suite: degrees/radians/gradians, negative angles, known ratios, same/reverse entry and shared-session category transitions. |
| 66–68 | Reproducible source build/check instructions, actual local executable/startup, dependency versions, [source/license inventory](third-party.md), this traceability/visual report and explicit unverified-platform limits. |

Conversion comparisons use the existing formatter's documented tolerances, generally 0.5 ppm, with fixed sub-unit cases allowing 0.5e-6 absolute rounding. Arithmetic bridge tests compare exact strings; they never convert the arbitrary-precision operands to JavaScript numbers. Graph pixel tests allow a three-pixel neighborhood at independently known coordinates and explicitly reject false strokes across domain gaps. Screenshot existence alone is not a correctness assertion.

## Pinned layout and visual review

Reference revision: `79e1ac53bba690cdf930e5dcd6ed9dbc4cbfb128`. Reviewed its `docs/Images/CalculatorScreenshot.png`, `Calculator/Views/Calculator.xaml`, `CalculatorStandardOperators.xaml`, `NumberPad.xaml`, `CalculatorScientificOperators.xaml`, `CalculatorProgrammerOperators.xaml`, `DateCalculator.xaml`, `UnitConverter.xaml`, graphing XAML and `Calculator.ViewModels/Common/NavCategory.cs`.

The comparison focuses on content layout and interaction: four-column/six-row Standard keys; five-column Scientific and Programmer arrangements; the C/CE/backspace/operator positions; expression/result hierarchy; memory/history split from 560 px with 320:240 proportions and a 320 px cap; calendar/offset controls; two converter values with unit selectors and the three-column keypad; landscape value/keypad columns; graph/equation split from 800 px; and the complete reference navigation order. The delivery regressions reproduced and corrected navigation ordering and focused-row clipping after reopening a resized drawer. Copy menus use the inherited palette with a minimum readable surface, open at the clicked result, and let Escape dismiss Scientific Copy without clearing pending arithmetic.

The test saves 144 per-mode images across the four language/theme configurations and two widths as `delivery-<mode>-<locale>-<theme>-<width>.png` in the build directory. The following contact sheets preserve representative reviewed content for all 18 modes in English/light and Chinese/dark. Individual 900 px captures and feature-specific flyout/settings/panel captures remain reproducible through CTest.

| Pages | English/light | Simplified Chinese/dark |
| --- | --- | --- |
| Standard, Scientific, Programmer, Date, Currency, Graphing | [Calculator pages](screenshots/delivery-calculators-en_US-light.png) | [Calculator pages](screenshots/delivery-calculators-zh_CN-dark.png) |
| Volume, Length, Weight and Mass, Temperature, Energy, Area | [Physical converters](screenshots/delivery-physical-converters-en_US-light.png) | [Physical converters](screenshots/delivery-physical-converters-zh_CN-dark.png) |
| Speed, Time, Power, Data, Pressure, Angle | [Other converters](screenshots/delivery-other-converters-en_US-light.png) | [Other converters](screenshots/delivery-other-converters-zh_CN-dark.png) |

The shared Copy menu also has reviewed [Light](screenshots/delivery-copy-menu-programmer-en_US-light.png) and [Dark](screenshots/delivery-copy-menu-programmer-en_US-dark.png) captures. Its regression samples the rendered text/surface contrast and checks translated menu text in all three arithmetic modes.

Visual inspection of captured product content is separate from automated UI events and from live manual interaction. No active-desktop manual operation was performed. Font metrics, glyph shapes, Qt control styling and native system decorations differ from Windows. The current port uses a text History action and normal native frame rather than Windows-specific title-bar/desktop effects. These captures establish functional layout/readability, not pixel equivalence or native GPU fidelity.

## Final application review corrections

The final review added arithmetic Paste to the shared result menu and platform shortcuts in Standard, Scientific and Programmer. Clipboard text is validated before native command replay, preserving exact digits, pending operations, exponent input and the current Programmer radix/width. Invalid input uses the core's localized error state. Copy remains first in the pinned menu order. Ctrl+H now toggles the narrow Standard/Scientific history sheet, and Ctrl+Shift+D clears visible history; modal isolation and focus restoration are verified.

All converter categories now reject unavailable results as input and retain the explanation when returning to a category. The public Length regression reuses kilometers→Angstroms 22 times to reach an unavailable result, visits Energy and returns, changes units and recovers input. A second regression reaches a finite subnormal through Angstrom→kilometer reuse. A focused portability repair replaces throwing current-value parsing with a complete finite `wcstod` parse, preserving representable subnormals while genuine double underflow rounds to zero. The converter's double policy and arithmetic core remain unchanged.

Currency refresh now fetches the current catalog and a known pair independently. Catalog additions/removals become selectable, retained observations remain usable, catalog failure does not block a known-pair refresh, and superseded replies cannot replace newer state. Retired-currency observations are pruned before saving so the remaining cache is valid after restart. Public tests cover additions, removal, stale replies, failure, retained values and restart recovery.

The review's two duplication findings are also addressed: `app/ProportionalRatios.h` shares source lookup and ratio construction across five metadata loaders, and `tests/restart-driver.cmake` shares the seven restart suites' private directory, isolation, stage execution and cleanup. Category catalogs/defaults, the explicit temperature offset table, and each restart suite's stages are preserved.

Review-fix validation starts from `86ec9f8c081be10210b300b12775f5bf1dad2768`. The broad `.build-review-fixes` matrix passes **49/49 in 1735.27 seconds**, with **3002 QtTest outcomes passed, 0 failed, 0 skipped**; this predates the final subnormal parsing repair. After that repair, the complete converter replay passes **20/23 in 760.22 seconds**; the only failures are the three Currency configurations reaching their unchanged 180-second harness limit while another matrix was running. Their serial replay passes **3/3 in 357.84 seconds**, **63/0/0** per configuration. The complete updated Length suites also pass **3/3 in 153.23 seconds**, **47/0/0** per configuration, including subnormal reuse and ordinary recovery. All 23 affected converter entries therefore have passing final results across the replay and retry; no frozen final 49-entry run including the last parsing repair is claimed. Final Debug builds, warning-free QML lint, the Chinese literal-string audit and isolated production startup pass. Retained logs are `fixes-{full,final-converters,final-currency,final-length}-LastTest.log` and the corresponding CTest logs in `.build-review-fixes`; the ticket records exact commands and red/green evidence. All UI checks use the required isolated launcher.

## Deliberate differences and verification limits

- Only Linux x86_64 with the toolchain above was built and run in this task. Windows, macOS, other architectures, Qt 6.8 runtime, native display plugins, hardware rendering and installer/signing/store deployment are unverified. The source structure targets those desktop platforms; that is separate from execution evidence.
- Graphing is explicit `y=f(x)` with multiple curves and finite double-based evaluation/sampling. It does not claim implicit relations, inequalities or the proprietary Microsoft analysis engine. Bounded adaptive sampling can omit unresolved intervals and cannot guarantee detection of arbitrarily narrow features/singularities.
- Currency uses independent Frankfurter blended daily reference observations. The observation date belongs to the selected pair; refresh/download time is separate. No real-time trading price, Bing parity or uniform provider date is implied. Currency names retain the service's names when Qt has no matching localized currency name; ISO codes remain visible. Regular acceptance tests use fixtures; historical live-service checks are recorded in tickets 18/19, and no new live-service availability claim is made here.
- System-theme changes are exercised at the approved controlled platform boundary. The isolated generic platform can report Unknown; its Light fallback and explicit palette behavior are verified. Real host theme, IME, session bus and compositor behavior are intentionally outside this run.
- Final integration review and the application-wide acceptance are complete as recorded above; the parent specification is resolved. Historical ticket-22 snapshots retain their original validation scope.
