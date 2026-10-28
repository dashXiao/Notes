import Combine
import Darwin
import Foundation

private struct CheckFailure: Error, CustomStringConvertible {
    let description: String
}

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() { throw CheckFailure(description: message) }
}

private actor StubExtractor: ScheduleExtracting {
    private(set) var callCount = 0
    let result: ExtractedSchedule?
    let shouldFail: Bool

    init(result: ExtractedSchedule?, shouldFail: Bool = false) {
        self.result = result
        self.shouldFail = shouldFail
    }

    func extract(from note: String, referenceDate: Date, timeZone: TimeZone) async throws -> ExtractedSchedule? {
        callCount += 1
        if shouldFail { throw CheckFailure(description: "Simulated service failure") }
        return result
    }
}

private actor DelayedExtractor: ScheduleExtracting {
    private var pending: [String: CheckedContinuation<ExtractedSchedule?, Never>] = [:]

    func extract(from note: String, referenceDate: Date, timeZone: TimeZone) async throws -> ExtractedSchedule? {
        await withCheckedContinuation { pending[note] = $0 }
    }

    func isWaiting(for text: String) -> Bool { pending[text] != nil }

    func finish(_ text: String, result: ExtractedSchedule?) {
        pending.removeValue(forKey: text)?.resume(returning: result)
    }
}

private final class FixtureURLProtocol: URLProtocol {
    static var content = ""
    static var statusCode = 200
    static var lastRequest: URLRequest?
    static var lastBody: Data?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lastRequest = request
        Self.lastBody = request.httpBody
        if let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var data = Data()
            var buffer = [UInt8](repeating: 0, count: 4096)
            while stream.hasBytesAvailable {
                let count = stream.read(&buffer, maxLength: buffer.count)
                if count <= 0 { break }
                data.append(contentsOf: buffer.prefix(count))
            }
            Self.lastBody = data
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.statusCode, httpVersion: nil, headerFields: nil)!
        let data = try! JSONSerialization.data(withJSONObject: [
            "choices": [["message": ["content": Self.content]]],
        ])
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@main
@MainActor
enum ArchitectureRegression {
    static let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

    static func eventually(_ condition: () -> Bool) async throws {
        for _ in 0..<200 {
            if condition() { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        throw CheckFailure(description: "Timed out waiting for asynchronous state")
    }

    private static func waitForRequest(_ extractor: DelayedExtractor, text: String) async throws {
        for _ in 0..<200 {
            if await extractor.isWaiting(for: text) { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        throw CheckFailure(description: "Extractor was not called")
    }

    static func storage() -> JSONFileStorage {
        JSONFileStorage(directory: FileManager.default.temporaryDirectory
            .appendingPathComponent("NotesRegression-\(UUID().uuidString)", isDirectory: true))
    }

    static func result(_ title: String = "Example activity") -> ExtractedSchedule {
        ExtractedSchedule(title: title, scheduledAt: tomorrow, timeIsPending: true, confidence: 0.95)
    }

    static func main() async throws {
        setbuf(stdout, nil)
        let tests: [(String, () async throws -> Void)] = [
            ("Legacy JSON compatibility and persistence", testPersistence),
            ("Schedule grouping, TBD ordering and empty today", testScheduleQueries),
            ("Note and schedule editor validation", testEditors),
            ("Text and voice share capture and deduplication", testCapture),
            ("Analysis failure does not lose a note", testFailure),
            ("An outdated or deleted note cannot create a schedule", testStaleResults),
            ("DeepSeek request and response contract without network", testExtraction),
        ]
        for (name, test) in tests {
            try await test()
            print("PASS: \(name)")
        }
        print("All \(tests.count) regression groups passed.")
    }

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
            case .scheduleCreated: scheduleEvents += 1
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

    static func testExtraction() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FixtureURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let extractor = DeepSeekScheduleExtractor(
            configuration: DeepSeekConfiguration(apiKey: "test-key", model: "deepseek-flash"),
            session: session
        )
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let date = formatter.string(from: tomorrow)
        let examples = [
            "I'm going to hang out with friends on Wednesday.",
            "I'm going to hang out with friends on Wednesday evening.",
        ]
        for text in examples {
            FixtureURLProtocol.content = "{\"is_schedule\":true,\"title\":\"Example activity\",\"date\":\"\(date)\",\"time\":\"\",\"time_is_pending\":true,\"confidence\":0.95}"
            try expect(ScheduleIntentDetector.shouldAnalyze(text), "A weekday was filtered out")
            let extracted = try await extractor.extract(from: text, referenceDate: Date(), timeZone: .current)
            try expect(extracted?.timeIsPending == true, "Missing or vague time was not kept pending")
            guard let data = FixtureURLProtocol.lastBody else {
                throw CheckFailure(description: "No request body was captured")
            }
            let body = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            try expect((body["thinking"] as? [String: String])?["type"] == "disabled", "Thinking mode changed")
            try expect(body["max_tokens"] as? Int == 512, "Output limit changed")
            try expect((body["response_format"] as? [String: String])?["type"] == "json_object", "JSON output changed")
        }
        FixtureURLProtocol.content = "{\"is_schedule\":true,\"title\":\"Meeting\",\"date\":\"\(date)\",\"time\":\"18:30\",\"time_is_pending\":false,\"confidence\":0.95}"
        let exact = try await extractor.extract(from: "Meeting tomorrow at 6:30 PM", referenceDate: Date(), timeZone: .current)
        try expect(exact?.timeIsPending == false, "Exact time was lost")
        try expect(Calendar.current.component(.hour, from: exact!.scheduledAt) == 18, "Clock time parsed incorrectly")
        FixtureURLProtocol.content = FixtureURLProtocol.content.replacingOccurrences(of: "0.95", with: "0.7")
        let uncertain = try await extractor.extract(from: "Activity tomorrow", referenceDate: Date(), timeZone: .current)
        try expect(uncertain == nil, "Confidence threshold changed")
        FixtureURLProtocol.content = ""
        let empty = try await extractor.extract(from: "Activity tomorrow", referenceDate: Date(), timeZone: .current)
        try expect(empty == nil, "Empty response was accepted")
    }
}
