pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls

ComboBox {
    id: selector
    // Fluent's asset indicator can ignore the generic offscreen theme fallback.
    // Draw the same chevron with inherited semantic foreground colors.
    indicator: Item {
        x: selector.width - width - 12
        y: (selector.height - height) / 2
        width: 14
        height: 8
        Rectangle {
            x: 1
            y: 3
            width: 7
            height: 2
            rotation: 45
            antialiasing: true
            color: selector.palette.text
        }
        Rectangle {
            x: 6
            y: 3
            width: 7
            height: 2
            rotation: -45
            antialiasing: true
            color: selector.palette.text
        }
    }
}
