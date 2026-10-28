import Combine
import Foundation

@MainActor
final class ScheduleEditorModel: ObservableObject {
    @Published var day: Date
    @Published var time: Date
    @Published var title: String
    @Published var isTimePending: Bool

    private let scheduleID: UUID?

    init(item: ScheduleItem?, day: Date) {
        scheduleID = item?.id
        let initialDay = Calendar.current.startOfDay(for: item?.scheduledAt ?? day)
        self.day = initialDay
        time = item?.scheduledAt ?? Self.defaultTime(for: initialDay)
        title = item?.title ?? ""
        isTimePending = item?.timeIsPending == true
    }

    var isEditing: Bool { scheduleID != nil }

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func save(in store: ScheduleStore) -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let scheduledAt = isTimePending
            ? calendar.startOfDay(for: day)
            : calendar.date(
                bySettingHour: components.hour ?? 0,
                minute: components.minute ?? 0,
                second: 0,
                of: day
            )
        guard let scheduledAt else { return false }
        return store.saveItem(
            id: scheduleID,
            scheduledAt: scheduledAt,
            title: title,
            timeIsPending: isTimePending
        )
    }

    private static func defaultTime(for day: Date) -> Date {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return Date() }
        return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: day) ?? day
    }
}
