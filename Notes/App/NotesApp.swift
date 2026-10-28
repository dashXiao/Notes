import SwiftUI

@main
struct NotesApp: App {
    @StateObject private var dependencies = AppDependencies()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(dependencies.notesStore)
                .environmentObject(dependencies.scheduleStore)
                .environmentObject(dependencies.speechInput)
                .environmentObject(dependencies.noteCapture)
                .environmentObject(dependencies.toastPresenter)
        }
    }
}
