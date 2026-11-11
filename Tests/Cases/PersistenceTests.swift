import Foundation

extension RegressionSuite {
    static func testPersistence() async throws {
        let disk = storage()
        defer { try? FileManager.default.removeItem(at: disk.directory) }
        let note = Note(id: UUID(), text: "Existing note", createdAt: Date(), updatedAt: Date())
        let legacyItem = ScheduleItem(id: UUID(), scheduledAt: tomorrow, title: "Existing schedule", createdAt: Date(), updatedAt: Date())
        try disk.save([note], to: "notes.json")
        // Legacy files omit both optional AI-related fields.
        let encoded = try JSONEncoder().encode([legacyItem])
        let object = try JSONSerialization.jsonObject(with: encoded) as! [[String: Any]]
        try expect(object[0]["timeIsPending"] == nil && object[0]["sourceNoteID"] == nil, "Legacy fixture includes new fields")
        try encoded.write(to: disk.directory.appendingPathComponent("schedules.json"))
        let notes = NotesStore(storage: disk)
        let schedules = ScheduleStore(storage: disk)
        try expect(notes.notes == [note], "Existing notes failed to load")
        try expect(schedules.items == [legacyItem], "Existing schedules failed to load")
        let updated = notes.saveNote(id: note.id, text: "  Updated note  ")!
        try expect(updated.id == note.id && updated.text == "Updated note", "Editing changed note identity")
        try expect(NotesStore(storage: disk).notes == [updated], "Note update did not persist")
        notes.deleteNote(id: note.id)
        schedules.deleteItem(id: legacyItem.id)
        try expect(NotesStore(storage: disk).notes.isEmpty, "Note deletion did not persist")
        try expect(ScheduleStore(storage: disk).items.isEmpty, "Schedule deletion did not persist")
    }
}
