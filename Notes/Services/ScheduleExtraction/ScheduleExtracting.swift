import Foundation

protocol ScheduleExtracting: Sendable {
    func extract(
        from note: String,
        referenceDate: Date,
        timeZone: TimeZone
    ) async throws -> ExtractedSchedule?
}
