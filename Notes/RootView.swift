import SwiftUI

enum AppTab: Hashable {
    case home
    case notes
    case schedule
}

private enum NoteRoute: Hashable {
    case create
    case edit(UUID)
}

private enum ScheduleRoute: Hashable {
    case create
    case edit(UUID)
}

struct RootView: View {
    @EnvironmentObject private var notesStore: NotesStore
    @EnvironmentObject private var scheduleStore: ScheduleStore
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var speechInput = SpeechInputController()

    @State private var selectedTab: AppTab = .home
    @State private var homePath: [NoteRoute] = []
    @State private var notesPath: [NoteRoute] = []
    @State private var schedulePath: [ScheduleRoute] = []
    @State private var scheduleDay = Calendar.current.startOfDay(for: Date())
    @State private var isShowingNoteCreated = false
    @State private var noteCreatedToastTask: Task<Void, Never>?

    private var isShowingTabBar: Bool {
        switch selectedTab {
        case .home:
            homePath.isEmpty
        case .notes:
            notesPath.isEmpty
        case .schedule:
            schedulePath.isEmpty
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

            NavigationStack(path: $schedulePath) {
                ScheduleView(
                    day: $scheduleDay,
                    onCreateSchedule: {
                        schedulePath.append(.create)
                    },
                    onSelectSchedule: { scheduleID in
                        schedulePath.append(.edit(scheduleID))
                    }
                )
                .navigationDestination(for: ScheduleRoute.self) { route in
                    scheduleDestination(for: route)
                }
                .toolbar(.hidden, for: .tabBar)
            }
            .tag(AppTab.schedule)
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
        .onChange(of: selectedTab) { _, newTab in
            if newTab == .schedule {
                scheduleDay = Calendar.current.startOfDay(for: Date())
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

    @ViewBuilder
    private func scheduleDestination(for route: ScheduleRoute) -> some View {
        switch route {
        case .create:
            ScheduleEditorView(item: nil, day: scheduleDay)
        case let .edit(scheduleID):
            ScheduleEditorView(
                item: scheduleStore.item(with: scheduleID),
                day: scheduleDay
            )
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
