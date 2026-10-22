import SwiftUI

enum AppTab: Hashable {
    case home
    case notes
}

private enum NoteRoute: Hashable {
    case create
    case edit(UUID)
}

struct RootView: View {
    @EnvironmentObject private var notesStore: NotesStore
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var speechInput = SpeechInputController()

    @State private var selectedTab: AppTab = .home
    @State private var homePath: [NoteRoute] = []
    @State private var notesPath: [NoteRoute] = []
    @State private var isShowingNoteCreated = false
    @State private var noteCreatedToastTask: Task<Void, Never>?

    private var isShowingTabBar: Bool {
        switch selectedTab {
        case .home:
            homePath.isEmpty
        case .notes:
            notesPath.isEmpty
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: $homePath) {
                HomeView(
                    speechInput: speechInput,
                    onCreateNote: {
                        homePath.append(.create)
                    }
                )
                .navigationDestination(for: NoteRoute.self) { route in
                    destination(for: route)
                }
                .toolbar(.hidden, for: .tabBar)
            }
            .tag(AppTab.home)

            NavigationStack(path: $notesPath) {
                NotesView { noteID in
                    notesPath.append(.edit(noteID))
                }
                .navigationDestination(for: NoteRoute.self) { route in
                    destination(for: route)
                }
                .toolbar(.hidden, for: .tabBar)
            }
            .tag(AppTab.notes)
        }
        .tint(AppTheme.accent)
        .toolbar(.hidden, for: .tabBar)
        .overlay(alignment: .top) {
            if isShowingNoteCreated {
                NoteCreatedToast()
                    .padding(.top, 12)
                    .transition(
                        .move(edge: .top)
                            .combined(with: .opacity)
                    )
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if isShowingTabBar {
                BottomTabBar(selection: $selectedTab)
            }
        }
        .onChange(of: speechInput.completedText) { _, transcript in
            saveVoiceNote(transcript)
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase != .active else {
                return
            }

            Task {
                await speechInput.stopIfListening()
            }
        }
        .alert(
            "Voice Input Unavailable",
            isPresented: Binding(
                get: { speechInput.errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        speechInput.clearError()
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                speechInput.clearError()
            }
        } message: {
            Text(speechInput.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private func destination(for route: NoteRoute) -> some View {
        switch route {
        case .create:
            EditNoteView(note: nil)
        case let .edit(noteID):
            EditNoteView(note: notesStore.note(with: noteID))
        }
    }

    private func saveVoiceNote(_ transcript: String?) {
        guard let transcript,
              notesStore.saveNote(text: transcript) else {
            return
        }

        speechInput.consumeCompletedText()
        noteCreatedToastTask?.cancel()

        withAnimation(.easeOut(duration: 0.2)) {
            isShowingNoteCreated = true
        }

        noteCreatedToastTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else {
                return
            }

            withAnimation(.easeIn(duration: 0.2)) {
                isShowingNoteCreated = false
            }
        }
    }
}

private struct NoteCreatedToast: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppTheme.accent)

            Text("Note created")
                .font(.callout)
                .foregroundStyle(AppTheme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppTheme.cream, in: Capsule())
        .overlay {
            Capsule()
                .stroke(AppTheme.accent, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}
