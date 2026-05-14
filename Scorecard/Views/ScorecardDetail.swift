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
                return RoundCell(round: round, strokes: rt.strokes, toPar: rt.toPar)
            } else {
                return RoundCell(round: round, strokes: nil, toPar: nil)
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
        let strokes: Int?
        let toPar: Int?
        var id: Int { round }
    }

    private struct RoundChip: View {
        let cell: RoundCell

        var body: some View {
            VStack(spacing: 3) {
                Text("R\(cell.round)")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.tertiary)
                // Score-to-par for the round so far. This is the right number
                // for both a finished round and a mid-round (shotgun or not):
                // for LIV's shotgun starts the gross stroke count for an
                // incomplete round is ambiguous without also knowing how
                // many holes have been played — to-par stays meaningful.
                Text(LeaderboardEntry.formatToPar(cell.toPar))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(toParStyle)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(.thinMaterial)
            )
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
