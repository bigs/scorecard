import SwiftUI

struct ScorecardDetail: View {
    let entry: LeaderboardEntry
    let tournament: Tournament

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            roundsTable
            HStack(spacing: 12) {
                if let today = entry.today {
                    Stat(label: "Today", value: LeaderboardEntry.formatToPar(today))
                }
                Spacer(minLength: 0)
                if let url = espnURL {
                    Link(destination: url) {
                        Label("ESPN", systemImage: "arrow.up.right.square")
                            .labelStyle(.titleAndIcon)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var roundsTable: some View {
        let cells: [RoundCell] = (1...4).map { round in
            if let rt = entry.rounds.first(where: { $0.id == round }) {
                return RoundCell(round: round, toPar: rt.toPar, state: rt.state)
            } else {
                return RoundCell(round: round, toPar: nil, state: .notStarted)
            }
        }
        return HStack(spacing: 6) {
            ForEach(cells) { cell in
                RoundChip(cell: cell)
            }
        }
    }

    private var espnURL: URL? {
        URL(string: "https://www.espn.com/golf/player/scorecards/_/id/\(entry.id)/tournamentId/\(tournament.id)")
    }

    private struct RoundCell: Identifiable {
        let round: Int
        let toPar: Int?
        let state: LeaderboardEntry.RoundTotal.State
        var id: Int { round }
    }

    private struct RoundChip: View {
        let cell: RoundCell

        var body: some View {
            VStack(spacing: 3) {
                Text("R\(cell.round)")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.tertiary)
                // Score-to-par for the round so far. Meaningful for both
                // completed rounds and in-progress rounds (and works for
                // LIV's shotgun starts, where the gross stroke total for
                // an incomplete round would be ambiguous).
                Text(LeaderboardEntry.formatToPar(cell.toPar))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(toParStyle)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(.thinMaterial)
            }
            .overlay {
                if cell.state == .inProgress {
                    // Tertiary stroke matches the chip's "R1/R2/R3/R4"
                    // label color so the live-round affordance lives in the
                    // same visual register as the rest of the chip. The
                    // under-par text color already carries the loudness.
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(.tertiary, lineWidth: 1)
                }
            }
        }

        private var toParStyle: AnyShapeStyle {
            guard let t = cell.toPar else { return AnyShapeStyle(HierarchicalShapeStyle.tertiary) }
            if t < 0 { return AnyShapeStyle(Color.accentColor) }
            if t > 0 { return AnyShapeStyle(HierarchicalShapeStyle.secondary) }
            return AnyShapeStyle(HierarchicalShapeStyle.primary)
        }
    }

    private struct Stat: View {
        let label: String
        let value: String

        var body: some View {
            HStack(spacing: 3) {
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)
                Text(value)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
            }
        }
    }
}
