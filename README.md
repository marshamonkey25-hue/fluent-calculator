# Fluent Calculator

A Qt Quick desktop calculator using the real Microsoft Calculator arithmetic core. This checkout implements tickets **01–10**: Standard arithmetic, expression/result/error display, entry correction, reference error recovery, copying results, keyboard input, persistent theme/language settings, Scientific precedence, extended operations and trigonometry, Programmer integer radix/word-width operations, bitwise operations and editable bit displays, per-mode calculation history, and shared calculator memory. Additional modes are separate implementation tickets.

The content follows the pinned Microsoft Standard keypad layout with Fluent controls and native system window decorations. Navigation is registered centrally in `qml/ModeRegistry.qml`. `MainWindow` owns one `CalculationSession`, which dispatches string command names to `CalculatorManager`, `CCalcEngine` and Ratpack. Arithmetic displays and expressions remain strings across C++/QML, including integers above JavaScript's safe integer range.

## Dependencies

- CMake **3.21+**, a Make-compatible build tool, and a C++17 compiler with support for the upstream trailing-array extension.
- Qt **6.8+** development libraries: Core, Gui, Qml, Quick, QuickControls2, Network; QuickTest for tests. Install the runtime QML modules for Qt Quick, Controls, Layouts, and QtTest, plus the **FluentWinUI3** style. The minimum follows the selected Qt APIs/style; the version actually checked is 6.12.0.
- For tests: Python **3.8+** (standard library only), and **dbus-run-session** on Linux. The test launcher refuses a Linux run if D-Bus isolation is unavailable. Qt offscreen/software rendering needs no desktop session or Vulkan SDK. Interactive production use needs the appropriate native Qt platform plugin.

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

The `calculator` executable is for normal interactive use. Acceptance validation must use the isolated test commands below; do not launch a visible app or native test window on the user's desktop. Historical native-check reports later in this file predate this explicit isolation policy.

Open navigation → Settings to select Light, Dark, or Use system setting, and English, Simplified Chinese, or Use system setting. Changes apply immediately, including current core errors, without clearing a pending calculation. Unsupported system languages (including Traditional Chinese) fall back to English. Explicit choices override system changes. Theme, language choice and the most recent available mode persist in local Qt settings; an unavailable saved mode safely opens Standard. Ordinary restarts create a fresh calculation session; history and memory are never written by preferences.

`AppPreferences` owns the settings and Qt translator. New pages use `qsTr`, add their context/source translations to `resources/ui/zh-CN.json`, and inherit the application palette; no separate theme or language state is needed. Register each implemented mode with a stable key in `qml/ModeRegistry.qml` to participate in navigation and restoration. `SystemPreferences` obtains the platform's language and applies Qt's native scheme override/reset; it is the external input replaced in deterministic tests. The engine language binding refreshes resources on the existing manager, preserving arithmetic state and shared Ratpack constants.

Click the visible keys, or use the reference shortcuts below. Tab/Shift+Tab navigate real controls, and Space activates the focused button. Both mouse and keyboard dispatch through the same command path. Standard mode evaluates step by step: `2 + 3 * 4 =` gives `20`.

| Operation | Keyboard |
| --- | --- |
| Digits, decimal, arithmetic | `0`–`9`, `.`, `+`, `-`, `*`, `/` |
| Equals | `=`, Return, keypad Enter |
| Percent, negate | `%`, F9 |
| Square, square root, reciprocal | Q, `@`, R |
| Clear all, clear entry, backspace | Escape, Delete, Backspace |
| Copy current result | Platform Copy shortcut (Ctrl+C on Linux/Windows, Command+C on macOS), or right-click the result and choose Copy |

CE clears the current operand while preserving the pending calculation; C clears the calculation. Backspace removes an input digit and leaves completed results unchanged. After an error, digits and the decimal separator start a fresh calculation; C, CE, Backspace, and equals clear the error. Operators are disabled until recovery. Copy remains available during errors: numeric text has grouping separators removed without numeric conversion, while localized error text is copied unchanged.

## Checks

```sh
ctest --test-dir .build --output-on-failure
cmake --build .build --target calculator_ui_qmllint -j2
```

Configure with `-DBUILD_TESTING=OFF` only when deliberately building without QuickTest. The normal configuration includes all current checks.

The three main CTest entries run the real-QML behavior suite with controlled English/light, English/dark, and Simplified-Chinese/light system preferences. The additional `calculator-preferences-restart` entry launches three separate processes against one temporary settings root: select preferences through the UI and close normally, restart and observe their restoration with fresh calculation state, then seed invalid external settings and observe safe defaults. CTest sets offscreen/software rendering; each run isolates Qt settings, data and cache. No network calls, shared user settings or mocked calculator core are involved. The suite covers:

- Mouse stepwise evaluation and displayed expression, keyboard decimal entry/evaluation/clear, all four arithmetic operations, decimal precision, and the core's 16-digit input limit.
- Exact `9007199254740992 + 1 = 9007199254740993`, then subtracting `9007199254740992` to get `1`, via both mouse and keyboard.
- Meaningful division-by-zero and undefined-result errors, clear and continued calculation, including Chinese engine messages and shared operation symbols.
- Navigation return with in-progress calculation retained, translated accessible labels, Tab focus, all current keys at 320×460 and 900×700, image capture, and normal window close.
- Runtime theme/language selection, translated live/future core errors, pending `6 × 7` continued after translation, controlled system changes and explicit overrides, unsupported-language fallback, keyboard scrolling/focus retention through translated settings, and readable heading/result contrast in both themes.

Screenshots are captured by the offscreen renderer in the test working/build directory. All CTest entries, including preference restart helpers, run through `tests/run-ui-isolated.py`. It removes inherited display, IME, session-bus, accessibility-bus and legacy theme configuration; forces compose, offscreen/software and the generic platform theme; creates private 0700 settings/data/cache/runtime roots; and cleans them after normal exit. On Linux it starts `dbus-run-session` with a private socket/config and no host service activation directories. It neither queries nor controls the user's IME or session bus. System-bus access is pointed at an unavailable private path as well.

Safe direct UI validation from this checkout:

```sh
cd .build
python3 ../tests/run-ui-isolated.py ./calculator_ui_tests
# A focused production-QML suite:
python3 ../tests/run-ui-isolated.py ./calculator_ui_tests -input ../tests/qml/tst_scientific_extended.qml
# This also re-enters the compiled-in launcher before QGuiApplication creation:
./calculator_ui_tests
```

The direct test executable validates its environment before constructing the Qt application; invalid/missing isolation causes a launcher restart, and failure to start it aborts the test. `--isolation-probe` reports the prepared environment before creating any GUI object. `calculator-test-isolation` seeds invalid inherited settings, checks child variables/private storage cleanup, authenticates only the private D-Bus socket, and verifies the direct executable's early restart. Restart test stages deliberately share only their temporary fixture data root, with a fresh runtime and bus for each process.

Linux is the verified platform for private D-Bus validation. The launcher uses offscreen/compose and private test paths on other platforms but does not assume they have `dbus-run-session`; Windows/macOS behavior remains unverified. The current Qt settings tests explicitly redirect QSettings to their private fixture paths. No test changes production IME configuration.

## Local verification for ticket 01

