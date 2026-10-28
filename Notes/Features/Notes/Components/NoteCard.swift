import SwiftUI

struct NoteCard: View {
    let note: Note
    let width: CGFloat
    let onSelect: () -> Void
    let onRequestDelete: () -> Void

    @ScaledMetric(relativeTo: .callout) private var estimatedLineHeight = 20.0

    private var maximumHeight: CGFloat {
        width * 1.3
    }

    private var maximumLineCount: Int {
        max(1, Int((maximumHeight - 32) / estimatedLineHeight))
    }

    var body: some View {
        Button(action: onSelect) {
            Text(note.text)
                .font(.callout)
                .foregroundStyle(AppTheme.accent)
                .multilineTextAlignment(.center)
                .lineLimit(maximumLineCount)
                .truncationMode(.tail)
                .padding(16)
                .frame(
                    maxWidth: .infinity,
                    minHeight: width,
                    maxHeight: maximumHeight,
                    alignment: .center
                )
                .overlay {
                    Rectangle()
                        .stroke(AppTheme.accent, lineWidth: 1)
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive, action: onRequestDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .accessibilityAction(named: "Delete", onRequestDelete)
        .accessibilityLabel(note.text)
        .accessibilityHint("Open note for editing. Long press to delete.")
    }
}
