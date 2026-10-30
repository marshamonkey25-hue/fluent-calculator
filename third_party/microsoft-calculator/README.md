# Microsoft Calculator core sources

Pinned upstream: [microsoft/calculator](https://github.com/microsoft/calculator/tree/79e1ac53bba690cdf930e5dcd6ed9dbc4cbfb128), commit `79e1ac53bba690cdf930e5dcd6ed9dbc4cbfb128`.

`src/CalcManager` contains the selected arithmetic and noncurrency converter sources and their headers, copied from that revision. The explicit 27-translation-unit manifest is in [CMakeLists.txt](CMakeLists.txt). The production path is `CalculatorManager → CCalcEngine → Ratpack`. The arithmetic target does not build the Windows project, forced precompiled header, UWP/WinRT bridges, unit converter or proprietary graphing components. The separate portable converter target is described below. Existing algorithms and fixed-width mantissas are retained.

The upstream [LICENSE](LICENSE), [NOTICE.txt](NOTICE.txt), and per-file copyright notices are preserved. NOTICE includes Microsoft's distributed third-party notice, including the Hebrew OpenType MIT attribution; retaining it does not imply this arithmetic subset uses that font code.

## Local portability changes

Nine upstream files differ from the pinned originals:

- `ExpressionCommandInterface.h`: directly include `<string>` for its public `std::wstring` declaration.
- `Header Files/IHistoryDisplay.h`: directly include `<string_view>` for its public interface.
- `CalculatorResource.h`: directly include `<string>` for its owning return type.
- `Ratpack/support.cpp`: include `<cmath>` and qualify `std::ceil` / `std::log2`.
- `Header Files/CalcEngine.h`: use non-inserting `find` in both `GetString` overloads. The original missing-key lookup could insert a `wstring_view` pointing into a temporary string; missing resources still yield an empty view. Expose resource refresh and retain the last error code for language-only redisplay.
- `CEngine/calc.cpp`: initialize `m_decimalSeparator` before `SettingsChanged()` reads it; add a focused resource refresh that does not reinitialize shared Ratpack constants or reset pending operands/history/memory.
- `CEngine/scifunc.cpp`: retain the last displayed error code so a language change can redisplay the actual current error.
- `CalculatorManager.h` / `CalculatorManager.cpp`: expose `RefreshResources()` over existing engines rather than reconstructing the manager when the UI language changes.

No arithmetic algorithms were replaced. Ratpack uses a trailing flexible array, a GCC/Clang/MSVC extension; strict ISO C++ builds with extensions rejected have not been verified. Run core operations serially: upstream constants, decimal separator and engine strings are process-global. The application owns one manager for its session, and the QML suite uses that same production path without mocked arithmetic.

## Engine resource provenance and fallback

`../../resources/engine/en-US.json` and `zh-CN.json` are direct key/value conversions of the corresponding upstream `src/Calculator/Resources/<language>/CEngineStrings.resw` tables. English has **108** entries; Simplified Chinese has **9** localized error overrides. `EngineResources` loads English first, then Chinese overrides for Simplified Chinese, preserving normal Windows resource fallback. The two supported UI locales both use `sDecimal="."`, `sThousand=","`, `sGrouping="3;0"` (Win32 grouping syntax).

`g_sids` has 152 references to 150 unique IDs. These **42** unique IDs have no mapping in the pinned English table and retain upstream empty fallback:

```text
0, 3, 5, 31, 32, 33, 34, 39, 42, 43, 44, 45, 46,
50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65,
93, 102, 103, 104, 106, 109, 111, 112, 113, 114, 115, 116, 117
```

Do not fill these IDs from `Resources.resw`: its numeric IDs are unrelated bit-position ordinals (`62` means `62nd`). No resource messages were invented for this port. Real QML tests exercise division by zero (`99`), undefined division (`101`), 16-digit entry limits, and expression symbols in both startup locales. Subsequent features must check their newly reachable errors against upstream resources. Ticket 03 binds runtime UI language to the existing session's resource refresh. Real-QML tests switch pending calculations and current errors between English and Chinese without resetting arithmetic state. `QQmlEngine::retranslate()` refreshes QML captions; the manager's focused refresh separately updates the core's static strings.

## Layout reference

The current Standard subset preserves number/operator positions from `Views/NumberPad.xaml` and `Views/CalculatorStandardOperators.xaml`, including C in row 0, column 2; division in row 1, column 3; digits in rows 2–5; and equals at the bottom right. Missing positions are intentionally empty until later tickets implement those operations. No inactive feature page is registered as working navigation.


## Noncurrency unit conversion — ticket 13

`microsoft_unit_converter` builds the pinned `UnitConverter.cpp/.h` and `NumberFormattingUtils.cpp/.h`, independently of the arbitrary-precision arithmetic target. It keeps the original decimal command input, double conversion ratios/offsets, active-field switching, 15-digit input cap, preferred seven-digit output, adaptive precision up to 15 digits, and scientific output below `1e-14` or beyond 15 whole-number digits. Scientific output uses the upstream stream precision (seven significant digits). Converter doubles are intentional and are never described as Ratpack values.

The selected noncurrency subset removes the Windows PPL async currency interfaces, Bing currency-loader constructor/branches, currency callbacks and currency-only formatting branch. It does not add task stubs or implement a currency service. Currency remains a separate ticket. Standard headers replace the PCH/PPL transitive dependencies: `<string>`, `<string_view>`, `<tuple>`, `<cstdint>`, `<algorithm>`, `<cmath>` and `<sstream>`. Default `Unit`/`Category` IDs are initialized to the existing empty sentinel `-1`, so startup validity comparisons do not read indeterminate IDs.

One behavior repair is covered through real QML: `TrimTrailingZeros` leaves scientific text intact. The upstream routine could trim the final zero in an exponent, turning `1.000000e-20` into `1.000000e-2` after the user selected that result as input and chose the same unit. Ordinary decimal trimming and the upstream conversion/rounding algorithms remain intact.

`../../app/LengthDataLoader.cpp` ports length IDs, selectable order, region defaults, metre factors and whimsical metadata from `src/Calculator.ViewModels/DataLoaders/UnitConverterDataLoader.cs` at the same pinned revision (lines 348–363 and 551–568). Category serialization ID **5** comes from `Common/NavCategory.cs`. English and Chinese unit names in the UI catalog come from the matching `Resources.resw` tables. There are 12 selectable units, from Angstroms through nautical miles; the three whimsical units stay outside the selectors as in upstream.

The Qt `ConversionSession` and QML `ConverterPage` share one input/conversion/formatting path for keypad and keyboard. Category metadata is separate from that interaction, so subsequent noncurrency tickets can supply their data without copying the input or formatting logic. Values stay strings across QML. Both supported UI locales use `.` and comma grouping; grouping does not round the core text. Paste validates a complete nonnegative decimal before sending commands, showing explicit malformed/negative/range/limit states instead of silently filtering bad input. This is an intentional validation adaptation to the ticket's error-recovery criteria. Ordinary conversion entry remains the pinned command path.


## Volume, area, weight and mass — ticket 14

`../../app/MeasurementDataLoader.cpp` ports the complete Volume, Area and Weight catalogs from the same pinned `Calculator.ViewModels/DataLoaders/UnitConverterDataLoader.cs`: unit IDs and selectable order, region-dependent source/target defaults, abbreviations, whimsical metadata, and explicit factors. Category serialization IDs 4, 9 and 6 come from `Common/NavCategory.cs`. Names in English and Simplified Chinese come from the matching `Resources.resw` files. There are 20 selectable volume units, 10 area units (11 in Japan, Taiwan and North/South Korea, where Pyeong is available), and 14 weight/mass units. Whimsical units remain outside selectors, matching the existing Length interaction.

Volume factors are in cubic centimeters/milliliters, area factors in square meters, and weight/mass factors in kilograms. US and UK liquid measures and short/long tons remain distinct. The pinned US cup factor is 236.588237 mL. Area and volume use their explicit dimensioned definitions, rather than linear length ratios. The existing real `UnitConverter` still owns decimal input, active-side conversion, double arithmetic, rounding and scientific output; no algorithm changes or additional vendored sources are needed for these categories.

`ConversionSession.category` selects the catalog on one MainWindow-owned session while retaining input, active side and per-category unit selections. The shared `ConverterPage` receives that session through the navigation registry and retains the existing Fluent layout, keyboard, accessibility, clipboard, translation and palette behavior. All three added categories reject negative pasted values with category-specific translated messages.

The UI tests use independent known ratios and the pinned display resolution: below 1 the normal seven-digit policy counts the leading zero, leaving six decimal places (maximum rounding error 0.5e-6); below 1e-6 it uses 15 decimal places; at or above 1, comparisons allow 0.5 ppm. Scientific output comparisons allow 0.5 ppm. This documents display accuracy, without claiming arbitrary precision for converters.
## Energy, speed, time and pressure metadata — ticket 15

`../../app/EnergySpeedTimePressureDataLoader.cpp` supplies the same portable `UnitConverter` with the four categories from pinned `Calculator.ViewModels/DataLoaders/UnitConverterDataLoader.cs`: Energy **8**, Speed **10**, Time **11**, Pressure **14** (IDs from `Common/NavCategory.cs`). It preserves all **35** unit definitions/factors: **8 / 7 / 8 / 6** selectable units respectively, plus the six upstream whimsical energy/speed definitions outside selectors. Selectable order, source/target flags, US/SI speed defaults, English names/abbreviations and Simplified Chinese names follow the pinned loader and matching `Resources.resw`. Joules is the first flagged Energy source; the later flagged kilowatt-hour does not override it.

The reference defines a year as **31,557,600 seconds** (365.25 days), mph as **44.7 cm/s**, knots as **51.44 cm/s**, Mach as **34,030 cm/s**, and mmHg using the pinned atmosphere ratio **0.0013155687145324**. These rounded reference definitions are intentionally retained. Thermal calories and food calories remain distinct (4.184 J and 4,184 J), and kilowatt-hours use 3,600,000 J. The pressure resource key's stray trailing space in the C# loader is removed so the actual RESW label resolves; incidental trailing whitespace in its localized name is trimmed.

`ConversionSession.category` selects one of these categories, Length, Volume, Area or Weight and Mass through a composite metadata loader without introducing another input/formatting path. MainWindow owns the shared session; the real converter preserves current input, active-side mapping and each category's selected unit pair. Native `SetCurrentCategory` also removes a leading minus when entering a category that disallows negative values. All values remain strings across QML. The ordinary pinned format policy still applies: preferred seven display digits counts the leading zero for fixed sub-unit output (e.g. one second in minutes displays `0.016667`); scientific output uses seven significant digits. Tests allow half a millionth for fixed sub-unit rounding and 0.5 ppm for scientific output, with literal independently known examples and all unit lists checked through the real QML application.

## Temperature, Power and Angle metadata — ticket 16

`../../app/TemperaturePowerAngleDataLoader.cpp` ports the same pinned C# loader's three signed categories: Temperature (serialization ID **7**), Power (**12**) and Angle (**15**), from `Common/NavCategory.cs`. Selectable units, order and regional defaults come from `UnitConverterDataLoader.cs` lines 365–378 and 455–458. Temperature contains Celsius/Fahrenheit/Kelvin and preserves every explicit ratio, offset and `offsetFirst` flag from lines 668–688, including Fahrenheit→Kelvin's offset-before-scaling rule. Power preserves the five selectable watt/kilowatt/US horsepower/foot-pound-per-minute/BTU-per-minute units and three hidden whimsical units, with watt factors from lines 569–579. Angle preserves degree/radian/gradian factors from lines 651–656. English and Simplified Chinese names come from the pinned `Resources.resw` files.

All three set the core category's `supportsNegative` flag. The shared QML keypad adds the reference bottom-left negate control and `-` / F9 shortcuts from `UnitConverter.xaml` and its resources. The original converter still owns entry, sign changes, scaling/offsets, active-side switching and formatting; ticket 16 changes no vendored algorithm. The pinned input budget counts the minus sign while appending digits: 14 digits after a sign, or 15 digits followed by a sign toggle. Signed paste validates a finite complete decimal with at most 15 normalized digits before entering its magnitude and toggling the sign; malformed/over-limit values cannot partially replace the entry. The Length category remains nonnegative.

## Data conversion metadata — ticket 17

`../../app/DataConversionDataLoader.cpp` ports Data (serialization ID **13**) from the same pinned `Calculator.ViewModels/DataLoaders/UnitConverterDataLoader.cs`: all **35 selectable units**, their order, Gigabytes→Megabytes defaults, abbreviations, and the three hidden whimsical definitions. The source factors use **megabytes** as base and remain explicit doubles, preserving bits (one eighth of a byte), nibbles (four bits), decimal kilo through yotta, and binary kibi through yobi. The upstream spelling “Zetabits/Zetabytes” and English/Simplified Chinese `Resources.resw` labels are retained, including compact Chinese labels and English Yottabits/Yottabytes fallbacks. Category flags disallow negative values. No converter arithmetic or input/formatting algorithms change.

The category joins the existing MainWindow-owned `ConversionSession` and shared Fluent page, with translated navigation/negative-input feedback. Current numeric input, active side, and the native converter's remembered source/target units survive category navigation. As in the pinned core, remembered source/target units map to the currently active field when a category is reentered; changing the active field in another category may reverse the physical display order. Data never inherits another category's units.

`tests/data/tst_data.qml` exercises actual QML navigation, selectors, keypad/keyboard, and the real converter for every selectable unit, decimal/binary boundaries, same-unit and reverse conversion, fractional input, 15-digit limits, correction/recovery, negative rejection, extreme scientific values, category lifetime, runtime translation/theme changes, and keyboard focus/layout at 320×480 and 900×600. Independent literal expectations allow **0.5 ppm** for scientific/significant-digit output; fixed sub-unit rounding cases explicitly permit **0.5e-6** absolute error. `tests/data-restart` checks recent-mode/theme/language persistence and fresh zero input in another process. All tests use the shared isolated offscreen launcher, with no host desktop/session-bus access.

## Dynamic currency metadata — ticket 18

The Qt application now adds Frankfurter v2 blended daily currency data through `app/CurrencyRates` as a real `IConverterDataLoader` (category serialization ID **3**), without reinstating the removed Windows/PPL/Bing interfaces. See [service attribution and data terms](../../docs/currency-rates.md). The same session-owned Microsoft `UnitConverter` performs decimal input, conversion, reverse-entry and formatting for currency and noncurrency categories. Qt handles asynchronous HTTPS and validates each actual pair/date/rate before exposing it to the converter; the QML bridge remains strings.

The currency-specific formatting branch removed for ticket 13 is restored through an explicit loader category query: currency rounds to 15 decimal places before trimming trailing zeroes, while noncurrency retains its seven-digit/adaptive/scientific policy. A real-QML regression reproduces the former loss (`0.123456789012345` became `0.123457`) and verifies the restored output.

Two narrow core adaptations support dynamic data: `RefreshData()` reloads catalog/ratios while preserving input, active-entry behavior and each category's selected units; `Calculate()` explicitly returns an unavailable empty result for a missing conversion or a non-finite converted amount instead of default-inserting an uninitialized ratio or formatting infinity. The Qt page renders that as an em dash with an explicit status and disables selecting that result as input. Existing conversion algorithms, arithmetic Ratpack precision and noncurrency metadata remain unchanged. QML regressions cover refresh while another category is active, retained per-category choices, stale-response rejection, extreme finite rates, recovery and reverse amounts. No persistent rate cache is introduced by ticket 18.