Checked on Linux x86_64 (Omarchy/Arch), Qt **6.12.0**, GCC **16.2.1**, CMake **4.4.4**, GNU Make. The private `.build-ticket01` Debug build compiled all 27 real core translation units, linked the application, and passed all three CTest entries (13 QtTest outcomes per entry, no failures/skips). The same complete QML suite passed on native Wayland (13 passed, no failures/skips). QML lint passed without warnings. The real standalone executable opened a native Wayland window titled `Calculator` (`xwayland=false`), then handled the compositor's normal close request and exited **0**. Tests also close the production QML window normally. Offscreen screenshots were reviewed in both themes and at narrow/wide sizes. No pixel-equivalence claim is made; other-ticket controls/history are absent and native fonts/chrome differ by platform.

TDD evidence: the initial mouse test failed with `0` versus `20`, then passed after the real core bridge was added; keyboard clear failed with `4` versus `0`, then passed after shortcuts were connected; explicit error-state and accessible-name tests each failed before their UI additions; Chinese expression symbols failed (`5 4` versus `5 × 4 =`) before layering the pinned English resource fallback. Exact-precision/digit-limit cases are regression checks of the real imported core and were not falsely reported as new failing tests.

Current limits: only Linux/Qt 6.12 is actually verified; no three-platform installers or deployment; history, memory, additional modes, converters and graphing remain with their own tickets. Ticket 01 is resolved after a fresh integration build, all three CTest configurations, native Wayland tests, QML lint and standalone normal-close validation; see its local tracker entry for merge evidence. The completed application still requires the workflow’s final independent review.


## Local verification for ticket 02

The private `.build-ticket02` Debug build passes all three CTest configurations with **122 passed, 0 failed, 0 skipped** per configuration, plus QML lint. The additional real-QML coverage exercises all Standard arithmetic/correction keys and their keyboard accelerators, percent contexts, repeated equals, operator replacement, entry correction, five error scenarios with every supported recovery key, and Copy observed through an editable control's real clipboard paste. Exact digits, decimal trailing zeroes and localized errors survive copying. Narrow/wide light/dark captures retain the pinned keypad positions and readable symbols.

The standalone executable also mapped a native Wayland window (`xwayland=false`) and exited **0** after a normal compositor close. The native Wayland QuickTest run could not obtain window activation on this desktop, including after explicit compositor focus requests; it stopped at its initial `active` assertion. The full behavior suite is therefore verified on offscreen/software rendering for this ticket, without claiming a successful native Wayland behavior run. Windows/macOS remain unverified. Runtime UI translation/preferences remain ticket 03.

TDD reds and greens, reference behavior sources, and merge-validation ownership are recorded in the [ticket 02 tracker](.scratch/calculator/issues/02-standard-operations-recovery.md). The tracker remains ready for the integration reviewer to validate and close.


## Local verification for ticket 03

The private `.build-ticket03` Debug build passed all four CTest entries on Linux with Qt **6.12.0**, GCC **16.2.1**, CMake **4.4.4**, and GNU Make. Each of the three main configurations reports **23 passed, 0 failed, 0 skipped**; the restart check passes all three independent process stages. QML lint completed without warnings. Settings screenshots were reviewed in English/light and Simplified-Chinese/dark at 320×460 and 900×700; keyboard focus scrolls each option into view, and heading/result contrast is checked automatically. The pinned Standard key positions and native window decorations remain in place.

TDD evidence includes failures before adding reachable Settings, language selection, live core-error translation, the controlled system-preference input, persistence across a real process restart, accessible option labels and keyboard scrolling, and a readable light-theme fallback heading. Each slice passed after its corresponding implementation; earlier red/green logs remain in the private build directory.

A native Wayland run was attempted but failed the existing `active === true` setup assertions before exercising calculator operations: the compositor did not activate either test window after `requestActivate()`. That run is **not** reported as passing, and the assertions remain intact. Functional acceptance here uses the complete offscreen/software-rendering tests. Windows/macOS and native Wayland keyboard interaction are not newly verified by ticket 03. Only Standard is registered at this integration point; recent-mode restoration covers its stable key and rejects an unavailable saved key. The registry hook applies to later implemented modes without adding preference state to those pages.

## Scientific precedence and parentheses (ticket 04)

Select **Scientific** in navigation. It uses the same session-owned Microsoft manager with its actual Scientific engine, 32-digit input policy, rational precision, precedence and 25-level parenthesis limit. `2 + 3 * 4 =` gives `14`; `((2 + 3) * 4) =` gives `20`. Type `(` and `)` or click their buttons. Equals closes unfinished parentheses; an unmatched close is ignored; an operand followed by an opening parenthesis implies multiplication, following the pinned core. Clear/Escape recovers from errors. Switching between arithmetic modes clears current entry/expression as in upstream `CalculatorManagerTestModeChange`; selecting the already-current mode keeps the calculation.

The Scientific panel uses the pinned five-column/seven-row layout in `CalculatorScientificOperators.xaml`, with extension positions reserved for tickets 05/06. All implemented keys remain at least 44×44, with a 320×540 minimum Scientific window (Standard retains 320×460). Long expressions have a horizontal viewport/scrollbar and remain fully available without overlapping controls. New labels use `qsTr`, controls reuse the shared palette/focus styles, and navigation remains in `ModeRegistry.qml`. Runtime preferences and translations use the settings infrastructure from ticket 03.

The production-QML suite `tests/qml/tst_scientific_precedence.qml` covers mode reset/return, 14 versus 20, mouse/keyboard nested parentheses, automatic closure, implicit multiplication, unmatched close, the 25-parenthesis/32-digit caps, exact `1 / 3 × 3 = 1`, decimals, localized division-error recovery, horizontal expression scrolling, focus/Space activation, and both window sizes. Behavioral sources are pinned `CalculatorManagerTest.cpp` (`CalculatorManagerTestScientificParenthesis`, `CalculatorManagerTestScientificError`, `CalculatorManagerTestModeChange`), `CEngine/scicomm.cpp` (`IDC_EQU`, `IDC_OPENP`/`IDC_CLOSEP`), `Header Files/History.h` and `CalculatorManager.h`. Additional results use independent arithmetic examples rather than recorded engine output.

Ticket 04 was built in `.build-ticket04` with Debug/Make and `-j2` on Linux x86_64, Qt 6.12/GCC 16.2. All three CTest variants passed, now **27 QtTest outcomes per variant**, and the complete native Wayland suite also passed 27/27 with no skips. QML lint passed without warnings. The standalone app was observed as a native Wayland `Calculator` window (`xwayland=false`); test windows close via the app's own close action. Screenshots `scientific-{light,dark}-{narrow,wide}.png` were reviewed in the private build directory. Windows/macOS remain unverified.

Real red→green evidence: Scientific navigation was initially absent; adding the real mode/page made 14 versus 20 pass. Nested mouse input initially lacked the opening-parenthesis key and keyboard input returned 14 instead of 20; native commands/shortcuts and parenthesis-aware expression spacing made both pass. A long-expression scrolling test initially had no viewport; the horizontal viewport/scrollbar made the same drag interaction pass. Limits and error cases then passed as regression checks of the imported core. Context7 verified current Qt Loader focus and Flickable/ScrollBar APIs; no documentation fallback was needed. Independent integration review remains the workflow's merge gate.


