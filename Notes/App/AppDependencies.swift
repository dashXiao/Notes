import Combine
import Foundation

@MainActor
final class AppDependencies: ObservableObject {
    let notesStore: NotesStore
    let scheduleStore: ScheduleStore
    let speechInput: SpeechInputController
    let noteCapture: NoteCaptureCoordinator
    let toastPresenter: ToastPresenter

    private var subscriptions = Set<AnyCancellable>()

    init() {
        let storage = JSONFileStorage()
        let notesStore = NotesStore(storage: storage)
        let scheduleStore = ScheduleStore(storage: storage)
        let speechInput = SpeechInputController()
        let toastPresenter = ToastPresenter()
        let extractor = DeepSeekConfiguration.current.map {
            DeepSeekScheduleExtractor(configuration: $0)
        }
        let noteCapture = NoteCaptureCoordinator(
            notesStore: notesStore,
            scheduleStore: scheduleStore,
            extractor: extractor
        )

        self.notesStore = notesStore
        self.scheduleStore = scheduleStore
        self.speechInput = speechInput
        self.noteCapture = noteCapture
        self.toastPresenter = toastPresenter

        noteCapture.events
            .sink { [weak toastPresenter] event in
                switch event {
                case .voiceNoteCreated:
                    toastPresenter?.show("Note created")
                case let .scheduleSaved(change):
                    toastPresenter?.showSchedule(change)
                }
            }
            .store(in: &subscriptions)

        speechInput.$completedText
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak noteCapture, weak speechInput] transcript in
                if noteCapture?.saveVoiceNote(text: transcript) == true {
                    speechInput?.consumeCompletedText()
                }
            }
            .store(in: &subscriptions)
    }
}
