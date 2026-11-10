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
        .toolbar { toolbarContent }
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

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Note")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
        }
        .sharedBackgroundVisibility(.hidden)

        ToolbarItem(placement: .topBarLeading) {
            AppIconButton(systemName: "chevron.left", label: "Back", action: dismiss.callAsFunction)
        }
        .sharedBackgroundVisibility(.hidden)

        ToolbarItem(placement: .topBarTrailing) {
            AppIconButton(systemName: "checkmark", label: "Save note", isPrimary: true, action: save)
            .disabled(!model.canSave)
            .opacity(model.canSave ? 1 : 0.35)
            .keyboardShortcut("s", modifiers: .command)
        }
        .sharedBackgroundVisibility(.hidden)
    }

    private func save() {
        guard model.save(using: noteCapture) else {
            return
        }

        dismiss()
    }
}
