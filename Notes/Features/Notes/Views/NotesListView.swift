import SwiftUI
import UIKit

struct NotesListView: View {
    @EnvironmentObject private var notesStore: NotesStore
    let onSelectNote: (UUID) -> Void

    @State private var notePendingDeletion: Note?

    var body: some View {
        GeometryReader { geometry in
            let horizontalPadding = 12.0
            let columnSpacing = 12.0
            let cardWidth = (
                geometry.size.width - horizontalPadding * 2 - columnSpacing
            ) / 2

            ScrollView {
                if notesStore.notes.isEmpty {
                    Text("No notes yet.")
                        .font(.body)
                        .foregroundStyle(AppTheme.inactive)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 48)
                } else {
                    HStack(alignment: .top, spacing: columnSpacing) {
                        noteColumn(
                            indices: Array(
                                stride(
                                    from: 0,
                                    to: notesStore.notes.count,
                                    by: 2
                                )
                            ),
                            cardWidth: cardWidth
                        )

                        noteColumn(
                            indices: Array(
                                stride(
                                    from: 1,
                                    to: notesStore.notes.count,
                                    by: 2
                                )
                            ),
                            cardWidth: cardWidth
                        )
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, 36)
                    .padding(.bottom, 24)
                }
            }
            .scrollIndicators(.hidden)
        }
        .background(Color(.systemBackground))
        .toolbar(.hidden, for: .navigationBar)
        .alert(
            "Delete Note?",
            isPresented: Binding(
                get: { notePendingDeletion != nil },
                set: { isPresented in
                    if !isPresented {
                        notePendingDeletion = nil
                    }
                }
            ),
            presenting: notePendingDeletion
        ) { note in
            Button("Cancel", role: .cancel) {
                notePendingDeletion = nil
            }
            Button("Delete", role: .destructive) {
                UINotificationFeedbackGenerator()
                    .notificationOccurred(.warning)
                withAnimation(.easeOut(duration: 0.2)) {
                    notesStore.deleteNote(id: note.id)
                }
                notePendingDeletion = nil
            }
        }
    }

    private func noteColumn(
        indices: [Int],
        cardWidth: CGFloat
    ) -> some View {
        LazyVStack(spacing: 12) {
            ForEach(indices, id: \.self) { index in
                let note = notesStore.notes[index]

                NoteCard(
                    note: note,
                    width: cardWidth,
                    onSelect: {
                        onSelectNote(note.id)
                    },
                    onRequestDelete: {
                        notePendingDeletion = note
                    }
                )
            }
        }
        .frame(width: cardWidth)
    }
}
