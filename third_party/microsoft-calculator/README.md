# Microsoft Calculator arithmetic core

Pinned upstream: [microsoft/calculator](https://github.com/microsoft/calculator/tree/79e1ac53bba690cdf930e5dcd6ed9dbc4cbfb128), commit `79e1ac53bba690cdf930e5dcd6ed9dbc4cbfb128`.

`src/CalcManager` contains the selected arithmetic sources and their headers, copied from that revision. The explicit 27-translation-unit manifest is in [CMakeLists.txt](CMakeLists.txt). The production path is `CalculatorManager → CCalcEngine → Ratpack`. It does not build the Windows project, forced precompiled header, UWP/WinRT bridges, unit converter or proprietary graphing components. Existing algorithms and fixed-width mantissas are retained.

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
