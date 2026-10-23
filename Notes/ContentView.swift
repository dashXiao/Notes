//
//  ContentView.swift
//  Notes
//
//  Created by xyh on 10/20/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        RootView()
    }
}

#Preview {
    ContentView()
        .environmentObject(NotesStore())
        .environmentObject(ScheduleStore())
}
