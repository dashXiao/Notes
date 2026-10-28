import Combine
import Foundation

@MainActor
final class NotesStore: ObservableObject {
    @Published private(set) var notes: [Note] = []
    @Published private(set) var lastSavedNote: Note?

    private let storageDirectory: URL
    private var storageURL: URL {
        storageDirectory.appendingPathComponent("notes.json")
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

        loadNotes()
    }

    func note(with id: UUID) -> Note? {
        notes.first { $0.id == id }
    }

    func deleteNote(id: UUID) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else {
            return
        }

        notes.remove(at: index)
        persistNotes()
    }

    @discardableResult
    func saveNote(id: UUID? = nil, text: String) -> Note? {
        let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            return nil
        }

        let now = Date()
        let savedNote: Note

        if let id, let index = notes.firstIndex(where: { $0.id == id }) {
            notes[index].text = normalizedText
            notes[index].updatedAt = now
            savedNote = notes[index]
        } else {
            savedNote = Note(
                id: UUID(),
                text: normalizedText,
                createdAt: now,
                updatedAt: now
            )
            notes.append(savedNote)
        }

        notes.sort { $0.updatedAt > $1.updatedAt }
        persistNotes()
        lastSavedNote = savedNote
        return savedNote
    }

    private func loadNotes() {
        guard let data = try? Data(contentsOf: storageURL) else {
            return
        }

        notes = (try? JSONDecoder().decode([Note].self, from: data))?
            .sorted { $0.updatedAt > $1.updatedAt } ?? []
    }

    private func persistNotes() {
        do {
            try FileManager.default.createDirectory(
                at: storageDirectory,
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(notes)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            assertionFailure("Unable to save notes: \(error.localizedDescription)")
        }
    }
}
