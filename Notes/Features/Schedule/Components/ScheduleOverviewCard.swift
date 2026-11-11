import SwiftUI

struct ScheduleOverviewCard: View {
    let group: ScheduleDayGroup
    let onSelectDay: () -> Void

    var body: some View {
        Button(action: onSelectDay) {
            VStack(alignment: .leading, spacing: 10) {
                ScheduleDateHeader(day: group.day, isCompact: true)

                VStack(alignment: .leading, spacing: 7) {
                    ForEach(
                        Array(group.items.prefix(3).enumerated()),
                        id: \.element.id
                    ) { index, item in
                        let showsOverflow = index == 2
                            && group.items.count > 3

                        HStack(alignment: .top, spacing: 8) {
                            Text(ScheduleFormatting.timeText(item))
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppTheme.accentInk)
                                .frame(width: 34, alignment: .leading)

                            Text(
                                item.title
                                    + (showsOverflow ? " …" : "")
                            )
                                .font(.footnote)
                                .foregroundStyle(AppTheme.textPrimary)
                                .lineLimit(2)
                                .truncationMode(.tail)
                                .frame(
                                    maxWidth: .infinity,
                                    alignment: .leading
                                )
                        }
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
            .contentShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "\(group.day.formatted(.dateTime.month(.wide).day())), "
                + "\(group.items.count) schedules"
        )
        .accessibilityHint("Open all schedules for this day")
    }
}
