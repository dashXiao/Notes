import Foundation

enum NoteFormatting {
    static func cardDateText(_ note: Note, timeZone: TimeZone = .current) -> String {
        if let editedAt = note.editedAt {
            return "Edited at \(DisplayDateFormatting.text(editedAt, format: "MMM d", timeZone: timeZone))"
        }
        return DisplayDateFormatting.text(note.createdAt, format: "MMM d", timeZone: timeZone)
    }

    static func detailDateTimeText(_ date: Date, timeZone: TimeZone = .current) -> String {
        DisplayDateFormatting.text(date, format: "MMMM d, yyyy 'at' h:mm a", timeZone: timeZone)
    }
}
