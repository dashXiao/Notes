import SwiftUI

struct HomeView: View {
    @ObservedObject var speechInput: SpeechInputController
    let prompt: String

    let onCreateNote: () -> Void

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

                    VoiceInputControl(
                        isListening: speechInput.isListening,
                        isBusy: speechInput.isBusy
                    ) {
                        Task { await speechInput.toggle() }
                    }

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
