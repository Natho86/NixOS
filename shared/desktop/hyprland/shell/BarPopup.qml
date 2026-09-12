// Shared chrome for bar dropdown popups (audio/network/bluetooth/power).
// PopupWindow API verified against the pinned quickshell source
// (src/window/popupwindow.hpp / src/core/popupanchor.hpp), and against a
// real worked example in Quickshell's own src/ui/Tooltip.qml, not guessed.
// relativeX/relativeY/parentWindow are documented as deprecated in favour
// of anchor.window/anchor.item/anchor.rect, so this uses the current API.
//
// anchor.window and anchor.item are mutually exclusive -- setting one
// unsets the other (popupanchor.hpp's own doc comment: "Setting this
// property unsets @@item" / "@@window"). This uses anchor.item alone,
// which positions relative to the anchoring icon directly; Tooltip.qml
// instead uses anchor.window + a manual onAnchoring handler, but only
// because it needs horizontal centering, an anchor combination the doc
// itself flags as having poor compositor support -- not needed here,
// since every popup opens directly below its triggering icon (a plain
// bottom-edge anchor, not centered).
//
// Styling matches Osd.qml's established convention (Theme.background/
// Theme.border/Theme.rounding), so popups look consistent with the rest of
// the shell rather than inventing a new visual language.
import QtQuick
import Quickshell

PopupWindow {
    id: popup

    // Set by the caller: the bar icon this popup opens below.
    required property Item anchorItem
    property int popupWidth: 280
    property int popupHeight: 200

    default property alias content: contentItem.children

    anchor.item: anchorItem
    anchor.rect.x: 0
    anchor.rect.y: anchorItem.height
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.adjustment: PopupAdjustment.Slide

    implicitWidth: popupWidth
    implicitHeight: popupHeight
    color: "transparent"
    grabFocus: true

    Rectangle {
        anchors.fill: parent
        radius: Theme.rounding
        color: Theme.background
        border.color: Theme.border
        border.width: 1

        Item {
            id: contentItem
            anchors.fill: parent
            anchors.margins: 12
        }
    }
}
