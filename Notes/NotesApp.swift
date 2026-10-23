//
//  NotesApp.swift
//  Notes
//
//  Created by xyh on 10/20/26.
//

import SwiftUI

@main
struct NotesApp: App {
    @StateObject private var notesStore = NotesStore()
    @StateObject private var scheduleStore = ScheduleStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notesStore)
                .environmentObject(scheduleStore)
        }
    }
}
