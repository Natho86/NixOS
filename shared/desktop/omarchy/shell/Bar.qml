// Milestone 2: minimal bar. Workspaces, focused window title, network,
// audio, battery, clock. QML API verified against pinned nixpkgs quickshell
// source (not examples of unverified version) -- see:
//   src/wayland/hyprland/ipc/{qml.hpp,hyprland_toplevel.hpp} for Hyprland.*
//   src/services/upower/{core.hpp,device.hpp} for UPower.*
//   src/services/pipewire/qml.hpp for Pipewire.*
//   src/io/process.hpp, src/io/datastream.hpp for Process/StdioCollector
//
// Verified with `qmllint -I <quickshell>/lib/qt-6/qml -I <qtdeclarative>/lib/qt-6/qml`
// -- only remaining warnings are a known qmllint false positive on
// PanelWindow (a C++ plugin root type; instantiated correctly, matches
// upstream's own src/window/test/manual/panel.qml) and the id-qualification
// hints addressed below.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire

PanelWindow {
    id: bar

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Theme.barHeight
    color: Theme.background

    // Keeps the default audio sink's PwNode alive/bound so its properties
    // (volume, muted) update reactively. Confirmed pattern: PwObjectTracker.
    PwObjectTracker {
        objects: [ Pipewire.defaultAudioSink ]
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 16

        // Workspaces
        RowLayout {
            spacing: 6

            Repeater {
                model: Hyprland.workspaces

                Rectangle {
                    id: wsDelegate
                    required property HyprlandWorkspace modelData

                    width: 22
                    height: 22
                    radius: 4 // independent of Theme.rounding -- a small pill radius, not derived from the general corner rounding
                    color: wsDelegate.modelData.focused ? Theme.accent : Theme.overlay

                    Text {
                        anchors.centerIn: parent
                        text: wsDelegate.modelData.id
                        color: wsDelegate.modelData.focused ? Theme.background : Theme.foreground
                        font.pixelSize: 12
                    }

                    TapHandler {
                        // Hyprland.dispatch() sends its argument to be executed as
                        // `hl.dispatch(<argument>)` by Hyprland's Lua IPC (Hyprland
                        // >=0.55 deprecated hyprlang dispatcher strings here too, same
                        // as the config file -- see Milestone 1 notes). The argument
                        // must be the Lua source for a dispatcher call, e.g.
                        // "hl.dsp.focus({workspace=2})", not the old "workspace 2"
                        // string. Confirmed via runtime error message when the old
                        // syntax was tried: quickshell.hyprland.ipc logged
                        // `[string "return hl.dispatch(workspace 2)"]:1: ')' expected`.
                        onTapped: Hyprland.dispatch("hl.dsp.focus({workspace=" + wsDelegate.modelData.id + "})")
                    }
                }
            }
        }

        // Focused window title
        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            color: Theme.foreground
            elide: Text.ElideRight
            text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
        }

        // Network (nmcli, polled -- no fully-verified simple SSID/signal
        // property on Quickshell.Networking within this research pass)
        Text {
            id: networkText
            color: Theme.foreground
            font.pixelSize: 13
            text: "󰤨"

            Process {
                id: networkProc
                command: [ "nmcli", "-t", "-f", "active,ssid", "dev", "wifi" ]
                stdout: StdioCollector {
                    onStreamFinished: {
                        const line = text.split("\n").find(l => l.startsWith("yes:"));
                        networkText.text = line ? ("󰤨 " + line.slice(4)) : "󰤭";
                    }
                }
            }

            Timer {
                interval: 10000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: networkProc.exec(networkProc.command)
            }
        }

        // Audio
        Text {
            color: Theme.foreground
            font.pixelSize: 13
            text: {
                const sink = Pipewire.defaultAudioSink;
                if (!sink || !sink.audio) return "󰝟";
                if (sink.audio.muted) return "󰝟";
                return "󰕾 " + Math.round(sink.audio.volume * 100) + "%";
            }
        }

        // Battery
        Text {
            color: Theme.foreground
            font.pixelSize: 13
            visible: UPower.displayDevice && UPower.displayDevice.isLaptopBattery
            text: {
                const d = UPower.displayDevice;
                if (!d) return "";
                // UPowerDevice.percentage is a 0-1 fraction (energy /
                // energyCapacity), not 0-100, despite the property name --
                // confirmed against the pinned quickshell source's own doc
                // comment (src/services/upower/device.hpp: "This would be
                // equivalent to energy / energyCapacity"). Multiplying by
                // 100 was missing, so a real 74% battery rounded to "1%".
                const pct = Math.round(d.percentage * 100);
                const charging = d.state === UPowerDeviceState.Charging;
                return (charging ? "󰂄 " : "󰁹 ") + pct + "%";
            }
        }

        // Clock
        Text {
            id: clockText
            color: Theme.foreground
            font.pixelSize: 13

            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }

            text: Qt.formatDateTime(clock.date, "yyyy-MM-dd HH:mm")
        }
    }
}
