import AppKit
import SwiftUI
import Observation

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var panelController: PanelController?
    private let starred: StarredPlayersStore
    private let appState: AppState
    private var displayMode: DisplayMode = .floating
    private var observationTask: Task<Void, Never>?

    /// How many leaderboard rows we include in the compact menu.
    private let compactRowCount = 10

    override init() {
        let starred = StarredPlayersStore()
        let provider = ESPNProvider()
        self.starred = starred
        self.appState = AppState(provider: provider, starred: starred)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        displayMode = DisplayMode.current
        installStatusItem()
        buildPanelController()
        applyDisplayMode()
        appState.start()
        observeStateForStatusBar()
    }

    func applicationWillTerminate(_ notification: Notification) {
        appState.stop()
        observationTask?.cancel()
    }

    // MARK: - Mode switching

    private func applyDisplayMode() {
        updateStatusItemAppearance()
        switch displayMode {
        case .floating:
            panelController?.show()
        case .compact:
            panelController?.hide()
        }
    }

    @objc private func toggleDisplayMode() {
        displayMode = (displayMode == .floating) ? .compact : .floating
        DisplayMode.setCurrent(displayMode)
        applyDisplayMode()
    }

    // MARK: - Status bar

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            let icon = NSImage(named: "MenuBarIcon")
            icon?.isTemplate = true
            icon?.accessibilityDescription = "Scorecard"
            button.image = icon
            button.imagePosition = .imageLeading
            button.action = #selector(statusItemClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        statusItem = item
    }

    private func updateStatusItemAppearance() {
        guard let button = statusItem?.button else { return }
        switch displayMode {
        case .floating:
            button.title = ""
        case .compact:
            let raw = appState.selectedTournament?.shortName ?? ""
            button.title = raw.isEmpty ? "" : "  \(raw)"
        }
    }

    private func observeStateForStatusBar() {
        observationTask?.cancel()
        observationTask = Task { @MainActor [weak self] in
            await self?.observeLoop()
        }
    }

    private func observeLoop() async {
        while !Task.isCancelled {
            await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                withObservationTracking {
                    _ = self.appState.selectedTournament?.shortName
                } onChange: {
                    cont.resume()
                }
            }
            updateStatusItemAppearance()
        }
    }

    @objc private func statusItemClicked(_ sender: Any?) {
        switch displayMode {
        case .floating:
            // Floating mode keeps the left/right split so a click toggles
            // the panel without taking the menu detour.
            guard let event = NSApp.currentEvent else {
                panelController?.toggle()
                return
            }
            if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
                showStatusMenu()
            } else {
                panelController?.toggle()
            }
        case .compact:
            // Compact mode IS the menu — both clicks show it.
            showStatusMenu()
        }
    }

    // MARK: - Menu construction

    private func showStatusMenu() {
        guard let statusItem else { return }
        let menu = buildMenu()
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        switch displayMode {
        case .floating:
            menu.addItem(makeItem(
                title: panelController?.panel.isVisible == true ? "Hide Scorecard" : "Show Scorecard",
                action: #selector(togglePanel)
            ))
            menu.addItem(.separator())
            menu.addItem(makeItem(title: "Switch to Compact", action: #selector(toggleDisplayMode)))
            menu.addItem(.separator())
            menu.addItem(makeItem(title: "Refresh", action: #selector(refreshNow), key: "r"))
        case .compact:
            addLeaderboardItems(to: menu)
            menu.addItem(.separator())
            menu.addItem(buildTournamentPickerItem())
            menu.addItem(makeItem(title: "Switch to Floating", action: #selector(toggleDisplayMode)))
            menu.addItem(makeItem(title: "Refresh", action: #selector(refreshNow), key: "r"))
        }
        menu.addItem(.separator())
        let quit = NSMenuItem(
            title: "Quit Scorecard",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quit)
        return menu
    }

    private func makeItem(title: String, action: Selector, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    // MARK: - Top-of-menu leaderboard rows (compact mode)

    private func addLeaderboardItems(to menu: NSMenu) {
        guard let entries = appState.leaderboard?.entries, !entries.isEmpty else {
            let placeholder = NSMenuItem(title: "  No data yet", action: nil, keyEquivalent: "")
            placeholder.isEnabled = false
            menu.addItem(placeholder)
            return
        }

        let top = Array(entries.prefix(compactRowCount))
        let topIDs = Set(top.map(\.id))
        let starredExtra = entries.filter { starred.isStarred($0.id) && !topIDs.contains($0.id) }

        if !starredExtra.isEmpty {
            menu.addItem(NSMenuItem.sectionHeader(title: "Starred"))
            for entry in starredExtra {
                menu.addItem(leaderboardItem(for: entry, isStarred: true))
            }
            menu.addItem(.separator())
        }

        menu.addItem(NSMenuItem.sectionHeader(title: "Leaderboard"))
        for entry in top {
            let isStarred = starred.isStarred(entry.id)
            menu.addItem(leaderboardItem(for: entry, isStarred: isStarred))
        }
    }

    /// One leaderboard row rendered as a custom `NSView` rather than via
    /// `attributedTitle`. NSMenuItem applies a dimming pass to disabled-item
    /// text even when an explicit foreground color is set, so the only way to
    /// keep the row at full label-color opacity while still suppressing hover
    /// highlight and click-to-close is to host a view we control. Tab stops
    /// align the position / star / name / score / thru columns.
    private func leaderboardItem(for entry: LeaderboardEntry, isStarred: Bool) -> NSMenuItem {
        let item = NSMenuItem()
        item.view = LeaderboardMenuRowView(entry: entry, isStarred: isStarred)
        item.isEnabled = false
        return item
    }

    // MARK: - Tournament picker (compact mode)

    private func buildTournamentPickerItem() -> NSMenuItem {
        let parent = NSMenuItem(title: "Tournament", action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: "Tournament")
        let grouped = Dictionary(grouping: appState.activeTournaments, by: \.league)
        var addedAny = false
        for league in League.allCases {
            guard let list = grouped[league], !list.isEmpty else { continue }
            if addedAny { submenu.addItem(.separator()) }
            submenu.addItem(NSMenuItem.sectionHeader(title: league.displayName))
            for tournament in list {
                let item = NSMenuItem(
                    title: tournament.shortName,
                    action: #selector(selectTournament(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = tournament.id
                if tournament.id == appState.selectedTournament?.id {
                    item.state = .on
                }
                submenu.addItem(item)
            }
            addedAny = true
        }
        if !addedAny {
            let empty = NSMenuItem(title: "No active tournaments", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            submenu.addItem(empty)
        }
        parent.submenu = submenu
        return parent
    }

    @objc private func selectTournament(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String,
              let tournament = appState.activeTournaments.first(where: { $0.id == id }) else {
            return
        }
        appState.select(tournament)
    }

    @objc private func togglePanel() {
        panelController?.toggle()
    }

    @objc private func refreshNow() {
        Task { await appState.refresh() }
    }

    // MARK: - Panel construction

    private func buildPanelController() {
        let root = LeaderboardView()
            .environment(appState)
            .environment(starred)
        panelController = PanelController(rootView: AnyView(root))
    }
}
