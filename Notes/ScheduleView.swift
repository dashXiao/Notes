import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject private var scheduleStore: ScheduleStore

    @Binding var day: Date
    let onCreateSchedule: () -> Void
    let onSelectSchedule: (UUID) -> Void

    @State private var dragTranslation: CGFloat = 0
    @State private var pendingDay: Date?
    @State private var transitionDirection: DayTransitionDirection?
    @State private var isTransitioning = false
    @State private var layoutMode: ScheduleLayoutMode = .singleDay
    @State private var expandedOverviewDay: Date?

    init(
        day: Binding<Date>,
        onCreateSchedule: @escaping () -> Void,
        onSelectSchedule: @escaping (UUID) -> Void
    ) {
        _day = day
        self.onCreateSchedule = onCreateSchedule
        self.onSelectSchedule = onSelectSchedule
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if layoutMode == .singleDay {
                    singleDayLayout(in: geometry.size)
                        .transition(.opacity)
                } else {
                    overviewLayout(in: geometry.size)
                        .opacity(expandedOverviewDay == nil ? 1 : 0)
                        .transition(.opacity)
                }

                if let expandedOverviewDay {
                    expandedOverviewLayout(
                        for: expandedOverviewDay,
                        in: geometry.size
                    )
                    .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .overlay(alignment: .top) {
                if expandedOverviewDay == nil {
                    HStack {
                        Button(action: toggleLayout) {
                            Image(
                                systemName: layoutMode == .singleDay
                                    ? "rectangle.grid.2x2"
                                    : "rectangle.portrait"
                            )
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(AppTheme.accent)
                            .frame(width: 44, height: 44)
                            .background(AppTheme.cream, in: Circle())
                            .overlay {
                                Circle()
                                    .stroke(AppTheme.accent, lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(
                            layoutMode == .singleDay
                                ? "Show all schedule days"
                                : "Show single-day schedule"
                        )

                        Spacer()

                        Button(action: onCreateSchedule) {
                            Image("NewScheduleIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                                .frame(width: 44, height: 44)
                                .background(AppTheme.cream, in: Circle())
                                .overlay {
                                    Circle()
                                        .stroke(AppTheme.accent, lineWidth: 1)
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Create schedule")
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                    .transition(.opacity)
                }
            }
        }
        .background(Color(.systemBackground))
        .toolbar(.hidden, for: .navigationBar)
        .animation(
            .easeOut(duration: 0.2),
            value: scheduleStore.items
        )
    }

    private func singleDayLayout(in size: CGSize) -> some View {
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

    private func overviewLayout(in size: CGSize) -> some View {
        let horizontalPadding = 12.0
        let columnSpacing = 12.0
        let cardWidth = (
            size.width - horizontalPadding * 2 - columnSpacing
        ) / 2
        let days = scheduleDayGroups

        return ScrollView {
            if days.isEmpty {
                Text("No schedules yet.")
                    .font(.body)
                    .foregroundStyle(AppTheme.inactive)
                    .frame(maxWidth: .infinity)
                    .padding(.top, size.height * 0.38)
            } else {
                HStack(alignment: .top, spacing: columnSpacing) {
                    overviewColumn(
                        indices: Array(
                            stride(
                                from: 0,
                                to: days.count,
                                by: 2
                            )
                        ),
                        days: days,
                        cardWidth: cardWidth
                    )

                    overviewColumn(
                        indices: Array(
                            stride(
                                from: 1,
                                to: days.count,
                                by: 2
                            )
                        ),
                        days: days,
                        cardWidth: cardWidth
                    )
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 88)
                .padding(.bottom, 24)
            }
        }
        .scrollIndicators(.hidden)
    }

    private func expandedOverviewLayout(
        for expandedDay: Date,
        in size: CGSize
    ) -> some View {
        ZStack {
            Color.black
                .opacity(0.22)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        expandedOverviewDay = nil
                    }
                }

            scheduleCard(
                for: expandedDay,
                width: min(342, max(0, size.width - 60))
            )
            .transition(.scale(scale: 0.88).combined(with: .opacity))
        }
    }

    private func overviewColumn(
        indices: [Int],
        days: [ScheduleDayGroup],
        cardWidth: CGFloat
    ) -> some View {
        LazyVStack(spacing: 12) {
            ForEach(indices, id: \.self) { index in
                let group = days[index]

                ScheduleOverviewCard(group: group) {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                        expandedOverviewDay = group.day
                    }
                }
                .frame(width: cardWidth)
            }
        }
        .frame(width: cardWidth)
    }

    private var scheduleDayGroups: [ScheduleDayGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(
            grouping: scheduleStore.items
        ) {
            calendar.startOfDay(for: $0.scheduledAt)
        }

        return grouped.keys.sorted().map { date in
            ScheduleDayGroup(
                day: date,
                items: (grouped[date] ?? []).sorted {
                    $0.scheduledAt < $1.scheduledAt
                }
            )
        }
    }

    private func toggleLayout() {
        expandedOverviewDay = nil
        withAnimation(.easeOut(duration: 0.2)) {
            layoutMode = layoutMode == .singleDay
                ? .overview
                : .singleDay
        }
    }

    @ViewBuilder
    private func scheduleCard(
        for cardDay: Date,
        width: CGFloat
    ) -> some View {
        ScheduleCard(
            day: cardDay,
            items: scheduleStore.items(on: cardDay),
            emptyMessage: emptyMessage(for: cardDay),
            onSelectSchedule: onSelectSchedule,
            onDeleteSchedule: deleteSchedule
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
        let calendar = Calendar.current
        let currentDay = calendar.startOfDay(for: day)
        let today = calendar.startOfDay(for: Date())

        var availableDays = Set(
            scheduleStore.items.map {
                calendar.startOfDay(for: $0.scheduledAt)
            }
        )
        availableDays.insert(today)

        let sortedDays = availableDays.sorted()

        if forward {
            return sortedDays.first { $0 > currentDay }
        }
        return sortedDays.last { $0 < currentDay }
    }

    private func emptyMessage(for pageDay: Date) -> String {
        Calendar.current.isDateInToday(pageDay)
            ? "No schedule today."
            : "No schedule for this day."
    }

    private func deleteSchedule(_ id: UUID) {
        withAnimation(.easeOut(duration: 0.2)) {
            scheduleStore.deleteItem(id: id)
        }
    }
}

private struct ScheduleCard: View {
    let day: Date
    let items: [ScheduleItem]
    let emptyMessage: String
    let onSelectSchedule: (UUID) -> Void
    let onDeleteSchedule: (UUID) -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var headingSize = 34.0

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if items.isEmpty {
                Text(emptyMessage)
                    .font(.callout)
                    .foregroundStyle(AppTheme.inactive)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
            } else {
                HStack(spacing: 8) {
                    Text(day.formatted(.dateTime.month(.wide).day()))
                        .font(
                            .system(
                                size: headingSize,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(Color(.label))

                    if Calendar.current.isDateInToday(day) {
                        Text("Today")
                            .font(
                                .system(
                                    size: headingSize,
                                    weight: .medium,
                                    design: .serif
                                )
                                .italic()
                            )
                            .foregroundStyle(
                                Color(
                                    red: 1,
                                    green: 0.3,
                                    blue: 0.1
                                )
                            )
                    }
                }
                .lineLimit(1)

                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) {
                        index,
                        item in

                        SwipeableScheduleRow(
                            item: item,
                            onSelect: {
                                onSelectSchedule(item.id)
                            },
                            onDelete: {
                                onDeleteSchedule(item.id)
                            }
                        )

                        if index < items.count - 1 {
                            Rectangle()
                                .fill(AppTheme.bottomBorder)
                                .frame(height: 1)
                                .padding(.vertical, 16)
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.accent, lineWidth: 1)
        }
    }
}

private struct ScheduleOverviewCard: View {
    let group: ScheduleDayGroup
    let onSelectDay: () -> Void

    @ScaledMetric(relativeTo: .headline) private var headingSize = 18.0

    var body: some View {
        Button(action: onSelectDay) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 5) {
                    Text(
                        group.day.formatted(
                            .dateTime.month(.abbreviated).day()
                        )
                    )
                    .font(
                        .system(
                            size: headingSize,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(Color(.label))

                    if Calendar.current.isDateInToday(group.day) {
                        Text("Today")
                            .font(
                                .system(
                                    size: headingSize,
                                    weight: .medium,
                                    design: .serif
                                )
                                .italic()
                            )
                            .foregroundStyle(
                                Color(
                                    red: 1,
                                    green: 0.3,
                                    blue: 0.1
                                )
                            )
                    }
                }
                .lineLimit(1)

                VStack(alignment: .leading, spacing: 7) {
                    ForEach(
                        Array(group.items.prefix(3).enumerated()),
                        id: \.element.id
                    ) { index, item in
                        let showsOverflow = index == 2
                            && group.items.count > 3

                        HStack(alignment: .top, spacing: 8) {
                            Text(scheduleTimeText(item))
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color(.label))
                            .frame(width: 34, alignment: .leading)

                            Text(
                                item.title
                                    + (showsOverflow ? " …" : "")
                            )
                            .font(.footnote)
                            .foregroundStyle(Color(.secondaryLabel))
                            .lineLimit(2)
                            .truncationMode(.tail)
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                        }
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.accent, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "\(group.day.formatted(.dateTime.month(.wide).day())), "
                + "\(group.items.count) schedules"
        )
        .accessibilityHint("Open all schedules for this day")
    }
}

private enum ScheduleLayoutMode {
    case singleDay
    case overview
}

private struct ScheduleDayGroup {
    let day: Date
    let items: [ScheduleItem]
}

private enum DayTransitionDirection {
    case next
    case previous
}

private struct SwipeableScheduleRow: View {
    let item: ScheduleItem
    let onSelect: () -> Void
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var dragStartOffset: CGFloat = 0
    @State private var isDragging = false

    private let actionWidth: CGFloat = 78

    private var isOpen: Bool {
        offset < 0
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            Button {
                withAnimation(.easeOut(duration: 0.18)) {
                    offset = 0
                }
                onDelete()
            } label: {
                Text("Delete")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(width: actionWidth)
                    .frame(maxHeight: .infinity)
                    .background(Color.red)
            }
            .buttonStyle(.plain)
            .opacity(isOpen ? 1 : 0)
            .disabled(!isOpen)
            .accessibilityHidden(!isOpen)

            HStack(alignment: .top, spacing: 12) {
                Text(scheduleTimeText(item))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color(.label))
                .frame(width: 48, alignment: .leading)

                Text(item.title)
                    .font(.callout)
                    .foregroundStyle(Color(.secondaryLabel))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
            .background(Color(.systemBackground))
            .offset(x: offset)
            .onTapGesture {
                if isOpen {
                    closeAction()
                } else {
                    onSelect()
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Open schedule for editing")
            .accessibilityAction {
                onSelect()
            }
            .accessibilityAction(
                named: "Delete",
                onDelete
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { value in
                        guard abs(value.translation.width)
                            > abs(value.translation.height) else {
                            return
                        }

                        if !isDragging {
                            isDragging = true
                            dragStartOffset = offset
                        }
                        offset = min(
                            0,
                            max(
                                -actionWidth,
                                dragStartOffset + value.translation.width
                            )
                        )
                    }
                    .onEnded { value in
                        let projectedOffset = offset
                            + value.predictedEndTranslation.width * 0.15
                        let shouldOpen = projectedOffset < -actionWidth * 0.5

                        withAnimation(.easeOut(duration: 0.18)) {
                            offset = shouldOpen ? -actionWidth : 0
                        }
                        dragStartOffset = shouldOpen ? -actionWidth : 0
                        isDragging = false
                    }
            )
        }
        .clipped()
    }

    private func closeAction() {
        withAnimation(.easeOut(duration: 0.18)) {
            offset = 0
        }
        dragStartOffset = 0
    }
}

private func scheduleTimeText(_ item: ScheduleItem) -> String {
    item.timeIsPending == true
        ? "TBD"
        : item.scheduledAt.formatted(
            .dateTime
                .hour(.twoDigits(amPM: .omitted))
                .minute(.twoDigits)
        )
}
