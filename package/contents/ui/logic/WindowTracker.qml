// WindowTracker: decides which window the panel controls represent (Option B).
//
// Policy (Option B):
//   1. If the active window is maximized -> it is the target.
//   2. Else, if any non-minimized maximized window exists on this screen -> the TOPMOST one
//      (highest StackingOrder; LastActivated breaks ties) is the target.
//   3. Else, fall back to the active window (mode "active-fallback").
//   4. Else, no target.
//
// Detection only. Window actions live in WindowActions.qml.
import QtQuick
import org.kde.plasma.plasmoid
import org.kde.taskmanager as TaskManager

Item {
    id: tracker
    visible: false

    // ---- Public, read-only state ----
    property int    targetRow: -1            // row in tasksModel at the last refresh
    property bool   hasTarget: false
    property bool   targetMaximized: false
    property bool   targetActive: false
    property bool   targetClosable: true
    property bool   targetMinimizable: true
    property bool   targetMaximizable: true
    property string targetTitle: ""
    property string targetWinId: ""
    property string mode: "none"             // "maximized" | "active-fallback" | "none"
    property int    maximizedCount: 0
    property int    windowCount: 0

    readonly property var atm: TaskManager.AbstractTasksModel
    readonly property alias tasksModel: tasksModel

    TaskManager.VirtualDesktopInfo { id: virtualDesktopInfo }
    TaskManager.ActivityInfo { id: activityInfo }

    TaskManager.TasksModel {
        id: tasksModel
        groupMode: TaskManager.TasksModel.GroupDisabled
        filterByVirtualDesktop: true
        filterByScreen: true
        filterByActivity: !Plasmoid.configuration.allActivities
        virtualDesktop: virtualDesktopInfo.currentDesktop
        activity: activityInfo.currentActivity
        screenGeometry: Plasmoid.containment.screenGeometry

        // The model state is asynchronous: coalesce bursts into one refresh.
        onDataChanged: Qt.callLater(tracker.refresh)
        onCountChanged: Qt.callLater(tracker.refresh)
        onModelReset: Qt.callLater(tracker.refresh)
        onLayoutChanged: Qt.callLater(tracker.refresh)
    }

    function roleAt(row, role) {
        return tasksModel.data(tasksModel.makeModelIndex(row), role);
    }

    // Diagnostic helper: role looked up by name, tolerant of roles missing in this Plasma build.
    function safeRole(row, name) {
        var r = atm[name];
        return (r === undefined) ? "n/a" : String(roleAt(row, r));
    }

    // Numeric value of a role looked up by name; -1 if the role is missing or not numeric.
    function numRole(row, name) {
        var r = atm[name];
        if (r === undefined) return -1;
        var n = Number(roleAt(row, r));
        return isNaN(n) ? -1 : n;
    }

    // Row of the window with this winId (stable UUID on Wayland), or -1 if it is gone.
    function rowForWinId(winId) {
        if (winId === "") return -1;
        var n = tasksModel.count;
        for (var i = 0; i < n; ++i) {
            if (roleAt(i, atm.IsWindow) !== true) continue;
            var ids = roleAt(i, atm.WinIdList);
            if (ids && ids.length > 0 && String(ids[0]) === winId) return i;
        }
        return -1;
    }

    function refresh() {
        var n = tasksModel.count;
        var activeRow = -1;
        var topMaxRow = -1, topStack = -1, topLast = -1;
        var maxCount = 0;
        var winCount = 0;
        var cands = [];

        for (var i = 0; i < n; ++i) {
            if (roleAt(i, atm.IsWindow) !== true) continue;
            if (roleAt(i, atm.IsMinimized) === true) continue;
            winCount++;
            if (roleAt(i, atm.IsActive) === true) activeRow = i;
            if (roleAt(i, atm.IsMaximized) === true) {
                maxCount++;
                var st = numRole(i, "StackingOrder");
                var la = numRole(i, "LastActivated");
                if (topMaxRow < 0 || st > topStack || (st === topStack && la > topLast)) {
                    topMaxRow = i; topStack = st; topLast = la;
                }
                cands.push(i + ":stack=" + st + ":lastAct=" + la);
            }
        }

        var row = -1;
        var newMode = "none";
        if (activeRow >= 0 && roleAt(activeRow, atm.IsMaximized) === true) {
            row = activeRow; newMode = "maximized";
        } else if (topMaxRow >= 0) {
            row = topMaxRow; newMode = "maximized";
        } else if (activeRow >= 0) {
            row = activeRow; newMode = "active-fallback";
        }

        var winId = "";
        var title = "";
        var isMax = false;
        var isActive = false;
        var canClose = true, canMin = true, canMax = true;
        if (row >= 0) {
            title = String(roleAt(row, Qt.DisplayRole));
            var ids = roleAt(row, atm.WinIdList);
            winId = (ids && ids.length > 0) ? String(ids[0]) : "";
            isMax = roleAt(row, atm.IsMaximized) === true;
            isActive = roleAt(row, atm.IsActive) === true;
            canClose = roleAt(row, atm.IsClosable) === true;
            canMin = roleAt(row, atm.IsMinimizable) === true;
            canMax = roleAt(row, atm.IsMaximizable) === true;
        }

        var changed = (row !== targetRow) || (newMode !== mode) || (winId !== targetWinId)
                      || (isMax !== targetMaximized) || (isActive !== targetActive)
                      || (maxCount !== maximizedCount) || (winCount !== windowCount);

        targetRow = row;
        hasTarget = row >= 0;
        mode = newMode;
        targetTitle = title;
        targetWinId = winId;
        targetMaximized = isMax;
        targetActive = isActive;
        targetClosable = canClose;
        targetMinimizable = canMin;
        targetMaximizable = canMax;
        maximizedCount = maxCount;
        windowCount = winCount;

        if (changed) {
            console.log("[MacWindow] mode=" + mode + " row=" + row + " winId=" + winId
                        + " maximized=" + isMax + " active=" + isActive
                        + " maxCount=" + maxCount + " windows=" + winCount
                        + " cands=[" + cands.join(" | ") + "]"
                        + " title=" + title);
        }
    }

    Component.onCompleted: Qt.callLater(refresh)
}
