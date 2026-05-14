import SwiftUI

struct TitleBar: View {
    @Environment(AppState.self) private var state
    @State private var pickerOpen = false

    var body: some View {
        HStack(spacing: 0) {
            // Fixed-width drag wings on either side — a flexible
            // (`.infinity`) width here would gobble all the space and
            // shrink the centered button down to its truncated minimum.
            // Each wing still gives ~28pt of drag target.
            WindowDragHandle()
                .frame(width: 28, height: 32)
            tournamentButton
                .frame(maxWidth: .infinity)
            WindowDragHandle()
                .frame(width: 28, height: 32)
        }
        .padding(.horizontal, 12)
        .frame(height: 32)
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
            // Larger horizontal padding gives the picker chip a more
            // generous click target while still leaving room on either
            // side for the WindowDragHandle wings to grab.
            .padding(.horizontal, 16)
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
