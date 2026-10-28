import SwiftUI

struct HomeView: View {
    @ObservedObject var speechInput: SpeechInputController

    let onCreateNote: () -> Void

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: geometry.size.height * 0.31)

                Button(action: onCreateNote) {
                    HStack {
                        Text("Write your note here.")
                            .font(.body)
                            .foregroundStyle(AppTheme.inactive)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                    .frame(
                        width: min(303, geometry.size.width - 106),
                        height: 86
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.accent, lineWidth: 2)
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Write a new note")

                Color.clear
                    .frame(height: 109)

                Button {
                    Task {
                        await speechInput.toggle()
                    }
                } label: {
                    ZStack {
                        if speechInput.isListening {
                            ListeningPulse()
                        }

                        Circle()
                            .fill(AppTheme.cream)
                            .overlay {
                                Circle()
                                    .stroke(AppTheme.accent, lineWidth: 2)
                            }

                        Image("MicIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                    }
                    .frame(width: 161, height: 161)
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(speechInput.isBusy)
                .opacity(speechInput.isBusy ? 0.75 : 1)
                .accessibilityLabel(
                    speechInput.isListening
                        ? "Stop voice input"
                        : "Start voice input"
                )
                .accessibilityHint(
                    speechInput.isListening
                        ? "Stops recording and saves the note"
                        : "Records an English note and saves it automatically"
                )

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemBackground))
        .toolbar(.hidden, for: .navigationBar)
    }
}
