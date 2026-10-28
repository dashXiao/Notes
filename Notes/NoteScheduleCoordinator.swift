import Combine
import Foundation

@MainActor
final class NoteScheduleCoordinator: ObservableObject {
    @Published private(set) var createdSchedule: ScheduleItem?

    private let extractor: DeepSeekScheduleExtractor?
    private var tasks: [UUID: Task<Void, Never>] = [:]

    init() {
        if let configuration = DeepSeekConfiguration.current {
            extractor = DeepSeekScheduleExtractor(
                configuration: configuration
            )
        } else {
            extractor = nil
        }
    }

    func process(note: Note, scheduleStore: ScheduleStore) {
        guard ScheduleIntentDetector.shouldAnalyze(note.text),
              let extractor else {
            return
        }

        tasks[note.id]?.cancel()
        tasks[note.id] = Task { [weak self] in
            defer {
                self?.tasks[note.id] = nil
            }

            do {
                let extracted = try await extractor.extract(
                    from: note.text,
                    referenceDate: note.updatedAt,
                    timeZone: .current
                )

                guard !Task.isCancelled,
                      let extracted,
                      self?.isValid(
                        extracted,
                        referenceDate: note.updatedAt
                      ) == true,
                      let item = scheduleStore.saveInferredItem(
                          sourceNoteID: note.id,
                          title: extracted.title,
                          scheduledAt: extracted.scheduledAt,
                          timeIsPending: extracted.timeIsPending
                      ) else {
                    return
                }

                self?.createdSchedule = item
            } catch {
                // Note saving must never be blocked by remote analysis.
            }
        }
    }

    func consumeCreatedSchedule() {
        createdSchedule = nil
    }

    private func isValid(
        _ schedule: ExtractedSchedule,
        referenceDate: Date
    ) -> Bool {
        if schedule.timeIsPending {
            let today = Calendar.current.startOfDay(for: referenceDate)
            return Calendar.current.startOfDay(
                for: schedule.scheduledAt
            ) >= today
        }

        return schedule.scheduledAt > Date().addingTimeInterval(-300)
    }
}
