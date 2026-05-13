import Foundation

struct Leaderboard: Hashable, Sendable {
    let tournament: Tournament
    let entries: [LeaderboardEntry]
    let lastUpdated: Date

    /// True when at least one player is currently on the course.
    var hasLiveRound: Bool {
        entries.contains { $0.status == .playing || $0.status == .teeing }
    }

    /// Sort key for the "currently playing > others" partition.
    /// Lower comes first.
    static func sortRank(_ entry: LeaderboardEntry) -> (Int, Int) {
        let primary: Int = {
            switch entry.status {
            case .playing, .teeing, .finished, .active: 0
            case .cut: 1
            case .withdrawn, .disqualified: 2
            }
        }()
        return (primary, entry.positionRank ?? Int.max)
    }
}
