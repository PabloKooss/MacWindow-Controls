// The group of three macOS-style buttons. Visual only: emits signals.
import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: lights

    // ---- API ----
    property real buttonSize: 12
    property real buttonSpacing: 8
    property bool shown: true
    property int animationDuration: 150
    property bool windowActive: true
    property bool windowMaximized: true
    property bool canClose: true
    property bool canMinimize: true
    property bool canMaximize: true
    readonly property bool groupHovered: groupHover.hovered
    signal closeClicked()
    signal minimizeClicked()
    signal maximizeClicked()

    // Inactive color follows the panel theme (works on light and dark panels).
    readonly property color themeText: Kirigami.Theme.textColor
    readonly property color inactiveColor: Qt.rgba(themeText.r, themeText.g, themeText.b, 0.28)

    implicitWidth: row.implicitWidth
    implicitHeight: lights.buttonSize

    // Smooth appear/disappear.
    opacity: shown ? 1 : 0
    scale: shown ? 1 : 0.85
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: lights.animationDuration; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: lights.animationDuration; easing.type: Easing.OutCubic } }

    HoverHandler { id: groupHover }

    Row {
        id: row
        spacing: lights.buttonSpacing

        TrafficLightButton {
            glyph: "close"
            baseColor: "#FF5F57"; glyphColor: "#4D0000"
            diameter: lights.buttonSize; hitMargin: lights.buttonSpacing / 2
            inactiveColor: lights.inactiveColor
            windowActive: lights.windowActive; showGlyph: lights.groupHovered
            buttonEnabled: lights.canClose
            onClicked: lights.closeClicked()
        }
        TrafficLightButton {
            glyph: "minimize"
            baseColor: "#FEBC2E"; glyphColor: "#995700"
            diameter: lights.buttonSize; hitMargin: lights.buttonSpacing / 2
            inactiveColor: lights.inactiveColor
            windowActive: lights.windowActive; showGlyph: lights.groupHovered
            buttonEnabled: lights.canMinimize
            onClicked: lights.minimizeClicked()
        }
        TrafficLightButton {
            glyph: "maximize"
            baseColor: "#28C840"; glyphColor: "#006500"
            diameter: lights.buttonSize; hitMargin: lights.buttonSpacing / 2
            inactiveColor: lights.inactiveColor
            glyphMaximized: lights.windowMaximized
            windowActive: lights.windowActive; showGlyph: lights.groupHovered
            buttonEnabled: lights.canMaximize
            onClicked: lights.maximizeClicked()
        }
    }
}
