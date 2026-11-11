import SwiftUI

struct AppIconButton: View {
    let systemName: String
    let label: String
    var isPrimary = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            AppIcon(systemName: systemName, size: 20)
                .foregroundStyle(isPrimary ? AppTheme.surface : AppTheme.textPrimary)
                .frame(width: 44, height: 44)
                .background(isPrimary ? AppTheme.accent : AppTheme.surface, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
