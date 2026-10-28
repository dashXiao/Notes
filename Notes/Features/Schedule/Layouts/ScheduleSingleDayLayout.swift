import SwiftUI

struct ScheduleSingleDayLayout: View {
    @Binding var day: Date
    let size: CGSize
    let availableDays: [Date]
    let groups: [ScheduleDayGroup]
    let onSelectSchedule: (UUID) -> Void
    let onDeleteSchedule: (UUID) -> Void

    @State private var dragTranslation: CGFloat = 0
    @State private var pendingDay: Date?
    @State private var transitionDirection: DayTransitionDirection?
    @State private var isTransitioning = false

    var body: some View {
        let cardWidth = min(342, max(0, size.width - 60))
        let progress = min(
            1,
            abs(dragTranslation) / max(size.height, 1)
        )

        return ZStack {
            scheduleCard(for: day, width: cardWidth)
                .offset(y: currentCardOffset)
                .scaleEffect(1 - progress * 0.04)
                .opacity(1 - progress * 0.35)

            if let pendingDay {
                scheduleCard(for: pendingDay, width: cardWidth)
                    .offset(
                        y: incomingCardOffset(
                            viewportHeight: size.height
                        )
                    )
                    .scaleEffect(0.96 + progress * 0.04)
                    .opacity(0.35 + progress * 0.65)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .simultaneousGesture(
            dayTransitionGesture(viewportHeight: size.height)
        )
    }

    private func scheduleCard(for cardDay: Date, width: CGFloat) -> some View {
        ScheduleDayCard(
            day: cardDay,
            items: groups.first { $0.day == Calendar.current.startOfDay(for: cardDay) }?.items ?? [],
            onSelectSchedule: onSelectSchedule,
            onDeleteSchedule: onDeleteSchedule
        )
        .fixedSize(horizontal: false, vertical: true)
        .frame(width: width)
    }

    private var currentCardOffset: CGFloat {
        transitionDirection == nil
            ? dragTranslation * 0.16
            : dragTranslation
    }

    private func incomingCardOffset(viewportHeight: CGFloat) -> CGFloat {
        switch transitionDirection {
        case .next:
            viewportHeight + dragTranslation
        case .previous:
            -viewportHeight + dragTranslation
        case nil:
            viewportHeight
        }
    }

    private func dayTransitionGesture(
        viewportHeight: CGFloat
    ) -> some Gesture {
        DragGesture(minimumDistance: 16)
            .onChanged { value in
                guard !isTransitioning,
                      abs(value.translation.height)
                        > abs(value.translation.width) else {
                    return
                }

                if transitionDirection == nil {
                    let forward = value.translation.height < 0
                    pendingDay = adjacentDay(forward: forward)
                    transitionDirection = pendingDay == nil
                        ? nil
                        : (forward ? .next : .previous)
                }

                guard transitionDirection != nil else {
                    dragTranslation = value.translation.height * 0.16
                    return
                }

                switch transitionDirection {
                case .next:
                    dragTranslation = min(0, value.translation.height)
                case .previous:
                    dragTranslation = max(0, value.translation.height)
                case nil:
                    break
                }
            }
            .onEnded { value in
                guard !isTransitioning else {
                    return
                }

                let threshold = viewportHeight * 0.16
                let shouldComplete = abs(dragTranslation) > threshold
                    || abs(value.predictedEndTranslation.height)
                        > viewportHeight * 0.35

                if let pendingDay, shouldComplete {
                    completeTransition(
                        to: pendingDay,
                        viewportHeight: viewportHeight
                    )
                } else {
                    cancelTransition()
                }
            }
    }

    private func completeTransition(
        to targetDay: Date,
        viewportHeight: CGFloat
    ) {
        isTransitioning = true
        let finalOffset = transitionDirection == .next
            ? -viewportHeight
            : viewportHeight

        withAnimation(.easeOut(duration: 0.3)) {
            dragTranslation = finalOffset
        }

        Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else {
                return
            }

            day = targetDay
            dragTranslation = 0
            pendingDay = nil
            transitionDirection = nil
            isTransitioning = false
        }
    }

    private func cancelTransition() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            dragTranslation = 0
        }

        Task {
            try? await Task.sleep(for: .milliseconds(320))
            guard !Task.isCancelled else {
                return
            }

            pendingDay = nil
            transitionDirection = nil
        }
    }

    private func adjacentDay(forward: Bool) -> Date? {
        let currentDay = Calendar.current.startOfDay(for: day)
        return forward
            ? availableDays.first { $0 > currentDay }
            : availableDays.last { $0 < currentDay }
    }
}

private enum DayTransitionDirection {
    case next
    case previous
}
