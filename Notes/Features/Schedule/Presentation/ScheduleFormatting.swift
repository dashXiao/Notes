import Foundation

enum ScheduleFormatting {
    static func toastDateText(_ item: ScheduleItem) -> String {
        toastText(item.scheduledAt, format: "MMM d, yyyy")
    }

    static func toastTimeText(_ item: ScheduleItem) -> String {
        item.timeIsPending == true ? "TBD" : toastText(item.scheduledAt, format: "HH:mm")
    }

    private static func toastText(_ date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = format
        return formatter.string(from: date)
    }

    static func timeText(_ item: ScheduleItem) -> String {
        item.timeIsPending == true
            ? "TBD"
            : item.scheduledAt.formatted(
                .dateTime
                    .hour(.twoDigits(amPM: .omitted))
                    .minute(.twoDigits)
            )
    }
}
