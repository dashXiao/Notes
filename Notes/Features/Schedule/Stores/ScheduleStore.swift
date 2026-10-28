import Combine
import Foundation

@MainActor
final class ScheduleStore: ObservableObject {
    @Published private(set) var items: [ScheduleItem] = []

    private let storage: JSONFileStorage

    init(storage: JSONFileStorage? = nil) {
        self.storage = storage ?? JSONFileStorage()
        loadItems()
    }

    func items(on day: Date) -> [ScheduleItem] {
        items
            .filter {
                Calendar.current.isDate($0.scheduledAt, inSameDayAs: day)
            }
            .sorted(by: isOrderedBefore)
    }

    var dayGroups: [ScheduleDayGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: items) {
            calendar.startOfDay(for: $0.scheduledAt)
        }
        return grouped.keys.sorted().map { day in
            ScheduleDayGroup(day: day, items: (grouped[day] ?? []).sorted(by: isOrderedBefore))
        }
    }

    func days(including day: Date) -> [Date] {
        var dates = Set(dayGroups.map(\.day))
        dates.insert(Calendar.current.startOfDay(for: day))
        return dates.sorted()
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
    ) -> InferredScheduleChange? {
        let normalizedTitle = title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !normalizedTitle.isEmpty else {
            return nil
        }

        let now = Date()
        let item: ScheduleItem
        let previousItem: ScheduleItem?

        if let index = items.firstIndex(where: {
            $0.sourceNoteID == sourceNoteID
        }) {
            previousItem = items[index]
            items[index].scheduledAt = scheduledAt
            items[index].title = normalizedTitle
            items[index].timeIsPending = timeIsPending ? true : nil
            items[index].updatedAt = now
            item = items[index]
        } else {
            previousItem = nil
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
        return InferredScheduleChange(item: item, previousItem: previousItem)
    }

    @discardableResult
    func undoInferredChange(_ change: InferredScheduleChange) -> Bool {
        // A dismissed notification must not undo a newer edit to the same item.
        guard let index = items.firstIndex(where: { $0.id == change.item.id }),
              items[index] == change.item else {
            return false
        }
        if let previousItem = change.previousItem {
            items[index] = previousItem
        } else {
            items.remove(at: index)
        }
        sortItems()
        persistItems()
        return true
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
        items = (try? storage.load([ScheduleItem].self, from: "schedules.json")) ?? []
        sortItems()
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
            try storage.save(items, to: "schedules.json")
        } catch {
            assertionFailure("Unable to save schedule items: \(error.localizedDescription)")
        }
    }
}