## Integration verification for ticket 04

Ticket 04 is merged and resolved after checking its acceptance criteria against the combined tickets 01–04. The integration preserves Standard recovery/Copy and all theme/language settings. Scientific now supplies its Simplified Chinese labels, and its keyboard shortcuts stay inactive while Settings is visible. Real-QML regressions reproduced both issues before their fixes; language changes now preserve a pending parenthesized calculation and translate an existing error. Restart coverage also restores Scientific as the recent mode, with a fresh calculation and correct precedence.

The `.build-integration` Debug build and all four CTest entries pass on Linux/Qt 6.12: **149 passed, 0 failed, 0 skipped** per main theme/language configuration, plus five successful independent restart stages. Native Wayland Scientific tests pass **16/16**. QML lint is warning-free, and light/dark captures at 320×540 and 900×700 were reviewed. The existing runtime Qt warning about Standard's single Copy key-sequence binding remains; clipboard behavior tests pass. Windows/macOS are unverified. See the [ticket 04 tracker](.scratch/calculator/issues/04-scientific-precedence.md) for merge/fix commits and logs. Final application-wide review remains pending.


## Programmer radix and word width — ticket 07

Open **Programmer** in navigation. Entry starts in decimal, **QWORD (64-bit)**. The HEX/DEC/OCT/BIN rows show the current integer in all four bases; click a row or press **F5/F6/F7/F8** to change the input base. Unsupported digits and the decimal separator are disabled, including their keyboard shortcuts. Changing the base finishes the current entry, following the pinned core; the next digit begins a new entry.

Click the word-size button to cycle **QWORD → DWORD → WORD → BYTE**, or select **64/32/16/8** bits with **F2/F3/F4/F12**. The original core supplies two’s-complement interpretation, truncation/sign extension, input limits, integer division and arithmetic wraparound. Results and radix representations stay strings across the Qt/QML boundary. There is no Programmer history panel.

The keypad retains the reference five-column arrangement with A–F at the left. It supports four arithmetic operations, parentheses, modulo (`%`), negate (**F9**), backspace, clear entry (**Delete**), and clear (**Escape**). Narrow or short windows scroll vertically while maintaining usable keys; Tab focus reveals the focused control. New captions and accessibility names use the application’s translation hooks and palette.

`tests/qml/tst_programmer.qml` exercises real navigation, buttons, shortcuts and core results. It covers all bases and widths, `9007199254740993` round trips, signed highest bits and wraparound, width narrowing/sign extension, decimal/hex input limits, illegal digits, editing/precedence, errors/recovery, mode changes, and 320×460 / 360×560 / 900×700 layouts. Captures are saved as `programmer-{light,dark}-{narrow,default,wide}-{radices,keypad}.png` in the test working directory. The same CTest configurations and isolated data setup described above run both Standard and Programmer suites. Only Linux/Qt 6.12 is verified; bitwise operations and bit editing are described below for ticket 08.


## Integration verification for ticket 07

Ticket 07 is merged and resolved with tickets 01–04 preserved. Programmer now uses the shared runtime Chinese translation catalog and disables keypad, radix and width shortcuts while Settings is visible. Real-QML regressions reproduced both integration issues before their fixes. Mode-switch tests also distinguish Programmer integer division from Scientific decimal division, and ordinary restart restores Programmer with fresh input and DEC/QWORD defaults while keeping theme/language preferences.

The `.build-integration` Debug build, QML lint and all four CTest entries pass on Linux/Qt 6.12: **187 passed, 0 failed, 0 skipped** per main configuration, plus seven independent restart stages. The expanded combined UI suite uses a 180-second limit after the former 60-second limit timed out; final configurations completed in 139–148 seconds. Selected native Wayland Programmer checks pass **14/14**, including exact 64-bit conversions, signed boundaries, translation and Settings shortcut isolation. Light/dark narrow/default/wide captures were reviewed. The existing Standard Copy shortcut warning remains, with clipboard tests passing; Windows/macOS remain unverified. See the [ticket 07 tracker](.scratch/calculator/issues/07-programmer-radix-word-width.md) for commits and evidence. Final application-wide review remains pending.


## Scientific extended operations — ticket 05

Scientific now exposes the pinned Microsoft power/root/logarithm column, constants, factorial, modulo, reciprocal, absolute value, exponent entry, scientific notation and Function flyout. **2nd** changes the six extension buttons to cube, cube root, nth root, two to the power, logarithm with a chosen base and exponential. Selecting a secondary operation restores the primary column and returns focus to 2nd. An unused 2nd selection survives temporary mode navigation within the session, matching the pinned cached operator panel; an ordinary restart creates fresh toggle state. The Function flyout offers absolute value, floor, ceiling, random number, degrees/minutes/seconds and decimal degrees; selection closes it, and Tab/Space/Escape work with its real controls. Trigonometric functions and the angle-unit selector are described in ticket 06 below.

All arithmetic executes in the existing Microsoft manager/CEngine/Ratpack, including full Scientific precision for π, e and intermediate values. `exp` enters an exponent on the current operand; it is distinct from the `eˣ` operation. The core caps exponent entry at four digits. **F-E** toggles result notation without converting numbers in QML, and ordinary C/CE actions or leaving Scientific restore ordinary notation according to the reference UI flow. The shared C/CE button reads `CalculatorManager::IsInputEmpty()`: CE preserves a pending calculation, while Escape always clears it. Backspace remains in its reference position. Invalid domains and range errors display the core's translated message; unavailable operations/shortcuts stay disabled until recovery.

| Scientific operation | Reference keyboard entry |
| --- | --- |
| Square / cube | Q / `#` |
| Square root / cube root | `@` / B |
| Power / nth root | Y or `^` / Ctrl+Y |
| Ten to the power / two to the power | Ctrl+G / G |
| Logarithm / logarithm with chosen base | L / Shift+L |
| Natural logarithm / exponential | N / Ctrl+N |
| π / e | P / Shift+E |
| Factorial / modulo | `!` / `%` |
| Reciprocal / absolute value | R / `\|` |
| Floor / ceiling / random | `[` / `]` / Shift+R |
| Degrees/minutes/seconds | M |
| Exponent entry / scientific notation | E / V |
| Negate / clear / clear entry / backspace | F9 / Escape / Delete / Backspace |

The E accelerator follows the pinned `CalculatorScientificOperators` constructor, which overrides the older X resource entry. Secondary and flyout accelerators work with those panels closed. All Scientific shortcuts are inactive while Settings is visible. Decimal degrees has no direct accelerator in the reference and is available through the keyboard-accessible Function flyout.

Scientific retains the reference five-column/seven-row keypad. At small window sizes its toolbar/keypad area scrolls, and keyboard focus reveals each control while the expression and result remain visible above it. Buttons stay at least 44×44; text, accessibility names, palettes and errors use the existing English/Chinese and theme hooks. The shared Scientific/restart tests now reveal focused keys before clicking, and reset with Escape so they exercise the real C/CE semantics.

