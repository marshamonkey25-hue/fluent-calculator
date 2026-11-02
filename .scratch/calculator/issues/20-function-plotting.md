# 20: 输入函数并绘制真实曲线

**What to build:** 用户可进入函数绘图，输入一条 y=f(x) 函数并看到真实计算的曲线，对非法表达式和无定义区间获得正确反馈。

**Blocked by:** 01: 运行真实核心驱动的标准计算器。

**Status:** resolved

**Spec:** Windows 11 风格跨平台计算器。

**User stories:** 41, 45。

- [x] 提供真实函数绘图入口、可编辑函数输入及带坐标轴的绘图区；至少可在当前范围绘制一条用户输入的 y=f(x)，不能使用预制静态曲线代替求值。
- [x] 支持自变量、数值、基础运算、括号以及常用幂和初等函数，明确记录实际支持的语法与函数范围；函数求值采用受限数学语法，不能执行任意脚本。
- [x] 函数求值与绘图采样独立于算术模式的逐次按键逻辑，且新增依赖的许可和来源有记录。
- [x] 对合法定义域内的点进行真实计算，在无定义点和不连续区间断开曲线；正确处理倒数函数和三角函数等渐近线附近的典型情况。
- [x] 非法语法、不支持的表达式和无有效点时有明确状态，用户可修改后恢复，界面不因计算异常或不受控采样失去响应。
- [x] 页面沿用主题、可翻译说明、键盘编辑和合理窗口适配；本任务不承诺隐式关系、不等式及完整图形分析。
- [x] 通过界面验证直线、抛物线、常见初等函数、非法输入和无定义区间；用已知坐标与不连续区间验证图形正确性，不只检查是否生成图像。

## Ticket 20 implementation evidence

The following evidence was recorded by the implementer before merge; independent integration review and closure evidence follow below. The parent spec and other tickets are unchanged.

- `qml/GraphingPage.qml` and the registered `graphing` mode provide real editable `y=f(x)` plotting, labeled axes/grid, Enter/Plot actions, translated syntax help, native QML focus controls and the shared theme palette. The pinned `GraphingCalculator.xaml` uses a 2:1 graph/equation split above 800 px; this page preserves that hierarchy and uses the reference Graph/Equations view switch below 800 px, retaining expression/plot state and keeping validation visible in either view. The existing navigation/preferences registry supplies mode restoration.
- `app/FunctionExpression.{h,cpp}` is a restricted, project-authored mathematical compiler/evaluator, separate from Microsoft CEngine command entry. Supported syntax is documented in README and in the page's Syntax popup: `x`, `pi`, `e`, decimal/scientific literals, unary signs, `+ - * / ^`, parentheses and `sin/cos/tan/sqrt/abs/ln/log/exp`, in radians. Explicit multiplication, right-associative powers and mathematical unary precedence are tested. No scripting engine, arbitrary host calls, new dependency or new third-party licensing obligation is introduced.
- `app/FunctionGraph.{h,cpp}` paints evaluated samples in the initial [-10,10] coordinate window. Bounded adaptive sampling, a non-dyadic probe, finite-intermediate checks and mathematical clipping keep typical reciprocal/tangent poles and undefined domains disconnected. Invalid syntax clears the plot; empty, undefined, offscreen and partially omitted plots have visible feedback. Work is limited to 512 input characters, 256 instructions, 64 parser frames, 65,536 evaluations and 12 adaptive subdivision levels.
- `tests/graphing/tst_graphing.qml` uses actual QML navigation, text editing, Enter/buttons and rendered coordinates. It checks known line/parabola/function coordinates, absence of strokes through reciprocal/tangent poles, square-root/log domains, parser/script rejection, limits, error recovery, high-frequency sine aliasing, bounded sampling, runtime Chinese translation, light/dark themes, help focus/Escape, long input and narrow/wide windows. CMake registers independent isolated graphing suites in English/light, English/dark and Chinese/light. No calculator, sampler or renderer is mocked.

Actual red → green slices, retained in the private `.build-ticket20` logs:

1. `red-01.log`: missing `mode_graphing`; `green-01.log`: the same input `2*x+1` draws through (-2,-3) and (2,5).
2. `red-02.log`: five power/precedence cases fail at known coordinates; `green-02.log`: native restricted exponent grammar gives all expected curves.
3. `red-03.log`: elementary-function/constant curves are absent; `green-03.log`: all documented functions/constants pass known-coordinate checks.
4. `red-04.log`: off-grid reciprocal and tangent poles have false connecting strokes; `green-04.log`: adaptive sampling removes those strokes while keeping valid branches.
5. `red-05.log`: rounded tan(pi/2) is treated as finite and sqrt(-1)^0 becomes 1; `green-05.log`: both are undefined, with edit recovery.
6. `red-06.log`: switching to Chinese leaves Graphing untranslated; `green-06.log`: translated controls/help/status and keyboard operation pass in both themes and both window sizes.
7. `red-07.log`: sin(256*pi*x) aliases to a flat line and misses a known peak; `green-07.log`: the non-dyadic probe recovers known peak/trough samples within the bounded work budget.
8. `red-08.log`: the pinned narrow Graph/Equations switch is absent; `green-08.log`: both views preserve editor/plot state, expose accessible selection, and show validation across the 799/800 px boundary.
9. `red-09.log`: focus is stranded when the focused view switch disappears on widening; `green-09.log`: focus moves to the visible equation editor and returns to the graph switch when narrowing.

