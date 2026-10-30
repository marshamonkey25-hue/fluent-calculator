# Fluent Calculator

A Qt Quick desktop calculator using the real Microsoft Calculator arithmetic core. This checkout implements tickets **01–04 and 07–08**: the Standard arithmetic keypad, expression/result/error display, entry correction, reference error recovery, copying results, keyboard input, persistent theme/language settings, Scientific precedence/parentheses, and Programmer integer radix/word-width operations, bitwise operations and editable bit displays with mode navigation. Extended Scientific functions, history, memory, and other modes are separate implementation tickets.

The content follows the pinned Microsoft Standard keypad layout with Fluent controls and native system window decorations. Navigation is registered centrally in `qml/ModeRegistry.qml`. `MainWindow` owns one `CalculationSession`, which dispatches string command names to `CalculatorManager`, `CCalcEngine` and Ratpack. Arithmetic displays and expressions remain strings across C++/QML, including integers above JavaScript's safe integer range.

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

Screenshots `standard-{light,dark}-{narrow,wide}.png` and `settings-{light,dark}-{narrow,wide}.png` are saved in the test working/build directory. To run the same QML suite in an actual Wayland session, preserving the current desktop's runtime environment:

```sh
cd .build
QT_QPA_PLATFORM=wayland QT_QUICK_BACKEND=software \
CALCULATOR_TEST_THEME=light ./calculator_ui_tests
```

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


## Programmer bitwise operations and bit editing — ticket 08

The **Bitwise** flyout provides **AND, OR, NOT, NAND, NOR, XOR** in the reference two-row arrangement. Reference shortcuts are `&`, `|`, `~`, `.`, `\`, and `^`, respectively; `.` is NAND in Programmer mode, where decimal input is unavailable. **Bit shift** selects arithmetic, logical, circular rotation, or rotation through carry. The first keypad row is **A / left shift / right shift / C or CE / backspace**, matching the pinned reference. `<` and `>` invoke the selected left/right operation. Arithmetic/logical shifts take a shift-count operand; rotations operate once per press. Circular rotation wraps the outgoing bit, while rotation through carry retains it for the next rotation. All operations dispatch to the real Microsoft engine, including its word-width truncation, signed arithmetic right shift, and undefined-result error for a count at least the selected width.

**Bits** replaces the keypad with the reference 64-bit display, arranged as four rows of sixteen bits with nibble labels. Click a bit, or Tab to it and press Space, to toggle it in the core. Bits beyond the selected word width remain visible and disabled; no bit editing is available during errors. **Keypad** returns to ordinary entry. Reference digit, arithmetic, bitwise, shift and clear shortcuts also work while Bits is visible and update the same integer; Settings keeps these shortcuts inactive. Width and radix changes remain available in the bit view, and all four radix rows stay synchronized without converting integer values to JavaScript numbers. Narrow windows scroll vertically and bring keyboard focus into view. The shared C/CE slot reads the core's actual entry state: C clears everything, CE clears only the entry, Escape always clears, and Delete always clears the entry.

The separate real-QML suite `tests/programmer/tst_programmer_bits.qml` is registered with CTest for English/light, English/dark, and Simplified-Chinese/light. It complements the existing Programmer suite and keeps each suite within its own timeout. It covers all logical operations by mouse and keyboard, all four shift variants in both directions, carry propagation, all 64 editable bits, every word width, exact signed high-bit values, invalid counts/error recovery, width truncation/sign extension, pending-operand editing, translated descriptions, hidden shortcuts, and narrow/default/wide layouts. Captures use `programmer-{bits,shift-menu,bitwise-menu}-{light,dark}-{narrow,default,wide}.png` in the test working directory. Build and check commands remain those above; no network, push, deployment or extra dependency is required.

Ticket 08's final private Debug build passes all **7 CTest entries**: **187 main-suite outcomes plus 32 bit-suite outcomes per theme/language**, with no failures/skips, and all seven independent restart stages. QML lint is warning-free. UI test entries have a measured 300-second limit after the prior 180-second combined-suite timeout; final main runs took 185–207 seconds. Native Wayland high-bit/shift checks pass 7/7 and bit-view keyboard checks pass 3/3. A broader native run lost desktop activation after resizing and failed; it is not represented as passing. The standalone native executable launched with isolated settings and exited 0 after a normal compositor close. Windows/macOS remain unverified; independent integration review is still required. The [ticket 08 evidence](.scratch/calculator/issues/08-programmer-bit-operations.md) records nine real red/green cycles, reference sources, logs and limitations.
