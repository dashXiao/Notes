import Combine
import Foundation

@MainActor
final class NoteEditorModel: ObservableObject {
    @Published var text: String
    private let noteID: UUID?

    init(note: Note?) {
        noteID = note?.id
        text = note?.text ?? ""
    }

    var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func save(using coordinator: NoteCaptureCoordinator) -> Bool {
        coordinator.saveNote(id: noteID, text: text) != nil
    }
}
