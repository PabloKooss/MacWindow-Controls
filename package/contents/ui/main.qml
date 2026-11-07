// MacWindow Controls - panel widget with macOS-style window controls.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import "logic"
import "components"

PlasmoidItem {
    id: root

    // Show the full representation directly in the panel (no popup), without a frame.
    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    // Buttons only make sense in a horizontal panel.
    readonly property bool isVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    // Animation duration from the settings (0 = no animation).
    readonly property int animMs: Plasmoid.configuration.animationEnabled ? Plasmoid.configuration.animationDuration : 0
    // While the panel is being edited the widget must stay grabbable even when "hidden".
    readonly property bool editMode: Plasmoid.containment.corona?.editMode === true

    Component.onCompleted: {
        var g = Plasmoid.containment.screenGeometry;
        var c = Plasmoid.configuration;
        console.log("[MacWindow] loaded: build 0.7.0 vertical=" + isVertical
                    + " screen=" + g.x + "," + g.y + " " + g.width + "x" + g.height
                    + " cfg{controlsEnabled=" + c.controlsEnabled + " size=" + c.buttonSize + " spacing=" + c.buttonSpacing
                    + " anim=" + c.animationEnabled + "/" + c.animationDuration + "ms"
                    + " onlyMax=" + c.onlyWhenMaximized + " allActivities=" + c.allActivities + "}");
    }

    WindowTracker { id: tracker }
    WindowActions { id: actions; windowTracker: tracker }

    fullRepresentation: Item {
        id: container

        // Visible when enabled, in a horizontal panel, with a target window that is maximized
        // (or any target window if "only when maximized" is turned off).
        readonly property bool shown: Plasmoid.configuration.controlsEnabled && !root.isVertical && tracker.hasTarget
                                      && (!Plasmoid.configuration.onlyWhenMaximized || tracker.targetMaximized)
        readonly property real pad: Kirigami.Units.smallSpacing
        readonly property real editMinSize: Kirigami.Units.gridUnit * 2

        // Collapse the applet width when hidden so it leaves no gap in the panel.
        property real contentWidth: shown ? lights.implicitWidth + 2 * pad : 0
        Behavior on contentWidth { NumberAnimation { duration: root.animMs; easing.type: Easing.OutCubic } }
        readonly property real effectiveWidth: root.editMode ? Math.max(contentWidth, editMinSize) : contentWidth

        implicitWidth: effectiveWidth
        implicitHeight: (root.isVertical && root.editMode) ? editMinSize : 0
        Layout.minimumWidth: effectiveWidth
        Layout.preferredWidth: effectiveWidth
        Layout.maximumWidth: effectiveWidth

        // Edit-mode placeholder so the widget can be selected, moved or removed.
        Rectangle {
            anchors.fill: parent
            visible: root.editMode
            radius: 4
            color: Kirigami.Theme.highlightColor
            opacity: 0.25
        }

        TrafficLights {
            id: lights
            anchors.left: parent.left
            anchors.leftMargin: container.pad
            anchors.verticalCenter: parent.verticalCenter

            shown: container.shown
            buttonSize: Plasmoid.configuration.buttonSize
            buttonSpacing: Plasmoid.configuration.buttonSpacing
            animationDuration: root.animMs
            windowActive: tracker.targetActive
            windowMaximized: tracker.targetMaximized
            canClose: tracker.targetClosable
            canMinimize: tracker.targetMinimizable
            canMaximize: tracker.targetMaximizable

            onCloseClicked: actions.close()
            onMinimizeClicked: actions.minimize()
            onMaximizeClicked: actions.toggleMaximize()
        }
    }
}
