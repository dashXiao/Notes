import Combine
import Foundation

@MainActor
final class NotesStore: ObservableObject {
    @Published private(set) var notes: [Note] = []

    private let storage: JSONFileStorage

    init(storage: JSONFileStorage? = nil) {
        self.storage = storage ?? JSONFileStorage()
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
        return savedNote
    }

    private func loadNotes() {
        notes = ((try? storage.load([Note].self, from: "notes.json")) ?? [])
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    private func persistNotes() {
        do {
            try storage.save(notes, to: "notes.json")
        } catch {
            assertionFailure("Unable to save notes: \(error.localizedDescription)")
        }
    }
}
