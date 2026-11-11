import SwiftUI

struct NoteEditorView: View {
    @EnvironmentObject private var noteCapture: NoteCaptureCoordinator
    @Environment(\.dismiss) private var dismiss

    @StateObject private var model: NoteEditorModel
    @FocusState private var isEditorFocused: Bool

    init(note: Note?) {
        _model = StateObject(wrappedValue: NoteEditorModel(note: note))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let lastModifiedAt = model.lastModifiedAt {
                Text(NoteFormatting.detailDateTimeText(lastModifiedAt))
                    .font(.caption)
                    .foregroundStyle(AppTheme.inactive)
                    .padding(.horizontal, 17)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
            }

            editor
        }
        .background(AppTheme.surface)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            EditorToolbar(
                title: "Note",
                saveLabel: "Save note",
                canSave: model.canSave,
                saveShortcut: KeyboardShortcut("s", modifiers: .command),
                onBack: dismiss.callAsFunction,
                onSave: save
            )
        }
        .toolbarBackground(AppTheme.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var editor: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $model.text)
                .font(.body)
                .foregroundStyle(AppTheme.textPrimary)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .focused($isEditorFocused)
                .accessibilityLabel("Note text")

            if model.text.isEmpty {
                Text("Start writing...")
                    .font(.body)
                    .foregroundStyle(AppTheme.inactive)
                    .padding(.horizontal, 17)
                    .padding(.vertical, 20)
                    .allowsHitTesting(false)
            }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture().onEnded {
                isEditorFocused = true
            }
        )
    }

    private func save() {
        guard model.save(using: noteCapture) else {
            return
        }

        dismiss()
    }
}
