import Foundation

struct InferredScheduleChange: Equatable {
    let item: ScheduleItem
    let previousItem: ScheduleItem?
}
