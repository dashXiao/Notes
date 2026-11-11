import Foundation

extension RegressionSuite {
    static func testScheduleQueries() async throws {
        let disk = storage()
        defer { try? FileManager.default.removeItem(at: disk.directory) }
        let store = ScheduleStore(storage: disk)
        let day = Calendar.current.startOfDay(for: tomorrow)
        store.saveItem(scheduledAt: day.addingTimeInterval(10 * 3600), title: "Later")
        store.saveItem(scheduledAt: day.addingTimeInterval(9 * 3600), title: "Earlier")
        store.saveItem(scheduledAt: day, title: "Pending", timeIsPending: true)
        try expect(store.items(on: day).map(\.title) == ["Pending", "Earlier", "Later"], "Single-day ordering changed")
        try expect(store.dayGroups.count == 1, "Overview contains an empty day")
        try expect(store.dayGroups[0].items == store.items(on: day), "Overview and full card use different ordering")
        let today = Calendar.current.startOfDay(for: Date())
        try expect(store.days(including: today) == [today, day], "Empty today is missing from paging")
        try expect(ScheduleFormatting.timeText(store.items(on: day)[0]) == "TBD", "Pending time label changed")
    }

    static func testInferredUndo() async throws {
        let disk = storage()
        defer { try? FileManager.default.removeItem(at: disk.directory) }
        let notes = NotesStore(storage: disk)
        let schedules = ScheduleStore(storage: disk)
        let note = notes.saveNote(text: "Activity tomorrow")!
        let created = schedules.saveInferredItem(
            sourceNoteID: note.id, title: "Activity", scheduledAt: tomorrow, timeIsPending: true
        )!
        try expect(created.previousItem == nil, "Creation was reported as an update")
        try expect(schedules.undoInferredChange(created), "Creation could not be undone")
        try expect(schedules.items.isEmpty, "Cancelled item is still present")
        try expect(ScheduleStore(storage: disk).items.isEmpty, "Cancellation did not persist")
        try expect(notes.note(with: note.id) == note, "Cancelling a schedule changed its note")
        try expect(!schedules.undoInferredChange(created), "Repeated cancellation was accepted")

        let original = schedules.saveInferredItem(
            sourceNoteID: note.id, title: "Original", scheduledAt: tomorrow, timeIsPending: true
        )!.item
        let updated = schedules.saveInferredItem(
            sourceNoteID: note.id, title: "Updated", scheduledAt: tomorrow.addingTimeInterval(3600), timeIsPending: false
        )!
        try expect(updated.previousItem == original, "Previous schedule was not captured")
        try expect(schedules.undoInferredChange(updated), "Update could not be undone")
        try expect(schedules.items == [original], "Undo deleted or changed the original schedule")
        try expect(ScheduleStore(storage: disk).items == [original], "Restored schedule did not persist")

        let anotherUpdate = schedules.saveInferredItem(
            sourceNoteID: note.id, title: "AI update", scheduledAt: tomorrow, timeIsPending: true
        )!
        schedules.saveItem(id: original.id, scheduledAt: tomorrow, title: "Manual edit")
        try expect(!schedules.undoInferredChange(anotherUpdate), "Old notification overwrote a later edit")
        try expect(schedules.items[0].title == "Manual edit", "Manual edit was lost")
    }

    static func testToastLifetime() async throws {
        let disk = storage()
        defer { try? FileManager.default.removeItem(at: disk.directory) }
        let schedules = ScheduleStore(storage: disk)
        let change = schedules.saveInferredItem(
            sourceNoteID: UUID(), title: "Activity", scheduledAt: tomorrow, timeIsPending: true
        )!
        let presenter = ToastPresenter()
        presenter.showSchedule(change)
        guard let first = presenter.toast, case let .schedule(shown) = first.content else {
            throw CheckFailure(description: "Schedule notification has no schedule details")
        }
        try expect(shown == change, "Notification details differ from the saved schedule")
        try await Task.sleep(for: .milliseconds(2200))
        try expect(presenter.toast?.id == first.id, "Schedule notification disappeared before three seconds")
        try await eventually { presenter.toast == nil }
        try expect(schedules.items == [change.item], "Timeout cancelled the saved schedule")

        presenter.showSchedule(change)
        let obsoleteID = presenter.toast!.id
        presenter.show("Note created")
        let replacementID = presenter.toast!.id
        try expect(!presenter.dismiss(id: obsoleteID), "Old action dismissed a replacement notification")
        try expect(presenter.toast?.id == replacementID, "Replacement notification was lost")
        try expect(presenter.dismiss(id: replacementID) && presenter.toast == nil, "Explicit dismissal failed")
    }

    static func testToastFormatting() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let date = calendar.date(from: DateComponents(year: 2026, month: 11, day: 2, hour: 18, minute: 30))!
        var item = ScheduleItem(id: UUID(), scheduledAt: date, title: "Activity", createdAt: Date(), updatedAt: Date())
        try expect(ScheduleFormatting.toastDateText(item) == "Nov 2, 2026", "Notification date is not clear English")
        try expect(ScheduleFormatting.toastTimeText(item) == "18:30", "Notification clock time is ambiguous")
        item.timeIsPending = true
        try expect(ScheduleFormatting.toastTimeText(item) == "TBD", "Pending notification time was lost")
    }
}
