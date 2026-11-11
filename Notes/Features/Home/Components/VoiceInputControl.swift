import SwiftUI

struct VoiceInputControl: View {
    let isListening: Bool
    let isBusy: Bool
    let onToggle: () -> Void

    private var caption: String {
        if isListening { return "Listening..." }
        return isBusy ? "Finishing your note..." : "Tap to speak"
    }

    var body: some View {
        VStack(spacing: 12) {
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accentTint)
                        .frame(width: 144, height: 144)

                    if isListening { ListeningPulse() }

                    Circle()
                        .fill(LinearGradient(
                            colors: [AppTheme.accent.opacity(0.8), AppTheme.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 112, height: 112)
                        .shadow(color: AppTheme.accent.opacity(0.22), radius: 18, y: 8)

                    AppIcon(
                        systemName: isListening ? "stop.fill" : "mic.fill",
                        size: isListening ? 31 : 37
                    )
                    .foregroundStyle(AppTheme.surface)
                }
                .frame(width: 161, height: 161)
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(isBusy)
            .opacity(isBusy ? 0.75 : 1)
            .accessibilityLabel(isListening ? "Stop voice input" : "Start voice input")
            .accessibilityHint(isListening
                ? "Stops recording and saves the note"
                : "Records an English note and saves it automatically")

            Text(caption)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isListening ? AppTheme.accentInk : AppTheme.inactive)
        }
        .frame(maxWidth: .infinity)
    }
}
