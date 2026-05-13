import Foundation

enum League: String, CaseIterable, Codable, Hashable, Sendable, Identifiable {
    case pga
    case liv
    case lpga
    case dpworld
    case kornferry
    case champions

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pga: "PGA Tour"
        case .liv: "LIV Golf"
        case .lpga: "LPGA Tour"
        case .dpworld: "DP World Tour"
        case .kornferry: "Korn Ferry Tour"
        case .champions: "PGA Tour Champions"
        }
    }

    /// Path segment used by ESPN's `/sports/golf/{slug}/...` endpoints.
    var espnSlug: String {
        switch self {
        case .pga: "pga"
        case .liv: "liv-golf"
        case .lpga: "lpga"
        case .dpworld: "eur"
        case .kornferry: "ntw"
        case .champions: "champions-tour"
        }
    }
}
