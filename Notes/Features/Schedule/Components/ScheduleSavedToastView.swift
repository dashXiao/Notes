import SwiftUI

struct ScheduleSavedToastView: View {
    let change: InferredScheduleChange
    let onEdit: () -> Void
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onEdit) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                        Text(ScheduleFormatting.toastDateText(change.item))
                        Text("·")
                        Text(ScheduleFormatting.toastTimeText(change.item))
                    }
                    .font(.caption)

                    Text(change.item.title)
                        .font(.subheadline.weight(.medium))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Edit this schedule")

            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 48)
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(change.previousItem == nil
                ? "Cancel schedule creation" : "Undo schedule update")
        }
        .fixedSize(horizontal: false, vertical: true)
        .foregroundStyle(AppTheme.accent)
        .background(AppTheme.cream)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .stroke(AppTheme.accent, lineWidth: 1)
        }
    }
}
