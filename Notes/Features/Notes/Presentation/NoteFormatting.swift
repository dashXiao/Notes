import Foundation

enum NoteFormatting {
    static func cardDateText(_ note: Note, timeZone: TimeZone = .current) -> String {
        if let editedAt = note.editedAt {
            return "Edited at \(text(editedAt, format: "MMM d", timeZone: timeZone))"
        }
        return text(note.createdAt, format: "MMM d", timeZone: timeZone)
    }

    static func detailDateTimeText(_ date: Date, timeZone: TimeZone = .current) -> String {
        text(date, format: "MMMM d, yyyy 'at' h:mm a", timeZone: timeZone)
    }

    private static func text(_ date: Date, format: String, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}
