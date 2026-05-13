import SwiftUI

struct TournamentPicker: View {
    @Environment(AppState.self) private var state
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if state.activeTournaments.isEmpty {
                Text("No active tournaments")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 18)
                    .padding(.horizontal, 14)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                        ForEach(groupedByLeague(), id: \.league) { group in
                            Section {
                                ForEach(group.tournaments) { tournament in
                                    TournamentRow(
                                        tournament: tournament,
                                        isSelected: tournament.id == state.selectedTournament?.id
                                    ) {
                                        state.select(tournament)
                                        isPresented = false
                                    }
                                    if tournament.id != group.tournaments.last?.id {
                                        Divider()
                                            .padding(.leading, 12)
                                            .opacity(0.4)
                                    }
                                }
                            } header: {
                                LeagueHeader(name: group.league.displayName)
                            }
                        }
                    }
                }
                .frame(maxHeight: 320)
            }
        }
        .frame(width: 280)
    }

    private var header: some View {
        HStack {
            Text("Active Tournaments")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Spacer()
            Button {
                Task { await state.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func groupedByLeague() -> [LeagueGroup] {
        let grouped = Dictionary(grouping: state.activeTournaments, by: \.league)
        return League.allCases.compactMap { league in
            guard let list = grouped[league], !list.isEmpty else { return nil }
            return LeagueGroup(league: league, tournaments: list)
        }
    }

    private struct LeagueGroup {
        let league: League
        let tournaments: [Tournament]
    }
}

private struct LeagueHeader: View {
    let name: String

    var body: some View {
        HStack {
            Text(name)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
                .tracking(0.5)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(Color.primary.opacity(0.04))
    }
}

private struct TournamentRow: View {
    let tournament: Tournament
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                stateIndicator
                VStack(alignment: .leading, spacing: 1) {
                    Text(tournament.shortName)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                    if let course = tournament.courseName {
                        Text(course)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.tint)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var stateIndicator: some View {
        switch tournament.state {
        case .inProgress:
            Circle()
                .fill(.green)
                .frame(width: 6, height: 6)
        case .suspended:
            Circle()
                .fill(.orange)
                .frame(width: 6, height: 6)
        case .scheduled:
            Circle()
                .stroke(Color.secondary.opacity(0.6), lineWidth: 1)
                .frame(width: 6, height: 6)
        case .final:
            Circle()
                .fill(.secondary.opacity(0.4))
                .frame(width: 6, height: 6)
        }
    }
}
