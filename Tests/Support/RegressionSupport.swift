import Foundation

struct CheckFailure: Error, CustomStringConvertible {
    let description: String
}

func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() { throw CheckFailure(description: message) }
}

actor StubExtractor: ScheduleExtracting {
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

actor DelayedExtractor: ScheduleExtracting {
    private var pending: [String: CheckedContinuation<ExtractedSchedule?, Never>] = [:]

    func extract(from note: String, referenceDate: Date, timeZone: TimeZone) async throws -> ExtractedSchedule? {
        await withCheckedContinuation { pending[note] = $0 }
    }

    func isWaiting(for text: String) -> Bool { pending[text] != nil }

    func finish(_ text: String, result: ExtractedSchedule?) {
        pending.removeValue(forKey: text)?.resume(returning: result)
    }
}

final class FixtureURLProtocol: URLProtocol {
    static var content = ""
    static var lastBody: Data?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
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
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let data = try! JSONSerialization.data(withJSONObject: [
            "choices": [["message": ["content": Self.content]]],
        ])
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

extension RegressionSuite {
    static let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

    static func eventually(_ condition: () -> Bool) async throws {
        for _ in 0..<200 {
            if condition() { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        throw CheckFailure(description: "Timed out waiting for asynchronous state")
    }

    static func waitForRequest(_ extractor: DelayedExtractor, text: String) async throws {
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
}
