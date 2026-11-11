import Darwin

@main
@MainActor
enum RegressionSuite {
    static func main() async throws {
        setbuf(stdout, nil)
        let tests: [(String, () async throws -> Void)] = [
            ("Legacy JSON compatibility and persistence", testPersistence),
            ("Note creation dates and edits survive saving and reloading", testNoteDates),
            ("Notes keep creation order after edits and reloads", testNoteOrdering),
            ("Schedule grouping, TBD ordering and empty today", testScheduleQueries),
            ("Note and schedule editor validation", testEditors),
            ("Text and voice share capture and deduplication", testCapture),
            ("Analysis failure does not lose a note", testFailure),
            ("An outdated or deleted note cannot create a schedule", testStaleResults),
            ("Schedule notification undo preserves notes and newer edits", testInferredUndo),
            ("Schedule notifications last three seconds and dismiss safely", testToastLifetime),
            ("Schedule notification dates, clock times and TBD", testToastFormatting),
            ("DeepSeek request and response contract without network", testExtraction),
        ]
        for (name, test) in tests {
            try await test()
            print("PASS: \(name)")
        }
        print("All \(tests.count) regression groups passed.")
    }
}
