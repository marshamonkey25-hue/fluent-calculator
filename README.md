# Fluent Calculator

A Qt Quick desktop calculator using the real Microsoft Calculator arithmetic core. This checkout implements ticket **01** (Standard digits, decimal entry, four arithmetic operations, equals, clear and display) and ticket **04** (Scientific precedence, parentheses and mode navigation). Both pages provide mouse and keyboard input through the same core. Extended Scientific functions and the remaining modes/operations belong to separate implementation tickets.

The content follows the pinned Microsoft Standard layout with Fluent controls and native system window decorations. Future operations occupy their reference positions; unimplemented controls are absent. Navigation is registered centrally in `qml/ModeRegistry.qml`. `MainWindow` owns one `CalculationSession`, which dispatches string command names to `CalculatorManager`, `CCalcEngine` and Ratpack. Arithmetic displays and expressions remain strings across C++/QML, including integers above JavaScript's safe integer range.

## Dependencies

- CMake **3.21+**, a Make-compatible build tool, and a C++17 compiler with support for the upstream trailing-array extension.
- Qt **6.8+** development libraries: Core, Gui, Qml, Quick, QuickControls2; QuickTest for tests. Install the runtime QML modules for Qt Quick, Controls, Layouts, and QtTest, plus the **FluentWinUI3** style. The minimum follows the selected Qt APIs/style; the version actually checked is 6.12.0.
- A desktop session with an appropriate Qt platform plugin. Automated tests use the offscreen plugin and software rendering; no Vulkan SDK is needed for these checks.

On Arch Linux, install `base-devel cmake qt6-base qt6-declarative`; on the checked host, `qt6-declarative` owns QuickControls2, FluentWinUI3 and QtTest. Distribution packaging varies: ensure its Qt Quick Controls installation includes FluentWinUI3 and QtTest. On Debian/Ubuntu use Qt 6 development/declarative tooling and QML packages from a distribution or Qt installation that provides at least 6.8; older distribution Qt releases do not meet this project's selected minimum. A Qt online/offline SDK is another option. Point `CMAKE_PREFIX_PATH` to the chosen SDK if CMake cannot locate it. Qt command-line tools on the checked host live in `/usr/lib/qt6/bin`.

The vendored arithmetic sources require no network download, UWP SDK or external arithmetic package. See [upstream provenance, changes and notices](third_party/microsoft-calculator/README.md), [MIT license](third_party/microsoft-calculator/LICENSE), and [third-party notices](third_party/microsoft-calculator/NOTICE.txt).

## Build and run

From this checkout, use a private build tree and modest parallelism:

```sh
cmake -S . -B .build -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Debug
cmake --build .build -j2
./.build/calculator
```

If using another build generator, select its installed equivalent. On macOS/Windows, retain the same source/CMake structure and use the appropriate Qt SDK, platform plugin and generator. **Those platforms have not been built or run for this ticket.**

Optional isolated app data for a Linux manual run:

```sh
mkdir -p .build/manual-data/config .build/manual-data/data .build/manual-data/cache
XDG_CONFIG_HOME="$PWD/.build/manual-data/config" \
XDG_DATA_HOME="$PWD/.build/manual-data/data" \
XDG_CACHE_HOME="$PWD/.build/manual-data/cache" \
QT_QUICK_BACKEND=software ./.build/calculator
```

The application uses the system color scheme and palette. All new UI captions/accessibility names use `qsTr`, and engine resources include English plus Simplified Chinese overrides selected at startup. Runtime language/theme preferences and a settings page are ticket 03, not a claim of completion in this tracer.

Click the visible keys, or type digits, `.`, `+`, `-`, `*`, `/`. `=`, Return and keypad Enter evaluate; Escape clears. Tab/Shift+Tab navigate real controls, and Space activates the focused button. Both mouse and keyboard dispatch through the same command path. Standard mode evaluates step by step: `2 + 3 * 4 =` gives `20`.

## Checks

```sh
ctest --test-dir .build --output-on-failure
cmake --build .build --target calculator_ui_qmllint -j2
```

Configure with `-DBUILD_TESTING=OFF` only when deliberately building without QuickTest. The normal configuration includes all current checks.

The three CTest entries run the same real-QML behavior suite in English/light, English/dark, and Simplified-Chinese engine startup/light. CTest sets offscreen/software rendering; the test setup gives each process a temporary settings/data/cache root and deterministic locale. No network calls, shared user settings or mocked calculator core are involved. The suite covers:

- Mouse stepwise evaluation and displayed expression, keyboard decimal entry/evaluation/clear, all four arithmetic operations, decimal precision, and the core's 16-digit input limit.
- Exact `9007199254740992 + 1 = 9007199254740993`, then subtracting `9007199254740992` to get `1`, via both mouse and keyboard.
- Meaningful division-by-zero and undefined-result errors, clear and continued calculation, including Chinese engine messages and shared operation symbols.
- Navigation return with in-progress calculation retained, translated-source accessible labels, Tab focus, all current keys at 320×460 and 900×700, image capture, and normal window close.

