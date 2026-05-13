import SwiftUI

struct LeaderboardView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        // `GlassEffectContainer` lets the title-bar chip and the surrounding
        // window glass coordinate their lensing instead of stacking flatly.
        GlassEffectContainer(spacing: 6) {
            VStack(spacing: 0) {
                TitleBar()
                Divider()
                    .opacity(0.35)
                content
                StatusFooter()
            }
            .frame(minWidth: 280, minHeight: 360)
            // Whole-window Liquid Glass, tinted just enough to read on bright
            // desktops. The edge highlight gives a hairline curve at the rim;
            // the drop shadow is drawn by the NSPanel itself.
            .glassEffect(Glass.regular, in: panelShape)
            .overlay(GlassEdgeHighlight())
            .clipShape(panelShape)
        }
    }

    @ViewBuilder private var content: some View {
        switch state.loadState {
        case .idle, .loading where state.leaderboard == nil:
            LoadingState()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message) where state.leaderboard == nil:
            ErrorState(message: message)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        default:
            if let board = state.leaderboard {
                LeaderboardList(board: board)
            } else {
                EmptyState()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

private struct LoadingState: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.regular)
            Text("Loading leaderboard…")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

private struct EmptyState: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.tertiary)
            Text("No active tournaments")
                .font(.callout)
                .foregroundStyle(.secondary)
            Text("We'll check again automatically.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .multilineTextAlignment(.center)
        .padding()
    }
}

private struct ErrorState: View {
    let message: String
    @Environment(AppState.self) private var state

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(.orange)
            Text("Couldn't load leaderboard")
                .font(.callout)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Try again") {
                Task { await state.refresh() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
    }
}
