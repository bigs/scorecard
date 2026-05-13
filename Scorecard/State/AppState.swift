import Foundation
import Observation

@MainActor
@Observable
final class AppState {
    enum LoadState: Equatable {
        case idle
        case loading
        case ready(Date)        // last successful refresh
        case failed(String)
    }

    private(set) var activeTournaments: [Tournament] = []
    private(set) var selectedTournament: Tournament?
    private(set) var leaderboard: Leaderboard?
    private(set) var loadState: LoadState = .idle
    var expandedPlayerID: String?

    let starred: StarredPlayersStore
    private let provider: any LeaderboardProvider
    private var pollTask: Task<Void, Never>?

    /// Polling cadence while a round is live.
    private let livePollInterval: Duration = .seconds(60)
    /// Polling cadence when no rounds are in progress.
    private let idlePollInterval: Duration = .seconds(300)

    init(provider: any LeaderboardProvider, starred: StarredPlayersStore) {
        self.provider = provider
        self.starred = starred
    }

    func start() {
        guard pollTask == nil else { return }
        pollTask = Task { [weak self] in
            await self?.pollLoop()
        }
    }

    func stop() {
        pollTask?.cancel()
        pollTask = nil
    }

    func select(_ tournament: Tournament) {
        guard tournament.id != selectedTournament?.id else { return }
        selectedTournament = tournament
        leaderboard = nil
        expandedPlayerID = nil
        Task { await refresh() }
    }

    func toggleExpand(_ playerID: String) {
        expandedPlayerID = expandedPlayerID == playerID ? nil : playerID
    }

    func refresh() async {
        if case .loading = loadState { return }
        loadState = .loading
        do {
            let active = try await provider.activeTournaments()
            self.activeTournaments = active
            // Hold onto the user's existing selection if it's still in the list,
            // otherwise default to the first active event.
            if let current = selectedTournament,
               let refreshed = active.first(where: { $0.id == current.id }) {
                self.selectedTournament = refreshed
            } else {
                self.selectedTournament = active.first
            }
            if let target = selectedTournament {
                let board = try await provider.leaderboard(for: target)
                self.leaderboard = board
                // Pull through any state updates from the leaderboard's
                // tournament copy (e.g. status transitions mid-round).
                self.selectedTournament = board.tournament
            } else {
                self.leaderboard = nil
            }
            self.loadState = .ready(Date())
        } catch {
            self.loadState = .failed(error.localizedDescription)
        }
    }

    /// Round-by-round + starred + cut-line aware grouping for the list view.
    /// Returns (starred entries, main entries). Starred slice excludes anyone
    /// already in the cut/withdrawn buckets so they show up where they should.
    func groupedEntries() -> (starred: [LeaderboardEntry], main: [LeaderboardEntry]) {
        guard let entries = leaderboard?.entries, !entries.isEmpty else {
            return ([], [])
        }
        let starredSet = starred.ids
        let starred = entries.filter { starredSet.contains($0.id) }
        return (starred, entries)
    }

    private func pollLoop() async {
        while !Task.isCancelled {
            await refresh()
            let interval = currentPollInterval()
            try? await Task.sleep(for: interval)
        }
    }

    private func currentPollInterval() -> Duration {
        if leaderboard?.hasLiveRound == true { return livePollInterval }
        if selectedTournament?.state == .inProgress { return livePollInterval }
        return idlePollInterval
    }
}
