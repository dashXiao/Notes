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
                        AppIcon(systemName: "calendar", size: 13)
                        Text(ScheduleFormatting.toastDateText(change.item))
                        Text("·")
                        Text(ScheduleFormatting.toastTimeText(change.item))
                    }
                    .font(.caption)
                    .foregroundStyle(AppTheme.accentInk)

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
                AppIcon(systemName: "xmark.circle.fill", size: 23)
                    .foregroundStyle(AppTheme.inactive)
                    .frame(width: 48)
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(change.previousItem == nil
                ? "Cancel schedule creation" : "Undo schedule update")
        }
        .fixedSize(horizontal: false, vertical: true)
        .foregroundStyle(AppTheme.textPrimary)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .shadow(color: AppTheme.textPrimary.opacity(0.1), radius: 18, y: 6)
    }
}
