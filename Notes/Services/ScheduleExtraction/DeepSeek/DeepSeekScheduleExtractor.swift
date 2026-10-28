import Foundation

struct DeepSeekScheduleExtractor: ScheduleExtracting {
    private let configuration: DeepSeekConfiguration
    private let session: URLSession

    init(configuration: DeepSeekConfiguration, session: URLSession? = nil) {
        self.configuration = configuration
        if let session {
            self.session = session
            return
        }
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.timeoutIntervalForRequest = 25
        sessionConfiguration.timeoutIntervalForResource = 40
        self.session = URLSession(configuration: sessionConfiguration)
    }

    func extract(
        from note: String,
        referenceDate: Date,
        timeZone: TimeZone
    ) async throws -> ExtractedSchedule? {
        let request = try makeRequest(
            note: note,
            referenceDate: referenceDate,
            timeZone: timeZone
        )
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw DeepSeekError.requestFailed
        }

        let apiResponse = try JSONDecoder().decode(
            DeepSeekResponse.self,
            from: data
        )
        guard let content = apiResponse.choices.first?.message.content,
              let payload = decodePayload(from: content),
              payload.isSchedule,
              let title = payload.title?
                .trimmingCharacters(in: .whitespacesAndNewlines),
              !title.isEmpty,
              let dateText = payload.date,
              !dateText.isEmpty else {
            return nil
        }

        let confidence = min(max(payload.confidence ?? 0, 0), 1)
        guard confidence >= 0.8 else {
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.timeZone = timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd"

        guard let day = dateFormatter.date(from: dateText) else {
            throw DeepSeekError.invalidDate
        }

        let timeIsPending = payload.timeIsPending == true
            || payload.time?.isEmpty != false
        let scheduledAt: Date

        if timeIsPending {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = timeZone
            scheduledAt = calendar.startOfDay(for: day)
        } else {
            let dateTimeFormatter = DateFormatter()
            dateTimeFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateTimeFormatter.calendar = Calendar(identifier: .gregorian)
            dateTimeFormatter.timeZone = timeZone
            dateTimeFormatter.dateFormat = "yyyy-MM-dd HH:mm"

            guard let time = payload.time,
                  let parsedDate = dateTimeFormatter.date(
                    from: "\(dateText) \(time)"
                  ) else {
                throw DeepSeekError.invalidDate
            }
            scheduledAt = parsedDate
        }

        return ExtractedSchedule(
            title: title,
            scheduledAt: scheduledAt,
            timeIsPending: timeIsPending,
            confidence: confidence
        )
    }

    private func makeRequest(
        note: String,
        referenceDate: Date,
        timeZone: TimeZone
    ) throws -> URLRequest {
        let systemPrompt = ScheduleExtractionPrompt.make(
            referenceDate: referenceDate,
            timeZone: timeZone
        )

        let body = DeepSeekRequest(
            model: configuration.model,
            messages: [
                DeepSeekMessage(role: "system", content: systemPrompt),
                DeepSeekMessage(
                    role: "user",
                    content: "NOTE:\n<<<\n\(note)\n>>>"
                )
            ],
            responseFormat: .init(type: "json_object"),
            thinking: .init(type: "disabled"),
            temperature: 0,
            maxTokens: 512,
            stream: false
        )

        guard let url = URL(
            string: "https://api.deepseek.com/chat/completions"
        ) else {
            throw DeepSeekError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        request.setValue(
            "Bearer \(configuration.apiKey)",
            forHTTPHeaderField: "Authorization"
        )
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    private func decodePayload(from content: String) -> DeepSeekPayload? {
        guard let firstBrace = content.firstIndex(of: "{"),
              let lastBrace = content.lastIndex(of: "}"),
              firstBrace <= lastBrace else {
            return nil
        }

        let json = String(content[firstBrace...lastBrace])
        return try? JSONDecoder().decode(
            DeepSeekPayload.self,
            from: Data(json.utf8)
        )
    }
}
