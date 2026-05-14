import AppKit

/// A floating, non-activating panel that hosts the leaderboard UI.
/// `.fullSizeContentView` lets the SwiftUI content extend under the
/// (hidden) title bar so the list can be truly full bleed.
final class FloatingPanel: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 520),
            styleMask: [.titled, .resizable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        // We disable AppKit's `isMovableByWindowBackground` machinery
        // because it doesn't reliably honour `mouseDownCanMoveWindow` on
        // SwiftUI-hosted view hierarchies (verified empirically: AppKit
        // hit-tests find our subclass returning `false`, but still drags
        // the window). Title-bar drag is implemented manually in
        // `sendEvent(_:)` via `performDrag(with:)`.
        isMovableByWindowBackground = false
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = true
        animationBehavior = .utilityWindow
        contentMinSize = NSSize(width: 260, height: 360)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
