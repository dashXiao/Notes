import Foundation

enum AppTab: Hashable {
    case home
    case notes
    case schedule
}

enum NoteRoute: Hashable {
    case create
    case edit(UUID)
}

enum ScheduleRoute: Hashable {
    case create
    case edit(UUID)
}
