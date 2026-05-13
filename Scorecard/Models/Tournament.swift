import Foundation

struct Tournament: Identifiable, Hashable, Sendable {
    enum State: String, Hashable, Sendable {
        case scheduled       // Hasn't teed off yet
        case inProgress      // At least one round is live
        case suspended       // Weather / darkness etc.
        case final           // Completed
    }

    let id: String           // ESPN event id
    let league: League
    let name: String
    let shortName: String
    let startDate: Date
    let endDate: Date
    let state: State
    let statusDetail: String // "Round 2 — In Progress", "Final", etc.
    let courseName: String?
    let currentRound: Int?
    let cutScore: Int?       // Score to par needed to make the cut, if known
    let competitionID: String

    /// True when the tournament is happening, about to start within a week,
    /// or just wrapped up in the last day or so.
    var isLiveOrImminent: Bool {
        switch state {
        case .inProgress, .suspended:
            return true
        case .scheduled:
            let days = Calendar.current.dateComponents([.day], from: Date(), to: startDate).day ?? .max
            return days <= 7
        case .final:
            let days = Calendar.current.dateComponents([.day], from: endDate, to: Date()).day ?? .max
            return days <= 1
        }
    }
}
