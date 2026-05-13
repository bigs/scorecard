import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var panelController: PanelController?
    private let starred: StarredPlayersStore
    private let appState: AppState

    override init() {
        let starred = StarredPlayersStore()
        let provider = ESPNProvider()
        self.starred = starred
        self.appState = AppState(provider: provider, starred: starred)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        installStatusItem()
        installPanel()
        appState.start()
        panelController?.show()
    }

    func applicationWillTerminate(_ notification: Notification) {
        appState.stop()
    }

    // MARK: - Status bar

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "flag.checkered", accessibilityDescription: "Scorecard")
            button.image?.isTemplate = true
            button.action = #selector(statusItemClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        statusItem = item
    }

    @objc private func statusItemClicked(_ sender: Any?) {
        guard let event = NSApp.currentEvent else {
            panelController?.toggle()
            return
        }
        if event.type == .rightMouseUp {
            showStatusMenu()
        } else {
            panelController?.toggle()
        }
    }

    private func showStatusMenu() {
        guard let statusItem else { return }
        let menu = NSMenu()
        let toggle = NSMenuItem(title: panelController?.panel.isVisible == true ? "Hide Scorecard" : "Show Scorecard",
                                action: #selector(togglePanel),
                                keyEquivalent: "")
        toggle.target = self
        menu.addItem(toggle)
        menu.addItem(NSMenuItem.separator())
        let refresh = NSMenuItem(title: "Refresh", action: #selector(refreshNow), keyEquivalent: "r")
        refresh.target = self
        menu.addItem(refresh)
        menu.addItem(NSMenuItem.separator())
        let quit = NSMenuItem(title: "Quit Scorecard", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func togglePanel() {
        panelController?.toggle()
    }

    @objc private func refreshNow() {
        Task { await appState.refresh() }
    }

    // MARK: - Panel

    private func installPanel() {
        let root = LeaderboardView()
            .environment(appState)
            .environment(starred)
        panelController = PanelController(rootView: AnyView(root))
    }
}