Screenshots `standard-{light,dark}-{narrow,wide}.png` are saved in the test working/build directory. To run the same QML suite in an actual Wayland session, preserving the current desktop's runtime environment:

```sh
cd .build
QT_QPA_PLATFORM=wayland QT_QUICK_BACKEND=software \
CALCULATOR_TEST_THEME=light ./calculator_ui_tests
```

## Local verification for ticket 01

Checked on Linux x86_64 (Omarchy/Arch), Qt **6.12.0**, GCC **16.2.1**, CMake **4.4.4**, GNU Make. The private `.build-ticket01` Debug build compiled all 27 real core translation units, linked the application, and passed all three CTest entries (13 QtTest outcomes per entry, no failures/skips). The same complete QML suite passed on native Wayland (13 passed, no failures/skips). QML lint passed without warnings. The real standalone executable opened a native Wayland window titled `Calculator` (`xwayland=false`), then handled the compositor's normal close request and exited **0**. Tests also close the production QML window normally. Offscreen screenshots were reviewed in both themes and at narrow/wide sizes. No pixel-equivalence claim is made; other-ticket controls/history are absent and native fonts/chrome differ by platform.

TDD evidence: the initial mouse test failed with `0` versus `20`, then passed after the real core bridge was added; keyboard clear failed with `4` versus `0`, then passed after shortcuts were connected; explicit error-state and accessible-name tests each failed before their UI additions; Chinese expression symbols failed (`5 4` versus `5 × 4 =`) before layering the pinned English resource fallback. Exact-precision/digit-limit cases are regression checks of the real imported core and were not falsely reported as new failing tests.

Current limits: only Linux/Qt 6.12 is actually verified; no three-platform installers or deployment; runtime settings/translation, full Standard operations, history, memory, additional modes, converters and graphing remain with their own tickets. Ticket 01 is resolved after a fresh integration build, all three CTest configurations, native Wayland tests, QML lint and standalone normal-close validation; see its local tracker entry for merge evidence. The completed application still requires the workflow’s final independent review.


## Scientific precedence and parentheses (ticket 04)

Select **Scientific** in navigation. It uses the same session-owned Microsoft manager with its actual Scientific engine, 32-digit input policy, rational precision, precedence and 25-level parenthesis limit. `2 + 3 * 4 =` gives `14`; `((2 + 3) * 4) =` gives `20`. Type `(` and `)` or click their buttons. Equals closes unfinished parentheses; an unmatched close is ignored; an operand followed by an opening parenthesis implies multiplication, following the pinned core. Clear/Escape recovers from errors. Switching between arithmetic modes clears current entry/expression as in upstream `CalculatorManagerTestModeChange`; selecting the already-current mode keeps the calculation.

The Scientific panel uses the pinned five-column/seven-row layout in `CalculatorScientificOperators.xaml`, with extension positions reserved for tickets 05/06. All implemented keys remain at least 44×44, with a 320×540 minimum Scientific window (Standard retains 320×460). Long expressions have a horizontal viewport/scrollbar and remain fully available without overlapping controls. New labels use `qsTr`, controls reuse the shared palette/focus styles, and navigation remains in `ModeRegistry.qml`. Runtime preferences/translations remain with ticket 03.

The production-QML suite `tests/qml/tst_scientific_precedence.qml` covers mode reset/return, 14 versus 20, mouse/keyboard nested parentheses, automatic closure, implicit multiplication, unmatched close, the 25-parenthesis/32-digit caps, exact `1 / 3 × 3 = 1`, decimals, localized division-error recovery, horizontal expression scrolling, focus/Space activation, and both window sizes. Behavioral sources are pinned `CalculatorManagerTest.cpp` (`CalculatorManagerTestScientificParenthesis`, `CalculatorManagerTestScientificError`, `CalculatorManagerTestModeChange`), `CEngine/scicomm.cpp` (`IDC_EQU`, `IDC_OPENP`/`IDC_CLOSEP`), `Header Files/History.h` and `CalculatorManager.h`. Additional results use independent arithmetic examples rather than recorded engine output.

Ticket 04 was built in `.build-ticket04` with Debug/Make and `-j2` on Linux x86_64, Qt 6.12/GCC 16.2. All three CTest variants passed, now **27 QtTest outcomes per variant**, and the complete native Wayland suite also passed 27/27 with no skips. QML lint passed without warnings. The standalone app was observed as a native Wayland `Calculator` window (`xwayland=false`); test windows close via the app's own close action. Screenshots `scientific-{light,dark}-{narrow,wide}.png` were reviewed in the private build directory. Windows/macOS remain unverified.

Real red→green evidence: Scientific navigation was initially absent; adding the real mode/page made 14 versus 20 pass. Nested mouse input initially lacked the opening-parenthesis key and keyboard input returned 14 instead of 20; native commands/shortcuts and parenthesis-aware expression spacing made both pass. A long-expression scrolling test initially had no viewport; the horizontal viewport/scrollbar made the same drag interaction pass. Limits and error cases then passed as regression checks of the imported core. Context7 verified current Qt Loader focus and Flickable/ScrollBar APIs; no documentation fallback was needed. Independent integration review remains the workflow's merge gate.
