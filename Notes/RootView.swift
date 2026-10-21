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

    @State private var selectedTab: AppTab = .home
    @State private var homePath: [NoteRoute] = []
    @State private var notesPath: [NoteRoute] = []

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
                HomeView {
                    homePath.append(.create)
                }
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
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if isShowingTabBar {
                BottomTabBar(selection: $selectedTab)
            }
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
}
