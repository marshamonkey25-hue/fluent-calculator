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

`ConversionSession.category` selects the catalog and resets category input/selection state. The shared `ConverterPage` receives that category through the navigation registry and retains the existing Fluent layout, keyboard, accessibility, clipboard, translation and palette behavior. All three added categories reject negative pasted values with category-specific translated messages.

The UI tests use independent known ratios and the pinned display resolution: below 1 the normal seven-digit policy counts the leading zero, leaving six decimal places (maximum rounding error 0.5e-6); below 1e-6 it uses 15 decimal places; at or above 1, comparisons allow 0.5 ppm. Scientific output comparisons allow 0.5 ppm. This documents display accuracy, without claiming arbitrary precision for converters.
