# Fluent Calculator

A Qt Quick desktop calculator using the real Microsoft Calculator arithmetic core. Standard mode provides digits, decimal entry, four arithmetic operations, equals, clear, expression/result/error display, and corresponding keyboard input. Programmer mode adds the integer radix and word-width behavior from ticket **07**. Other functionality is tracked in separate implementation tickets.

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

## Programmer radix and word width — ticket 07

Open **Programmer** in navigation. Entry starts in decimal, **QWORD (64-bit)**. The HEX/DEC/OCT/BIN rows show the current integer in all four bases; click a row or press **F5/F6/F7/F8** to change the input base. Unsupported digits and the decimal separator are disabled, including their keyboard shortcuts. Changing the base finishes the current entry, following the pinned core; the next digit begins a new entry.

Click the word-size button to cycle **QWORD → DWORD → WORD → BYTE**, or select **64/32/16/8** bits with **F2/F3/F4/F12**. The original core supplies two’s-complement interpretation, truncation/sign extension, input limits, integer division and arithmetic wraparound. Results and radix representations stay strings across the Qt/QML boundary. There is no Programmer history panel.

The keypad retains the reference five-column arrangement with A–F at the left. It supports four arithmetic operations, parentheses, modulo (`%`), negate (**F9**), backspace, clear entry (**Delete**), and clear (**Escape**). Narrow or short windows scroll vertically while maintaining usable keys; Tab focus reveals the focused control. New captions and accessibility names use the application’s translation hooks and palette.

`tests/qml/tst_programmer.qml` exercises real navigation, buttons, shortcuts and core results. It covers all bases and widths, `9007199254740993` round trips, signed highest bits and wraparound, width narrowing/sign extension, decimal/hex input limits, illegal digits, editing/precedence, errors/recovery, mode changes, and 320×460 / 360×560 / 900×700 layouts. Captures are saved as `programmer-{light,dark}-{narrow,default,wide}-{radices,keypad}.png` in the test working directory. The same CTest configurations and isolated data setup described above run both Standard and Programmer suites. Only Linux/Qt 6.12 is verified; bitwise operations and bit editing belong to ticket 08.
