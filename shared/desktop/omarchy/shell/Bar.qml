// Milestone 2 base + top-bar Omarchy-parity pass. Workspaces, focused
// window title, menu/launcher, system tray, bluetooth, network, audio,
// keyboard layout, battery, clock -- plus click-popups for
// audio/network/bluetooth. QML API verified against pinned nixpkgs
// quickshell source (not examples of unverified version) -- see:
//   src/wayland/hyprland/ipc/{qml.hpp,hyprland_toplevel.hpp} for Hyprland.*
//   src/services/upower/{core.hpp,device.hpp} for UPower.*
//   src/services/pipewire/qml.hpp for Pipewire.*
//   src/services/status_notifier/{qml.hpp,item.hpp} for SystemTray.*
//   src/bluetooth/{bluez.hpp,adapter.hpp,device.hpp} for Bluetooth.*
//   src/network/{qml.hpp,device.hpp,network.hpp,wifi.hpp} for Networking.*
//
// Verified with `qmllint -I <quickshell>/lib/qt-6/qml -I <qtdeclarative>/lib/qt-6/qml`
// -- only remaining warnings are a known qmllint false positive on
// PanelWindow (a C++ plugin root type; instantiated correctly, matches
// upstream's own src/window/test/manual/panel.qml) and the id-qualification
// hints addressed below.
//
// Module order (left to right) follows upstream Omarchy's own right-section
// ordering (github.com/omacom/omarchy, config/omarchy/shell.json, MIT
// licensed) where our modules map to theirs: tray, bluetooth, network,
// audio, keyboard-layout, battery. Weather/agents/AI-usage widgets and the
// full plugin/popup system are out of scope -- see
// omarchy-inspired-nixos-plan.md's top-bar pass notes.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Bluetooth
import Quickshell.Networking

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

    // The Wi-Fi device, if any -- resolved from Networking.devices.values.
    // UntypedObjectModel (Networking.devices' real type) exposes `values`
    // (a reactive QList<QObject*>/JS array), not `count`/`get()` -- those
    // don't exist on this type at all, confirmed against its own doc
    // comment in src/core/model.hpp ("the same information ... is
    // available as a normal list via the `values` property... property
    // binding [using] model.values[3] will update reactively"). Using
    // .values here, not the internal QAbstractListModel row API.
    // DeviceType.Wifi confirmed against src/network/enums.hpp.
    property var wifiDevice: {
        const devices = Networking.devices.values;
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].type === DeviceType.Wifi) return devices[i];
        }
        return null;
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: Theme.gapsIn

        // Menu/launcher button. Left-click opens the same combi launcher
        // SUPER+SPACE does (home.nix's `menu` local var); right-click opens
        // a new terminal -- matching upstream's omarchy.menu bar-widget
        // click behaviour (left = open menu, right = open terminal).
        Text {
            color: Theme.accent
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontMonoFamily
            text: "󰣇"

            TapHandler {
                acceptedButtons: Qt.LeftButton
                onTapped: Hyprland.dispatch("hl.dsp.exec_cmd('rofi -show combi')")
            }
            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: Hyprland.dispatch("hl.dsp.exec_cmd('alacritty')")
            }
        }

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
            font.family: Theme.fontFamily
            elide: Text.ElideRight
            text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
        }

        // System tray. StatusNotifierItem API (icon/title/activate/
        // secondaryActivate/hasMenu/menu/display) confirmed against
        // src/services/status_notifier/item.hpp.
        RowLayout {
            spacing: 8

            Repeater {
                model: SystemTray.items

                Image {
                    id: trayDelegate
                    // The C++ class is StatusNotifierItem, but its real
                    // QML-exposed name is SystemTrayItem
                    // (QML_NAMED_ELEMENT(SystemTrayItem), item.hpp) --
                    // found live via `qs` erroring "StatusNotifierItem is
                    // not a type", not caught by the class-name-based
                    // comment above until then.
                    required property SystemTrayItem modelData

                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    source: trayDelegate.modelData.icon
                    sourceSize: Qt.size(16, 16)

                    // Left-click activates (or opens the menu if that's all
                    // the item offers); right-click explicitly opens the
                    // context menu when one exists -- the common desktop
                    // convention. secondaryActivate() is deliberately not
                    // wired to right-click: its own doc comment
                    // (item.hpp) says it's "generally triggered via a
                    // middle click," not right-click, and middle-click
                    // tray actions aren't common/valuable enough here to
                    // add a third TapHandler for.
                    TapHandler {
                        acceptedButtons: Qt.LeftButton
                        onTapped: {
                            if (trayDelegate.modelData.hasMenu) {
                                trayDelegate.modelData.display(bar, trayDelegate.x, trayDelegate.y + bar.height);
                            } else {
                                trayDelegate.modelData.activate();
                            }
                        }
                    }
                    TapHandler {
                        acceptedButtons: Qt.RightButton
                        onTapped: {
                            if (trayDelegate.modelData.hasMenu) {
                                trayDelegate.modelData.display(bar, trayDelegate.x, trayDelegate.y + bar.height);
                            }
                        }
                    }
                }
            }
        }

        // Bluetooth. BluezQml singleton (Bluetooth), defaultAdapter.enabled
        // is writable -- click toggles the radio. Popup lists paired
        // devices. API confirmed against src/bluetooth/{bluez,adapter,device}.hpp.
        Text {
            id: bluetoothIcon
            color: Theme.foreground
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontMonoFamily
            text: {
                const a = Bluetooth.defaultAdapter;
                if (!a || !a.enabled) return "󰂲";
                return "󰂯";
            }

            TapHandler {
                onTapped: bluetoothPopup.visible = !bluetoothPopup.visible
            }

            BarPopup {
                id: bluetoothPopup
                anchorItem: bluetoothIcon
                popupWidth: 260
                popupHeight: Math.max(120, 40 + (Bluetooth.devices ? Bluetooth.devices.values.length * 32 : 0))
                visible: false

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Bluetooth"
                            color: Theme.foreground
                            font.pixelSize: Theme.fontSize
                            Layout.fillWidth: true
                        }
                        Text {
                            text: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? "On" : "Off"
                            color: Theme.accent
                            font.pixelSize: Theme.fontSize

                            TapHandler {
                                onTapped: {
                                    const a = Bluetooth.defaultAdapter;
                                    if (a) a.enabled = !a.enabled;
                                }
                            }
                        }
                    }

                    Repeater {
                        model: Bluetooth.devices

                        RowLayout {
                            id: btDelegate
                            required property BluetoothDevice modelData
                            Layout.fillWidth: true

                            Text {
                                text: btDelegate.modelData.name
                                color: Theme.foreground
                                font.pixelSize: Theme.fontSize
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            Text {
                                text: btDelegate.modelData.connected ? "󰂱" : "󰂯"
                                color: btDelegate.modelData.connected ? Theme.accent : Theme.muted
                                font.pixelSize: Theme.fontSize

                                TapHandler {
                                    onTapped: {
                                        if (btDelegate.modelData.connected) {
                                            btDelegate.modelData.disconnect();
                                        } else {
                                            btDelegate.modelData.connect();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Network. Replaces the earlier nmcli-polling implementation with
        // Quickshell's real reactive Networking API (NetworkManager-backed,
        // confirmed via src/network/nm/* -- this is the same backend this
        // repo actually uses, unlike impala's iwd-only assumption found
        // earlier). wifiDevice resolved once above.
        Text {
            id: networkIcon
            color: Theme.foreground
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontMonoFamily
            text: {
                const d = bar.wifiDevice;
                if (!d) return "󰤭";
                if (!d.connected) return "󰤭";
                return "󰤨";
            }

            TapHandler {
                onTapped: networkPopup.visible = !networkPopup.visible
            }

            BarPopup {
                id: networkPopup
                anchorItem: networkIcon
                popupWidth: 280
                popupHeight: 240
                visible: false

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 6

                    Text {
                        text: "Wi-Fi"
                        color: Theme.foreground
                        font.pixelSize: Theme.fontSize
                    }

                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentHeight: networkList.implicitHeight
                        clip: true

                        ColumnLayout {
                            id: networkList
                            width: parent.width
                            spacing: 4

                            Repeater {
                                model: bar.wifiDevice ? bar.wifiDevice.networks : null

                                RowLayout {
                                    id: netDelegate
                                    required property WifiNetwork modelData
                                    Layout.fillWidth: true

                                    Text {
                                        text: netDelegate.modelData.name
                                        color: netDelegate.modelData.connected ? Theme.accent : Theme.foreground
                                        font.pixelSize: Theme.fontSize
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        text: Math.round(netDelegate.modelData.signalStrength) + "%"
                                        color: Theme.muted
                                        font.pixelSize: Theme.fontSize

                                        TapHandler {
                                            // Network.connect() (base class,
                                            // confirmed in src/network/network.hpp)
                                            // connects using already-saved
                                            // credentials -- correct for a
                                            // known/previously-connected
                                            // network. A new, unsaved secured
                                            // network needs
                                            // WifiNetwork.connectWithPsk(),
                                            // not built here per the plan's
                                            // own scope note (no password-entry
                                            // flow in this pass).
                                            onTapped: {
                                                if (!netDelegate.modelData.connected) {
                                                    netDelegate.modelData.connect();
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Audio
        Text {
            id: audioIcon
            color: Theme.foreground
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontMonoFamily
            text: {
                const sink = Pipewire.defaultAudioSink;
                if (!sink || !sink.audio) return "󰝟";
                if (sink.audio.muted) return "󰝟";
                return "󰕾 " + Math.round(sink.audio.volume * 100) + "%";
            }

            TapHandler {
                onTapped: audioPopup.visible = !audioPopup.visible
            }

            BarPopup {
                id: audioPopup
                anchorItem: audioIcon
                popupWidth: 260
                popupHeight: 90
                visible: false

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: {
                                const sink = Pipewire.defaultAudioSink;
                                return (sink && sink.audio && sink.audio.muted) ? "󰝟" : "󰕾";
                            }
                            color: Theme.foreground
                            font.pixelSize: Theme.fontSize

                            TapHandler {
                                onTapped: {
                                    const sink = Pipewire.defaultAudioSink;
                                    if (sink && sink.audio) sink.audio.muted = !sink.audio.muted;
                                }
                            }
                        }

                        // Hand-built slider, not QtQuick.Controls' Slider --
                        // confirmed unavailable: the only qtquickcontrols2
                        // packages in this system are Qt 5.15.19 (an
                        // unrelated dependency elsewhere on the system),
                        // while Quickshell itself is built against Qt
                        // 6.11.2 and its own package's Nix references
                        // (`nix-store -q --references`) include no
                        // qtquickcontrols2 at all. Same visual language as
                        // Osd.qml's existing volume bar (Theme.overlay
                        // track, Theme.accent fill), made interactive with
                        // Tap/DragHandler instead of Controls.
                        Rectangle {
                            id: volumeTrack
                            Layout.fillWidth: true
                            Layout.preferredHeight: 8
                            radius: 4
                            color: Theme.overlay

                            property real value: {
                                const sink = Pipewire.defaultAudioSink;
                                return (sink && sink.audio) ? sink.audio.volume : 0;
                            }

                            function setFromX(x: real): void {
                                const sink = Pipewire.defaultAudioSink;
                                if (!sink || !sink.audio) return;
                                sink.audio.volume = Math.max(0, Math.min(1, x / volumeTrack.width));
                            }

                            Rectangle {
                                width: parent.width * Math.min(volumeTrack.value, 1)
                                height: parent.height
                                radius: 4
                                color: Theme.accent
                            }

                            TapHandler {
                                onTapped: volumeTrack.setFromX(point.position.x)
                            }
                            DragHandler {
                                // DragHandler's prototype is
                                // QQuickMultiPointHandler, not
                                // QQuickSinglePointHandler (confirmed
                                // directly in QtQuick's own plugins.qmltypes:
                                // DragHandler's Component entry says
                                // `prototype: "QQuickMultiPointHandler"`),
                                // so it exposes `centroid`/`centroidChanged`,
                                // not `point`/`pointChanged` -- despite
                                // being conceptually a single-point drag.
                                // An earlier attempt at this used `point`
                                // based on a misread of a different
                                // Component entry at a nearby file offset;
                                // caught live via `qs` erroring "Cannot
                                // assign to non-existent property
                                // onPointChanged", not caught by re-reading
                                // the header comments alone.
                                target: null
                                onCentroidChanged: if (active) volumeTrack.setFromX(centroid.position.x)
                            }
                        }

                        Text {
                            text: {
                                const sink = Pipewire.defaultAudioSink;
                                return (sink && sink.audio) ? Math.round(sink.audio.volume * 100) + "%" : "";
                            }
                            color: Theme.foreground
                            font.pixelSize: Theme.fontSize
                        }
                    }
                }
            }
        }

        // Keyboard layout. No native Quickshell keyboard-layout type exists
        // (confirmed: no keyboard/layout source files in the pinned tree).
        // Only one layout ("gb", home.nix's kb_layout) is configured with
        // no switch bind, so this is a static label, not reactive -- it
        // becomes meaningful once a second layout + switch bind exist.
        Text {
            color: Theme.foreground
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontMonoFamily
            text: "GB"
        }

        // Battery
        Text {
            color: Theme.foreground
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontMonoFamily
            visible: UPower.displayDevice && UPower.displayDevice.isLaptopBattery
            text: {
                const d = UPower.displayDevice;
                if (!d) return "";
                // UPowerDevice.percentage is a 0-1 fraction (energy /
                // energyCapacity), not 0-100, despite the property name --
                // confirmed against the pinned quickshell source's own doc
                // comment (src/services/upower/device.hpp: "This would be
                // equivalent to energy / energyCapacity").
                const pct = Math.round(d.percentage * 100);
                const charging = d.state === UPowerDeviceState.Charging;
                return (charging ? "󰂄 " : "󰁹 ") + pct + "%";
            }
        }

        // Clock
        Text {
            id: clockText
            color: Theme.foreground
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontMonoFamily

            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }

            text: Qt.formatDateTime(clock.date, "yyyy-MM-dd HH:mm")
        }
    }
}
