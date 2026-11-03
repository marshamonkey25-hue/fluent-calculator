# Compact programmer layout

The equal-cell correction in v0.1.1 did not address the programmer page's
vertical budget. At the reported 402×632 logical-pixel window, the E row
extended to 656 and the final key row was outside the viewport. Four default
40-pixel radix controls plus separate memory and view-selector rows consumed
space intended for the main keypad.

The pinned [Calculator.xaml](https://github.com/microsoft/calculator/blob/79e1ac53bba690cdf930e5dcd6ed9dbc4cbfb128/src/Calculator/Views/Calculator.xaml)
uses proportional regions: expression 22, result 72, programmer radix display
96, toolbar 32 and programmer keypad/operator area 268. The programmer page now
uses these proportions, with sensible minima/caps; the operator row plus main
keypad retain the combined keypad budget. The radix group starts at 96 pixels
and may grow to 244 as in the reference. Long radix values retain wrapping.

The view switches, word-width selector, MS and narrow-window memory list share
one toolbar. View selectors use font-independent dot icons and a selected
underline. Accessible names, tooltips, button identities, word/radix shortcuts,
bit editing and memory backend commands are retained. The generic MemoryBar in
Standard/Scientific is unchanged.

A Flickable gives the weighted content the available height, extending only
when its actual minimum requires it. This avoids using preferred implicit
content height as a mandatory minimum. Normal compact programmer keys may
shrink to 28 logical pixels high; their widths remain at least 44, and all grid
cells stay equal. This follows the compact desktop use case instead of forcing
a touch-oriented 44-pixel height at every window size. Exceptional long/error
or bit-panel content can still scroll, including focus-based reveal.

## Actual checks

The real-window regression first failed at the reported viewport. It now
checks all 30 keys without scrolling at 320×460, 402×632, 422×600 and 542×743.
It checks a shared toolbar row, usable control targets and horizontal bounds,
in addition to the existing cell equality checks. Resizes are allowed to settle
before assertions; no fixed application delay is introduced.

Local tests include the four English/Chinese × Light/Dark integrated suites,
full programmer and bit-operation suites in both languages, and memory suites.
Two old memory assertions were adjusted to the intended UI contract: MR is
absent or hidden in programmer mode, and compact toolbar targets use the desktop
minimum. The affected shared-memory/focus cases then passed in both languages;
no backend arithmetic was modified. Build and QML lint pass without warnings.

All GUI execution remains offscreen/software with Compose input and private
settings/runtime/D-Bus. Fresh complete-window captures at display scale 2 are:

- [Chinese/dark, 804×1264](screenshots/programmer-compact-v0.1.2-zh_CN-dark.png)
- [English/light, 804×1264](screenshots/programmer-compact-v0.1.2-en_US-light.png)

## Native release verification

[v0.1.2](https://github.com/marshamonkey25-hue/fluent-calculator/releases/tag/v0.1.2)
was published automatically from commit
`2435b05a7efdae08637c4f2e252ffe1ffe266694` by
[workflow 41594582067](https://github.com/marshamonkey25-hue/fluent-calculator/actions/runs/41594582067).
All Arch, Debian, Fedora, Windows, macOS and final publication jobs passed.
Every platform's integrated matrix includes the four compact-window visibility
cases, the previous equal-cell checks and the existing 18-mode operation tests.
Installed/image startup checks pass; all eight published binary/source/recipe
entries match GitHub's asset digests, and the downloaded Arch file matches its
published checksum. The Release is public, non-draft and latest.

The user's original screenshot is not included in the repository. Original
failure logs and focused corrected-memory evidence are retained under
`.build-programmer-compact/` rather than counted as a single frozen all-green run.
