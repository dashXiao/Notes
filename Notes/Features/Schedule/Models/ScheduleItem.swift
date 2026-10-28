import Foundation

struct ScheduleItem: Codable, Hashable, Identifiable {
    let id: UUID
    var scheduledAt: Date
    var title: String
    var timeIsPending: Bool? = nil
    var sourceNoteID: UUID? = nil
    let createdAt: Date
    var updatedAt: Date
}
