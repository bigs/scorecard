import SwiftUI

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let tournament: Tournament
    let isExpanded: Bool
    let isStarred: Bool
    let accent: Bool

    var body: some View {
        VStack(spacing: 0) {
            mainRow
            if isExpanded {
                ScorecardDetail(entry: entry, tournament: tournament)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 10)
                    // Pure opacity transition: the container is laid out at
                    // natural size and the VStack grows to fit it, so the
                    // detail reveals itself in place instead of sliding from
                    // beneath the row above. No material/zIndex tricks needed.
                    .transition(.opacity)
            }
        }
        .background {
            if accent {
                Color.accentColor.opacity(0.07)
            } else if isExpanded {
                Color.primary.opacity(0.05)
            }
        }
    }

    private var mainRow: some View {
        HStack(spacing: 8) {
            positionCell
            nameCell
            Spacer(minLength: 4)
            scoreCell
            thruCell
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
    }

    private var positionCell: some View {
        Text(entry.positionDisplay)
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundStyle(positionColor)
            .frame(width: 32, alignment: .leading)
    }

    private var positionColor: Color {
        switch entry.status {
        case .cut, .withdrawn, .disqualified: Color.secondary
        default: Color.primary
        }
    }

    private var nameCell: some View {
        HStack(spacing: 4) {
            if isStarred {
                Image(systemName: "star.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.tint)
            }
            Text(entry.playerName)
                .font(.system(size: 12, weight: accent ? .semibold : .regular))
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(entry.status == .cut ? Color.secondary : Color.primary)
        }
    }

    private var scoreCell: some View {
        Text(LeaderboardEntry.formatToPar(entry.scoreToPar))
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
            .foregroundStyle(scoreColor)
            .frame(width: 36, alignment: .trailing)
    }

    private var scoreColor: Color {
        switch entry.status {
        case .cut, .withdrawn, .disqualified:
            return Color.secondary
        default:
            if let s = entry.scoreToPar {
                return s < 0 ? Color.accentColor : Color.primary
            }
            return Color.secondary
        }
    }

    private var thruCell: some View {
        Text(entry.thruDisplay)
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(.secondary)
            .frame(width: 28, alignment: .trailing)
    }
}
