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
            navigate("mode_standard")
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
        function test_multiple_functions_edit_and_delete_independently() {
            draw("x", true)
            mouseClick(control("addFunctionButton"))
            draw("-x", false)
            const swatch = control("graphFunctionColor_2").color
            const secondColor = Qt.rgba(swatch.r, swatch.g, swatch.b, 1)
            let image = grabImage(application.contentItem)
            verify(curveNear(image, 3, 3), "First function remains at (3,3)")
            verify(curveNear(image, 3, -3, secondColor), "Second function is independently evaluated")
            mouseClick(control("selectFunction_1"))
            compare(control("functionInput").text, "x")
            draw("x+2", true)
            image = grabImage(application.contentItem)
            verify(curveNear(image, 3, 5), "Editing first updates its curve")
            verify(!curveNear(image, 3, 3), "Previous first curve is removed")
            verify(curveNear(image, 3, -3, secondColor), "Second curve is unchanged")
            mouseClick(control("selectFunction_2"))
            compare(control("functionInput").text, "-x")
            draw("x+", true)
            compare(control("graphStatus").text, localized("Invalid or unsupported expression. Check the syntax.", "表达式无效或不受支持。请检查语法。"))
            verify(curveNear(grabImage(application.contentItem), 3, 5), "An invalid second function preserves the valid first")
            mouseClick(control("deleteFunctionButton"))
            compare(control("functionInput").text, "x+2")
            verify(curveNear(grabImage(application.contentItem), 3, 5))
        }
        function test_deleting_middle_function_preserves_stable_identifiers_and_selection() {
            draw("x", true)
            mouseClick(control("addFunctionButton"))
            draw("x+2", true)
            mouseClick(control("addFunctionButton"))
            draw("-x", true)
            mouseClick(control("selectFunction_2"))
            mouseClick(control("deleteFunctionButton"))
            compare(control("functionInput").text, "-x")
            draw("-x-2", true)
            mouseClick(control("selectFunction_1"))
            compare(control("functionInput").text, "x")
            verify(waitForRendering(application.contentItem))
            verify(curveNear(grabImage(application.contentItem), 3, 3), "First curve remains independently selectable")
            mouseClick(control("selectFunction_3"))
            compare(control("functionInput").text, "-x-2")
            mouseClick(control("addFunctionButton"))
            draw("x^2", true)
            verify(control("selectFunction_4").checked, "A new identifier does not reuse a deleted function")
            mouseClick(control("deleteFunctionButton"))
            mouseClick(control("deleteFunctionButton"))
            mouseClick(control("deleteFunctionButton"))
            compare(control("functionInput").text, "")
            compare(control("graphStatus").text, localized("Enter a function, then press Enter or Plot.", "输入函数，然后按回车或绘制。"))
        }
        function test_zoom_and_pan_update_curves_axes_and_visible_range() {
            draw("x^2", true)
            mouseClick(control("graphZoomInButton"))
            compare(control("graphRange").text, "x: -5 … 5; y: -5 … 5")
            verify(waitForRendering(application.contentItem))
            verify(curveNear(grabImage(application.contentItem), 2, 4), "Zoom reprojects the parabola")
            mouseClick(control("graphPanRightButton"))
            mouseClick(control("graphPanUpButton"))
            compare(control("graphRange").text, "x: -2.5 … 7.5; y: -2.5 … 7.5")
            verify(waitForRendering(application.contentItem))
            verify(curveNear(grabImage(application.contentItem), 2, 4), "Panning resamples and reprojects the curve")
            mouseClick(control("graphResetButton"))
            compare(control("graphRange").text, "x: -10 … 10; y: -10 … 10")
        }
        function test_coordinate_reading_tracks_view_selection_and_undefined_points() {
            draw("x^2", true)
            mouseClick(control("graphZoomInButton"))
            mouseClick(control("graphPanRightButton"))
            mouseClick(control("graphPanUpButton"))
            const graph = control("functionGraph")
            mouseClick(graph, graph.width / 2, graph.height / 2)
            keyClick(Qt.Key_Space) // Inspect the exact center, independent of integer pointer rounding.
            compare(control("graphCoordinates").text, "x: 2.5; y: 2.5; F1(x): 6.25")
            mouseClick(control("addFunctionButton"))
            draw("sqrt(-1)", true)
            mouseClick(graph, graph.width / 2, graph.height / 2)
            keyClick(Qt.Key_Space)
            compare(control("graphCoordinates").text, localized("x: 2.5; y: 2.5; F2(x): Undefined", "x: 2.5; y: 2.5; F2(x): 无定义"))
            mouseClick(control("selectFunction_1"))
            compare(control("graphCoordinates").text, "x: 2.5; y: 2.5; F1(x): 6.25")
            mouseClick(control("selectFunction_2"))
            mouseClick(control("deleteFunctionButton"))
            mouseClick(control("graphResetButton"))
        }
        function test_drag_keyboard_and_zoom_boundaries_remain_responsive() {
            draw("x+1", true)
            const graph = control("functionGraph")
            mousePress(graph, graph.width / 2, graph.height / 2)
            mouseMove(graph, graph.width * 3 / 4, graph.height * 3 / 4)
            mouseRelease(graph, graph.width * 3 / 4, graph.height * 3 / 4)
            const ranges = control("graphRange").text.match(/-?\d+(?:\.\d+)?/g).map(Number)
            fuzzyCompare(ranges[0], -15, 0.04)
            fuzzyCompare(ranges[1], 5, 0.04)
            fuzzyCompare(ranges[2], -5, 0.04)
            fuzzyCompare(ranges[3], 15, 0.04)
            keyClick(Qt.Key_Home)
            keyClick(Qt.Key_Right)
            keyClick(Qt.Key_Down)
            compare(control("graphRange").text, "x: -5 … 15; y: -15 … 5")
            keyClick(Qt.Key_Home)
            keyClick(Qt.Key_Plus)
            compare(control("graphRange").text, "x: -5 … 5; y: -5 … 5")
            mouseWheel(graph, graph.width / 2, graph.height / 2, 0, -120)
            compare(control("graphRange").text, "x: -10 … 10; y: -10 … 10")
            mouseWheel(graph, graph.width / 2, graph.height / 2, 0, 120)
            compare(control("graphRange").text, "x: -5 … 5; y: -5 … 5")
            keyClick(Qt.Key_Space)
            compare(control("graphCoordinates").text, "x: 0; y: 0; F1(x): 1")
            keyClick(Qt.Key_Home)
            for (let step = 0; step < 30 && control("graphZoomInButton").enabled; ++step)
                mouseClick(control("graphZoomInButton"))
            compare(control("graphZoomInButton").enabled, false)
            const tinyLimits = control("graphRange").text.match(/-?\d+(?:\.\d+)?(?:e[+-]?\d+)?/g).map(Number)
            compare(tinyLimits, [-0.0000005, 0.0000005, -0.0000005, 0.0000005])
            mouseClick(control("graphResetButton"))
            for (let step = 0; step < 30 && control("graphZoomOutButton").enabled; ++step)
                mouseClick(control("graphZoomOutButton"))
            compare(control("graphZoomOutButton").enabled, false)
            compare(control("graphRange").text, "x: -500000 … 500000; y: -500000 … 500000")
            mouseClick(control("graphResetButton"))
            verify(waitForRendering(application.contentItem))
            verify(curveNear(grabImage(application.contentItem), 2, 3), "A bounded view can return to its original curve")
        }
        function test_function_management_and_view_controls_translate_in_both_layouts_and_themes() {
            for (const theme of ["light", "dark"]) {
                navigate("settingsButton")
                mouseClick(control("theme_" + theme))
                mouseClick(control("language_zh-CN"))
                navigate("mode_graphing")
                compare(control("addFunctionButton").text, "添加函数")
                compare(control("deleteFunctionButton").text, "删除")
                compare(control("graphZoomInButton").Accessible.name, "放大")
                compare(control("graphPanRightButton").Accessible.name, "向右平移")
                compare(control("graphResetButton").Accessible.name, "重置视图")
                for (const size of [[320, 460], [900, 700]]) {
                    application.width = size[0]
                    application.height = size[1]
                    draw("x", true, true)
                    if (!control("functionInput").visible) mouseClick(control("graphEquationsButton"))
                    mouseClick(control("addFunctionButton"))
                    draw("-x", true, true)
                    const graph = control("functionGraph")
                    const secondId = graph.functions[graph.selectedIndex].id
                    verify(waitForRendering(application.contentItem))
                    verify(selectedFunctionTextHasContrast(control("selectFunction_" + secondId)),
                           "Selected function text keeps 4.5:1 contrast in " + theme)
                    const color = control("graphFunctionColor_" + secondId).color
                    const copy = Qt.rgba(color.r, color.g, color.b, 1)
                    verify(contrastRatio(copy, graph.backgroundColor) >= 4.5,
                           "Each labeled curve contrasts with the graph surface in " + theme)
                    if (!graph.visible) mouseClick(control("graphViewButton"))
                    mouseClick(control("graphZoomInButton"))
                    mouseClick(control("graphPanRightButton"))
                    mouseClick(graph, graph.width / 2, graph.height / 2)
                    const coordinates = control("graphCoordinates").text
                    const parts = coordinates.match(/x: ([^;]+); y: ([^;]+); F(\d+)\(x\): (.+)/)
                    verify(parts !== null, coordinates)
                    fuzzyCompare(Number(parts[1]), 2.5, 0.06)
                    fuzzyCompare(Number(parts[2]), 0, 0.06)
                    compare(Number(parts[3]), secondId)
                    fuzzyCompare(Number(parts[4]), -2.5, 0.06)
                    verify(waitForRendering(application.contentItem))
                    const image = grabImage(application.contentItem)
                    verify(curveNear(image, 2, 2), "First curve remains usable")
                    verify(curveNear(image, 2, -2, copy), "Second curve remains readable")
                    image.save("graphing-multiple-" + theme + "-" + size[0] + ".png")
                    for (const name of ["graphZoomInButton", "graphZoomOutButton", "graphPanLeftButton", "graphPanRightButton", "graphPanUpButton", "graphPanDownButton", "graphResetButton", "graphRange", "graphCoordinates", "graphStatus"]) {
                        const item = control(name)
                        const position = item.mapToItem(application.contentItem, 0, 0)
                        verify(position.x >= 0 && position.x + item.width <= application.contentItem.width,
                               name + " fits horizontally")
                        verify(position.y >= 0 && position.y + item.height <= application.contentItem.height,
                               name + " fits vertically")
                    }
                    if (!control("functionInput").visible) mouseClick(control("graphEquationsButton"))
                    mouseClick(control("deleteFunctionButton"))
                    compare(control("functionInput").text, "x")
                    mouseClick(control("graphSyntaxButton"))
                    tryCompare(control("graphSyntaxPopup"), "opened", true)
                    verify(control("graphNavigationHelp").text.indexOf("平移") !== -1)
                    keyClick(Qt.Key_Escape)
                    tryCompare(control("functionInput"), "activeFocus", true)
                    if (!graph.visible) mouseClick(control("graphViewButton"))
                    mouseClick(control("graphResetButton"))
                }
            }
            navigate("settingsButton")
            mouseClick(control("theme_system"))
            mouseClick(control("language_system"))
            navigate("mode_graphing")
        }
        function test_view_changes_resample_discontinuities_and_preserve_other_functions() {
            draw("1/(x-0.123)", true)
            mouseClick(control("addFunctionButton"))
            draw("x+2", true)
            const swatch = control("graphFunctionColor_2").color
            const secondColor = Qt.rgba(swatch.r, swatch.g, swatch.b, 1)
            for (let iteration = 0; iteration < 3; ++iteration) {
                mouseClick(control("graphZoomInButton"))
                mouseClick(control("graphPanRightButton"))
                mouseClick(control("graphPanUpButton"))
                verify(waitForRendering(application.contentItem))
                const image = grabImage(application.contentItem)
                verify(curveNear(image, 1.123, 1), "Positive reciprocal branch is recomputed")
                verify(curveNear(image, -0.877, -1), "Negative reciprocal branch is recomputed")
                verify(curveNear(image, 2, 4, secondColor), "Other function uses the changed view")
                verify(!curveNear(image, 0.123, 0), "No false stroke across the moved pole")
                verify(!curveNear(image, 0.123, 3), "Pole stays disconnected after view changes")
                mouseClick(control("graphResetButton"))
            }
            mouseClick(control("selectFunction_1"))
            draw("1/(x-2.5)", true)
            mouseClick(control("graphZoomInButton"))
            mouseClick(control("graphPanRightButton"))
            const graph = control("functionGraph")
            mouseClick(graph, graph.width / 2, graph.height / 2)
            keyClick(Qt.Key_Space)
            const coordinates = control("graphCoordinates").text
            verify(coordinates.indexOf("F1(x): " + localized("Undefined", "无定义")) !== -1, coordinates)
            application.update()
            verify(waitForRendering(application.contentItem))
            const changed = grabImage(application.contentItem)
            verify(!curveNear(changed, 2.5, 0), "Editing removes the previous sample set")
            verify(curveNear(changed, 3.5, 1), "Edited reciprocal has its own valid branch")
            draw("sqrt(x-2.5)", true)
            application.update()
            verify(waitForRendering(application.contentItem))
            const domain = grabImage(application.contentItem)
            verify(curveNear(domain, 3.5, 1), "Edited domain is sampled")
            verify(!curveNear(domain, 1.5, -1), "Undefined negative branch is removed")
            mouseClick(control("selectFunction_2"))
            mouseClick(control("deleteFunctionButton"))
            mouseClick(control("graphResetButton"))
        }
        function test_narrow_view_keeps_distinct_limits_after_panning_and_deep_zoom() {
            draw("x+1", true)
            for (let step = 0; step < 30 && control("graphZoomOutButton").enabled; ++step)
                mouseClick(control("graphZoomOutButton"))
            for (let step = 0; step < 4; ++step) mouseClick(control("graphPanRightButton"))
            for (let step = 0; step < 50 && control("graphZoomInButton").enabled; ++step)
                mouseClick(control("graphZoomInButton"))
            const limits = control("graphRange").text.match(/-?\d+(?:\.\d+)?(?:e[+-]?\d+)?/g).map(Number)
            verify(limits[1] > limits[0], "Displayed x limits remain distinct far from the origin")
            fuzzyCompare(limits[1] - limits[0], 0.000001, 0.0000001)
            const graph = control("functionGraph")
            mouseClick(graph, graph.width / 2, graph.height / 2)
            keyClick(Qt.Key_Space)
            compare(control("graphCoordinates").text, "x: 1000000; y: 0; F1(x): 1000001")
            mouseClick(control("graphResetButton"))
        }
        function test_pan_boundary_keeps_coordinate_readout_aligned_with_visible_limits() {
            draw("x", true)
            for (let step = 0; step < 30 && control("graphZoomOutButton").enabled; ++step)
                mouseClick(control("graphZoomOutButton"))
            const graph = control("functionGraph")
            mousePress(graph, graph.width / 2, graph.height / 2)
            mouseMove(graph, -2000 * graph.width, graph.height / 2)
            mouseRelease(graph, -2000 * graph.width, graph.height / 2)
            for (let step = 0; step < 50 && control("graphZoomInButton").enabled; ++step)
                mouseClick(control("graphZoomInButton"))
            const limits = control("graphRange").text.match(/-?\d+(?:\.\d+)?(?:e[+-]?\d+)?/g).map(Number)
            verify(limits[1] > limits[0], "Pan boundary retains distinct limits")
            fuzzyCompare((limits[0] + limits[1]) / 2, 1000000000, 0.000001)
            fuzzyCompare(limits[1] - limits[0], 0.000001, 0.00000005)
            mouseClick(graph, graph.width - 1, graph.height / 2)
            const coordinate = Number(control("graphCoordinates").text.match(/x: ([^;]+)/)[1])
            compare(coordinate, limits[1], "The last pixel agrees with the visible maximum within double precision")
            mouseClick(control("graphResetButton"))
        }
        function test_function_list_keeps_keyboard_focus_visible_in_narrow_window() {
            application.width = 320
            application.height = 460
            draw("x", true, true)
            for (let index = 1; index <= 6; ++index) {
                mouseClick(control("addFunctionButton"))
                draw("x+" + index, true, true)
            }
            control("functionInput").forceActiveFocus(Qt.TabFocusReason)
            let focusedRows = 0
            for (let step = 0; step < 12; ++step) {
                keyClick(Qt.Key_Tab)
                verify(waitForPolish(application.contentItem))
                for (let id = 1; id <= 7; ++id) {
                    const row = findChild(application.contentItem, "selectFunction_" + id)
                    if (!row || !row.activeFocus) continue
                    ++focusedRows
                    const list = control("functionList")
                    const position = row.mapToItem(list, 0, 0)
                    verify(position.y >= 0 && position.y + row.height <= list.height,
                           "Focused function F" + id + " is fully visible")
                }
            }
            verify(focusedRows > 0, "Function rows participate in keyboard navigation")
        }
        function contrastRatio(first, second) {
            function luminance(color) {
                function linear(channel) { return channel <= 0.04045 ? channel / 12.92 : Math.pow((channel + 0.055) / 1.055, 2.4) }
                return 0.2126 * linear(color.r) + 0.7152 * linear(color.g) + 0.0722 * linear(color.b)
            }
            const a = luminance(first)
            const b = luminance(second)
            return (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05)
        }
        function selectedFunctionTextHasContrast(row) {
            const image = grabImage(application.contentItem)
            const position = row.mapToItem(application.contentItem, 0, 0)
            const background = image.pixel(Math.round(position.x + row.width - 12), Math.round(position.y + row.height / 2))
            // Scan the rendered short equation label, excluding swatch and focus border.
            for (let x = 24; x < 100; ++x)
                for (let y = 8; y < row.height - 8; ++y) {
                    const text = image.pixel(Math.round(position.x + x), Math.round(position.y + y))
                    if (contrastRatio(text, background) >= 4.5)
                        return true
                }
            return false
        }
        function curveNear(image, x, y, curveColor) {
            const graph = control("functionGraph")
            const minimumX = graph.minimumX
            const maximumX = graph.maximumX
            const minimumY = graph.minimumY
            const maximumY = graph.maximumY
            const position = graph.mapToItem(application.contentItem, (x - minimumX) * graph.width / (maximumX - minimumX),
                                             (maximumY - y) * graph.height / (maximumY - minimumY))
            const px = Math.round(position.x)
            const py = Math.round(position.y)
            const color = curveColor || application.accentColor
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
