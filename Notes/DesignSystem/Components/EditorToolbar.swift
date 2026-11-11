import SwiftUI

struct EditorToolbar: ToolbarContent {
    let title: String
    let saveLabel: String
    let canSave: Bool
    var saveShortcut: KeyboardShortcut? = nil
    let onBack: () -> Void
    let onSave: () -> Void

    @ToolbarContentBuilder
    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
        }
        .sharedBackgroundVisibility(.hidden)

        ToolbarItem(placement: .topBarLeading) {
            AppIconButton(systemName: "chevron.left", label: "Back", action: onBack)
        }
        .sharedBackgroundVisibility(.hidden)

        ToolbarItem(placement: .topBarTrailing) {
            AppIconButton(systemName: "checkmark", label: saveLabel, isPrimary: true, action: onSave)
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.35)
                .keyboardShortcut(saveShortcut)
        }
        .sharedBackgroundVisibility(.hidden)
    }
}
