# Integrated delivery verification — ticket 22

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
| 10–12 | Real mouse/key paths, Tab/Space and clipboard paste in `qml/tst_standard.qml` and other mode suites. Delivery tests add exact Scientific Copy, Programmer Copy in the current radix via menu and keyboard, and Standard's alternate platform Copy binding. Rendered Copy-menu contrast/translation and Scientific Escape dismissal are checked through the same UI. Converter suites cover real Copy/Paste. Navigation modal isolation and keyboard visibility are checked. |
| 13–15 | Standard/Scientific/Programmer display, expression/error separation, C/CE/backspace and error recovery in the three arithmetic suites; delivery cross-mode journey verifies translated division-error recovery after graph/converter/settings navigation. |
| 16–20 | Standard suite covers stepwise 20, all ordinary/unary/percent keys, repeated equals, operator replacement, result continuation, precision sentinel `9007199254740992 + 1`, rational/decimal behavior and input limits. Delivery independently compares 20 with Scientific 14. |
| 21–22 | `qml/tst_scientific_precedence.qml` and `tst_scientific_extended.qml`: precedence, nested parentheses, powers/roots, constants, logarithms/exponentials, secondary functions and known results through actual controls/core. |
| 23–26 | `qml/tst_scientific_trigonometry.qml`, `tst_scientific_extended.qml` and `tst_scientific_short_window.qml`: circular/inverse/hyperbolic families, DEG/RAD/GRAD, factorial/modulo, domains/range recovery, exponent entry, 25-level parentheses, all function controls and shortcuts. |
| 27–31 | `qml/tst_programmer.qml` and `programmer/tst_programmer_bits.qml`: radix round trips, DEC/QWORD startup, 64/32/16/8-bit signed boundaries, truncation/wraparound, legal digits, bitwise operations, all shift variants, carry and editable bit display. |
| 32–34 | `date/tst_date_difference.qml` and `tst_date_add_subtract.qml`: same/reversed dates, leap days/centuries, month ends, cross-year dates, add/subtract year/month/day order, range errors and recovery through calendar/offset UI. Date-only DST boundaries are included. |
| 35–37 | `history/tst_history.qml`: Standard/Scientific separation, expression/result ordering, reuse with native precision/angle/notation, clear/delete and 20/21 eviction boundary. Delivery journey reuses Standard history after Scientific, Programmer, graph, converter and settings visits. |
| 38–40 | `memory/tst_memory.qml`: real shared rational memory, toolbar/list/context actions, recall into pending arithmetic, current radix/width formatting, native precision and 100/101 eviction. History/memory restart suites verify no ordinary restoration; delivery and currency restart tests also verify state boundaries. |
| 41–45 | `graphing/tst_graphing.qml`: editable multi-curve known coordinates and rendered pixels, independent edit/delete, stable labels, pan/zoom/drag/wheel/keyboard, inspection, parser/domain errors, bounded sampling, undefined intervals and reciprocal/tangent asymptote gaps. This is the accepted explicit `y=f(x)` scope. |
| 46–47 | Every converter suite exercises selectors, active-side/reverse entry, real keypad/key input, same-unit ratios, permitted/rejected signs, 15-digit limits and fixed/scientific display policies. Shared category-session lifetime and per-category units are covered. |
| 48–50 | `currency/tst_currency.qml`: current catalog, validated pair conversion, automatic/manual asynchronous refresh, source and pair observation date, attempt time, unavailable status and out-of-order responses using deterministic external fixtures. |
| 51–53 | Currency suite plus `currency-restart/tst_currency_restart.qml`: first offline, cached offline, missing/corrupt/wrong-pair/invalid data, retained valid quotes, atomic-save failure/interruption, recovery and four independent restart stages. Preferences/rates persist while input/history/memory start fresh. |
| 54 | `volume-area-mass/tst_volume_area_mass.qml`: all 20 selectable volume units, US/UK distinctions, actual cubic-meter/liter example and limits/sign rules. |
| 55 | `length/tst_length.qml`: all 12 selectable units, actual ratios, same/reverse conversion, scientific display, paste validation and correction. |
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

## Deliberate differences and verification limits

- Only Linux x86_64 with the toolchain above was built and run in this task. Windows, macOS, other architectures, Qt 6.8 runtime, native display plugins, hardware rendering and installer/signing/store deployment are unverified. The source structure targets those desktop platforms; that is separate from execution evidence.
- Graphing is explicit `y=f(x)` with multiple curves and finite double-based evaluation/sampling. It does not claim implicit relations, inequalities or the proprietary Microsoft analysis engine. Bounded adaptive sampling can omit unresolved intervals and cannot guarantee detection of arbitrarily narrow features/singularities.
- Currency uses independent Frankfurter blended daily reference observations. The observation date belongs to the selected pair; refresh/download time is separate. No real-time trading price, Bing parity or uniform provider date is implied. Currency names retain the service's names when Qt has no matching localized currency name; ISO codes remain visible. Regular acceptance tests use fixtures; historical live-service checks are recorded in tickets 18/19, and no new live-service availability claim is made here.
- System-theme changes are exercised at the approved controlled platform boundary. The isolated generic platform can report Unknown; its Light fallback and explicit palette behavior are verified. Real host theme, IME, session bus and compositor behavior are intentionally outside this run.
- Independent integration review and the workflow's final application-wide review remain separate gates. No parent-spec checklist or other ticket status is modified by ticket 22.
