import Foundation

/// Per-hole detail for a single player at a single tournament.
struct Scorecard: Hashable, Sendable {
    struct Hole: Identifiable, Hashable, Sendable {
        let id: Int          // hole number, 1..18
        let par: Int?
        let strokes: Int?
        var toPar: Int? {
            guard let par, let strokes else { return nil }
            return strokes - par
        }
    }

    struct Round: Identifiable, Hashable, Sendable {
        let id: Int          // round number, 1..4
        let holes: [Hole]
        let strokes: Int?
        let toPar: Int?

        var frontNineStrokes: Int? {
            holes.prefix(9).compactMap(\.strokes).reduce(0, +).nilIfZero
        }
        var backNineStrokes: Int? {
            holes.dropFirst(9).compactMap(\.strokes).reduce(0, +).nilIfZero
        }
    }

    let playerID: String
    let playerName: String
    let tournamentID: String
    let league: League
    let rounds: [Round]

    /// Deep link to ESPN's scorecard page for the user.
    var espnURL: URL? {
        URL(string: "https://www.espn.com/golf/player/scorecards/_/id/\(playerID)/tournamentId/\(tournamentID)")
    }
}

private extension Int {
    var nilIfZero: Int? { self == 0 ? nil : self }
}
