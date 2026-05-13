import Foundation

/// Reads golf data from ESPN's undocumented `site.api.espn.com` endpoints.
/// Same shape works for PGA, LPGA, LIV, DP World, Korn Ferry, Champions.
struct ESPNProvider: LeaderboardProvider {
    var supportedLeagues: [League] {
        [.pga, .liv, .lpga, .dpworld, .kornferry, .champions]
    }

    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            if let date = Self.parseDate(raw) { return date }
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Unrecognized date: \(raw)"
            )
        }
        self.decoder = d
    }

    /// ESPN ships at least three flavors: with millis, with seconds, and
    /// minute-precision ("2026-05-14T04:00Z"). Try them in order of likelihood.
    private static func parseDate(_ raw: String) -> Date? {
        if let d = isoMillis.date(from: raw) { return d }
        if let d = isoSeconds.date(from: raw) { return d }
        if let d = isoMinutes.date(from: raw) { return d }
        return nil
    }

    private nonisolated(unsafe) static let isoMillis: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private nonisolated(unsafe) static let isoSeconds: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private nonisolated(unsafe) static let isoMinutes: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd'T'HH:mm'Z'"
        return f
    }()

    func activeTournaments() async throws -> [Tournament] {
        // Fan out across leagues in parallel; ignore individual league failures
        // so one outage doesn't take down the whole picker.
        let leagues = supportedLeagues
        let lists: [[Tournament]] = await withTaskGroup(of: [Tournament].self) { group in
            for league in leagues {
                group.addTask {
                    (try? await self.tournaments(for: league)) ?? []
                }
            }
            var out: [[Tournament]] = []
            for await list in group { out.append(list) }
            return out
        }
        return lists.flatMap { $0 }
            .filter(\.isLiveOrImminent)
            .sorted { lhs, rhs in
                if lhs.state.priority != rhs.state.priority {
                    return lhs.state.priority < rhs.state.priority
                }
                return lhs.startDate < rhs.startDate
            }
    }

    func leaderboard(for tournament: Tournament) async throws -> Leaderboard {
        let url = scoreboardURL(for: tournament.league, eventID: tournament.id)
        let response = try await fetch(ScoreboardEnvelope.self, from: url)
        guard let event = response.events.first(where: { $0.id == tournament.id }) ?? response.events.first else {
            throw ProviderError.notFound
        }
        let updated = try? Self.normalize(event: event, league: tournament.league)
        let refreshedTournament = updated?.tournament ?? tournament
        let entries = updated?.entries ?? []
        return Leaderboard(
            tournament: refreshedTournament,
            entries: entries.sorted { Leaderboard.sortRank($0) < Leaderboard.sortRank($1) },
            lastUpdated: Date()
        )
    }

    func scorecard(playerID: String, tournament: Tournament) async throws -> Scorecard {
        // V1: derive a round-summary scorecard from the scoreboard payload.
        // (Per-hole detail is available from a separate ESPN endpoint and is a
        // planned enhancement.)
        let board = try await leaderboard(for: tournament)
        guard let entry = board.entries.first(where: { $0.id == playerID }) else {
            throw ProviderError.notFound
        }
        let rounds: [Scorecard.Round] = entry.rounds.map { roundTotal in
            Scorecard.Round(
                id: roundTotal.id,
                holes: [],
                strokes: roundTotal.strokes,
                toPar: roundTotal.toPar
            )
        }
        return Scorecard(
            playerID: playerID,
            playerName: entry.playerName,
            tournamentID: tournament.id,
            league: tournament.league,
            rounds: rounds
        )
    }

    // MARK: - Internals

    private func tournaments(for league: League) async throws -> [Tournament] {
        let url = scoreboardURL(for: league, eventID: nil)
        let response = try await fetch(ScoreboardEnvelope.self, from: url)
        return response.events.compactMap { event in
            (try? Self.normalize(event: event, league: league))?.tournament
        }
    }

    private func scoreboardURL(for league: League, eventID: String?) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "site.api.espn.com"
        components.path = "/apis/site/v2/sports/golf/\(league.espnSlug)/scoreboard"
        if let eventID {
            components.queryItems = [URLQueryItem(name: "event", value: eventID)]
        }
        return components.url!
    }

    private func fetch<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw ProviderError.badResponse(http.statusCode)
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw ProviderError.decode(String(describing: error))
        }
    }

    private struct ScoreboardEnvelope: Decodable {
        let events: [ESPN.Event]
    }

    // MARK: - Normalization

    private struct NormalizedEvent {
        let tournament: Tournament
        let entries: [LeaderboardEntry]
    }

    private static func normalize(event: ESPN.Event, league: League) throws -> NormalizedEvent {
        let competition = event.competitions?.first
        let state = mapState(event.status?.type, completed: event.status?.type?.completed)
        let course = competition?.course?.first
        let par = course?.shotsToPar
        let cutScore = extractCutScore(from: competition?.notes)
        let tournament = Tournament(
            id: event.id,
            league: league,
            name: event.name,
            shortName: event.shortName ?? event.name,
            startDate: event.date ?? .distantPast,
            endDate: event.endDate ?? event.date ?? .distantPast,
            state: state,
            statusDetail: event.status?.type?.detail ?? event.status?.type?.shortDetail ?? "",
            courseName: course?.name ?? competition?.venue?.fullName,
            currentRound: event.status?.period,
            cutScore: cutScore,
            competitionID: competition?.id ?? event.id
        )
        let entries = (competition?.competitors ?? []).compactMap {
            normalize(competitor: $0, par: par)
        }
        return NormalizedEvent(tournament: tournament, entries: entries)
    }

    private static func normalize(competitor: ESPN.Competitor, par: Int?) -> LeaderboardEntry? {
        guard let name = competitor.athlete?.displayName else { return nil }
        let athleteID = competitor.athlete?.id ?? competitor.id
        let positionDisplay = competitor.status?.position?.displayName ?? "—"
        let positionRank = Int(competitor.status?.position?.id ?? "")
        let scoreToPar = competitor.score?.intValue
        let today = competitor.today?.intValue
        let thru = competitor.status?.displayThru
            ?? (competitor.status?.thru.map { $0 == 18 ? "F" : String($0) })
            ?? "—"
        let status = mapPlayerStatus(positionDisplay: positionDisplay, thru: competitor.status?.thru, displayThru: competitor.status?.displayThru)
        let rounds: [LeaderboardEntry.RoundTotal] = (competitor.linescores ?? []).enumerated().map { idx, line in
            let strokes = line.value.flatMap { $0 > 0 ? Int($0) : nil }
            let toPar: Int? = {
                guard let par, let strokes else { return nil }
                return strokes - par
            }()
            return LeaderboardEntry.RoundTotal(
                id: line.period ?? (idx + 1),
                strokes: strokes,
                toPar: toPar
            )
        }
        return LeaderboardEntry(
            id: athleteID,
            playerName: name,
            countryFlag: competitor.athlete?.flag?.href.flatMap(URL.init(string:)),
            headshot: competitor.athlete?.headshot?.href.flatMap(URL.init(string:)),
            positionDisplay: positionDisplay,
            positionRank: positionRank,
            scoreToPar: scoreToPar,
            today: today,
            thruDisplay: thru,
            rounds: rounds,
            status: status
        )
    }

    private static func mapState(_ type: ESPN.StatusType?, completed: Bool?) -> Tournament.State {
        if completed == true { return .final }
        switch type?.state {
        case "in": return .inProgress
        case "post": return .final
        case "pre": return .scheduled
        default:
            let detail = (type?.detail ?? "").lowercased()
            if detail.contains("suspend") { return .suspended }
            return .scheduled
        }
    }

    private static func mapPlayerStatus(positionDisplay: String, thru: Int?, displayThru: String?) -> LeaderboardEntry.PlayerStatus {
        let upper = positionDisplay.uppercased()
        if upper.contains("CUT") { return .cut }
        if upper.contains("WD") { return .withdrawn }
        if upper.contains("DQ") { return .disqualified }
        let display = (displayThru ?? "").uppercased()
        if display == "F" || thru == 18 { return .finished }
        if let thru, thru > 0 { return .playing }
        if display == "—" || display.isEmpty { return .active }
        return .teeing
    }

    private static func extractCutScore(from notes: [ESPN.Note]?) -> Int? {
        guard let notes else { return nil }
        for note in notes {
            guard let head = note.headline else { continue }
            // Patterns we've seen: "Projected cut: +3", "Cut line: E", "Cut: -1"
            let lower = head.lowercased()
            guard lower.contains("cut") else { continue }
            let scanner = Scanner(string: head)
            scanner.charactersToBeSkipped = .whitespaces
            // Skip until we hit a digit, +, -, or "E"
            while !scanner.isAtEnd {
                let next = scanner.string[scanner.currentIndex]
                if next.isNumber || next == "+" || next == "-" || next.uppercased() == "E" { break }
                scanner.currentIndex = scanner.string.index(after: scanner.currentIndex)
            }
            if scanner.isAtEnd { continue }
            if let s = scanner.scanCharacters(from: CharacterSet(charactersIn: "+-0123456789E")) {
                if s.uppercased() == "E" { return 0 }
                return Int(s)
            }
        }
        return nil
    }
}

private extension Tournament.State {
    var priority: Int {
        switch self {
        case .inProgress, .suspended: 0
        case .scheduled: 1
        case .final: 2
        }
    }
}
