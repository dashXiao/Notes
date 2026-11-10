import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject private var scheduleStore: ScheduleStore
    @Binding var day: Date
    let onCreateSchedule: () -> Void
    let onSelectSchedule: (UUID) -> Void

    @State private var layoutMode: ScheduleLayoutMode = .singleDay
    @State private var expandedOverviewDay: Date?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if layoutMode == .singleDay {
                    ScheduleSingleDayLayout(
                        day: $day,
                        size: geometry.size,
                        availableDays: scheduleStore.days(including: Date()),
                        groups: scheduleStore.dayGroups,
                        onSelectSchedule: onSelectSchedule,
                        onDeleteSchedule: deleteSchedule
                    )
                    .transition(.opacity)
                } else {
                    ScheduleOverviewLayout(
                        size: geometry.size,
                        days: scheduleStore.dayGroups
                    ) { selectedDay in
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                            expandedOverviewDay = selectedDay
                        }
                    }
                    .opacity(expandedOverviewDay == nil ? 1 : 0)
                    .transition(.opacity)
                }

                if let expandedOverviewDay {
                    ScheduleExpandedDayLayout(
                        day: expandedOverviewDay,
                        items: scheduleStore.items(on: expandedOverviewDay),
                        size: geometry.size,
                        onSelectSchedule: onSelectSchedule,
                        onDeleteSchedule: deleteSchedule,
                        onDismiss: {
                            withAnimation(.easeOut(duration: 0.2)) {
                                self.expandedOverviewDay = nil
                            }
                        }
                    )
                    .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.canvas)
            .overlay(alignment: .top) {
                if expandedOverviewDay == nil {
                    HStack(spacing: 10) {
                        Text("Schedule")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        AppIconButton(
                            systemName: layoutMode == .singleDay ? "square.grid.2x2" : "rectangle.portrait",
                            label: layoutMode == .singleDay ? "Show all schedule days" : "Show single-day schedule",
                            action: toggleLayout
                        )
                        AppIconButton(systemName: "plus", label: "Create schedule", isPrimary: true, action: onCreateSchedule)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .transition(.opacity)
                }
            }
        }
        .background(AppTheme.canvas)
        .toolbar(.hidden, for: .navigationBar)
        .animation(.easeOut(duration: 0.2), value: scheduleStore.items)
    }

    private func toggleLayout() {
        expandedOverviewDay = nil
        withAnimation(.easeOut(duration: 0.2)) {
            layoutMode = layoutMode == .singleDay ? .overview : .singleDay
        }
    }

    private func deleteSchedule(_ id: UUID) {
        withAnimation(.easeOut(duration: 0.2)) {
            scheduleStore.deleteItem(id: id)
        }
    }
}

private enum ScheduleLayoutMode {
    case singleDay
    case overview
}
