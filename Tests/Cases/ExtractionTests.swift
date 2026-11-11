import Foundation

extension RegressionSuite {
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
