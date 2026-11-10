import SwiftUI

struct NoteCard: View {
    let note: Note
    let width: CGFloat
    let onSelect: () -> Void
    let onRequestDelete: () -> Void

    @ScaledMetric(relativeTo: .callout) private var estimatedLineHeight = 20.0
    @ScaledMetric(relativeTo: .caption2) private var metadataHeight = 14.0

    private var heightRange: ClosedRange<CGFloat> {
        // A stable seed keeps card proportions unchanged across redraws and launches.
        let seed = note.id.uuidString.utf8.reduce(UInt64(5381)) { ($0 &* 33) &+ UInt64($1) }
        let minimumVariation = CGFloat(seed % 101) / 100
        let maximumVariation = CGFloat((seed / 101) % 101) / 100
        return (width * (0.65 + minimumVariation * 0.35))
            ... (width * (1.3 + maximumVariation * 0.3))
    }

    private var maximumLineCount: Int {
        max(1, Int((heightRange.upperBound - 44 - metadataHeight) / estimatedLineHeight))
    }

    var body: some View {
        Button(action: onSelect) {
            Text(note.text)
                .font(.callout)
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(maximumLineCount)
                .truncationMode(.tail)
                .padding(.horizontal, 16)
                .padding(.top, metadataHeight + 28)
                .padding(.bottom, 16)
                .frame(
                    maxWidth: .infinity,
                    minHeight: heightRange.lowerBound,
                    maxHeight: heightRange.upperBound,
                    alignment: .center
                )
                .overlay(alignment: .topLeading) {
                    Text(NoteFormatting.cardDateText(note))
                        .font(.caption2)
                        .foregroundStyle(AppTheme.inactive)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .padding(.horizontal, 12)
                        .padding(.top, 12)
                }
                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
                .contentShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
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
