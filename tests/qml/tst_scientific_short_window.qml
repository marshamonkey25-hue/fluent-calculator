import QtQuick
import QtTest
import Calculator

Item {
    MainWindow { id: application; systemPreferences: testSystemPreferences }
    TestCase {
        name: "ScientificShortWindow"
        when: windowShown && application.visible

        function initTestCase() {
            application.requestActivate()
            tryCompare(application, "active", true)
        }

        function test_scientific_keys_remain_reachable_below_requested_minimum_height() {
            mouseClick(findChild(application.contentItem, "navigationButton"))
            const drawer = findChild(application, "navigationDrawer")
            tryCompare(drawer, "opened", true)
            mouseClick(findChild(drawer.contentItem, "mode_scientific"))
            tryCompare(drawer, "visible", false)
            // Some desktop compositors can tile a window below its size hint.
            application.minimumHeight = 460
            application.width = 320
            application.height = 460
            const scroll = findChild(application.contentItem, "scientificScroll")
            verify(scroll !== null, "A short Scientific window has a scrollable keypad")
            const viewport = scroll.contentItem
            tryVerify(function() { return viewport.contentHeight > viewport.height })
            const zero = findChild(application.contentItem, "key_0")
            zero.forceActiveFocus(Qt.TabFocusReason)
            tryVerify(function() { return viewport.contentY > 0 })
            let point = zero.mapToItem(application.contentItem, 0, 0)
            verify(point.y >= 0 && point.y + zero.height <= application.height)
            mouseClick(zero)
            for (const key of ["3", "0"])
                keyClick(key)
            const angle = findChild(application.contentItem, "angleUnitButton")
            angle.forceActiveFocus(Qt.TabFocusReason)
            tryVerify(function() {
                const position = angle.mapToItem(application.contentItem, 0, 0)
                return position.y >= 0 && position.y + angle.height <= application.height
            })
            mouseClick(angle)
            compare(angle.text, "RAD")
            const trigonometry = findChild(application.contentItem, "trigonometryButton")
            trigonometry.forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_Space)
            const popup = findChild(application, "trigonometryPopup")
            tryCompare(popup, "opened", true)
            keyClick(Qt.Key_Escape)
            tryCompare(popup, "visible", false)
            compare(findChild(application.contentItem, "resultDisplay").text, "30")
            keyClick(Qt.Key_F3)
            keyClick(Qt.Key_S)
            compare(findChild(application.contentItem, "resultDisplay").text, "0.5")
            grabImage(application.contentItem).save("scientific-short-window.png")
        }

        function cleanupTestCase() { application.close() }
    }
}
