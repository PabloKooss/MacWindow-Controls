// WindowActions: executes close / minimize / maximize-restore on the window the tracker
// designated. The window is re-resolved by its winId at click time and verified; if it is
// gone (or its state changed), NOTHING is executed, so a different window is never touched.
import QtQuick

QtObject {
    id: actions

    required property var windowTracker

    function _resolve(what) {
        var winId = windowTracker.targetWinId;
        var row = windowTracker.rowForWinId(winId);
        if (row < 0) {
            console.log("[MacWindow] " + what + " ABORTED: window " + winId + " is no longer in the model");
            windowTracker.refresh();
            return null;
        }
        return { row: row, index: windowTracker.tasksModel.makeModelIndex(row), winId: winId };
    }

    function close() {
        var t = _resolve("close");
        if (t === null) return;
        console.log("[MacWindow] close -> " + t.winId);
        windowTracker.tasksModel.requestClose(t.index);
    }

    function minimize() {
        var t = _resolve("minimize");
        if (t === null) return;
        console.log("[MacWindow] minimize -> " + t.winId);
        windowTracker.tasksModel.requestToggleMinimized(t.index);
    }

    // Toggles maximize/restore. The button shows what the user saw (tracker.targetMaximized);
    // if the real state changed in the meantime, toggling would do the opposite of what was
    // displayed, so abort instead.
    function toggleMaximize() {
        var t = _resolve("maximize/restore");
        if (t === null) return;
        var nowMaximized = windowTracker.roleAt(t.row, windowTracker.atm.IsMaximized) === true;
        if (nowMaximized !== windowTracker.targetMaximized) {
            console.log("[MacWindow] maximize/restore ABORTED: state of " + t.winId + " changed (now maximized=" + nowMaximized + ")");
            windowTracker.refresh();
            return;
        }
        console.log("[MacWindow] " + (nowMaximized ? "restore" : "maximize") + " -> " + t.winId);
        windowTracker.tasksModel.requestToggleMaximized(t.index);
    }
}