Additional syntax, domain, limits and long-input cases are regression checks of the real implementation, not claimed as new red cycles. A first complete CTest run exposed test-harness issues (empty edits did not press Backspace, the void image-save method was asserted as a boolean, and a failed resize test leaked its narrow width into later discontinuity pixel tolerances); those were corrected without loosening the mathematical expectations. Historical failed runs remain in `.build-ticket20/ctest-graphing.log`.

Documentation lookup: required find-docs/Context7 resolved `/websites/doc_qt_io_qt-6` and verified `QQuickPaintedItem::paint`, `update` and `setAntialiasing`; no unavailable/quota fallback was needed. UI/UX search returned the applicable Fluent 2 style, retaining neutral semantic palette roles, standard controls and visible focus. All GUI validation uses the repository's private offscreen/software/compose/generic launcher with isolated settings/data/runtime and private D-Bus. No desktop/native-window validation, Windows/macOS build, remote push, PR or deployment is claimed. Numerical sampling remains a finite approximation and does not promise detection of arbitrary sub-resolution features. Ticket 21 owns multiple curves, pan/zoom and coordinate inspection.

Final branch validation: Linux x86_64, Qt 6.12.0, GCC 16.2.1, CMake 4.4.4 and GNU Make, private Debug build `.build-ticket20`, `-j2` compilation. All **15 CTest entries passed** in 1017.33 seconds (`ctest-full.log`): the existing main UI suite reports 298 outcomes per theme/language, Programmer bits 35 and history 20, with restart/isolation checks passing. That run's graphing entries preceded the final pinned narrow-layout adjustment; all **three affected graphing configurations were rerun and passed** afterwards in 75.59 seconds (`ctest-graphing-accepted.log`). A fresh full graphing run after the final no-op integration merge reports **45 passed, 0 failed, 0 skipped** (`graphing-final-merge.log`). Final QML lint and `git diff --check` pass. Reviewed final offscreen light/dark captures show the narrow view switch and wide graph/equation split.

`integration/calculator` at `d327f2de0e09bca87e02416e42374db91a506883` was verified as an ancestor before starting and re-merged before final validation (`Already up to date`); no existing changes were reset or discarded. Final source, tests, build registration, documentation, translations and this evidence are committed together. At implementation handoff, independent review/merge validation remained pending and the implementer left acceptance checklists and Status open.


## Integration review and closure

Merged source commit `e5d6a6212e87205b9e2662b9be67ec907710685b` with `git merge --no-ff` into `integration/calculator` as **`97961478f015180d0a0fa0fe060e47b9b446ddc8`**. The root checkout was clean at `52b3bea` before merging. CMake, navigation, translation and appended README conflicts were resolved additively; existing memory, date and length controllers/pages/tests were retained. A preservation audit confirms all pre-existing Chinese translations remain and the six new evaluator/graph/page/test files match the source commit.

Independent merger inspection found no ticket blockers. The seven criteria are fulfilled by the real editable Graphing page and labeled computed plot; documented bounded mathematical grammar; separate project-authored evaluator with no new dependencies; discontinuity-aware domain sampling; explicit validation and recovery; shared translated palette, keyboard focus and responsive controls; and real-QML known-coordinate/absent-stroke tests. Multiple curves, pan/zoom and coordinate inspection remain ticket 21's approved scope. The pinned upstream `GraphingCalculator.xaml` confirms the 800 px panel breakpoint and 2:1 graph/equation hierarchy.

Integration validation on Linux/Qt 6.12, Debug/Make, `-j2`:

- `cmake -S . -B .build-integration -DCMAKE_BUILD_TYPE=Debug`, `cmake --build .build-integration -j2` and `cmake --build .build-integration --target calculator_ui_qmllint -j2` pass; build and lint logs contain no warnings.
- `ctest --test-dir .build-integration --output-on-failure -j2`: **26/26 entries pass in 1341.43 seconds**, including every existing application, Programmer-bit, history, memory, date, Length, restart and isolation entry, plus all three new Graphing configurations. Each Graphing suite reports **45 passed, 0 failed, 0 skipped**. No integration code/test repair was needed.
- Merger reviewed generated 320×460 and 900×700 Chinese Graphing captures in both light/dark themes: labeled axes, computed parabola, readable feedback, narrow view switch and wide graph/editor split. Automated tests additionally cover keyboard/help focus and the 799/800 px boundary.
- Evidence logs: `.build-integration/merge20-configure.log`, `merge20-build.log`, `merge20-qmllint.log`, `merge20-ctest.log` and frozen `merge20-LastTest.log`. `git diff --check` passes. Parent spec unchanged.

All GUI verification used the shared private offscreen/software/compose/generic launcher with isolated settings/data/cache/runtime and private D-Bus. No active desktop, host IME, remote push, PR or deployment was used. Windows/macOS and native rendering remain unverified. Finite sampling retains the documented sub-resolution limitation. Ticket 20 is resolved after independent merger review and successful integrated validation; final application-wide review remains separate.
