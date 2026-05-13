import SwiftUI

@main
struct ScorecardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        // No user-visible scene — the AppDelegate owns the floating panel.
        // A `Settings` scene is included so Cmd+, has a sensible default and
        // SwiftUI has at least one scene to host.
        Settings {
            EmptyView()
        }
    }
}
