import Foundation

enum ScheduleIntentDetector {
    static func shouldAnalyze(_ text: String) -> Bool {
        let normalized = text
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()

        guard !normalized.isEmpty else {
            return false
        }

        let hasExplicitDate = containsDetectedDate(in: normalized)
            || containsAny(temporalKeywords, in: normalized)
        let hasExplicitTime = containsTimeExpression(in: normalized)

        return hasExplicitDate || hasExplicitTime
    }

    private static let temporalKeywords = [
        "today", "tonight", "tomorrow", "this morning",
        "this afternoon", "this evening", "morning", "afternoon",
        "evening", "noon", "midnight", "next week",
        "next month", "monday", "tuesday", "wednesday",
        "thursday", "friday", "saturday", "sunday"
    ]

    private static let timePattern = try! NSRegularExpression(
        pattern: #"\b(?:(?:1[0-2]|[1-9])(?::[0-5]\d)?\s*(?:am|pm)|(?:[01]?\d|2[0-3]):[0-5]\d|(?:1[0-2]|[1-9])\s*o'clock)\b"#,
        options: [.caseInsensitive]
    )

    private static func containsAny(
        _ phrases: [String],
        in text: String
    ) -> Bool {
        phrases.contains { text.contains($0) }
    }

    private static func containsDetectedDate(in text: String) -> Bool {
        guard let detector = try? NSDataDetector(
            types: NSTextCheckingResult.CheckingType.date.rawValue
        ) else {
            return false
        }

        let range = NSRange(text.startIndex..., in: text)
        return !detector.matches(in: text, range: range).isEmpty
    }

    private static func containsTimeExpression(in text: String) -> Bool {
        let range = NSRange(text.startIndex..., in: text)
        return timePattern.firstMatch(in: text, range: range) != nil
    }
}
