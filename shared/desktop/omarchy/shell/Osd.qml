// Milestone 3: volume/brightness OSD. Triggered externally via
// `qs -c omarchy ipc call osd showVolume <0-100>` / `showBrightness <0-100>`,
// called from Hyprland keybinds (see home.nix) after pactl/brightnessctl
// change the real value -- Quickshell has no native brightness service to
// bind reactively (confirmed: no Quickshell.Services.Brightness module
// exists in the pinned source tree), so this is push-based rather than the
// Bar's pull-based Pipewire/UPower bindings.
//
// IpcHandler API verified against pinned quickshell source
// (src/io/ipchandler.hpp doc comment, which includes a complete worked
// example matching this usage).
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: osdScope

    property int currentValue: 0
    property string currentIcon: ""
    property bool visible_: false

    IpcHandler {
        target: "osd"

        function showVolume(value: real): void {
            osdScope.currentValue = Math.round(value);
            osdScope.currentIcon = value > 0 ? "󰕾" : "󰝟";
            osdScope.visible_ = true;
            hideTimer.restart();
        }

        function showBrightness(value: real): void {
            osdScope.currentValue = Math.round(value);
            osdScope.currentIcon = "󰃟";
            osdScope.visible_ = true;
            hideTimer.restart();
        }
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: osdScope.visible_ = false
    }

    PanelWindow {
        anchors {
            bottom: true
        }

        margins {
            bottom: 80
        }

        implicitWidth: 220
        implicitHeight: 56
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        visible: osdScope.visible_

        Rectangle {
            anchors.fill: parent
            radius: 10
            color: "#1a1b26"
            border.color: "#414868"
            border.width: 1

            Row {
                anchors.centerIn: parent
                spacing: 10

                Text {
                    text: osdScope.currentIcon
                    color: "#c0caf5"
                    font.pixelSize: 20
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    width: 130
                    height: 8
                    radius: 4
                    color: "#414868"
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        width: parent.width * Math.min(osdScope.currentValue, 100) / 100
                        height: parent.height
                        radius: 4
                        color: "#7aa2f7"
                    }
                }

                Text {
                    text: osdScope.currentValue + "%"
                    color: "#c0caf5"
                    font.pixelSize: 13
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
