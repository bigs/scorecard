import Foundation

/// Decodable shapes for ESPN's `site.api.espn.com` golf scoreboard responses.
/// Kept tolerant — ESPN's payload varies by tournament state, so most fields
/// are optional.
enum ESPN {
    struct ScoreboardResponse: Decodable {
        let events: [Event]
    }

    struct Event: Decodable {
        let id: String
        let name: String
        let shortName: String?
        let date: Date?
        let endDate: Date?
        let status: Status?
        let competitions: [Competition]?
    }

    struct Status: Decodable {
        let period: Int?
        let type: StatusType?
    }

    struct StatusType: Decodable {
        let state: String?       // "pre" | "in" | "post"
        let completed: Bool?
        let detail: String?
        let shortDetail: String?
        let description: String?
    }

    struct Competition: Decodable {
        let id: String
        let venue: Venue?
        let course: [Course]?
        let status: Status?
        let competitors: [Competitor]?
        let notes: [Note]?
    }

    struct Note: Decodable {
        let type: String?
        let headline: String?
    }

    struct Venue: Decodable {
        let fullName: String?
    }

    struct Course: Decodable {
        let name: String?
        let totalYards: Int?
        let shotsToPar: Int?
    }

    struct Competitor: Decodable {
        let id: String
        let athlete: Athlete?
        let status: CompetitorStatus?
        let linescores: [Linescore]?
        let score: FlexValue?
        let scoreDisplay: String?
        let today: FlexValue?
        let todayDisplay: String?
    }

    struct Athlete: Decodable {
        let id: String?
        let displayName: String?
        let headshot: Image?
        let flag: Image?
    }

    struct Image: Decodable {
        let href: String?
    }

    struct CompetitorStatus: Decodable {
        let position: Position?
        let thru: Int?
        let displayThru: String?
        let type: String?
        let displayValue: String?
        let hasTeed: Bool?
    }

    struct Position: Decodable {
        let id: String?
        let displayName: String?
    }

    struct Linescore: Decodable {
        let period: Int?
        let value: Double?
        let displayValue: String?
        /// Per-hole detail nested under each round's linescore. Mid-
        /// tournament this is the only place ESPN's `/scoreboard` exposes
        /// "thru" — the count is how many holes the player has played in
        /// the current round.
        let linescores: [Linescore]?
    }

    /// Some fields come back as a string ("E", "-12") or a number (-12).
    /// `FlexValue` decodes either and exposes both views.
    struct FlexValue: Decodable, Hashable, Sendable {
        let stringValue: String?
        let doubleValue: Double?

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let s = try? container.decode(String.self) {
                stringValue = s
                doubleValue = Self.numericFromString(s)
            } else if let d = try? container.decode(Double.self) {
                doubleValue = d
                stringValue = Self.formatNumeric(d)
            } else if container.decodeNil() {
                stringValue = nil
                doubleValue = nil
            } else {
                throw DecodingError.typeMismatch(
                    FlexValue.self,
                    .init(codingPath: decoder.codingPath, debugDescription: "Expected String or Number")
                )
            }
        }

        var intValue: Int? {
            if let d = doubleValue { return Int(d) }
            guard let s = stringValue else { return nil }
            if s.uppercased() == "E" { return 0 }
            return Int(s)
        }

        private static func numericFromString(_ s: String) -> Double? {
            if s.uppercased() == "E" { return 0 }
            return Double(s)
        }

        private static func formatNumeric(_ d: Double) -> String {
            let i = Int(d)
            if i == 0 { return "E" }
            return i > 0 ? "+\(i)" : "\(i)"
        }
    }
}
