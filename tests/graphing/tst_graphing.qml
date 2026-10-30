import QtQuick
import QtTest
import Calculator

Item {
    MainWindow { id: application; systemPreferences: testSystemPreferences; width: 900; height: 700 }
    TestCase {
        name: "FunctionGraphing"
        when: windowShown && application.visible
        property string variant

        function navigate(name) {
            mouseClick(findChild(application.contentItem, "navigationButton"))
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            const entry = findChild(drawer.contentItem, name)
            verify(entry !== null, "Navigation contains " + name)
            mouseClick(entry)
            tryCompare(drawer, "visible", false)
        }
        function initTestCase() {
            variant = (application.darkTheme ? "dark-" : "light-") + Qt.locale().name
            application.requestActivate()
            tryCompare(application, "active", true)
        }
        function cleanupTestCase() {
            application.close()
            tryCompare(application, "visible", false)
        }
        function init() {
            application.width = 900
            application.height = 700
            navigate("mode_graphing")
        }
        function control(name) {
            const item = findChild(application.contentItem, name) || findChild(application, name)
                || findChild(controlPopupContent(), name)
            verify(item !== null, "Graphing control " + name)
            return item
        }
        function controlPopupContent() {
            const popup = findChild(application, "graphSyntaxPopup")
            return popup ? popup.contentItem : application.contentItem
        }
        function draw(expression, keyboard, keepEditor) {
            tryCompare(application.currentPage, "width", application.width - 8)
            verify(waitForPolish(application.contentItem))
            const input = control("functionInput")
            if (!input.visible) mouseClick(control("graphEquationsButton"))
            tryCompare(input, "visible", true)
            verify(waitForPolish(application.contentItem))
            mouseClick(input)
            keyClick(Qt.Key_A, Qt.ControlModifier)
            keyClick(Qt.Key_Backspace)
            // Real text editing, including operators and parentheses.
            for (const character of expression) keyClick(character)
            if (keyboard) keyClick(Qt.Key_Return)
            else mouseClick(control("plotFunctionButton"))
            if (!keepEditor && control("graphViewButton").visible)
                mouseClick(control("graphViewButton"))
            application.update()
            verify(waitForRendering(application.contentItem))
        }
        function curveNear(image, x, y) {
            const graph = control("functionGraph")
            const position = graph.mapToItem(application.contentItem, (x + 10) * graph.width / 20,
                                             (10 - y) * graph.height / 20)
            const px = Math.round(position.x)
            const py = Math.round(position.y)
            const color = application.accentColor
            for (let dx = -3; dx <= 3; ++dx)
                for (let dy = -3; dy <= 3; ++dy) {
                    const pixel = image.pixel(px + dx, py + dy)
                    if (Math.abs(pixel.r - color.r) < 0.12 && Math.abs(pixel.g - color.g) < 0.12
                            && Math.abs(pixel.b - color.b) < 0.12) return true
                }
            return false
        }
        function test_powers_parentheses_and_precedence_data() {
            return [
                { tag: "parabola", expression: "x^2", points: [[-2, 4], [2, 4], [0, 0]], absent: [2, -4] },
                { tag: "translated", expression: "(x-1)^2-2", points: [[-1, 2], [1, -2], [3, 2]], absent: [3, -2] },
                { tag: "unary-below-power", expression: "-x^2", points: [[-2, -4], [2, -4]], absent: [2, 4] },
                { tag: "right-associative", expression: "x^2^2/8", points: [[2, 2], [-2, 2]], absent: [2, 0.5] },
                { tag: "negative-exponent", expression: "x^-2", points: [[2, 0.25], [-1, 1]], absent: [2, 4] }
            ]
        }
        function test_powers_parentheses_and_precedence(data) {
            draw(data.expression, true)
            const image = grabImage(application.contentItem)
            for (const point of data.points)
                verify(curveNear(image, point[0], point[1]), data.expression + " passes through " + point)
            verify(!curveNear(image, data.absent[0], data.absent[1]), "Power precedence has no spurious curve")
        }
        function test_elementary_functions_use_known_coordinates_data() {
            return [
                { tag: "sine-radians", expression: "sin(x)", points: [[0, 0], [Math.PI / 2, 1], [-Math.PI / 2, -1]] },
                { tag: "cosine", expression: "cos(x)", points: [[0, 1], [Math.PI, -1]] },
                { tag: "tangent", expression: "tan(x)", points: [[Math.PI / 4, 1], [-Math.PI / 4, -1]] },
                { tag: "square-root", expression: "sqrt(x)", points: [[1, 1], [4, 2], [9, 3]] },
                { tag: "absolute", expression: "abs(x)", points: [[-3, 3], [3, 3]] },
                { tag: "natural-log", expression: "ln(x)", points: [[1, 0], [Math.E, 1]] },
                { tag: "decimal-log", expression: "log(x)", points: [[1, 0], [0.1, -1]] },
                { tag: "exponential", expression: "exp(x)", points: [[0, 1], [1, Math.E]] },
                { tag: "constants", expression: "sin(pi/2)+ln(e)+x", points: [[-2, 0], [2, 4]] },
                { tag: "numeric-literals", expression: "1e-1*x+.5", points: [[-5, 0], [5, 1]] }
            ]
        }
        function test_elementary_functions_use_known_coordinates(data) {
            draw(data.expression, true)
            const image = grabImage(application.contentItem)
            for (const point of data.points)
                verify(curveNear(image, point[0], point[1]), data.expression + " passes through " + point)
        }
        function test_undefined_intervals_and_asymptotes_are_not_connected_data() {
            return [
                { tag: "offset-reciprocal", expression: "1/(x-0.123)", points: [[1.123, 1], [-0.877, -1]], gaps: [[0.123, 0], [0.123, 3], [0.123, -3]] },
                { tag: "tangent-poles", expression: "tan(x)", points: [[Math.PI / 4, 1], [-Math.PI / 4, -1]], gaps: [[Math.PI / 2, 0], [-Math.PI / 2, 0], [Math.PI / 2, 3]] },
                { tag: "partial-domain", expression: "sqrt(x)", points: [[4, 2]], gaps: [[-4, 2], [-1, 0]] },
                { tag: "log-domain", expression: "ln(x)", points: [[Math.E, 1]], gaps: [[-1, 0], [-4, 2]] }
            ]
        }
        function test_undefined_intervals_and_asymptotes_are_not_connected(data) {
            draw(data.expression, true)
            const image = grabImage(application.contentItem)
            for (const point of data.points)
                verify(curveNear(image, point[0], point[1]), "Defined coordinate " + point)
            for (const point of data.gaps)
                verify(!curveNear(image, point[0], point[1]), "No connection across undefined interval at " + point)
        }
        function test_undefined_expressions_have_no_curve_and_recover_data() {
            return [
                { tag: "negative-root", expression: "sqrt(-1)" },
                { tag: "negative-log", expression: "ln(-1)" },
                { tag: "division-zero", expression: "1/(x-x)" },
                { tag: "exponential-overflow", expression: "exp(1000)" },
                { tag: "tangent-pole", expression: "tan(pi/2)" },
                { tag: "invalid-subexpression", expression: "sqrt(-1)^0" }
            ]
        }
        function test_undefined_expressions_have_no_curve_and_recover(data) {
            draw(data.expression, true)
            compare(control("graphStatus").text, localized("No defined points in this range.", "此范围内没有有定义的点。"))
            verify(!curveNear(grabImage(application.contentItem), 2, 1))
            draw("x+1", true)
            verify(curveNear(grabImage(application.contentItem), 2, 3), "Edit recovers after a domain error")
        }
        function localized(english, chinese) {
            return control("pageTitle").text === "函数绘图" ? chinese : english
        }
        function test_invalid_or_unsupported_syntax_clears_old_curve_and_recovers_data() {
            return [
                { tag: "missing-operand", expression: "x+" },
                { tag: "missing-parenthesis", expression: "sin(x" },
                { tag: "empty-call", expression: "sin()" },
                { tag: "unknown-function", expression: "alert(x)" },
                { tag: "script", expression: "x;quit()" },
                { tag: "property-access", expression: "Math.sin(x)" },
                { tag: "assignment", expression: "x=2" },
                { tag: "relation", expression: "x<2" },
                { tag: "implicit-product", expression: "2x" },
                { tag: "extra-arguments", expression: "sin(x,2)" },
                { tag: "recursion-limit", expression: "(".repeat(70) + "x" + ")".repeat(70) },
                { tag: "length-limit", expression: "x+".repeat(260) + "1" }
            ]
        }
        function test_invalid_or_unsupported_syntax_clears_old_curve_and_recovers(data) {
            draw("x", true)
            draw(data.expression, true)
            compare(control("graphStatus").text, localized("Invalid or unsupported expression. Check the syntax.", "表达式无效或不受支持。请检查语法。"))
            verify(!curveNear(grabImage(application.contentItem), 3, 3), "Invalid input clears the previous plot")
            draw("x+1", true)
            verify(curveNear(grabImage(application.contentItem), 2, 3))
        }
        function test_translation_theme_keyboard_and_responsive_layout() {
            // Read settings through real UI; restore system preferences afterwards.
            for (const theme of ["light", "dark"]) {
                navigate("settingsButton")
                mouseClick(control("theme_" + theme))
                mouseClick(control("language_zh-CN"))
                navigate("mode_graphing")
                compare(control("pageTitle").text, "函数绘图")
                compare(control("functionInput").Accessible.name, "x 的函数")
                compare(control("plotFunctionButton").text, "绘制")
                for (const size of [[320, 460], [900, 700]]) {
                    application.width = size[0]
                    application.height = size[1]
                    draw("x^2", true)
                    compare(control("graphStatus").text, "正在显示 y = x^2")
                    const graph = control("functionGraph")
                    verify(graph.width >= 200 && graph.height >= 160)
                    const image = grabImage(application.contentItem)
                    verify(curveNear(image, 2, 4))
                    image.save("graphing-" + variant + "-" + theme + "-" + size[0] + ".png")
                    if (!control("functionInput").visible)
                        mouseClick(control("graphEquationsButton"))
                    const input = control("functionInput")
                    input.forceActiveFocus(Qt.TabFocusReason)
                    keyClick(Qt.Key_Tab)
                    tryCompare(control("plotFunctionButton"), "activeFocus", true)
                    keyClick(Qt.Key_Tab)
                    tryCompare(control("graphSyntaxButton"), "activeFocus", true)
                    keyClick(Qt.Key_Space)
                    tryCompare(control("graphSyntaxPopup"), "opened", true)
                    verify(control("graphSyntaxText").text.indexOf("弧度") !== -1)
                    keyClick(Qt.Key_Escape)
                    tryCompare(control("graphSyntaxPopup"), "visible", false)
                }
            }
            navigate("settingsButton")
            mouseClick(control("theme_system"))
            mouseClick(control("language_system"))
            navigate("mode_graphing")
        }
        function test_empty_outside_and_partial_domain_feedback_and_bounded_sampling() {
            draw("", true)
            compare(control("graphStatus").text, localized("Enter a function, then press Enter or Plot.", "输入函数，然后按回车或绘制。"))
            draw("1000+x", true)
            compare(control("graphStatus").text, localized("The curve is outside the visible range.", "曲线在可见范围之外。"))
            draw("sqrt(x)", true)
            compare(control("graphStatus").text, localized("Showing y = sqrt(x). Undefined or unresolved intervals are omitted.", "正在显示 y = sqrt(x)。已省略无定义或无法解析的区间。"))
            // Stress a bounded sampler through the same user path, then edit
            // immediately. The suite timeout also detects an unbounded evaluator.
            draw("sin(100000*x)", true)
            verify(control("graphStatus").text.length > 0)
            draw("x+1", true)
            verify(curveNear(grabImage(application.contentItem), 2, 3))
        }
        function test_sampling_does_not_alias_a_sine_wave_into_a_flat_line() {
            draw("sin(256*pi*x)", true)
            const image = grabImage(application.contentItem)
            verify(curveNear(image, -9.998046875, 1), "Known peak near the left edge is evaluated")
            verify(curveNear(image, -9.994140625, -1), "Known trough near the left edge is evaluated")
            draw("x+1", true)
            verify(curveNear(grabImage(application.contentItem), 2, 3))
        }
        function test_long_valid_expression_keeps_graph_and_controls_inside_narrow_window() {
            application.width = 320
            application.height = 460
            draw("0." + "0".repeat(240) + "1+x", true, true)
            const graph = control("functionGraph")
            verify(graph.height >= 160)
            for (const name of ["functionInput", "plotFunctionButton", "graphSyntaxButton", "graphStatus"]) {
                const item = control(name)
                const position = item.mapToItem(application.contentItem, 0, 0)
                verify(position.y >= 0 && position.y + item.height <= application.contentItem.height,
                       name + " is fully inside the allocated window")
            }
            mouseClick(control("graphViewButton"))
            verify(waitForRendering(application.contentItem))
            verify(curveNear(grabImage(application.contentItem), 2, 2))
            application.width = 900
            application.height = 700
        }
        function test_narrow_view_switch_preserves_equation_plot_and_focus_at_reference_boundary() {
            application.width = 799
            verify(waitForPolish(application))
            const graphTab = control("graphViewButton")
            const equationTab = control("graphEquationsButton")
            tryCompare(graphTab, "visible", true)
            verify(equationTab.visible, "Reference view switch is present below 800px")
            verify(graphTab.checked)
            mouseClick(equationTab)
            verify(equationTab.checked && equationTab.Accessible.selected)
            verify(control("functionInput").visible)
            verify(!control("functionGraph").visible)
            draw("x^2", true, true)
            mouseClick(graphTab)
            verify(graphTab.checked && graphTab.Accessible.selected)
            verify(control("functionGraph").visible)
            verify(!control("functionInput").visible)
            verify(curveNear(grabImage(application.contentItem), 2, 4))
            equationTab.forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_Space)
            verify(control("functionInput").visible)
            compare(control("functionInput").text, "x^2")
            draw("x+", true, true)
            verify(control("graphStatus").visible)
            compare(control("graphStatus").text, localized("Invalid or unsupported expression. Check the syntax.", "表达式无效或不受支持。请检查语法。"))
            mouseClick(graphTab)
            verify(control("graphStatus").visible, "Validation is still reachable in Graph view")
            verify(!curveNear(grabImage(application.contentItem), 2, 4))
            graphTab.forceActiveFocus(Qt.TabFocusReason)
            application.width = 800
            verify(waitForPolish(application))
            tryCompare(graphTab, "visible", false)
            verify(!equationTab.visible)
            verify(control("functionGraph").visible && control("functionInput").visible)
            tryCompare(control("functionInput"), "activeFocus", true)
            compare(control("functionInput").text, "x+")
            draw("x+1", true)
            application.width = 799
            verify(waitForPolish(application))
            tryCompare(graphTab, "visible", true)
            tryCompare(graphTab, "activeFocus", true)
            verify(graphTab.checked)
            verify(curveNear(grabImage(application.contentItem), 2, 3))
        }
        function test_user_draws_a_line_from_editable_input() {
            draw("2*x+1", false)
            verify(control("graphStatus").text.indexOf("2*x+1") !== -1, control("graphStatus").text)
            const image = grabImage(application.contentItem)
            verify(curveNear(image, -2, -3), "Line passes through (-2,-3)")
            verify(curveNear(image, 2, 5), "Line passes through (2,5)")
            verify(!curveNear(image, 2, -5), "No fabricated curve at (2,-5)")
        }
    }
}
