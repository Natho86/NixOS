// Milestone 3: minimal notification popups. Claims org.freedesktop.Notifications
// on the session bus so notify-send (used by screenshot.nix and, later, OSDs)
// doesn't hang waiting for D-Bus activation with no daemon present -- confirmed
// live: no service owned org.freedesktop.Notifications before this, and
// notify-send blocked for tens of seconds as a result.
//
// API verified against pinned quickshell source: src/services/notifications/
// {qml.hpp,notification.hpp} -- NotificationServer.notification(Notification*)
// signal, Notification.{summary,body,appName,urgency,expireTimeout}, and
// .dismiss()/.expire() invokables.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications

Scope {
    NotificationServer {
        id: notifServer
        keepOnReload: false
        bodySupported: true
        actionsSupported: false
        imageSupported: false

        onNotification: notification => {
            notification.tracked = true;
            popupTimer.createObject(notifWindow, { notification: notification });
        }
    }

    Component {
        id: popupTimer
        Timer {
            // `notification` is set via createObject's initial-properties
            // argument, but QML does not guarantee that assignment
            // completes before this binding's first evaluation -- guard
            // against the resulting transient null (observed live:
            // "TypeError: Cannot read property 'expireTimeout' of null").
            required property Notification notification
            interval: notification && notification.expireTimeout > 0 ? notification.expireTimeout : 5000
            running: true
            onTriggered: {
                if (notification) notification.expire();
                destroy();
            }
        }
    }

    PanelWindow {
        id: notifWindow

        anchors {
            top: true
            right: true
        }

        margins {
            top: 40
            right: 8
        }

        implicitWidth: 320
        implicitHeight: notifColumn.implicitHeight
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        ColumnLayout {
            id: notifColumn
            anchors.right: parent.right
            anchors.top: parent.top
            width: 320
            spacing: 6

            Repeater {
                model: notifServer.trackedNotifications

                Rectangle {
                    id: notifDelegate
                    required property Notification modelData

                    Layout.fillWidth: true
                    implicitHeight: notifContent.implicitHeight + 20
                    radius: Theme.rounding
                    color: Theme.background
                    border.color: Theme.border
                    border.width: 1

                    ColumnLayout {
                        id: notifContent
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 4

                        Text {
                            Layout.fillWidth: true
                            text: notifDelegate.modelData.summary
                            color: Theme.foreground
                            font.bold: true
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: notifDelegate.modelData.body.length > 0
                            text: notifDelegate.modelData.body
                            color: "#a9b1d6"
                            font.pixelSize: 12
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }
                    }

                    TapHandler {
                        onTapped: notifDelegate.modelData.dismiss()
                    }
                }
            }
        }
    }
}
