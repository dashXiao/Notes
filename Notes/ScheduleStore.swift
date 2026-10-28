import Combine
import Foundation

@MainActor
final class ScheduleStore: ObservableObject {
    @Published private(set) var items: [ScheduleItem] = []

    private let storageDirectory: URL
    private var storageURL: URL {
        storageDirectory.appendingPathComponent("schedules.json")
    }

    init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "Notes"
        storageDirectory = appSupport.appendingPathComponent(
            bundleIdentifier,
            isDirectory: true
        )

        loadItems()
    }

    func items(on day: Date) -> [ScheduleItem] {
        items
            .filter {
                Calendar.current.isDate($0.scheduledAt, inSameDayAs: day)
            }
            .sorted(by: isOrderedBefore)
    }

    func item(with id: UUID) -> ScheduleItem? {
        items.first { $0.id == id }
    }

    @discardableResult
    func saveInferredItem(
        sourceNoteID: UUID,
        title: String,
        scheduledAt: Date,
        timeIsPending: Bool
    ) -> ScheduleItem? {
        let normalizedTitle = title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !normalizedTitle.isEmpty else {
            return nil
        }

        let now = Date()
        let item: ScheduleItem

        if let index = items.firstIndex(where: {
            $0.sourceNoteID == sourceNoteID
        }) {
            items[index].scheduledAt = scheduledAt
            items[index].title = normalizedTitle
            items[index].timeIsPending = timeIsPending ? true : nil
            items[index].updatedAt = now
            item = items[index]
        } else {
            let newItem = ScheduleItem(
                id: UUID(),
                scheduledAt: scheduledAt,
                title: normalizedTitle,
                timeIsPending: timeIsPending ? true : nil,
                sourceNoteID: sourceNoteID,
                createdAt: now,
                updatedAt: now
            )
            items.append(newItem)
            item = newItem
        }

        sortItems()
        persistItems()
        return item
    }

    func deleteItem(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            return
        }

        items.remove(at: index)
        persistItems()
    }

    @discardableResult
    func saveItem(
        id: UUID? = nil,
        scheduledAt: Date,
        title: String,
        timeIsPending: Bool = false
    ) -> Bool {
        let normalizedTitle = title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !normalizedTitle.isEmpty else {
            return false
        }

        let now = Date()

        if let id, let index = items.firstIndex(where: { $0.id == id }) {
            items[index].scheduledAt = scheduledAt
            items[index].title = normalizedTitle
            items[index].timeIsPending = timeIsPending ? true : nil
            items[index].updatedAt = now
        } else {
            items.append(
                ScheduleItem(
                    id: UUID(),
                    scheduledAt: scheduledAt,
                    title: normalizedTitle,
                    timeIsPending: timeIsPending ? true : nil,
                    createdAt: now,
                    updatedAt: now
                )
            )
        }

        sortItems()
        persistItems()
        return true
    }

    private func loadItems() {
        guard let data = try? Data(contentsOf: storageURL) else {
            return
        }

        items = (try? JSONDecoder().decode([ScheduleItem].self, from: data))?
            .sorted { $0.scheduledAt < $1.scheduledAt } ?? []
    }

    private func sortItems() {
        items.sort(by: isOrderedBefore)
    }

    private func isOrderedBefore(
        _ lhs: ScheduleItem,
        _ rhs: ScheduleItem
    ) -> Bool {
        let lhsIsPending = lhs.timeIsPending == true
        let rhsIsPending = rhs.timeIsPending == true

        if lhsIsPending != rhsIsPending {
            return lhsIsPending
        }

        if lhs.scheduledAt == rhs.scheduledAt {
            return lhs.createdAt < rhs.createdAt
        }
        return lhs.scheduledAt < rhs.scheduledAt
    }

    private func persistItems() {
        do {
            try FileManager.default.createDirectory(
                at: storageDirectory,
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(items)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            assertionFailure(
                "Unable to save schedule items: \(error.localizedDescription)"
            )
        }
    }
}
