import SwiftUI

struct ScheduleOverviewLayout: View {
    let size: CGSize
    let days: [ScheduleDayGroup]
    let onSelectDay: (Date) -> Void

    var body: some View {
        let horizontalPadding = AppTheme.pageInset
        let columnSpacing = AppTheme.cardSpacing
        let cardWidth = max(0, (
            size.width - horizontalPadding * 2 - columnSpacing
        ) / 2)

        return ScrollView {
            if days.isEmpty {
                Text("No schedules yet.")
                    .font(.body)
                    .foregroundStyle(AppTheme.inactive)
                    .frame(maxWidth: .infinity)
                    .padding(.top, size.height * 0.38)
            } else if cardWidth > 0 {
                MasonryLayout(columnWidth: cardWidth, spacing: columnSpacing) {
                    ForEach(days, id: \.day) { group in
                        ScheduleOverviewCard(group: group) {
                            onSelectDay(group.day)
                        }
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 88)
                .padding(.bottom, 24)
            }
        }
        .scrollIndicators(.hidden)
    }

}
