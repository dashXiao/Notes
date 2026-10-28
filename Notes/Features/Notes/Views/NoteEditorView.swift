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
        ZStack(alignment: .topLeading) {
            TextEditor(text: $model.text)
                .font(.body)
                .foregroundStyle(AppTheme.accent)
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
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Note")
                    .font(.callout)
                    .foregroundStyle(Color(.label))
            }
            .sharedBackgroundVisibility(.hidden)

            ToolbarItem(placement: .topBarLeading) {
                Button(action: dismiss.callAsFunction) {
                    Image("BackIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                .accessibilityLabel("Back")
            }
            .sharedBackgroundVisibility(.hidden)

            ToolbarItem(placement: .topBarTrailing) {
                Button(action: save) {
                    Image("CheckIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .opacity(model.canSave ? 1 : 0.35)
                }
                .disabled(!model.canSave)
                .keyboardShortcut("s", modifiers: .command)
                .accessibilityLabel("Save note")
            }
            .sharedBackgroundVisibility(.hidden)
        }
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            isEditorFocused = true
        }
    }

    private func save() {
        guard model.save(using: noteCapture) else {
            return
        }

        dismiss()
    }
}
