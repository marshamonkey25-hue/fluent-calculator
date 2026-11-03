# Equal keypad cell sizing

The programmer keypad used content-dependent preferred widths. At a 542 × 743
logical-pixel viewport, the visible A button measured 89 pixels wide while the
left-shift button measured 114. Standard and converter grids also had unequal
columns; Scientific already used uniform cells. Earlier layout tests checked
reachability/minimum bounds but did not assert equal cell dimensions.

Microsoft's pinned programmer layout specifies five equal star-sized columns
and six equal star-sized key rows in
[CalculatorProgrammerRadixOperators.xaml](https://github.com/microsoft/calculator/blob/79e1ac53bba690cdf930e5dcd6ed9dbc4cbfb128/src/Calculator/Views/CalculatorProgrammerRadixOperators.xaml).
The source [NumberPad.xaml](https://github.com/microsoft/calculator/blob/79e1ac53bba690cdf930e5dcd6ed9dbc4cbfb128/src/Calculator/Views/NumberPad.xaml)
also divides its rows/columns evenly. The Qt 6.8 GridLayout API provides
`uniformCellWidths` and `uniformCellHeights` for this policy.

Programmer, Standard and converter main keypads now use uniform cells. All
keys retain their commands, order, disabled states, keyboard bindings and
minimum usable bounds. Overall dimensions continue to respond to the available
window area and display scaling; the screenshot pair's differing viewport and
DPI are not treated as identical physical-pixel dimensions.

## Regression boundary

The production-window test `tests/integration/tst_keypad_geometry.qml` measures
actual button bounds through QML user navigation. It checks all programmer
keys in DEC and HEX at 320, 422, 542 and 900 logical-pixel widths; it also checks
Standard, Scientific, positive converters and signed converters. Dimensions
must agree within one logical pixel for raster rounding, rows must align,
spacing must remain even, and keys must keep their minimum usable bounds.
It asserts rendered geometry rather than the implementation's layout flags.
The test runs in the integrated-delivery matrix on every release platform.

The original probe deterministically failed in under a second for the reported
viewport. After the layout fix, all eight geometry cases pass on local Qt 6.12.
English/light and Chinese/dark probes also pass at scale factor 2. Captures use
the production QQuickWindow image so the complete high-DPI window is retained.
The direct QtTest item image helper cropped this scenario at scale factor 2;
that cropped output is not used as visual verification.

All checks use the isolated offscreen/Compose/private-bus launcher. The original
user screenshots are not redistributed. The following images are fresh app
captures at 1084 × 1486 physical pixels, matching the reported app capture size:

- [Chinese/dark, HEX](screenshots/keypad-programmer-v0.1.1-zh_CN-dark.png)
- [English/light, DEC](screenshots/keypad-programmer-v0.1.1-en_US-light.png)

These images substantiate this cell-sizing correction; they do not establish
pixel identity for unrelated toolbar arrangement, fonts, decorations or theme
assets against an unspecified Microsoft Store version.
