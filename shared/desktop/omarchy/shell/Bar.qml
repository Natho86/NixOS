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
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Bluetooth
import Quickshell.Networking
import "./WeatherIcons.js" as WeatherIcons

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

        // Weather. Ported from upstream Omarchy's own weather widget
        // (shell/plugins/panels/weather/{Panel.qml,Model.js},
        // github.com/omacom/omarchy, MIT licensed, quattro branch) at the
        // user's explicit request, scoped down: current conditions + 3-day
        // forecast only, no live location-search-and-edit UI (upstream's
        // debounced geocoding search field) -- location is resolved once
        // and cached, matching the plan's own trimmed scope. Both backend
        // APIs are free/keyless, confirmed via upstream's own backend
        // scripts: wttr.in for IP geolocation (`?format=%l`), Open-Meteo
        // for forecast + geocoding.
        Text {
            id: weatherIcon
            color: Theme.foreground
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontMonoFamily
            visible: weatherData.current !== null
            text: {
                if (!weatherData.current) return "";
                return WeatherIcons.iconForOpenMeteoCode(weatherData.current.weatherCode, weatherData.current.isDay === 0) + " " + weatherData.current.temp + "°";
            }

            TapHandler {
                onTapped: weatherPopup.visible = !weatherPopup.visible
            }

            // Cached {name, latitude, longitude} so location resolution
            // (one wttr.in call + one Open-Meteo geocoding call) only
            // happens once, not on every shell restart -- same state-file
            // convention as the rest of this repo
            // (~/.local/state/omarchy/...).
            FileView {
                id: locationCache
                path: Quickshell.env("HOME") + "/.local/state/omarchy/weather-location.json"
                watchChanges: false
                // preload defaults to true (confirmed in fileview.hpp),
                // so the file starts loading as soon as `path` is set --
                // no manual reload() needed on completion.

                // A missing file (first run, no cache yet) is a load
                // *error*, not a successful empty load -- `loaded`
                // (NOTIFY loadedOrAsyncChanged) only reflects success, so
                // relying on onLoadedChanged alone would mean the
                // fallback resolution path (locationProc) never runs on
                // first launch. loadFailed is the real signal for this
                // case, confirmed via fileview.hpp's own
                // `void loadFailed(qs::io::FileViewError::Enum error)`.
                onLoadFailed: (error) => locationProc.running = true

                onLoadedChanged: {
                    if (!loaded) return;
                    try {
                        const cached = JSON.parse(text());
                        if (cached && cached.latitude !== undefined && cached.longitude !== undefined) {
                            weatherData.latitude = cached.latitude;
                            weatherData.longitude = cached.longitude;
                            forecastProc.running = true;
                            return;
                        }
                    } catch (e) {
                        // Cache exists but is malformed -- fall through to resolve.
                    }
                    locationProc.running = true;
                }
            }

            QtObject {
                id: weatherData
                property real latitude: 0
                property real longitude: 0
                property var current: null
                property var forecast: []
            }

            Process {
                id: locationProc
                command: ["curl", "-fsS", "--max-time", "4", "https://wttr.in/?format=%l"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        const name = text.trim().split(",")[0];
                        if (!name) return;
                        geocodeProc.command = ["curl", "-fsS", "--max-time", "4", "https://geocoding-api.open-meteo.com/v1/search?name=" + encodeURIComponent(name) + "&count=1&language=en&format=json"];
                        geocodeProc.running = true;
                    }
                }
            }

            Process {
                id: geocodeProc
                stdout: StdioCollector {
                    onStreamFinished: {
                        try {
                            const data = JSON.parse(text);
                            const result = data.results && data.results[0];
                            if (!result) return;
                            weatherData.latitude = result.latitude;
                            weatherData.longitude = result.longitude;
                            locationCache.setText(JSON.stringify({ name: result.name, latitude: result.latitude, longitude: result.longitude }));
                            forecastProc.running = true;
                        } catch (e) {
                            // Geocoding failed -- weather stays hidden
                            // (weatherIcon.visible is gated on
                            // weatherData.current, which never gets set).
                        }
                    }
                }
            }

            Process {
                id: forecastProc
                command: [
                    "curl", "-fsS", "--max-time", "5",
                    "https://api.open-meteo.com/v1/forecast?latitude=" + weatherData.latitude
                        + "&longitude=" + weatherData.longitude
                        + "&daily=weather_code,temperature_2m_max,temperature_2m_min"
                        + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code,is_day"
                        + "&forecast_days=4&timezone=auto"
                ]
                stdout: StdioCollector {
                    onStreamFinished: {
                        try {
                            const data = JSON.parse(text);
                            if (data.current) {
                                weatherData.current = {
                                    temp: Math.round(data.current.temperature_2m),
                                    feelsLike: Math.round(data.current.apparent_temperature),
                                    humidity: Math.round(data.current.relative_humidity_2m),
                                    windKmh: Math.round(data.current.wind_speed_10m),
                                    weatherCode: data.current.weather_code,
                                    isDay: data.current.is_day
                                };
                            }
                            if (data.daily && data.daily.time) {
                                const days = [];
                                const today = new Date().toISOString().slice(0, 10);
                                for (let i = 0; i < data.daily.time.length && days.length < 3; i++) {
                                    if (data.daily.time[i] <= today) continue;
                                    days.push({
                                        date: data.daily.time[i],
                                        max: Math.round(data.daily.temperature_2m_max[i]),
                                        min: Math.round(data.daily.temperature_2m_min[i]),
                                        weatherCode: data.daily.weather_code[i]
                                    });
                                }
                                weatherData.forecast = days;
                            }
                        } catch (e) {
                            // Malformed/empty response -- keep last-known
                            // weatherData.current rather than clearing it.
                        }
                    }
                }
            }

            Timer {
                interval: 15 * 60 * 1000
                running: weatherData.latitude !== 0 || weatherData.longitude !== 0
                repeat: true
                onTriggered: forecastProc.running = true
            }

            BarPopup {
                id: weatherPopup
                anchorItem: weatherIcon
                popupWidth: 280
                popupHeight: 200
                visible: false

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: weatherData.current ? WeatherIcons.iconForOpenMeteoCode(weatherData.current.weatherCode, weatherData.current.isDay === 0) : ""
                            color: Theme.foreground
                            font.pixelSize: Theme.fontSizeLarge
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                text: weatherData.current ? weatherData.current.temp + "°C" : "--"
                                color: Theme.foreground
                                font.pixelSize: Theme.fontSizeLarge
                                font.bold: true
                            }
                            Text {
                                text: weatherData.current ? "Feels " + weatherData.current.feelsLike + "° · " + weatherData.current.humidity + "% · " + weatherData.current.windKmh + " km/h" : ""
                                color: Theme.muted
                                font.pixelSize: Theme.fontSize - 2
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Theme.overlay
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Repeater {
                            model: weatherData.forecast

                            ColumnLayout {
                                id: forecastDay
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: {
                                        const d = new Date(forecastDay.modelData.date + "T12:00:00");
                                        return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][d.getDay()];
                                    }
                                    color: Theme.muted
                                    font.pixelSize: Theme.fontSize - 2
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    text: WeatherIcons.iconForOpenMeteoCode(forecastDay.modelData.weatherCode, false)
                                    color: Theme.foreground
                                    font.pixelSize: Theme.fontSize
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    text: forecastDay.modelData.max + "° / " + forecastDay.modelData.min + "°"
                                    color: Theme.foreground
                                    font.pixelSize: Theme.fontSize - 2
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }
                    }
                }
            }
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

                            // BluetoothDeviceState (confirmed real:
                            // Disconnected=0, Connected=1, Disconnecting=2,
                            // Connecting=3 -- src/bluetooth/device.hpp) gives
                            // a real in-progress state, unlike the plain
                            // `connected` boolean this used before -- fixes
                            // the reported "delay could be mistaken for
                            // nothing happening" by showing a distinct
                            // connecting/disconnecting icon and disabling
                            // the click target while a transition is in
                            // flight (so a second click can't fire a
                            // redundant connect()/disconnect() mid-transition).
                            readonly property bool isTransitioning: btDelegate.modelData.state === BluetoothDeviceState.Connecting || btDelegate.modelData.state === BluetoothDeviceState.Disconnecting

                            Text {
                                text: btDelegate.modelData.name
                                color: Theme.foreground
                                font.pixelSize: Theme.fontSize
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            Text {
                                text: {
                                    switch (btDelegate.modelData.state) {
                                    case BluetoothDeviceState.Connecting: return "󰂰";
                                    case BluetoothDeviceState.Disconnecting: return "󰂰";
                                    case BluetoothDeviceState.Connected: return "󰂱";
                                    default: return "󰂯";
                                    }
                                }
                                color: btDelegate.modelData.connected ? Theme.accent : Theme.muted
                                opacity: btDelegate.isTransitioning ? 0.6 : 1.0
                                font.pixelSize: Theme.fontSize

                                TapHandler {
                                    enabled: !btDelegate.isTransitioning
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

        // Network. Icon uses Quickshell's real reactive Networking API
        // (NetworkManager-backed, confirmed via src/network/nm/* -- this is
        // the same backend this repo actually uses, unlike impala's
        // iwd-only assumption found earlier). Popup content (ping,
        // throughput, IP/gateway, speed test) ported from upstream
        // Omarchy's own network panel and its two backend scripts
        // (bin-omarchy-network-{status,speedtest}, now
        // network-tools.nix's omarchy-network-status/-speedtest) at the
        // user's explicit request. wifiDevice resolved once above.
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
                popupWidth: 320
                popupHeight: 420
                visible: false

                onVisibleChanged: {
                    if (bar.wifiDevice) bar.wifiDevice.scannerEnabled = visible;
                    statusProc.running = visible;
                    if (!visible) {
                        speedtestDownProc.running = false;
                        speedtestUpProc.running = false;
                    }
                }

                // Polls `omarchy-network-status --verbose` every 1.5s while
                // open (matches upstream's own poll cadence) -- tab-
                // separated key\tvalue lines, parsed the same way the
                // script's own output is shaped. Ping/IP/gateway/
                // throughput all come from this one process, not separate
                // calls, matching upstream's design.
                property var statusData: ({})
                property var prevSample: null
                property real downloadRate: 0
                property real uploadRate: 0
                property bool speedtestRunning: speedtestDownProc.running || speedtestUpProc.running
                property real speedtestDownMbps: 0
                property real speedtestUpMbps: 0

                function formatRate(bytesPerSec: real): string {
                    if (bytesPerSec < 1024) return Math.round(bytesPerSec) + " B/s";
                    if (bytesPerSec < 1024 * 1024) return (bytesPerSec / 1024).toFixed(1) + " KB/s";
                    return (bytesPerSec / (1024 * 1024)).toFixed(1) + " MB/s";
                }

                function formatPing(ms: string): string {
                    const value = parseFloat(ms);
                    if (!isFinite(value) || ms === undefined || ms === "") return "--";
                    return value.toFixed(value > 0 && value < 10 ? 1 : 0) + " ms";
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 6

                    // Process/Timer are not QQuickItems, so they can't be
                    // BarPopup's own direct children (its default property
                    // aliases to an Item-only `.children` list) -- they
                    // live here instead, inside this real Item, whose true
                    // default property (`data`) accepts non-visual
                    // QtObjects too. Found live via `qs`: "Cannot assign
                    // object of type Process to list property content;
                    // expected QQuickItem".
                    Process {
                        id: statusProc
                        command: ["omarchy-network-status", "--verbose"]
                        stdout: StdioCollector {
                            onStreamFinished: {
                                const data = {};
                                const lines = text.split("\n");
                                for (let i = 0; i < lines.length; i++) {
                                    const parts = lines[i].split("\t");
                                    if (parts.length >= 2 && parts[0]) data[parts[0]] = parts[1];
                                }
                                networkPopup.statusData = data;

                                // Throughput: byte-delta / elapsed-time
                                // between successive samples, ported from
                                // upstream's Model.js throughputState() --
                                // resets to 0 on the first sample after
                                // opening or an interface change, rather
                                // than showing a spurious spike.
                                const now = Date.now() / 1000;
                                const rx = parseFloat(data.rx_bytes || "0");
                                const tx = parseFloat(data.tx_bytes || "0");
                                const prev = networkPopup.prevSample;
                                if (prev && prev.iface === data.iface && prev.time > 0) {
                                    const dt = now - prev.time;
                                    if (dt > 0) {
                                        networkPopup.downloadRate = Math.max(0, (rx - prev.rx) / dt);
                                        networkPopup.uploadRate = Math.max(0, (tx - prev.tx) / dt);
                                    }
                                } else {
                                    networkPopup.downloadRate = 0;
                                    networkPopup.uploadRate = 0;
                                }
                                networkPopup.prevSample = { iface: data.iface, rx: rx, tx: tx, time: now };
                            }
                        }
                    }

                    Timer {
                        interval: 1500
                        running: networkPopup.visible
                        repeat: true
                        triggeredOnStart: true
                        onTriggered: if (!statusProc.running) statusProc.running = true
                    }

                    Process {
                        id: speedtestDownProc
                        command: ["omarchy-network-speedtest", "down"]
                        stdout: SplitParser {
                            onRead: (line) => {
                                const v = parseFloat(line);
                                if (isFinite(v)) networkPopup.speedtestDownMbps = v;
                            }
                        }
                        onRunningChanged: if (speedtestDownProc.running) { speedtestUpProc.running = false; networkPopup.speedtestUpMbps = 0; }
                        onExited: (exitCode, exitStatus) => {
                            if (!speedtestUpProc.running && exitCode === 0) speedtestUpProc.running = true;
                        }
                    }

                    Process {
                        id: speedtestUpProc
                        command: ["omarchy-network-speedtest", "up"]
                        stdout: SplitParser {
                            onRead: (line) => {
                                const v = parseFloat(line);
                                if (isFinite(v)) networkPopup.speedtestUpMbps = v;
                            }
                        }
                    }

                    // Connection summary + speed test trigger
                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: networkPopup.statusData.ssid || networkPopup.statusData.iface || "Disconnected"
                            color: Theme.foreground
                            font.pixelSize: Theme.fontSize
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: networkPopup.speedtestRunning ? "󰑐" : "󰓅"
                            color: Theme.accent
                            font.pixelSize: Theme.fontSize

                            TapHandler {
                                enabled: !networkPopup.speedtestRunning
                                onTapped: {
                                    networkPopup.speedtestDownMbps = 0;
                                    networkPopup.speedtestUpMbps = 0;
                                    speedtestDownProc.running = true;
                                }
                            }
                        }
                    }

                    // IP / gateway / ping / throughput grid
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 12
                        rowSpacing: 2

                        Text { text: "IP"; color: Theme.muted; font.pixelSize: Theme.fontSize }
                        Text { text: networkPopup.statusData.ip || "--"; color: Theme.foreground; font.pixelSize: Theme.fontSize; Layout.fillWidth: true; elide: Text.ElideRight }

                        Text { text: "Gateway"; color: Theme.muted; font.pixelSize: Theme.fontSize }
                        Text { text: networkPopup.statusData.gateway || "--"; color: Theme.foreground; font.pixelSize: Theme.fontSize; Layout.fillWidth: true; elide: Text.ElideRight }

                        Text { text: "Router ping"; color: Theme.muted; font.pixelSize: Theme.fontSize }
                        Text { text: networkPopup.formatPing(networkPopup.statusData.router_ping_ms); color: Theme.foreground; font.pixelSize: Theme.fontSize }

                        Text { text: "Internet ping"; color: Theme.muted; font.pixelSize: Theme.fontSize }
                        Text { text: networkPopup.formatPing(networkPopup.statusData.internet_ping_ms); color: Theme.foreground; font.pixelSize: Theme.fontSize }

                        Text { text: "Down"; color: Theme.muted; font.pixelSize: Theme.fontSize }
                        Text { text: networkPopup.speedtestRunning && speedtestDownProc.running ? networkPopup.speedtestDownMbps.toFixed(0) + " Mbps" : networkPopup.formatRate(networkPopup.downloadRate); color: Theme.foreground; font.pixelSize: Theme.fontSize }

                        Text { text: "Up"; color: Theme.muted; font.pixelSize: Theme.fontSize }
                        Text { text: networkPopup.speedtestRunning && speedtestUpProc.running ? networkPopup.speedtestUpMbps.toFixed(0) + " Mbps" : networkPopup.formatRate(networkPopup.uploadRate); color: Theme.foreground; font.pixelSize: Theme.fontSize }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Theme.overlay
                    }

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

        // Audio. Master volume + per-app mixer, ported from upstream
        // Omarchy's own audio panel (shell/plugins/panels/audio/Panel.qml)
        // at the user's explicit request -- same Pipewire.defaultAudioSink
        // .audio.volume/.muted bindings this repo already used, now paired
        // with PanelSlider.qml (see that file) instead of a hand-rolled
        // Tap/DragHandler track, and a real per-app stream list upstream's
        // audio panel also has.
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

            // Per-app playback streams: PwNodeType.AudioOutStream is the
            // exact flag combination (Audio | Sink | Stream) for a
            // playback stream (confirmed in
            // src/services/pipewire/node.hpp) -- a type-safe equivalent of
            // upstream's own JS string-matching isPlaybackStream()
            // (Model.js), since this repo's Quickshell exposes a real
            // PwNodeType.Flags enum rather than a raw media-class string.
            property var playbackStreams: {
                const nodes = Pipewire.nodes.values;
                const out = [];
                for (let i = 0; i < nodes.length; i++) {
                    const n = nodes[i];
                    if (n.isStream && (n.type & PwNodeType.AudioOutStream) === PwNodeType.AudioOutStream) {
                        out.push(n);
                    }
                }
                return out;
            }

            BarPopup {
                id: audioPopup
                anchorItem: audioIcon
                popupWidth: 300
                popupHeight: Math.min(400, 90 + audioIcon.playbackStreams.length * 56)
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

                        PanelSlider {
                            Layout.fillWidth: true
                            minimum: 0
                            maximum: 1
                            step: 0.05
                            value: {
                                const sink = Pipewire.defaultAudioSink;
                                return (sink && sink.audio) ? sink.audio.volume : 0;
                            }
                            opacity: {
                                const sink = Pipewire.defaultAudioSink;
                                return (sink && sink.audio && sink.audio.muted) ? 0.5 : 1.0;
                            }

                            onMoved: (v) => {
                                const sink = Pipewire.defaultAudioSink;
                                if (sink && sink.audio) sink.audio.volume = v;
                            }
                            onRightClicked: {
                                const sink = Pipewire.defaultAudioSink;
                                if (sink && sink.audio) sink.audio.muted = !sink.audio.muted;
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

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Theme.overlay
                        visible: audioIcon.playbackStreams.length > 0
                    }

                    Repeater {
                        model: audioIcon.playbackStreams

                        ColumnLayout {
                            id: streamRow
                            required property PwNode modelData
                            Layout.fillWidth: true
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: streamRow.modelData.audio && streamRow.modelData.audio.muted ? "󰝟" : "󰕾"
                                    color: Theme.foreground
                                    font.pixelSize: Theme.fontSize
                                    opacity: streamRow.modelData.audio && streamRow.modelData.audio.muted ? 0.5 : 1.0

                                    TapHandler {
                                        onTapped: {
                                            if (streamRow.modelData.audio) {
                                                streamRow.modelData.audio.muted = !streamRow.modelData.audio.muted;
                                            }
                                        }
                                    }
                                }

                                Text {
                                    text: streamRow.modelData.description || streamRow.modelData.nickname || streamRow.modelData.name
                                    color: Theme.foreground
                                    font.pixelSize: Theme.fontSize
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: streamRow.modelData.audio ? Math.round(streamRow.modelData.audio.volume * 100) + "%" : ""
                                    color: Theme.muted
                                    font.pixelSize: Theme.fontSize
                                }
                            }

                            PanelSlider {
                                Layout.fillWidth: true
                                minimum: 0
                                maximum: 1.5
                                step: 0.05
                                value: streamRow.modelData.audio ? streamRow.modelData.audio.volume : 0
                                opacity: streamRow.modelData.audio && streamRow.modelData.audio.muted ? 0.5 : 1.0

                                onMoved: (v) => {
                                    if (streamRow.modelData.audio) streamRow.modelData.audio.volume = v;
                                }
                                onRightClicked: {
                                    if (streamRow.modelData.audio) {
                                        streamRow.modelData.audio.muted = !streamRow.modelData.audio.muted;
                                    }
                                }
                            }
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

        // Clock -> calendar popup. Month-grid/ISO-week/year-progress date
        // math ported near-verbatim from upstream Omarchy's own
        // shell/plugins/panels/clock/Model.js (github.com/omacom/omarchy,
        // MIT licensed, quattro branch) at the user's request. Trimmed
        // from upstream: week-start toggle persistence, the memento-mori
        // life-progress bar, the timezone picker, and format-cycling
        // (kept the existing single yyyy-MM-dd HH:mm format) -- none of
        // which the user asked for; only "date and time... opens a
        // calendar popup" was requested.
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

            TapHandler {
                onTapped: calendarPopup.visible = !calendarPopup.visible
            }

            BarPopup {
                id: calendarPopup
                anchorItem: clockText
                popupWidth: 280
                popupHeight: 320
                visible: false

                // viewYear/viewMonth track which month is displayed;
                // reset to the real current month whenever the popup is
                // reopened, matching upstream's own "always opens on
                // today" behaviour.
                property int viewYear: (new Date()).getFullYear()
                property int viewMonth: (new Date()).getMonth()

                onVisibleChanged: {
                    if (visible) {
                        const now = new Date();
                        viewYear = now.getFullYear();
                        viewMonth = now.getMonth();
                    }
                }

                readonly property var today: new Date()
                readonly property string todayKey: dateKey(today.getFullYear(), today.getMonth(), today.getDate())

                function pad2(n: int): string {
                    return (n < 10 ? "0" : "") + n;
                }

                function dateKey(year: int, month: int, day: int): string {
                    return year + "-" + pad2(month + 1) + "-" + pad2(day);
                }

                // ISO-8601 week number (Thursday-anchored): shift to the
                // Thursday of the same week, then count weeks from that
                // Thursday's own year-start. Ported from Model.js's
                // isoWeek(), which is itself the standard ISO week
                // algorithm, not an Omarchy-specific invention.
                function isoWeek(year: int, month: int, day: int): int {
                    const date = new Date(Date.UTC(year, month, day));
                    const weekday = date.getUTCDay() || 7;
                    date.setUTCDate(date.getUTCDate() + 4 - weekday);
                    const yearStart = new Date(Date.UTC(date.getUTCFullYear(), 0, 1));
                    return Math.ceil(((date.getTime() - yearStart.getTime()) / 86400000 + 1) / 7);
                }

                function dayOfYear(year: int, month: int, day: int): int {
                    return Math.round((Date.UTC(year, month, day) - Date.UTC(year, 0, 1)) / 86400000) + 1;
                }

                function daysInYear(year: int): int {
                    return dayOfYear(year, 11, 31);
                }

                readonly property real yearProgress: {
                    const total = daysInYear(today.getFullYear());
                    if (total <= 0) return 0;
                    return Math.max(0, Math.min(1, (dayOfYear(today.getFullYear(), today.getMonth(), today.getDate()) - 1) / total));
                }

                // 6x7 fixed grid (always 6 weeks) so the popup never
                // resizes stepping between months -- ported from
                // Model.js's monthGrid(), Monday-start fixed (upstream
                // supports a user-toggleable week start; not built here,
                // see the trimmed-scope note above).
                property var weeks: {
                    const weekStart = 1; // Monday
                    const leading = (new Date(viewYear, viewMonth, 1).getDay() - weekStart + 7) % 7;
                    let cursor = new Date(viewYear, viewMonth, 1 - leading);
                    const result = [];
                    for (let w = 0; w < 6; w++) {
                        const days = [];
                        // A real calendar week always contains a Thursday
                        // (it's a 7-day loop starting from a fixed
                        // weekStart), so this is always overwritten before
                        // use below -- no fallback needed, unlike an
                        // earlier draft of this function which reached for
                        // days[0] "just in case" and then couldn't
                        // reconstruct a year/month from it.
                        let anchorYear = viewYear;
                        let anchorMonth = viewMonth;
                        let anchorDay = 1;
                        for (let d = 0; d < 7; d++) {
                            const cellYear = cursor.getFullYear();
                            const cellMonth = cursor.getMonth();
                            const cellDay = cursor.getDate();
                            const weekday = cursor.getDay();
                            const key = dateKey(cellYear, cellMonth, cellDay);
                            if (weekday === 4) {
                                anchorYear = cellYear;
                                anchorMonth = cellMonth;
                                anchorDay = cellDay;
                            }
                            days.push({
                                key: key,
                                day: cellDay,
                                inMonth: cellMonth === viewMonth && cellYear === viewYear,
                                weekend: weekday === 0 || weekday === 6,
                                isToday: key === todayKey
                            });
                            cursor.setDate(cursor.getDate() + 1);
                        }
                        result.push({ week: isoWeek(anchorYear, anchorMonth, anchorDay), days: days });
                    }
                    return result;
                }

                readonly property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "󰅁"
                            color: Theme.foreground
                            font.pixelSize: Theme.fontSize
                            TapHandler {
                                onTapped: {
                                    if (calendarPopup.viewMonth === 0) {
                                        calendarPopup.viewMonth = 11;
                                        calendarPopup.viewYear -= 1;
                                    } else {
                                        calendarPopup.viewMonth -= 1;
                                    }
                                }
                            }
                        }

                        Text {
                            text: calendarPopup.monthNames[calendarPopup.viewMonth] + " " + calendarPopup.viewYear
                            color: Theme.foreground
                            font.pixelSize: Theme.fontSize
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Text {
                            text: "󰅂"
                            color: Theme.foreground
                            font.pixelSize: Theme.fontSize
                            TapHandler {
                                onTapped: {
                                    if (calendarPopup.viewMonth === 11) {
                                        calendarPopup.viewMonth = 0;
                                        calendarPopup.viewYear += 1;
                                    } else {
                                        calendarPopup.viewMonth += 1;
                                    }
                                }
                            }
                        }
                    }

                    // Year-progress meter -- pure date math, no external
                    // dependency, cheap and visually nice per the plan.
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 4
                        radius: 2
                        color: Theme.overlay

                        Rectangle {
                            width: parent.width * calendarPopup.yearProgress
                            height: parent.height
                            radius: 2
                            color: Theme.accent
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 8
                        columnSpacing: 2
                        rowSpacing: 4

                        Text { text: "W"; color: Theme.muted; font.pixelSize: Theme.fontSize - 2; Layout.alignment: Qt.AlignHCenter }
                        Repeater {
                            model: ["M", "T", "W", "T", "F", "S", "S"]
                            Text {
                                required property string modelData
                                text: modelData
                                color: Theme.muted
                                font.pixelSize: Theme.fontSize - 2
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        Repeater {
                            model: calendarPopup.weeks

                            Text {
                                required property var modelData
                                text: modelData.week
                                color: Theme.muted
                                font.pixelSize: Theme.fontSize - 2
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        Repeater {
                            model: {
                                const flat = [];
                                for (let w = 0; w < calendarPopup.weeks.length; w++) {
                                    for (let d = 0; d < 7; d++) flat.push(calendarPopup.weeks[w].days[d]);
                                }
                                return flat;
                            }

                            Rectangle {
                                id: dayDelegate
                                required property var modelData
                                Layout.preferredWidth: 26
                                Layout.preferredHeight: 26
                                Layout.alignment: Qt.AlignHCenter
                                radius: 4
                                color: "transparent"
                                border.color: dayDelegate.modelData.isToday ? Theme.accent : "transparent"
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: dayDelegate.modelData.day
                                    font.pixelSize: Theme.fontSize
                                    font.bold: dayDelegate.modelData.isToday
                                    color: dayDelegate.modelData.weekend ? Theme.muted : Theme.foreground
                                    opacity: dayDelegate.modelData.inMonth ? 1.0 : 0.4
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
