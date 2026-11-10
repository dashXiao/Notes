import SwiftUI

struct RootView: View {
    @EnvironmentObject private var homePrompt: HomePromptModel
    @EnvironmentObject private var notesStore: NotesStore
    @EnvironmentObject private var scheduleStore: ScheduleStore
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var speechInput: SpeechInputController
    @EnvironmentObject private var toastPresenter: ToastPresenter

    @State private var selectedTab: AppTab = .home
    @State private var homePath: [NoteRoute] = []
    @State private var notesPath: [NoteRoute] = []
    @State private var schedulePath: [ScheduleRoute] = []
    @State private var scheduleDay = Calendar.current.startOfDay(for: Date())

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
                    prompt: homePrompt.prompt,
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
                NotesListView { noteID in
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
        .preferredColorScheme(.light)
        .toolbar(.hidden, for: .tabBar)
        .overlay(alignment: .top) {
            if let toast = toastPresenter.toast {
                toastView(toast)
                    .id(toast.id)
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
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                homePrompt.appDidEnterBackground()
            }
            if newPhase == .active {
                homePrompt.appDidBecomeActive()
            }
            guard newPhase != .active else {
                return
            }

            Task {
                await speechInput.stopIfListening()
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == .schedule && schedulePath.isEmpty {
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
    private func toastView(_ toast: ToastPresenter.Toast) -> some View {
        switch toast.content {
        case let .message(message):
            SuccessToastView(message: message)
        case let .schedule(change):
            ScheduleSavedToastView(
                change: change,
                onEdit: {
                    guard toastPresenter.dismiss(id: toast.id),
                          let item = scheduleStore.item(with: change.item.id) else {
                        return
                    }
                    scheduleDay = Calendar.current.startOfDay(for: item.scheduledAt)
                    schedulePath = [.edit(item.id)]
                    selectedTab = .schedule
                },
                onCancel: {
                    guard toastPresenter.dismiss(id: toast.id) else { return }
                    scheduleStore.undoInferredChange(change)
                }
            )
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private func destination(for route: NoteRoute) -> some View {
        switch route {
        case .create:
            NoteEditorView(note: nil)
        case let .edit(noteID):
            NoteEditorView(note: notesStore.note(with: noteID))
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
}