The real-QML suite `tests/qml/tst_scientific_extended.qml` covers all listed operations, both function layers, expression/result synchronization, exact Scientific constants/logarithms, compound precedence, exponent limits/editing, seven domain/range errors and all recovery routes, every reference shortcut, Function flyout focus/dismissal, Settings shortcut isolation, live translation and 320×540/900×800 layouts. No calculator mocks or alternate arithmetic implementation are used. Its addition raises the combined suite's timeout to 300 seconds; the independent restart check retains its existing timeout. Screenshots `scientific-{extended,second,function}-{light,dark}-{narrow,wide}.png` are generated in the test working directory.


The isolated generic Qt platform can report an unknown color scheme or ignore native override hints. Explicit Light/Dark preferences therefore also select the app's inherited Fluent palette through `AppPreferences.effectiveTheme`; every mode shares readable semantic foreground/background/button/focus colors. System mode still follows the native scheme on platforms that report it, and uses a stable Light fallback for Unknown. Tests simulate system theme changes through the existing `SystemPreferences` boundary and assert visible colors, contrast and restored preferences rather than assuming a platform hint is supported.


Ticket 05 final validation used the private `.build-ticket05` Debug/Make build on Linux x86_64, Qt 6.12/GCC 16.2, with `-j2` compilation. The frozen full suite passed **all five CTest entries** normally: **255 passed, 0 failed, 0 skipped** in each English/light, English/dark and Chinese/light configuration, three child-process isolation checks, and all seven independent restart stages. Every final GUI process used compose/generic/offscreen/software with private settings/runtime and D-Bus; no final native-desktop run is claimed. QML lint completed without warnings. Light/dark and English/Chinese offscreen screenshots at narrow/wide sizes were reviewed; short Scientific windows scroll the controls while keeping the result visible.

The ticket's tracker records 22 red/green slices and their private logs, including the core notation/error synchronization fix, cached 2nd state across mode navigation, runtime Chinese captions, pre-GUI isolation bootstrap and generic-platform palette fallback. Earlier interrupted or failing runs are retained separately and are not counted as final passes. The inherited Standard Copy shortcut warning remains, with its real clipboard behavior tests passing. Windows/macOS are not built or run here; the independent integration reviewer still owns ticket closure and final application-wide review.
## Scientific trigonometry and angle units — ticket 06

Open **Scientific**, then **Trigonometry**. The flyout retains the pinned Microsoft four-column/two-row arrangement: **2nd** and **hyp** at the left, with **sin/cos/tan** above **sec/csc/cot**. The two toggles select ordinary, inverse, hyperbolic, or inverse hyperbolic functions, for 24 actual core operations. Choosing a function resets both toggles and closes the flyout; dismissing it preserves the toggle selection. Labels and accessible names reflect the selected function. Tab follows the visual row order, Space activates the focused control, Escape dismisses the flyout while preserving the entry, and focus returns to its opener.

Scientific starts in **DEG**. Click the unit button to cycle **DEG → RAD → GRAD → DEG**, or use **F3/F4/F5** to select degrees/radians/gradians directly. Unit changes preserve the current entry; they affect circular and inverse circular functions, while hyperbolic functions use the core's unit-independent definitions. Clear and switching away from/returning to Scientific retain the chosen unit on the existing Scientific engine. An ordinary restart starts in degrees.

| Function family | S / O / T / U / I / J |
| --- | --- |
| Circular | sin / cos / tan / sec / csc / cot |
| Inverse circular | Shift plus the corresponding key |
| Hyperbolic | Ctrl plus the corresponding key |
| Inverse hyperbolic | Ctrl+Shift plus the corresponding key |

Digit and function accelerators remain available while the flyout owns focus; Clear/Escape yields to dismissal. Calculator input pauses while navigation is open and resumes when it closes. The commands are explicitly allowlisted at the Qt session boundary and dispatched to the pinned `CalculatorManager`, including its composite inverse commands. No trigonometric calculation or arithmetic-value conversion occurs in QML. Core domain, division and range errors use the existing localized display and recovery path; angle/function controls and their shortcuts are disabled during errors. Digits start fresh input, and Clear/Escape recover normally. Hidden Scientific shortcuts remain inactive in Settings. All new captions and accessibility names use the shared English/Simplified Chinese catalog and the application palette.

The complete Scientific keypad requests a **320×632** minimum window after adding the two function rows. A scrollable body and automatic focus reveal keep the keys reachable when a compositor allocates a shorter window. `tests/qml/tst_scientific_short_window.qml` exercises the real UI at 320×460, including reaching lower keys, the angle control, flyout dismissal and continued calculation. Existing full-keypad size checks now use 632 px.

The production-QML coverage in `tests/qml/tst_scientific_trigonometry.qml` exercises all 24 flyout commands and keyboard equivalents, known values in all three units, hyperbolic independence from units, toggle/dismissal semantics, angle retention, 12 domain/singularity/range scenarios and recovery, runtime translation, Settings isolation, focus, and all four function-label states in narrow/wide windows. Numerical expectations are independently known trigonometric values or pinned upstream public behavior; approximate transcendental comparisons use a stated tolerance in the test. Production values stay strings. Screenshots use `trigonometry-{light,dark}-{narrow,wide}-{0,1,2,3}.png` in the private test build directory.


Ticket 06's branch validation passed **56/56 focused outcomes per language** (English and Simplified Chinese), using isolated offscreen/software rendering. To run the integrated trigonometry tests after the build above:

```sh
CALCULATOR_TEST_LANGUAGE=en-US CALCULATOR_TEST_THEME=light \
  python3 tests/run-ui-isolated.py .build/calculator_ui_tests \
  -input tests/qml/tst_scientific_trigonometry.qml
```

Repeat with `CALCULATOR_TEST_LANGUAGE=zh-CN` for Simplified Chinese. The ticket 06 branch initially used `/tmp/calc-implementation-notes/run-ui-isolated.sh` for its focused checks. Integration uses the repository launcher `python3 tests/run-ui-isolated.py` for direct checks and all CTest entries. It removes inherited display and input-method configuration and creates private settings/runtime roots and a private D-Bus before GUI startup.

Ticket 05's shared appearance fallback is retained in integration: explicit preferences set the inherited application palette, while System follows native hints when supported and falls back to Light for Unknown. The ticket 06 branch's earlier isolated appearance failures are historical; full integrated validation is recorded below. Future validation stays isolated from the user's display, IME and session bus.


Ticket 06 is merged and resolved with tickets 01–05 and 07 preserved. The shared two-row header combines angle units/F-E and Trigonometry/Function, retaining the complete Scientific keypad and the visible result above its scroll area. Both flyouts use the inherited theme palette and remain inside narrow windows. Integration regressions cover extended shortcuts while Trigonometry owns focus, Escape dismissal, navigation input blocking, every toggle state's rendered text contrast, and access to all six Function commands.

The final `.build-integration` Debug build and QML lint pass on Linux/Qt 6.12. All **five CTest entries pass**: **298 passed, 0 failed, 0 skipped** in each English/light, English/dark and Chinese/light UI configuration, all seven restart stages, and three child-process isolation checks. The main UI configurations use a 600-second limit; the final `ctest --test-dir .build-integration --output-on-failure -j2` completed normally in 618.67 seconds overall, with each main configuration finishing in 289–331 seconds. All GUI checks and reviewed narrow/wide light/dark captures used the repository's isolated offscreen/software launcher. The earlier ticket-06 appearance failure is resolved by ticket 05's retained palette fallback. Windows/macOS and native desktop behavior remain unverified; final application-wide independent review is still pending.

