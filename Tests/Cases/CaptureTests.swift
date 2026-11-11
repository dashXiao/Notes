import Combine
import Foundation

extension RegressionSuite {
    static func testCapture() async throws {
        let disk = storage()
        defer { try? FileManager.default.removeItem(at: disk.directory) }
        let notes = NotesStore(storage: disk)
        let schedules = ScheduleStore(storage: disk)
        let extractor = StubExtractor(result: result())
        let capture = NoteCaptureCoordinator(notesStore: notes, scheduleStore: schedules, extractor: extractor)
        var voiceEvents = 0
        var scheduleEvents = 0
        let subscription = capture.events.sink { event in
            switch event {
            case .voiceNoteCreated: voiceEvents += 1
            case .scheduleSaved: scheduleEvents += 1
            }
        }
        let note = capture.saveNote(text: "Example activity tomorrow")!
        try await eventually { schedules.items.count == 1 }
        let id = schedules.items[0].id
        try expect(schedules.items[0].sourceNoteID == note.id, "Source association was lost")
        capture.saveNote(id: note.id, text: "Updated activity tomorrow")
        try await eventually { scheduleEvents == 2 }
        try expect(schedules.items.count == 1 && schedules.items[0].id == id, "Saving a note duplicated its schedule")
        try expect(capture.saveVoiceNote(text: "Voice activity tomorrow"), "Voice note failed to save")
        try await eventually { schedules.items.count == 2 }
        try expect(voiceEvents == 1 && notes.notes.count == 2, "Voice capture did not use the common save flow")
        notes.deleteNote(id: note.id)
        try expect(schedules.item(with: id) != nil, "Deleting a note removed its existing schedule")
        withExtendedLifetime(subscription) {}
    }

    static func testFailure() async throws {
        let disk = storage()
        defer { try? FileManager.default.removeItem(at: disk.directory) }
        let notes = NotesStore(storage: disk)
        let schedules = ScheduleStore(storage: disk)
        let extractor = StubExtractor(result: nil, shouldFail: true)
        let capture = NoteCaptureCoordinator(notesStore: notes, scheduleStore: schedules, extractor: extractor)
        let note = capture.saveNote(text: "Activity tomorrow")!
        for _ in 0..<100 {
            if await extractor.callCount > 0 { break }
            try await Task.sleep(for: .milliseconds(10))
        }
        try expect(notes.note(with: note.id) != nil && schedules.items.isEmpty, "Service failure affected saved data")
        let calls = await extractor.callCount
        capture.saveNote(text: "A general note without a date")
        try await Task.sleep(for: .milliseconds(20))
        let newCalls = await extractor.callCount
        try expect(calls == newCalls, "Undated note bypassed the local filter")
    }

    static func testStaleResults() async throws {
        let disk = storage()
        defer { try? FileManager.default.removeItem(at: disk.directory) }
        let notes = NotesStore(storage: disk)
        let schedules = ScheduleStore(storage: disk)
        let extractor = DelayedExtractor()
        let capture = NoteCaptureCoordinator(notesStore: notes, scheduleStore: schedules, extractor: extractor)
        let text = "Old activity tomorrow"
        let note = capture.saveNote(text: text)!
        try await waitForRequest(extractor, text: text)
        capture.saveNote(id: note.id, text: "Now an undated note")
        await extractor.finish(text, result: result("Old activity"))
        try await Task.sleep(for: .milliseconds(20))
        try expect(schedules.items.isEmpty, "Old analysis created a schedule after an edit")
        let deletedText = "Deleted activity tomorrow"
        let deleted = capture.saveNote(text: deletedText)!
        try await waitForRequest(extractor, text: deletedText)
        notes.deleteNote(id: deleted.id)
        await extractor.finish(deletedText, result: result("Deleted activity"))
        try await Task.sleep(for: .milliseconds(20))
        try expect(schedules.items.isEmpty, "An analysis result outlived its deleted note")
    }
}
