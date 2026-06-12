import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Notification backend: makes Quickshell the system notification server
// (replacing dunst). Holds DND state, keeps a live tracked list for the
// control-center list, and fires popup() for transient toasts.
Item {
    id: svc

    // Do Not Disturb: notifications still arrive and are tracked, but no toast.
    property bool dnd: false

    // Suppress on-screen toasts (e.g. while the control center is open, where
    // the notification already appears in the list). Tracking still happens.
    property bool suppressPopups: false

    // Live model of notifications retained for the sidebar list.
    readonly property var list: server.trackedNotifications

    // Emitted when a freshly-arrived notification should toast (respects DND).
    signal popup(var n)

    // Arrival times keyed by notification id, for relative timestamps.
    property var times: ({})

    NotificationServer {
        id: server
        keepOnReload: false
        imageSupported: true
        actionsSupported: true
        bodySupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true

        onNotification: function (n) {
            n.tracked = true;            // retain past its timeout for the list
            svc.times[n.id] = Date.now();
            if (!svc.dnd && !svc.suppressPopups) svc.popup(n);
        }
    }

    function timeOf(n) { return svc.times[n.id] || Date.now(); }

    // Dismiss everything in the list.
    function dismissAll() {
        const items = server.trackedNotifications.values.slice();
        for (var i = 0; i < items.length; i++) items[i].dismiss();
    }
}
