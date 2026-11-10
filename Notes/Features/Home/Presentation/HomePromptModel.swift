import Combine

@MainActor
final class HomePromptModel: ObservableObject {
    @Published private(set) var prompt: String

    private var needsRefresh = false

    private static let prompts = [
        "Got a brainwave? Drop it here.",
        "Brain full? Unpack a thought.",
        "Catch that thought before it escapes.",
        "Plot twist? Write it down.",
        "Loose thoughts? Park them here.",
        "Give your brain a sticky note.",
        "Tiny thought? Make it official.",
        "Save it before your brain hits snooze.",
        "Big idea? Small box. Go for it.",
        "Dear brain, let's write this down."
    ]

    init() {
        prompt = Self.prompts.randomElement() ?? Self.prompts[0]
    }

    func appDidEnterBackground() {
        needsRefresh = true
    }

    func appDidBecomeActive() {
        guard needsRefresh else { return }
        needsRefresh = false
        prompt = Self.prompts.filter { $0 != prompt }.randomElement() ?? Self.prompts[0]
    }
}
