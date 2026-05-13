import SwiftUI

struct TitleBar: View {
    @Environment(AppState.self) private var state
    @State private var pickerOpen = false

    var body: some View {
        HStack {
            Spacer(minLength: 0)
            tournamentButton
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(height: 32)
        // Whole bar is a drag handle for the floating panel.
        .contentShape(Rectangle())
    }

    private var tournamentButton: some View {
        Button {
            pickerOpen.toggle()
        } label: {
            HStack(spacing: 5) {
                Text(displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .popover(isPresented: $pickerOpen, arrowEdge: .top) {
            TournamentPicker(isPresented: $pickerOpen)
                .environment(state)
        }
    }

    private var displayName: String {
        state.selectedTournament?.shortName
            ?? state.selectedTournament?.name
            ?? "Scorecard"
    }
}
