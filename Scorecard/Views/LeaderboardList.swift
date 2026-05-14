import SwiftUI

struct LeaderboardList: View {
    let board: Leaderboard
    @Environment(AppState.self) private var state
    @Environment(StarredPlayersStore.self) private var starred

    var body: some View {
        GlassScrollView {
            // `GlassScrollView` hosts this content in an NSHostingView, so
            // re-inject our environment values; they don't automatically
            // bridge across the NSViewRepresentable boundary.
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                let starredEntries = board.entries.filter { starred.isStarred($0.id) }
                if !starredEntries.isEmpty {
                    Section {
                        ForEach(starredEntries) { entry in
                            row(for: entry, accent: true)
                        }
                    } header: {
                        SectionHeader(title: "Starred", systemImage: "star.fill")
                    }
                }
                Section {
                    ForEach(board.entries) { entry in
                        row(for: entry, accent: false)
                    }
                } header: {
                    if !starredEntries.isEmpty {
                        SectionHeader(title: "Field", systemImage: nil)
                    } else {
                        EmptyView()
                    }
                }
            }
            .environment(state)
            .environment(starred)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func row(for entry: LeaderboardEntry, accent: Bool) -> some View {
        LeaderboardRow(
            entry: entry,
            tournament: board.tournament,
            isExpanded: state.expandedPlayerID == entry.id,
            isStarred: starred.isStarred(entry.id),
            accent: accent
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.18)) {
                state.toggleExpand(entry.id)
            }
        }
        .contextMenu {
            Button {
                starred.toggle(entry.id)
            } label: {
                Label(
                    starred.isStarred(entry.id) ? "Unstar \(entry.playerName)" : "Star \(entry.playerName)",
                    systemImage: starred.isStarred(entry.id) ? "star.slash" : "star"
                )
            }
            if let url = URL(string: "https://www.espn.com/golf/player/scorecards/_/id/\(entry.id)/tournamentId/\(board.tournament.id)") {
                Divider()
                Link(destination: url) {
                    Label("View on ESPN", systemImage: "arrow.up.right.square")
                }
            }
        }
        Divider()
            .opacity(0.18)
    }
}

private struct SectionHeader: View {
    let title: String
    let systemImage: String?

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 9, weight: .bold))
            }
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .textCase(.uppercase)
                .tracking(0.6)
            Spacer()
        }
        .foregroundStyle(.tertiary)
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Section headers sit on top of the window's Liquid Glass surface;
        // an extra material would look hazy. A subtle tint reads cleaner.
        .background(Color.primary.opacity(0.04))
    }
}
