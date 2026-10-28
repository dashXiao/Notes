import SwiftUI

struct SuccessToastView: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppTheme.accent)
            Text(message)
                .font(.callout)
                .foregroundStyle(AppTheme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppTheme.cream, in: Capsule())
        .overlay {
            Capsule().stroke(AppTheme.accent, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}
