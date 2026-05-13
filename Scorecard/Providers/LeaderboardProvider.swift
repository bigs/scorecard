import Foundation

/// Source-agnostic interface for golf leaderboard data.
///
/// Implementations should be safe to call from any task. Conformers must
/// produce normalized `Tournament` and `LeaderboardEntry` values regardless
/// of their underlying API's shape.
protocol LeaderboardProvider: Sendable {
    /// Leagues this provider can serve.
    var supportedLeagues: [League] { get }

    /// Active or near-active tournaments across the supported leagues.
    /// "Active" here means in progress, suspended, or scheduled for today.
    func activeTournaments() async throws -> [Tournament]

    /// Full leaderboard for a tournament. Implementations may also include
    /// players who missed the cut / withdrew, marked via `PlayerStatus`.
    func leaderboard(for tournament: Tournament) async throws -> Leaderboard

    /// Per-hole scorecard for a single player at a tournament. May return
    /// round totals only if per-hole data isn't available from the source.
    func scorecard(playerID: String, tournament: Tournament) async throws -> Scorecard
}

enum ProviderError: LocalizedError {
    case badResponse(Int)
    case decode(String)
    case notFound

    var errorDescription: String? {
        switch self {
        case .badResponse(let code): "Server returned \(code)"
        case .decode(let detail): "Couldn't read response: \(detail)"
        case .notFound: "Not found"
        }
    }
}
