import SwiftUI

struct ScheduleDayCard: View {
    let day: Date
    let items: [ScheduleItem]
    let onSelectSchedule: (UUID) -> Void
    let onDeleteSchedule: (UUID) -> Void

    private var emptyMessage: String {
        Calendar.current.isDateInToday(day)
            ? "No schedule today."
            : "No schedule for this day."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if items.isEmpty {
                VStack(spacing: 14) {
                    AppIcon(systemName: "calendar.badge.clock", size: 32, weight: .regular)
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 72, height: 72)
                        .background(AppTheme.accentTint, in: Circle())
                    Text(emptyMessage)
                        .font(.callout)
                        .foregroundStyle(AppTheme.inactive)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .transition(.opacity)
            } else {
                ScheduleDateHeader(day: day)

                VStack(spacing: 10) {
                    ForEach(items) { item in
                        SwipeableScheduleRow(
                            item: item,
                            onSelect: {
                                onSelectSchedule(item.id)
                            },
                            onDelete: {
                                onDeleteSchedule(item.id)
                            }
                        )
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    }
}
