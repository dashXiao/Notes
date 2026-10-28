import SwiftUI

struct ScheduleOverviewLayout: View {
    let size: CGSize
    let days: [ScheduleDayGroup]
    let onSelectDay: (Date) -> Void

    var body: some View {
        let horizontalPadding = 12.0
        let columnSpacing = 12.0
        let cardWidth = (
            size.width - horizontalPadding * 2 - columnSpacing
        ) / 2

        return ScrollView {
            if days.isEmpty {
                Text("No schedules yet.")
                    .font(.body)
                    .foregroundStyle(AppTheme.inactive)
                    .frame(maxWidth: .infinity)
                    .padding(.top, size.height * 0.38)
            } else {
                HStack(alignment: .top, spacing: columnSpacing) {
                    overviewColumn(
                        indices: Array(
                            stride(
                                from: 0,
                                to: days.count,
                                by: 2
                            )
                        ),
                        days: days,
                        cardWidth: cardWidth
                    )

                    overviewColumn(
                        indices: Array(
                            stride(
                                from: 1,
                                to: days.count,
                                by: 2
                            )
                        ),
                        days: days,
                        cardWidth: cardWidth
                    )
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 88)
                .padding(.bottom, 24)
            }
        }
        .scrollIndicators(.hidden)
    }

    private func overviewColumn(
        indices: [Int],
        days: [ScheduleDayGroup],
        cardWidth: CGFloat
    ) -> some View {
        LazyVStack(spacing: 12) {
            ForEach(indices, id: \.self) { index in
                let group = days[index]

                ScheduleOverviewCard(group: group) {
                    onSelectDay(group.day)
                }
                .frame(width: cardWidth)
            }
        }
        .frame(width: cardWidth)
    }

}
