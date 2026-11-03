import QtQuick
import QtTest
import Calculator

Item {
    MainWindow { id: application; systemPreferences: testSystemPreferences; currencySource: testCurrencySource }
    TestCase {
        name: "KeypadGeometry"
        when: windowShown && application.visible
        readonly property var programmerRows: [
            ["A", "shift_left", "shift_right", "clear", "backspace"],
            ["B", "open", "close", "mod", "divide"],
            ["C", "7", "8", "9", "multiply"],
            ["D", "4", "5", "6", "subtract"],
            ["E", "1", "2", "3", "add"],
            ["F", "negate", "0", "decimal", "equals"]
        ]
        readonly property var standardRows: [
            ["percent", "clearEntry", "clear", "backspace"],
            ["reciprocal", "square", "squareRoot", "divide"],
            ["7", "8", "9", "multiply"],
            ["4", "5", "6", "subtract"],
            ["1", "2", "3", "add"],
            ["sign", "0", "decimal", "equals"]
        ]
        readonly property var scientificRows: [
            ["second", "pi", "euler", "clear", "backspace"],
            ["square", "reciprocal", "abs", "exp", "mod"],
            ["squareRoot", "openParenthesis", "closeParenthesis", "factorial", "divide"],
            ["power", "7", "8", "9", "multiply"],
            ["powerTen", "4", "5", "6", "subtract"],
            ["log", "1", "2", "3", "add"],
            ["ln", "negate", "0", "decimal", "equals"]
        ]
        readonly property var converterRows: [
            [null, "clear", "backspace"],
            ["7", "8", "9"],
            ["4", "5", "6"],
            ["1", "2", "3"],
            ["negate", "0", "decimal"]
        ]
        function control(name) {
            const found = findChild(application.contentItem, name)
            verify(found !== null, "Application control: " + name)
            return found
        }
        function navigate(mode) {
            mouseClick(control("navigationButton"))
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            const entry = findChild(drawer.contentItem, "mode_" + mode)
            entry.forceActiveFocus(Qt.TabFocusReason)
            verify(waitForPolish(application.contentItem))
            keyClick(Qt.Key_Space)
            tryCompare(drawer, "visible", false)
            verify(waitForPolish(application.contentItem))
        }
        function verifyCells(rows, prefix) {
            const firstName = rows[0].find(name => name !== null)
            const first = control(prefix + firstName)
            const columnPositions = {}
            let previousY = null
            for (let row = 0; row < rows.length; ++row) {
                let rowY = null
                let previousX = null
                for (let column = 0; column < rows[row].length; ++column) {
                    const key = rows[row][column]
                    if (key === null) continue
                    const button = control(prefix + key)
                    if (!button.visible) continue
                    const position = button.mapToItem(application.contentItem, 0, 0)
                    verify(Math.abs(button.width - first.width) <= 1,
                           key + " width " + button.width + " differs from first key " + first.width)
                    verify(Math.abs(button.height - first.height) <= 1,
                           key + " height " + button.height + " differs from first key " + first.height)
                    verify(button.width >= 44 && button.height >= 44, key + " remains usable at the minimum size")
                    if (columnPositions[column] !== undefined)
                        verify(Math.abs(position.x - columnPositions[column]) <= 1, "Keys align in column " + column)
                    else
                        columnPositions[column] = position.x
                    if (rowY !== null) verify(Math.abs(position.y - rowY) <= 1, "Keys align in row " + row)
                    if (previousX !== null) verify(Math.abs(position.x - previousX - first.width - 4) <= 1, "Even column spacing")
                    rowY = position.y
                    previousX = position.x
                }
                if (rowY !== null && previousY !== null)
                    verify(Math.abs(rowY - previousY - first.height - 4) <= 1, "Even row spacing")
                if (rowY !== null) previousY = rowY
            }
        }
        function initTestCase() {
            application.requestActivate()
            tryCompare(application, "active", true)
        }
        function test_programmer_keypad_has_equal_cells_data() {
            return [
                { tag: "minimum", width: 320, height: 560 },
                { tag: "medium", width: 422, height: 600 },
                { tag: "reported", width: 542, height: 743 },
                { tag: "wide", width: 900, height: 700 }
            ]
        }
        function test_programmer_keypad_has_equal_cells(data) {
            application.width = data.width
            application.height = data.height
            navigate("programmer")
            for (const radix of [10, 16]) {
                mouseClick(control("radix_" + radix))
                verify(waitForPolish(application.contentItem))
                verifyCells(programmerRows, "key_")
                verify(waitForRendering(application.contentItem))
                verify(testWindowCapture.saveWindow(application, "keypad-programmer-" + data.tag + "-base" + radix + "-" + Qt.locale().name + "-" + (application.darkTheme ? "dark" : "light") + ".png"))
            }
        }
        function test_other_regular_keypads_have_equal_cells_data() {
            return [
                { tag: "standard", mode: "standard" },
                { tag: "scientific", mode: "scientific" },
                { tag: "positive-converter", mode: "length" },
                { tag: "signed-converter", mode: "temperature" }
            ]
        }
        function test_other_regular_keypads_have_equal_cells(data) {
            for (const size of [{width: 360, height: 740}, {width: 900, height: 740}]) {
                application.width = size.width
                application.height = size.height
                navigate(data.mode)
                if (data.mode === "standard") verifyCells(standardRows, "key_")
                else if (data.mode === "scientific") verifyCells(scientificRows, "key_")
                else verifyCells(converterRows, "converterKey_")
            }
        }
        function cleanupTestCase() { application.close() }
    }
}
