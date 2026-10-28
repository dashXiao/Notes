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
        VStack(alignment: .leading, spacing: 20) {
            if items.isEmpty {
                Text(emptyMessage)
                    .font(.callout)
                    .foregroundStyle(AppTheme.inactive)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
            } else {
                ScheduleDateHeader(day: day)

                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) {
                        index,
                        item in

                        SwipeableScheduleRow(
                            item: item,
                            onSelect: {
                                onSelectSchedule(item.id)
                            },
                            onDelete: {
                                onDeleteSchedule(item.id)
                            }
                        )

                        if index < items.count - 1 {
                            Rectangle()
                                .fill(AppTheme.bottomBorder)
                                .frame(height: 1)
                                .padding(.vertical, 16)
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .stroke(AppTheme.accent, lineWidth: 1)
        }
    }
}
