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
            .sorted { $0.scheduledAt < $1.scheduledAt }
    }

    func item(with id: UUID) -> ScheduleItem? {
        items.first { $0.id == id }
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
        title: String
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
            items[index].updatedAt = now
        } else {
            items.append(
                ScheduleItem(
                    id: UUID(),
                    scheduledAt: scheduledAt,
                    title: normalizedTitle,
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
        items.sort {
            if $0.scheduledAt == $1.scheduledAt {
                return $0.createdAt < $1.createdAt
            }
            return $0.scheduledAt < $1.scheduledAt
        }
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
