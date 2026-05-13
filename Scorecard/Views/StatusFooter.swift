import SwiftUI

struct StatusFooter: View {
    @Environment(AppState.self) private var state

    var body: some View {
        HStack(spacing: 6) {
            statusDot
            Text(statusText)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
            Spacer(minLength: 0)
            if let status = roundStatus, !status.isEmpty {
                Text(status)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        // No background — sit on the panel's Liquid Glass surface.
    }

    private var roundStatus: String? {
        state.selectedTournament?.statusDetail
    }

    @ViewBuilder
    private var statusDot: some View {
        switch state.loadState {
        case .loading:
            ProgressView()
                .controlSize(.mini)
                .scaleEffect(0.6)
                .frame(width: 8, height: 8)
        case .failed:
            Circle().fill(.red).frame(width: 6, height: 6)
        case .ready:
            Circle().fill(.green.opacity(0.8)).frame(width: 6, height: 6)
        case .idle:
            Circle().fill(.secondary.opacity(0.5)).frame(width: 6, height: 6)
        }
    }

    private var statusText: String {
        switch state.loadState {
        case .idle: return ""
        case .loading: return "Updating…"
        case .failed(let msg): return msg
        case .ready(let date): return "Updated \(relative(date))"
        }
    }

    private func relative(_ date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        if seconds < 30 { return "just now" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
