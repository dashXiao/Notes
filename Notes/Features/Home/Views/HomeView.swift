import SwiftUI

struct HomeView: View {
    @ObservedObject var speechInput: SpeechInputController
    let prompt: String

    let onCreateNote: () -> Void

    private var recordingCaption: String {
        if speechInput.isListening { return "Listening..." }
        return speechInput.isBusy ? "Finishing your note..." : "Tap to speak"
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 9) {
                        AppIcon(systemName: "square.stack.fill", size: 21)
                            .foregroundStyle(AppTheme.accent)
                        Text("Notes")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(AppTheme.textPrimary)
                    }

                    Spacer(minLength: 48)

                    Button(action: onCreateNote) {
                        Text(prompt)
                            .font(.body)
                            .foregroundStyle(AppTheme.inactive)
                            .padding(.horizontal, 20)
                            .frame(maxWidth: .infinity, minHeight: 86, alignment: .leading)
                            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 22))
                            .shadow(color: AppTheme.accentInk.opacity(0.05), radius: 16, y: 6)
                            .contentShape(RoundedRectangle(cornerRadius: 22))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Write a new note")
                    .accessibilityValue(prompt)

                    Spacer(minLength: 40)

                    VStack(spacing: 12) {
                        Button {
                            Task { await speechInput.toggle() }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.accentTint)
                                    .frame(width: 144, height: 144)

                                if speechInput.isListening { ListeningPulse() }

                                Circle()
                                    .fill(LinearGradient(
                                        colors: [AppTheme.accent.opacity(0.8), AppTheme.accent],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 112, height: 112)
                                    .shadow(color: AppTheme.accent.opacity(0.22), radius: 18, y: 8)

                                AppIcon(
                                    systemName: speechInput.isListening ? "stop.fill" : "mic.fill",
                                    size: speechInput.isListening ? 31 : 37
                                )
                                .foregroundStyle(AppTheme.surface)
                            }
                            .frame(width: 161, height: 161)
                            .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .disabled(speechInput.isBusy)
                        .opacity(speechInput.isBusy ? 0.75 : 1)
                        .accessibilityLabel(speechInput.isListening ? "Stop voice input" : "Start voice input")
                        .accessibilityHint(speechInput.isListening
                            ? "Stops recording and saves the note"
                            : "Records an English note and saves it automatically")

                        Text(recordingCaption)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(speechInput.isListening ? AppTheme.accentInk : AppTheme.inactive)
                    }
                    .frame(maxWidth: .infinity)

                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 28)
                .padding(.top, 24)
                .frame(maxWidth: .infinity, minHeight: max(0, geometry.size.height))
            }
            .scrollIndicators(.hidden)
        }
        .background(LinearGradient(
            colors: [AppTheme.accentTint.opacity(0.85), AppTheme.surface, AppTheme.surface],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ))
        .toolbar(.hidden, for: .navigationBar)
    }
}
