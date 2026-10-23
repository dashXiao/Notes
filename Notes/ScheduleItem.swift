import Foundation

struct ScheduleItem: Codable, Hashable, Identifiable {
    let id: UUID
    var scheduledAt: Date
    var title: String
    let createdAt: Date
    var updatedAt: Date
}
