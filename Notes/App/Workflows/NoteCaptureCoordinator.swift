import Combine
import Foundation

enum NoteCaptureEvent {
    case voiceNoteCreated
    case scheduleCreated
}

@MainActor
final class NoteCaptureCoordinator: ObservableObject {
    let events = PassthroughSubject<NoteCaptureEvent, Never>()

    private let notesStore: NotesStore
    private let scheduleStore: ScheduleStore
    private let extractor: (any ScheduleExtracting)?
    private var tasks: [UUID: AnalysisTask] = [:]

    private struct AnalysisTask {
        let id: UUID
        let task: Task<Void, Never>
    }

    init(
        notesStore: NotesStore,
        scheduleStore: ScheduleStore,
        extractor: (any ScheduleExtracting)?
    ) {
        self.notesStore = notesStore
        self.scheduleStore = scheduleStore
        self.extractor = extractor
    }

    @discardableResult
    func saveNote(id: UUID? = nil, text: String) -> Note? {
        guard let note = notesStore.saveNote(id: id, text: text) else {
            return nil
        }
        analyze(note)
        return note
    }

    @discardableResult
    func saveVoiceNote(text: String) -> Bool {
        guard saveNote(text: text) != nil else {
            return false
        }
        events.send(.voiceNoteCreated)
        return true
    }

    private func analyze(_ note: Note) {
        tasks.removeValue(forKey: note.id)?.task.cancel()
        guard ScheduleIntentDetector.shouldAnalyze(note.text), let extractor else {
            return
        }

        let taskID = UUID()
        let task = Task { [weak self] in
            defer {
                if self?.tasks[note.id]?.id == taskID {
                    self?.tasks[note.id] = nil
                }
            }

            do {
                let extracted = try await extractor.extract(
                    from: note.text,
                    referenceDate: note.updatedAt,
                    timeZone: .current
                )
                guard let self,
                      !Task.isCancelled,
                      self.notesStore.note(with: note.id) == note,
                      let extracted,
                      self.isValid(extracted, referenceDate: note.updatedAt),
                      self.scheduleStore.saveInferredItem(
                          sourceNoteID: note.id,
                          title: extracted.title,
                          scheduledAt: extracted.scheduledAt,
                          timeIsPending: extracted.timeIsPending
                      ) != nil else {
                    return
                }
                self.events.send(.scheduleCreated)
            } catch {
                // Remote analysis must never interrupt a locally saved note.
            }
        }
        tasks[note.id] = AnalysisTask(id: taskID, task: task)
    }

    private func isValid(_ schedule: ExtractedSchedule, referenceDate: Date) -> Bool {
        if schedule.timeIsPending {
            let calendar = Calendar.current
            return calendar.startOfDay(for: schedule.scheduledAt)
                >= calendar.startOfDay(for: referenceDate)
        }
        return schedule.scheduledAt > Date().addingTimeInterval(-300)
    }
}
