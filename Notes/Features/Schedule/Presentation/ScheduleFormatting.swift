import Foundation

enum ScheduleFormatting {
    static func toastDateText(_ item: ScheduleItem) -> String {
        DisplayDateFormatting.text(item.scheduledAt, format: "MMM d, yyyy")
    }

    static func toastTimeText(_ item: ScheduleItem) -> String {
        item.timeIsPending == true ? "TBD" : DisplayDateFormatting.text(item.scheduledAt, format: "HH:mm")
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
