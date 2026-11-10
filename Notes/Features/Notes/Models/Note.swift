import Foundation

struct Note: Codable, Hashable, Identifiable {
    let id: UUID
    var text: String
    let createdAt: Date
    var updatedAt: Date

    var editedAt: Date? {
        updatedAt > createdAt ? updatedAt : nil
    }
}
