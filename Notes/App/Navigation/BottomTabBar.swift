import SwiftUI

struct BottomTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 0) {
            tabButton(
                for: .home,
                title: "Home",
                imageName: "HomeIcon"
            )
            tabButton(
                for: .notes,
                title: "Notes",
                imageName: "NotesIcon"
            )
            tabButton(
                for: .schedule,
                title: "Schedule",
                imageName: "ScheduleIcon"
            )
        }
        .frame(height: 52)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppTheme.bottomBorder)
                .frame(height: 1)
        }
        .background {
            Color(.systemBackground)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private func tabButton(
        for tab: AppTab,
        title: String,
        imageName: String
    ) -> some View {
        let isSelected = selection == tab

        return Button {
            selection = tab
        } label: {
            VStack(spacing: 4) {
                Image(imageName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)

                Text(title)
                    .font(.callout)
            }
            .foregroundStyle(
                isSelected ? AppTheme.accent : AppTheme.inactive
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                if isSelected {
                    AppTheme.cream
                        .ignoresSafeArea(edges: .bottom)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
