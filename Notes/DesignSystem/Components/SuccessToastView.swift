import SwiftUI

struct SuccessToastView: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            AppIcon(systemName: "checkmark.circle.fill", size: 20)
                .foregroundStyle(AppTheme.textPrimary)
            Text(message)
                .font(.callout)
                .foregroundStyle(AppTheme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppTheme.surface, in: Capsule())
        .shadow(color: AppTheme.textPrimary.opacity(0.1), radius: 18, y: 6)
        .accessibilityElement(children: .combine)
    }
}
