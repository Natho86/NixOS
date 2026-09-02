// Reusable slider for bar popups (audio master volume, per-app mixer).
// Adapted from upstream Omarchy's own shell/Ui/PanelSlider.qml
// (github.com/omacom/omarchy, MIT licensed, quattro branch), at the user's
// explicit request to port upstream's real audio-popup implementation
// rather than build one from scratch. Interaction model kept identical
// (drag anywhere on the track to set, right-click to mute, mouse wheel to
// step, live value shown during drag before the bound `value` catches up)
// -- only the styling layer changed, since upstream's `Style`/`Color`/
// `BorderSurface` singletons and component don't exist in this repo.
// Those are replaced with this repo's own `Theme.*` tokens (theme.nix) and
// a plain `Rectangle` knob instead of the custom bordered-circle
// `BorderSurface` component. Tick-mark notches (upstream's optional
// macOS-style volume-notch feature) are dropped -- not used by either
// caller here.
import QtQuick

Item {
    id: root

    property real value: 0
    property real minimum: 0
    property real maximum: 1
    property real step: 0.05
    property bool dragging: false
    property real liveValue: value

    onValueChanged: if (!dragging) liveValue = value

    signal moved(real value)
    signal released(real value)

    // Right-click is a secondary action on the whole track -- audio uses
    // it to mute the channel the slider belongs to. Dragging stays
    // left-button only.
    signal rightClicked()

    implicitWidth: 200
    implicitHeight: 22

    readonly property real range: Math.max(0.0001, maximum - minimum)
    readonly property real progress: Math.max(0, Math.min(1, (liveValue - minimum) / range))
    readonly property bool hot: mouseArea.containsMouse || root.dragging

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        height: 6
        radius: height / 2
        color: Theme.overlay
    }

    Rectangle {
        id: fill
        anchors.verticalCenter: track.verticalCenter
        anchors.left: track.left
        height: track.height
        radius: track.radius
        color: Theme.accent
        width: track.width * root.progress

        Behavior on width {
            enabled: !root.dragging
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }
    }

    Rectangle {
        id: knob
        width: 14
        height: 14
        radius: width / 2
        color: Theme.foreground
        border.color: Theme.background
        border.width: 2
        anchors.verticalCenter: track.verticalCenter
        x: Math.max(0, Math.min(track.width - width, track.width * root.progress - width / 2))
        scale: root.hot ? 1.15 : 1.0

        Behavior on x {
            enabled: !root.dragging
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        function valueFromX(x: real): real {
            const clamped = Math.max(0, Math.min(track.width, x));
            const raw = root.minimum + (clamped / track.width) * root.range;
            return Math.max(root.minimum, Math.min(root.maximum, raw));
        }

        onPressed: (mouse) => {
            if (mouse.button !== Qt.LeftButton) return;
            root.dragging = true;
            const next = valueFromX(mouse.x);
            root.liveValue = next;
            root.moved(next);
        }
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) root.rightClicked();
        }
        onPositionChanged: (mouse) => {
            if (!root.dragging) return;
            const next = valueFromX(mouse.x);
            root.liveValue = next;
            root.moved(next);
        }
        onReleased: (mouse) => {
            if (mouse.button !== Qt.LeftButton) return;
            root.dragging = false;
            root.released(root.liveValue);
            root.liveValue = root.value;
        }
        onWheel: (wheel) => {
            const delta = wheel.angleDelta.y > 0 ? root.step : -root.step;
            const next = Math.max(root.minimum, Math.min(root.maximum, root.liveValue + delta));
            root.liveValue = next;
            root.moved(next);
            root.released(next);
        }
    }
}
