import SwiftUI

struct BottomTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 0) {
            tabButton(
                for: .home,
                title: "Home",
                symbol: "house",
                selectedSymbol: "house.fill"
            )
            tabButton(
                for: .notes,
                title: "Notes",
                symbol: "square.stack",
                selectedSymbol: "square.stack.fill"
            )
            tabButton(
                for: .schedule,
                title: "Schedule",
                symbol: "calendar",
                selectedSymbol: "calendar"
            )
        }
        .frame(height: 60)
        .background {
            AppTheme.surface
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private func tabButton(
        for tab: AppTab,
        title: String,
        symbol: String,
        selectedSymbol: String
    ) -> some View {
        let isSelected = selection == tab

        return Button {
            selection = tab
        } label: {
            VStack(spacing: 5) {
                AppIcon(
                    systemName: isSelected ? selectedSymbol : symbol,
                    size: 24,
                    weight: isSelected ? .semibold : .regular
                )
                .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.inactive)

                Text(title)
                    .font(.caption2.weight(isSelected ? .semibold : .medium))
            }
            .foregroundStyle(
                isSelected ? AppTheme.accentInk : AppTheme.inactive
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
