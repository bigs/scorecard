import SwiftUI
import AppKit

/// A SwiftUI view that — when clicked — kicks off AppKit's
/// `NSWindow.performDrag(with:)` tracking loop, moving the window if the
/// user drags or doing nothing if they just click and release. Use this
/// as an explicit drag affordance in your view hierarchy (e.g. the
/// empty regions of a custom title bar) when
/// `isMovableByWindowBackground` is not a reliable mechanism — which is
/// the case for SwiftUI-hosted view hierarchies on macOS, where AppKit's
/// hit-test chain doesn't reliably consult `mouseDownCanMoveWindow`.
struct WindowDragHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { DragView() }
    func updateNSView(_ nsView: NSView, context: Context) {}

    final class DragView: NSView {
        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }

        // Make sure the view is hit-testable everywhere within its
        // bounds, including when its layer is fully transparent.
        override func hitTest(_ point: NSPoint) -> NSView? {
            bounds.contains(convert(point, from: superview)) ? self : nil
        }
    }
}
