import SwiftUI
import AppKit

/// A vertical scroll view that hosts SwiftUI content inside an explicit
/// `NSScrollView`. Two reasons we don't just use `SwiftUI.ScrollView`:
///
/// 1. **Window drag.** With `isMovableByWindowBackground = true`, SwiftUI's
///    own scroll-bar implementation routed clicks back up through the
///    hosting view, which permitted window-drag — so dragging the scroll
///    thumb moved the panel. A real `NSScroller` natively returns
///    `mouseDownCanMoveWindow = false`, so the scroller eats its own
///    clicks before the window-drag machinery sees them.
///
/// 2. **Liquid Glass styling.** We force `scrollerStyle = .overlay` here
///    regardless of the user's system preference, which gives a thin,
///    translucent thumb over the panel's glass instead of the opaque
///    legacy track.
struct GlassScrollView<Content: View>: NSViewRepresentable {
    @ViewBuilder var content: () -> Content

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.scrollerStyle = .overlay
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.backgroundColor = .clear
        scrollView.borderType = .noBorder
        scrollView.verticalScrollElasticity = .allowed
        scrollView.horizontalScrollElasticity = .none
        // Replace the default scroller with one that opts out of window
        // drag. `NSScroller`'s default `mouseDownCanMoveWindow` is `true`
        // (opaque view default), which is what was causing the scroll-bar
        // drag to move the panel under `isMovableByWindowBackground`.
        let scroller = NoDragScroller(frame: .zero)
        scroller.scrollerStyle = .overlay
        scrollView.verticalScroller = scroller

        // The document view holds the SwiftUI content and is the hit-test
        // target when the user clicks the scroll area outside the
        // (overlay) thumb. We use a subclass that returns
        // `mouseDownCanMoveWindow = false` so those clicks don't move the
        // window. The outer hosting view (which owns the title bar) still
        // returns `true` by default, so the title-bar drag keeps working.
        let host = NoDragHostingView(rootView: AnyView(content()))
        host.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = host

        if let clipView = scrollView.contentView as? NSClipView {
            clipView.drawsBackground = false
            NSLayoutConstraint.activate([
                host.leadingAnchor.constraint(equalTo: clipView.leadingAnchor),
                host.trailingAnchor.constraint(equalTo: clipView.trailingAnchor),
                host.topAnchor.constraint(equalTo: clipView.topAnchor),
                host.widthAnchor.constraint(equalTo: clipView.widthAnchor),
            ])
        }

        context.coordinator.host = host
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        context.coordinator.host?.rootView = AnyView(content())
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var host: NoDragHostingView<AnyView>?
    }
}

/// `NSScroller` that refuses to participate in window-background drag.
/// Installed on `GlassScrollView`'s underlying `NSScrollView` so that
/// dragging the scroll thumb scrolls instead of moving the panel.
final class NoDragScroller: NSScroller {
    override var mouseDownCanMoveWindow: Bool { false }
}

/// `NSHostingView` subclass used as the document view of
/// `GlassScrollView`. Overlay scrollers only hit-test their thumb; clicks
/// on the scroll area outside the thumb fall through to the document
/// view. Returning `false` here keeps those click-throughs from dragging
/// the panel. The outer hosting view (which owns the title bar) still
/// returns the default `true`, so title-bar drag continues to work.
final class NoDragHostingView<Content: View>: NSHostingView<Content> {
    override var mouseDownCanMoveWindow: Bool { false }
}

