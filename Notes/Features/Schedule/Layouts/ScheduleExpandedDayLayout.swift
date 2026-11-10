import SwiftUI

struct ScheduleExpandedDayLayout: View {
    let day: Date
    let items: [ScheduleItem]
    let size: CGSize
    let onSelectSchedule: (UUID) -> Void
    let onDeleteSchedule: (UUID) -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black
                .opacity(0.10)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture(perform: onDismiss)

            ScheduleDayCard(
                day: day,
                items: items,
                onSelectSchedule: onSelectSchedule,
                onDeleteSchedule: onDeleteSchedule
            )
            .fixedSize(horizontal: false, vertical: true)
            .frame(width: min(520, max(0, size.width - AppTheme.pageInset * 2)))
            .transition(.scale(scale: 0.88).combined(with: .opacity))
        }
    }
}
