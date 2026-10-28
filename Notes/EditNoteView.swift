import SwiftUI

struct EditNoteView: View {
    @EnvironmentObject private var notesStore: NotesStore
    @Environment(\.dismiss) private var dismiss

    private let noteID: UUID?

    @State private var text: String
    @FocusState private var isEditorFocused: Bool

    init(note: Note?) {
        noteID = note?.id
        _text = State(initialValue: note?.text ?? "")
    }

    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .font(.body)
                .foregroundStyle(AppTheme.accent)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .focused($isEditorFocused)
                .accessibilityLabel("Note text")

            if text.isEmpty {
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
                        .opacity(canSave ? 1 : 0.35)
                }
                .disabled(!canSave)
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
        guard notesStore.saveNote(id: noteID, text: text) != nil else {
            return
        }

        dismiss()
    }
}
