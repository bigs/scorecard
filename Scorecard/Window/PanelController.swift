import AppKit
import SwiftUI

@MainActor
final class PanelController: NSObject, NSWindowDelegate {
    let panel: FloatingPanel
    private let hostingController: NSHostingController<AnyView>
    private let frameKey = "panel.savedFrame"
    private let userDefaults: UserDefaults

    init(rootView: AnyView, userDefaults: UserDefaults = .standard) {
        let host = NSHostingController(rootView: rootView)
        // Intentionally NOT setting `.preferredContentSize` — that would let the
        // SwiftUI content grow the window to fit a 156-row leaderboard. We want
        // the window to drive size and the ScrollView to handle overflow.
        host.sizingOptions = []
        // Force the hosting view to a transparent layer so the panel's Liquid
        // Glass background actually refracts what's behind the window instead
        // of rendering on top of an opaque white backing.
        host.view.wantsLayer = true
        host.view.layer?.backgroundColor = .clear
        host.view.layer?.isOpaque = false
        self.hostingController = host
        self.userDefaults = userDefaults
        let panel = FloatingPanel()
        panel.contentViewController = host
        self.panel = panel
        super.init()
        panel.delegate = self
        restoreOrPlaceFrame()
    }

    func show() {
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }

    func toggle() {
        if panel.isVisible { hide() } else { show() }
    }

    // MARK: - Frame persistence + snap-to-corner

    private func restoreOrPlaceFrame() {
        if let saved = userDefaults.string(forKey: frameKey) {
            let rect = NSRectFromString(saved)
            if isSaneFrame(rect) {
                panel.setFrame(rect, display: false)
                return
            }
        }
        placeInDefaultCorner()
    }

    private func isSaneFrame(_ rect: NSRect) -> Bool {
        guard rect.width >= 200, rect.height >= 200 else { return false }
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return false }
        // Reject rects that span more than the visible screen — likely from
        // an earlier bad layout pass.
        if rect.width > screen.visibleFrame.width { return false }
        if rect.height > screen.visibleFrame.height { return false }
        return frameIsOnScreen(rect)
    }

    private func placeInDefaultCorner() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let visible = screen.visibleFrame
        let margin: CGFloat = 16
        let size = panel.frame.size
        let origin = NSPoint(
            x: visible.maxX - size.width - margin,
            y: visible.minY + margin
        )
        panel.setFrameOrigin(origin)
    }

    private func frameIsOnScreen(_ rect: NSRect) -> Bool {
        NSScreen.screens.contains { $0.visibleFrame.intersects(rect) }
    }

    private func persistFrame() {
        userDefaults.set(NSStringFromRect(panel.frame), forKey: frameKey)
    }

    // MARK: - NSWindowDelegate

    nonisolated func windowDidMove(_ notification: Notification) {
        Task { @MainActor in
            self.persistFrame()
        }
    }

    nonisolated func windowDidEndLiveResize(_ notification: Notification) {
        Task { @MainActor in
            self.persistFrame()
        }
    }
}
