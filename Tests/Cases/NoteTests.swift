import Foundation

extension RegressionSuite {
    static func testNoteDates() async throws {
        let disk = storage()
        defer { try? FileManager.default.removeItem(at: disk.directory) }
        let createdAt = ISO8601DateFormatter().date(from: "2020-12-31T23:45:59Z")!
        let original = Note(id: UUID(), text: "Original note", createdAt: createdAt, updatedAt: createdAt)
        try disk.save([original], to: "notes.json")
        let notes = NotesStore(storage: disk)
        let unchanged = notes.saveNote(id: original.id, text: "  Original note\n")!
        try expect(unchanged == original && unchanged.editedAt == nil, "Saving unchanged content marked a note as edited")
        let updated = notes.saveNote(id: original.id, text: "Changed note")!
        try expect(updated.createdAt == createdAt && updated.editedAt != nil, "Editing lost the creation date or edit time")
        let savedAgain = notes.saveNote(id: original.id, text: updated.text)!
        try expect(savedAgain.updatedAt == updated.updatedAt, "An unchanged save advanced the edit time")
        try expect(NotesStore(storage: disk).note(with: original.id) == updated, "Note dates did not survive reloading")
        let newNote = notes.saveNote(text: "New note")!
        try expect(newNote.createdAt == newNote.updatedAt && newNote.editedAt == nil, "A new note is marked as edited")

        let newEditor = NoteEditorModel(note: nil)
        let originalEditor = NoteEditorModel(note: original)
        let editedEditor = NoteEditorModel(note: updated)
        try expect(newEditor.lastModifiedAt == nil, "Unsaved notes show saved dates")
        try expect(originalEditor.lastModifiedAt == createdAt, "Unedited note does not show its creation time")
        try expect(editedEditor.lastModifiedAt == updated.updatedAt, "Edited note does not show its latest edit time")

        let utc = TimeZone(secondsFromGMT: 0)!
        let nextDay = TimeZone(secondsFromGMT: 3600)!
        var edited = original
        edited.updatedAt = createdAt.addingTimeInterval(3600)
        try expect(NoteFormatting.cardDateText(original, timeZone: utc) == "Dec 31", "Unedited card does not show an abbreviated month and day")
        try expect(NoteFormatting.cardDateText(edited, timeZone: utc) == "Edited at Jan 1", "Edited card does not show its latest edit date with an abbreviated month")
        try expect(NoteFormatting.detailDateTimeText(createdAt, timeZone: utc) == "December 31, 2020 at 11:45 PM", "Detail timestamp does not match the English 12-hour format")
        try expect(NoteFormatting.detailDateTimeText(createdAt, timeZone: nextDay) == "January 1, 2021 at 12:45 AM", "Detail timestamp ignores the local date boundary")
        let example = ISO8601DateFormatter().date(from: "2026-11-09T21:18:00Z")!
        try expect(NoteFormatting.detailDateTimeText(example, timeZone: utc) == "November 9, 2026 at 9:18 PM", "Detail timestamp does not match the supplied example")
    }

    static func testNoteOrdering() async throws {
        let disk = storage()
        defer { try? FileManager.default.removeItem(at: disk.directory) }
        let date = Date(timeIntervalSince1970: 1_600_000_000)
        let older = Note(id: UUID(), text: "Older note", createdAt: date, updatedAt: date.addingTimeInterval(120))
        let newer = Note(id: UUID(), text: "Newer note", createdAt: date.addingTimeInterval(60), updatedAt: date.addingTimeInterval(60))
        try disk.save([older, newer], to: "notes.json")
        let notes = NotesStore(storage: disk)
        let expectedOrder = [newer.id, older.id]
        try expect(notes.notes.map(\.id) == expectedOrder, "Loading used edit times instead of creation times")
        notes.saveNote(id: older.id, text: "Edited older note")
        try expect(notes.notes.map(\.id) == expectedOrder, "Editing moved an old note to the top")
        let created = notes.saveNote(text: "Newly created note")!
        try expect(notes.notes.map(\.id) == [created.id] + expectedOrder, "A new note was not placed first")
        try expect(NotesStore(storage: disk).notes.map(\.id) == [created.id] + expectedOrder, "Creation order changed after reloading")
    }
}
