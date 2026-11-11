import Foundation

extension RegressionSuite {
    static func testEditors() async throws {
        let disk = storage()
        defer { try? FileManager.default.removeItem(at: disk.directory) }
        let notes = NotesStore(storage: disk)
        let schedules = ScheduleStore(storage: disk)
        let capture = NoteCaptureCoordinator(notesStore: notes, scheduleStore: schedules, extractor: nil)
        let editor = NoteEditorModel(note: nil)
        editor.text = " \n "
        try expect(!editor.canSave && !editor.save(using: capture), "Blank note was saved")
        editor.text = "Editor note"
        try expect(editor.save(using: capture), "Note editor failed to save")
        let scheduleEditor = ScheduleEditorModel(item: nil, day: tomorrow)
        try expect(!scheduleEditor.canSave, "Blank schedule can be saved")
        scheduleEditor.title = "Meeting"
        scheduleEditor.time = Calendar.current.date(bySettingHour: 18, minute: 30, second: 0, of: Date())!
        try expect(scheduleEditor.save(in: schedules), "Schedule editor failed to save")
        let item = schedules.items[0]
        try expect(Calendar.current.isDate(item.scheduledAt, inSameDayAs: tomorrow), "Editor saved the wrong day")
        try expect(Calendar.current.component(.hour, from: item.scheduledAt) == 18, "Editor saved the wrong time")
        let pending = ScheduleEditorModel(item: item, day: tomorrow)
        pending.isTimePending = true
        try expect(pending.save(in: schedules), "Pending schedule failed to save")
        try expect(schedules.items.count == 1 && schedules.items[0].id == item.id, "Editing duplicated a schedule")
        try expect(schedules.items[0].timeIsPending == true, "Pending state was lost")
        try expect(schedules.items[0].scheduledAt == Calendar.current.startOfDay(for: tomorrow), "Pending time is not start of day")
    }
}
