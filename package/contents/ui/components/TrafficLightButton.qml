// One macOS-style circular button. Purely visual: emits clicked().
import QtQuick
import QtQuick.Shapes

Item {
    id: btn

    // ---- API ----
    property string glyph: "close"            // "close" | "minimize" | "maximize"
    property color baseColor: "#FF5F57"
    property color glyphColor: "#4D0000"
    property color inactiveColor: "#44888888"
    property real diameter: 12
    property real hitMargin: 4                 // extends the click area into the gap
    property bool windowActive: true           // false -> gray, like inactive macOS windows
    property bool showGlyph: false             // set by the group on hover
    property bool glyphMaximized: true         // green glyph: true = restore, false = maximize
    property bool buttonEnabled: true
    readonly property bool pressed: mouse.pressed
    readonly property bool hovered: mouse.containsMouse
    signal clicked()

    // Inactive windows are gray until the group is hovered (macOS behaviour).
    readonly property bool colored: buttonEnabled && (windowActive || showGlyph)

    implicitWidth: diameter
    implicitHeight: diameter
    width: diameter
    height: diameter

    Rectangle {
        id: disc
        anchors.fill: parent
        radius: width / 2
        color: !btn.colored ? btn.inactiveColor
               : btn.pressed ? Qt.darker(btn.baseColor, 1.35)
               : btn.hovered ? Qt.lighter(btn.baseColor, 1.08)
               : btn.baseColor
        border.width: 1
        border.color: Qt.rgba(0, 0, 0, 0.18)
        Behavior on color { ColorAnimation { duration: 80 } }
    }

    // ---- Glyphs (shown on group hover) ----
    Item {
        id: glyphLayer
        anchors.fill: parent
        opacity: (btn.showGlyph && btn.colored) ? 0.85 : 0
        Behavior on opacity { NumberAnimation { duration: 80 } }

        // close: ×
        Item {
            anchors.fill: parent
            visible: btn.glyph === "close"
            Rectangle {
                anchors.centerIn: parent
                width: btn.diameter * 0.52; height: 1.4; radius: 0.7
                color: btn.glyphColor; rotation: 45
            }
            Rectangle {
                anchors.centerIn: parent
                width: btn.diameter * 0.52; height: 1.4; radius: 0.7
                color: btn.glyphColor; rotation: -45
            }
        }

        // minimize: −
        Rectangle {
            anchors.centerIn: parent
            visible: btn.glyph === "minimize"
            width: btn.diameter * 0.52; height: 1.4; radius: 0.7
            color: btn.glyphColor
        }

        // maximize/restore: two triangles (outward = maximize, inward = restore)
        Item {
            id: zoomGlyph
            anchors.fill: parent
            visible: btn.glyph === "maximize"
            readonly property real d: btn.diameter
            readonly property var triA: btn.glyphMaximized
                ? [[0.48, 0.48], [0.48, 0.27], [0.27, 0.48]]
                : [[0.27, 0.27], [0.27, 0.48], [0.48, 0.27]]
            readonly property var triB: btn.glyphMaximized
                ? [[0.52, 0.52], [0.52, 0.73], [0.73, 0.52]]
                : [[0.73, 0.73], [0.73, 0.52], [0.52, 0.73]]

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: btn.glyphColor; strokeColor: "transparent"; strokeWidth: 0
                    startX: zoomGlyph.triA[0][0] * zoomGlyph.d
                    startY: zoomGlyph.triA[0][1] * zoomGlyph.d
                    PathLine { x: zoomGlyph.triA[1][0] * zoomGlyph.d; y: zoomGlyph.triA[1][1] * zoomGlyph.d }
                    PathLine { x: zoomGlyph.triA[2][0] * zoomGlyph.d; y: zoomGlyph.triA[2][1] * zoomGlyph.d }
                    PathLine { x: zoomGlyph.triA[0][0] * zoomGlyph.d; y: zoomGlyph.triA[0][1] * zoomGlyph.d }
                }
                ShapePath {
                    fillColor: btn.glyphColor; strokeColor: "transparent"; strokeWidth: 0
                    startX: zoomGlyph.triB[0][0] * zoomGlyph.d
                    startY: zoomGlyph.triB[0][1] * zoomGlyph.d
                    PathLine { x: zoomGlyph.triB[1][0] * zoomGlyph.d; y: zoomGlyph.triB[1][1] * zoomGlyph.d }
                    PathLine { x: zoomGlyph.triB[2][0] * zoomGlyph.d; y: zoomGlyph.triB[2][1] * zoomGlyph.d }
                    PathLine { x: zoomGlyph.triB[0][0] * zoomGlyph.d; y: zoomGlyph.triB[0][1] * zoomGlyph.d }
                }
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: -btn.hitMargin
        hoverEnabled: true
        enabled: btn.buttonEnabled
        onClicked: btn.clicked()
    }
}
