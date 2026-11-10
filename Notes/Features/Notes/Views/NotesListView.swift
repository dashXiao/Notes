import SwiftUI
import UIKit

struct NotesListView: View {
    @EnvironmentObject private var notesStore: NotesStore
    let onSelectNote: (UUID) -> Void

    @State private var notePendingDeletion: Note?

    var body: some View {
        GeometryReader { geometry in
            let horizontalPadding = AppTheme.pageInset
            let columnSpacing = AppTheme.cardSpacing
            let cardWidth = max(0, (
                geometry.size.width - horizontalPadding * 2 - columnSpacing
            ) / 2)

            ScrollView {
                if notesStore.notes.isEmpty {
                    Text("No notes yet.")
                        .font(.body)
                        .foregroundStyle(AppTheme.inactive)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 48)
                } else if cardWidth > 0 {
                    MasonryLayout(columnWidth: cardWidth, spacing: columnSpacing) {
                        ForEach(notesStore.notes) { note in
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
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, 2)
                    .padding(.bottom, 16)
                }
            }
            .scrollIndicators(.hidden)
        }
        .background(AppTheme.canvas)
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack {
                Text("Notes")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text("\(notesStore.notes.count) \(notesStore.notes.count == 1 ? "note" : "notes")")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.accentInk)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(AppTheme.accentTint, in: Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 16)
            .background(AppTheme.canvas)
        }
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
}