## Programmer bitwise operations and bit editing — ticket 08

The **Bitwise** flyout provides **AND, OR, NOT, NAND, NOR, XOR** in the reference two-row arrangement. Reference shortcuts are `&`, `|`, `~`, `.`, `\`, and `^`, respectively; `.` is NAND in Programmer mode, where decimal input is unavailable. **Bit shift** selects arithmetic, logical, circular rotation, or rotation through carry. The first keypad row is **A / left shift / right shift / C or CE / backspace**, matching the pinned reference. `<` and `>` invoke the selected left/right operation. Arithmetic/logical shifts take a shift-count operand; rotations operate once per press. Circular rotation wraps the outgoing bit, while rotation through carry retains it for the next rotation. All operations dispatch to the real Microsoft engine, including its word-width truncation, signed arithmetic right shift, and undefined-result error for a count at least the selected width.

**Bits** replaces the keypad with the reference 64-bit display, arranged as four rows of sixteen bits with nibble labels. Click a bit, or Tab to it and press Space, to toggle it in the core. Bits beyond the selected word width remain visible and disabled; no bit editing is available during errors. **Keypad** returns to ordinary entry. Reference digit, arithmetic, bitwise, shift and clear shortcuts also work while Bits is visible and update the same integer; Settings keeps these shortcuts inactive. Width and radix changes remain available in the bit view, and all four radix rows stay synchronized without converting integer values to JavaScript numbers. Narrow windows scroll vertically and bring keyboard focus into view. The shared C/CE slot reads the core's actual entry state: C clears everything, CE clears only the entry, Escape always clears, and Delete always clears the entry.

The separate real-QML suite `tests/programmer/tst_programmer_bits.qml` is registered with CTest for English/light, English/dark, and Simplified-Chinese/light. It complements the existing Programmer suite and keeps each suite within its own timeout. It covers all logical operations by mouse and keyboard, all four shift variants in both directions, carry propagation, all 64 editable bits, every word width, exact signed high-bit values, invalid counts/error recovery, width truncation/sign extension, pending-operand editing, translated descriptions, hidden shortcuts, and narrow/default/wide layouts. Captures use `programmer-{bits,shift-menu,bitwise-menu}-{light,dark}-{narrow,default,wide}.png` in the test working directory. Build and check commands remain those above; no network, push, deployment or extra dependency is required.

Ticket 08's final private Debug build passes all **7 CTest entries**: **187 main-suite outcomes plus 32 bit-suite outcomes per theme/language**, with no failures/skips, and all seven independent restart stages. QML lint is warning-free. UI test entries have a measured 300-second limit after the prior 180-second combined-suite timeout; final main runs took 185–207 seconds. Native Wayland high-bit/shift checks pass 7/7 and bit-view keyboard checks pass 3/3. A broader native run lost desktop activation after resizing and failed; it is not represented as passing. The standalone native executable launched with isolated settings and exited 0 after a normal compositor close. Windows/macOS remain unverified; independent integration review is still required. The [ticket 08 evidence](.scratch/calculator/issues/08-programmer-bit-operations.md) records nine real red/green cycles, reference sources, logs and limitations.

Ticket 08 is now merged and resolved with tickets 01–07 preserved. Integration fixes keep selected Keypad/Bits text and both flyouts readable with the shared palette fallback, and keep the full menus inside narrow windows. Real-QML regressions reproduced selector contrast, light-menu contrast and popup clipping before the fixes; added checks also cover navigation shortcut isolation and all four shift-selection states. Screenshot names use the visible application theme.

The final `.build-integration` Debug build and warning-free QML lint pass on Linux/Qt 6.12. All **eight CTest entries pass** in **615.16 seconds**: **298 main-suite outcomes and 35 Programmer-bit outcomes per language/theme**, zero failures/skips, all seven restart stages and three isolation checks. All GUI checks and reviewed English/Chinese light/dark captures used the repository's private offscreen/software launcher; no native desktop run was performed for this merge. The integration's existing 600-second UI timeout remains. Earlier interrupted/failing checks are retained separately; `merge08-ctest-accepted.log` and `Testing/Temporary/LastTest.log` contain final results. Windows/macOS and native desktop behavior remain unverified, and final application-wide review is pending.

## Shared calculator memory — ticket 10

Standard and Scientific offer **MC / MR / M+ / M− / MS**, plus **M▾** in narrow windows. The reference shortcuts are **Ctrl+L / Ctrl+R / Ctrl+P / Ctrl+Q / Ctrl+M** respectively. M+ on empty memory stores the current value; M− stores its negative. MR loads the newest value as the current operand, so a pending calculation can continue. Programmer follows the pinned **MS / M▾** toolbar; recall and indexed modifications are available through the memory list.

At **560 px** and wider, select **Memory** beside History in the shared sidebar; Programmer shows Memory without History. Narrow windows open a bottom sheet from M▾. Click a value (or focus it and press Space) to recall it. Each item has MC, M+, and M− controls plus a right-click / Menu-key / Shift+F10 context menu. Context deletion focuses the nearest remaining item; deleting the last item closes the narrow sheet and returns focus to M+ (MS in Programmer). The panel also clears all memory. Empty memory disables MR/MC and M▾; the wide panel displays its empty state. Memory arithmetic is disabled during errors, while the panel's clear-all action remains available, matching the reference.

All three modes use the same manager-owned rational values, with **100 entries**, newest first and oldest evicted on the 101st save. Formatting follows the active core mode, notation, radix, and word width: a stored `255.5` appears as `255` in Programmer decimal, `FF` in hex, and `−1` in BYTE decimal, while returning to Standard preserves `255.5`. No displayed value is reparsed through JavaScript numbers. Mode navigation retains memory; ordinary restart clears it while retaining preferences/recent mode.

Memory controls inherit the existing Fluent palette and live English/Simplified Chinese translations. The Scientific full-keypad size hint is now **320×676** to accommodate its memory row. Standard and Scientific, like Programmer, scroll focused controls into view when a window is allocated less space. The existing Standard 320×460 check still exercises every key via focus/scrolling, and the Scientific 320×460 regression remains intact.

`tests/memory/tst_memory.qml` exercises the production QML and native core: toolbar/reference shortcuts, selected-item operations in all modes, context menus, continued calculations, exact integer/rational recall, Programmer interpretation, scientific notation, empty/error states, the 100/101 boundary, translation, and narrow/wide/short layouts. CTest runs it in English/light, English/dark, and Chinese/light. `calculator-memory-restart` closes and reopens six isolated processes (write/restore for each arithmetic mode), checking shared session data before close and empty memory plus retained settings afterward. No memory persistence, mock core, native-desktop testing, remote push, or deployment is introduced.

Ticket 10's private Linux/Qt 6.12 Debug build passed all **16 CTest entries** (1,151.49 seconds), including **298 main UI / 35 bit-operation / 20 history / 19 memory outcomes** in each theme/language configuration, with no failures/skips. After a final QML focus-helper type cleanup, warning-free lint and focused focus/layout checks passed, and all **four memory CTest entries** passed again (167.68 seconds): **21 memory outcomes per theme/language**, with context-focus return covered in all three modes, plus six restart stages. The final sidebar cap, Standard 320×460/900×700 reachability and Scientific 320×460 checks also pass. The tracker records red/green and log evidence.

Ticket 10 is now merged and resolved on `integration/calculator` at merge commit `b9ceb3f`. Independent integration review found no ticket blockers or code regressions. The integration Debug build and warning-free QML lint passed, followed by **16/16 CTest entries in 1,094.46 seconds**, with **298 application / 35 Programmer-bit / 20 history / 21 memory outcomes** in each theme/language configuration, zero failures/skips, and all restart/isolation checks passing. English/Chinese wide/narrow memory captures were reviewed in both themes. All GUI checks used the shared private offscreen/software launcher. Logs are `.build-integration/merge10-build.log`, `.build-integration/merge10-ctest.log` and `Testing/Temporary/LastTest.log`. Windows/macOS and native desktop behavior remain unverified; final application-wide review is pending.

## Length conversion — ticket 13

Open **Length** in navigation, choose either unit, and enter digits with the on-screen keypad or keyboard. Click either value (or Tab to it and press Space) to make it the input; the bold value receives the next entry, and unit positions stay fixed. CE, Escape or Delete clears the entry; Backspace edits it. Right-click a value for Copy/Paste, or use the platform copy/paste shortcut. Negative lengths are unavailable; malformed, negative or unrepresentable pasted input has an explicit message, and fresh input recovers.

All 12 reference selectable units are available: Angstroms, nanometers, microns, millimeters, centimeters, meters, kilometers, inches, feet, yards, miles and nautical miles. The real pinned Microsoft `UnitConverter` performs conversion and formatting using doubles, with its 15-digit entry limit, seven preferred display digits, adaptive precision and scientific notation. It is distinct from the arbitrary-precision arithmetic core. The [converter provenance notes](third_party/microsoft-calculator/README.md) document the metadata, portable subset and exponent-preservation repair.

The page inherits the shared palette and English/Chinese translations, retains the pinned three-column/five-row keypad, and places it beside the values in landscape windows. The stable `length` mode key participates in recent-mode persistence; ordinary restart starts fresh numeric input. The `calculator-length-{light,dark,zh-CN}` CTest entries exercise actual navigation, controls, selected-side conversion, known ratios for every unit, same-unit/round-trip cases, input limits, decimal/scientific display, clipboard errors/recovery, focus, responsive layout and settings isolation. `calculator-length-restart` verifies recent-mode/theme/language restoration across separate isolated processes. Numeric output comparisons allow up to **0.5 ppm** (seven significant digits), with tighter literal checks for independently known exact displayed values. No arithmetic mocks are used.


Ticket 13 validation used the private `.build-ticket13` Debug/Make build on Linux/Qt 6.12/GCC 16.2. The final four Length CTest entries pass: **44/44 outcomes** per English/light, English/dark and Chinese/light configuration, plus successful separate-process write/restore stages. All 12 pre-existing CTest checks passed in the broader regression run. Two development-time Length failures in that broader run were fixed and covered by the final four-entry rerun; no single all-green full-run claim is made. Production build, warning-free QML lint, whitespace validation and final offscreen capture review pass. Ten real red/green slices and the exponent repair are recorded in the [ticket 13 evidence](.scratch/calculator/issues/13-length-conversion.md). Native desktop behavior and Windows/macOS remain unverified; independent integration validation follows.


Ticket 13 is merged at `19471a9` and resolved on `integration/calculator`. Independent review preserved the existing memory/date features and corrected reversed default source/target flags to match the pinned region policy, with real-QML US/Chinese startup coverage. The combined production build and warning-free lint pass. The full isolated integration matrix passed **22/23 entries** (1,252.60 seconds), including all **19 pre-existing entries** and **45 Length outcomes per theme/language**; the sole failure was a restart test literal for pinned display precision. Correcting that literal and rerunning the failed entry passed **1/1** (2.22 seconds), with both write/restore stages passing. All entries have passing final results across these runs; no single all-green full run is claimed. The [ticket evidence](.scratch/calculator/issues/13-length-conversion.md) records commits, red/green evidence and frozen logs. No active-desktop GUI was used; Windows/macOS and native rendering remain unverified.

## Function plotting — ticket 20

Open **Graphing** in navigation, enter the right side of `y=f(x)` and click **Plot** or press **Enter**. The initial coordinate window is `-10 ≤ x ≤ 10`, `-10 ≤ y ≤ 10`, with labeled axes and grid lines. The equation editor sits beside the graph from an 800 px application width. Below that width, the reference Graph/Equations view switch selects the panel while preserving the entered expression and plot; validation remains visible in either view. **Syntax** opens keyboard-accessible help. The page shares the application's themes, English/Simplified Chinese translation and recent-mode registry.

The supported, case-sensitive grammar is deliberately mathematical: variable `x`, constants `pi` and `e`, decimal/scientific numeric literals (`.5`, `1e-3`), `+ - * / ^`, unary signs and parentheses. Multiplication must be explicit (`2*x`). Exponentiation associates right (`x^2^3 = x^(2^3)`), and binds more tightly than a leading sign (`-x^2 = -(x^2)`); signed exponents such as `x^-2` are supported. Available single-argument functions are `sin`, `cos`, `tan`, `sqrt`, `abs`, `ln`, `log` (base 10), and `exp`. Trigonometric arguments are radians, independently of Scientific mode's angle setting. Numeric literals always use a decimal point. Assignments, implicit multiplication, other variables/functions, relations, property access and scripts are rejected. The editor already supplies `y =`; enter only the right-hand expression.

`FunctionExpression` is project-authored C++ using the existing Qt and C++ standard-library dependencies; no additional parser, scripting engine, external service, or new third-party license is introduced. It compiles the allowlisted grammar into a bounded instruction sequence and evaluates graph values as finite `double`s, independently of the Microsoft arithmetic session. This plotting approximation does not change arithmetic-mode precision. Expressions are limited to 512 characters, 256 instructions and 64 recursive parser frames (a nested grammatical construct can consume multiple frames).

`FunctionGraph` samples the expression and paints actual computed coordinates. Adaptive midpoint and non-dyadic checks avoid ordinary reciprocal/tangent pole connections and regular-grid sine aliasing. Undefined/overflowing subexpressions remain undefined; tangent's rounded `pi/2` poles are rejected when `abs(cos(argument)) < 1e-14`. The sampler caps work at 65,536 evaluations and 12 subdivision levels per initial interval, clips mathematical segments before rasterization, and omits undefined or unresolved intervals. Status text distinguishes empty input, invalid syntax, no defined samples, an offscreen curve, and a plot with omitted intervals. Like other finite numerical samplers, it cannot guarantee detection of every arbitrarily narrow feature or singularity. Multi-curve management, pan/zoom and coordinate inspection belong to ticket 21.

The `tests/graphing/tst_graphing.qml` suite uses the real application and keyboard/mouse input. It checks rendered curve pixels at independently known coordinates (within three display pixels), and checks that false curves are absent across reciprocal/tangent asymptotes and undefined square-root/log regions. It also covers operator precedence, all documented elementary functions/constants, domain/overflow errors and recovery, script/unsupported-syntax rejection, expression/nesting limits, bounded high-frequency sampling, long expressions, live Chinese translation, both themes, syntax-popup focus/Escape, and 320×460 / 900×700 layouts. These are coordinate and discontinuity assertions, not merely screenshot-existence checks. The shared isolated launcher is used by the three `calculator-graphing-*` CTest entries; captures are named `graphing-<initial-theme>-<locale>-<visible-theme>-<width>.png` in the private test working directory.

A focused isolated run after building is:

```sh
ctest --test-dir .build -R calculator-graphing --output-on-failure -j2
```

Ticket 20 verification is Linux/Qt 6.12 with Make and software/offscreen rendering. Windows/macOS and native-desktop rendering are unverified. All GUI validation uses private settings/data/runtime and a private D-Bus, without accessing the user's desktop or IME.

Ticket 20's private Debug/Make build passed all **15 CTest entries** (1017.33 s), preserving the existing 298 main-UI, 35 Programmer-bit and 20 history outcomes per theme/language plus restart/isolation checks. The final narrow-view correction was followed by a separate successful rerun of all three affected graphing configurations (75.59 s), and a fresh final graphing run reports **45 passed, 0 failed, 0 skipped** after the no-op integration merge. Final QML lint is warning-free. Nine actual red→green slices and the precise before/after validation scope are recorded in the [ticket 20 evidence](.scratch/calculator/issues/20-function-plotting.md). Independent integration review owns closure.


## Volume, area, weight and mass (ticket 14)

Open **Volume**, **Area**, or **Weight and Mass** in navigation. These modes reuse the Length page's unit selectors, selected input side, keypad, keyboard shortcuts, clipboard actions and responsive Fluent layout. They provide all reference units: 20 for volume, 10 for area (plus Pyeong in its four reference regions), and 14 for weight and mass. US/UK volume measures and short/long tons have separate definitions. Negative input is unavailable in these categories; pasted negative input shows a translated category-specific message and a new digit recovers.

The production Microsoft converter performs the calculations and formatting. For example, 1 cubic meter is 1,000 liters; 1 square meter is 10,000 square centimeters; and 1 kilogram is 1,000 grams. Both values can be selected for input to reverse the conversion. Switching categories preserves the current input and active side, selects the appropriate unit catalog, and restores each category's selected units. Theme and language changes in Settings preserve the current conversion. See the [metadata provenance and display tolerances](third_party/microsoft-calculator/README.md) for details.

`calculator-volume-area-mass-{light,dark,zh-CN}` exercises actual QML navigation, all selectable unit names/order/ratios, identity and reverse conversions, category isolation, positive-only input, 15-digit limits, clear/backspace/decimal behavior, scientific display extremes, runtime English/Chinese and light/dark settings, focus order, and 320×480/900×600 layouts. `calculator-volume-area-mass-ja-JP` checks the regional Pyeong catalog and SI defaults through the same UI. All GUI checks use the existing isolated offscreen launcher; native desktop rendering and Windows/macOS remain unverified.
## Energy, speed, time and pressure conversion — ticket 15

Open **Energy**, **Speed**, **Time** or **Pressure** in navigation. These modes share Length's actual Microsoft converter, two selectable input/result values, unit selectors, keypad, keyboard, Copy/Paste and clear/backspace behavior. The pinned Microsoft content layout remains unchanged, including balanced value/keypad columns in landscape. Navigation scrolls at small window heights and keeps keyboard-focused modes visible. Each mode registers a stable recent-mode key and inherits the shared themes and English/Simplified Chinese translations.

All **29 selectable reference units** are available: eight energy units (including distinct thermal/food calories and kilowatt-hours), seven speed units, eight time units and six pressure units. The [metadata provenance notes](third_party/microsoft-calculator/README.md) document exact reference factors, regional defaults, the 365.25-day year and rounded mph/knot/Mach definitions. These categories accept nonnegative decimal input up to 15 digits; category-specific errors explain rejected negative paste. A category switch retains the current input and active side, initializes valid units for the new category, and restores its prior unit choices when revisited, following the pinned shared converter session.

`calculator-energy-speed-time-pressure-{light,dark,zh-CN}` runs the real application controls with the real converter. Coverage includes every ordered/localized unit list and unit's numeric example, same-unit and round-trip conversions, repeated category switching, both keypad/keyboard paths, input/paste boundaries and recovery, fixed/scientific rounding, runtime preferences, minimum/wide layouts and keyboard focus. Comparisons use explicit display tolerances: generally 0.5 ppm, with half a millionth absolute tolerance for fixed sub-unit output where the pinned formatter counts the leading zero. Captures are `ticket15-<category>-<width>-<theme>-<language>.png` in the private test build directory. All GUI validation uses the isolated offscreen/software launcher; Windows/macOS and native desktop rendering are unverified.

```sh
ctest --test-dir .build -R calculator-energy-speed-time-pressure --output-on-failure -j2
```

Ticket 15's final private `.build-ticket15` Debug/Make build passes warning-free QML lint and **all 29 CTest entries** in **1509.70 seconds** on Linux/Qt 6.12/GCC 16.2, preserving every inherited suite. Each ticket15 theme/language entry passes **87 outcomes, 0 failed, 0 skipped**. Final navigation checks also pass in all three configurations after confirming the latest integration tip. Nine red→green slices, the shared-session reference correction and exact metadata provenance are recorded in the [ticket 15 evidence](.scratch/calculator/issues/15-energy-speed-time-pressure-conversion.md). Independent integration merge validation passed all 33 CTest entries in 1993.32 seconds; ticket 15 is resolved. The ticket evidence records the merge commit, preserved converter categories and integration checks.

## Temperature, Power and Angle conversion — ticket 16

Open **Temperature**, **Power** or **Angle** in navigation. The shared converter supports all pinned selectable units: Celsius/Fahrenheit/Kelvin; watts/kilowatts/US horsepower/foot-pounds per minute/BTUs per minute; and degrees/radians/gradians. Temperature uses the reference offsets as well as scale factors (`0 °C = 32 °F`, `−40 °C = −40 °F`), rather than treating temperatures as pure ratios. Each category allows negative input, including the reference's unrestricted Kelvin sign behavior. Use the bottom-left **±** key, **-**, or **F9** to toggle the selected entry's sign. Either value can be the input, with immediate recalculation after edits and unit changes. Copy/Paste, clear and backspace use the existing converter behavior, and negative Length input remains unavailable.

These categories use the real Microsoft double-based converter and its display policy, separately from Ratpack arithmetic. Its input budget counts a minus sign while appending digits, allowing 14 digits after a sign or 15 digits followed by negation. A complete signed decimal can be pasted with at most 15 normalized digits; invalid, non-finite, malformed and over-limit input displays an error and leaves the previous entry until correction. English/Chinese translations and light/dark/system themes use the shared application hooks. Recent mode and appearance preferences survive ordinary restart; the numeric entry starts fresh.

The isolated `calculator-temperature-power-angle-{light,dark,zh-CN}` checks exercise navigation, every selectable unit, temperature zero/offset pairs, mouse/keyboard sign entry, signed limits and paste validation/recovery, same-unit/reverse conversion, both active sides, runtime translations, focus, contrast and 320×560 / 900×600 layouts. Numeric expectations use independently known values and allow the larger of **5e-8 absolute** or **0.5 ppm relative** for the pinned fixed/scientific formatting policy; exact temperature landmarks and identities also have literal display checks. `calculator-temperature-power-angle-restart` verifies each mode across two real processes with private settings. Captures named `<mode>-<language>-<width>.png` are generated in the build directory. All GUI validation uses the private offscreen/software launcher; native desktop behavior and Windows/macOS remain unverified.

Ticket 16's private Linux/Qt 6.12/GCC 16.2 build and warning-free QML lint pass. The complete 29-entry matrix passed in 1727.47 seconds, including 40 ticket-16 outcomes per theme/language and all pre-existing regressions. The final no-op integration merge was followed by another successful build/lint and the separately added restart check: all six mode write/restore processes pass, so all 30 registered entries have passing final results across those runs. The restart helper explicitly establishes window focus before keyboard unit selection; no production changes followed the full matrix. The [ticket 16 evidence](.scratch/calculator/issues/16-temperature-power-angle-conversion.md) records the six red/green slices, logs and independent merge-review gate.


## Online currency conversion — ticket 18

Open **Currency** to load the current Frankfurter v2 currency catalog and selected pair's blended daily reference rate over HTTPS. Choose either currency and enter an amount using the existing converter keypad, keyboard or clipboard; select the other value to enter the reverse amount. **Refresh rates** retries while input and navigation stay responsive. Source, pair observation date, refresh state and UTC attempt time are visible below the values. Missing or invalid quotes show an unavailable result; earlier responses cannot replace a later selection. Session input and unit choices remain shared with the other converter categories.

The [currency service/terms notes](docs/currency-rates.md) explain request paths, response validation, display precision, source-name translation, attribution and the distinction between MIT software licensing and provider data rights. Currency follows the pinned converter's nonnegative 15-digit input and formatting rules, with source-provided symbols and the shared themes/languages/recent-mode hooks. Persistent offline caching belongs to ticket 19.

Run the deterministic real-QML checks with `ctest --test-dir .build -R calculator-currency --output-on-failure -j2`. They replace only external network/time inputs, retain the real application and Microsoft converter, and use private offscreen/software settings and D-Bus. The restart entry uses two separate isolated processes. Live-service connectivity is checked separately from routine tests; Windows/macOS and native-desktop rendering remain unverified.


Ticket 18 validation used Linux/Qt 6.12/GCC 16.2 with a private Make build and `-j2`. The full 41-entry matrix passed 39 entries in 2606.81 seconds; two inherited 180-second light-converter timeouts then passed when replayed serially (2/2, 244.01 seconds), so every entry has a passing result across those runs. After final currency-specific formatting restoration, build/lint and the 10-case noncurrency formatting regression passed, followed by all four affected Currency CTest entries in 160.76 seconds: **43/43 per theme/language**, no failures/skips, plus both restart stages. The [ticket evidence](.scratch/calculator/issues/18-online-currency-conversion.md) distinguishes the full run, timeout replays, nine actual red/green cycles, final affected checks and separate successful production HTTPS smoke. Independent merge review owns ticket closure.

## Multiple curves and graph navigation — ticket 21

In **Graphing**, use **Add function** to create an equation, select an existing row to edit it, and press **Enter** or **Plot** to apply the expression to that function. **Delete** removes the selected function; deleting the last one leaves an empty editor. Each function keeps a stable `F1`, `F2`, … identifier and a theme-derived color in the equation list and on the actual computed curve. Invalid expressions have their own feedback and do not remove other curves. The existing 800 px graph/equation split and narrow **Graph / Equations** switch are retained.

Use the arrow buttons or drag the graph to pan. **+ / −**, the mouse wheel, and the zoom buttons change the range; **Home** or **Reset** restores `[-10,10]` on both axes. With the graph focused, arrow keys pan and **Space** inspects its center. Click anywhere in the graph to read the pointer's mathematical `x` and `y`, together with the selected function's separately evaluated `Fₙ(x)`. A marker is drawn only for a finite function value inside the visible range; undefined values are explicitly labeled, including at poles. Selecting or editing another function and changing the viewport refresh the inspection. **Syntax** contains translated equation and navigation help, with scrolling at small sizes and Escape returning focus to the editor.

Both axes display their actual range and updated decimal ticks. Zoom spans are bounded to `10⁻⁶ … 10⁶` and pan centers to `±10⁹`. Display precision adapts to the current span so nearby limits remain distinguishable away from the origin. Every expression and range change resamples each function with the existing bounded adaptive sampler; previous samples are replaced synchronously, and undefined/unresolved intervals remain omitted. This is finite numerical graphing with doubles, distinct from the arbitrary-precision arithmetic modes; arbitrarily narrow features and singularities remain subject to the documented finite-sampling limitation.

The expanded `tests/graphing/tst_graphing.qml` exercises real navigation, equation editing, stable identifiers, independent deletion/error recovery, rendered positions of multiple curves, zoom/pan/drag/wheel/keyboard actions, zoom boundaries, coordinate values and undefined points, and resampled reciprocal/domain gaps after edits and repeated viewport changes. It also checks rendered selected-row text and labeled-curve contrast of at least 4.5:1, both themes, Chinese translation/help/focus and 320×460 / 900×700 layouts. Existing single-function mathematical regressions remain in the same three isolated `calculator-graphing-*` CTest entries. Captures named `graphing-multiple-<theme>-<width>.png` are produced in the private test working directory. All GUI checks use the shared offscreen/software launcher with private settings/data/runtime and D-Bus; native desktop rendering and Windows/macOS remain unverified.

## Offline currency observations — ticket 19

Currency saves validated Frankfurter metadata and observations for each currency pair. Opening the mode or returning to a cached pair immediately enables conversion with its original data date, then refreshes asynchronously. **Using cached rates** distinguishes fallback data from a successful update; refresh failures retain the quote and show their own attempt time. A missing, corrupt or unmatched cache shows an unavailable result. Atomic file replacement protects earlier observations from failed writes; a storage warning explains when a new quote could not be saved.

The cache contains currency data only. Ordinary restarts retain appearance/recent-mode preferences and cached rates, while numeric input, arithmetic histories and shared memory start fresh. See [currency storage and service notes](docs/currency-rates.md) for the file location/schema, date/refresh semantics and source terms. The currency CTest entries cover cache corruption, missing pairs, offline conversion, asynchronous responses, storage failures, English/Chinese, both themes, and four independent restart/recovery processes through `tests/run-ui-isolated.py`.

Ticket 19's private Linux/Qt 6.12/GCC 16.2 Debug build and QML lint pass without warnings. The full 45-entry isolated matrix passed 44 entries in 2492.38 seconds; correcting a new Chinese test literal to match the existing translation and replaying its sole failed entry passed 1/1 in 106.07 seconds. All 45 entries have passing final results across those runs, including 60 Currency outcomes and 298 main application outcomes per theme/language, plus four currency restart stages. The [ticket evidence](.scratch/calculator/issues/19-offline-currency-cache.md) records three actual TDD cycles, logs, scope and the pending independent merge-review gate. Windows/macOS and native desktop behavior remain unverified.
