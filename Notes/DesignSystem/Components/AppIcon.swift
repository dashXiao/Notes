import SwiftUI

struct AppIcon: View {
    let systemName: String
    var size: CGFloat = 24
    var weight: Font.Weight = .semibold

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size, weight: weight))
            .symbolRenderingMode(.hierarchical)
            .accessibilityHidden(true)
    }
}

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
