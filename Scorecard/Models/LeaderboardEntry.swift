import Foundation

struct LeaderboardEntry: Identifiable, Hashable, Sendable {
    enum PlayerStatus: String, Sendable {
        case active        // In the field, not yet teed off today
        case teeing        // On the tee / about to start
        case playing       // Currently on the course
        case finished      // Done for the day
        case cut           // Missed the cut
        case withdrawn
        case disqualified
    }

    let id: String          // ESPN athlete id
    let playerName: String
    let countryFlag: URL?
    let headshot: URL?

    /// "1", "T4", "CUT", "WD". We keep the display string from the source so we
    /// don't have to recompute tie logic ourselves.
    let positionDisplay: String
    /// Numeric position when one is available, for sort stability.
    let positionRank: Int?

    /// Score to par for the whole tournament. nil means "-" (e.g. WD/CUT).
    let scoreToPar: Int?
    /// Score to par today (current round). nil if the round hasn't started.
    let today: Int?
    /// Display string for "thru" — "F" for finished, "15" for hole 15, "—" pre-round.
    let thruDisplay: String

    /// Round-by-round totals for the rounds completed or in-progress.
    let rounds: [RoundTotal]

    let status: PlayerStatus

    struct RoundTotal: Identifiable, Hashable, Sendable {
        let id: Int          // round number (1..4)
        let strokes: Int?    // nil if not yet played
        let toPar: Int?      // strokes - par for that round, nil if unknown
        var displayValue: String {
            strokes.map(String.init) ?? "—"
        }
    }
}

extension LeaderboardEntry {
    /// Format a to-par integer as "E", "-3", "+5".
    static func formatToPar(_ value: Int?) -> String {
        guard let value else { return "—" }
        if value == 0 { return "E" }
        return value > 0 ? "+\(value)" : "\(value)"
    }
}
