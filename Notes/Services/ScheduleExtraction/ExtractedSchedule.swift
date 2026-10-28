import Foundation

struct ExtractedSchedule: Sendable {
    let title: String
    let scheduledAt: Date
    let timeIsPending: Bool
    let confidence: Double
}
