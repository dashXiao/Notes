import SwiftUI

struct NoteCard: View {
    let note: Note
    let width: CGFloat
    let onSelect: () -> Void
    let onRequestDelete: () -> Void

    @ScaledMetric(relativeTo: .callout) private var estimatedLineHeight = 20.0
    @ScaledMetric(relativeTo: .caption2) private var metadataHeight = 14.0

    private var maximumHeight: CGFloat {
        width * 1.3
    }

    private var maximumLineCount: Int {
        max(1, Int((maximumHeight - 44 - metadataHeight) / estimatedLineHeight))
    }

    var body: some View {
        Button(action: onSelect) {
            Text(note.text)
                .font(.callout)
                .foregroundStyle(AppTheme.accent)
                .multilineTextAlignment(.center)
                .lineLimit(maximumLineCount)
                .truncationMode(.tail)
                .padding(.horizontal, 16)
                .padding(.top, metadataHeight + 28)
                .padding(.bottom, 16)
                .frame(
                    maxWidth: .infinity,
                    minHeight: width,
                    maxHeight: maximumHeight,
                    alignment: .center
                )
                .overlay(alignment: .topLeading) {
                    Text(NoteFormatting.cardDateText(note))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .padding(.horizontal, 12)
                        .padding(.top, 12)
                }
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
        .accessibilityElement(children: .combine)
        .accessibilityHint("Open note for editing. Long press to delete.")
    }
}
