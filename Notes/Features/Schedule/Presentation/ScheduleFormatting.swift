import Foundation

enum ScheduleFormatting {
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
