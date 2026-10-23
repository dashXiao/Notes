import SwiftUI

struct ScheduleEditorView: View {
    @EnvironmentObject private var scheduleStore: ScheduleStore
    @Environment(\.dismiss) private var dismiss

    private let scheduleID: UUID?

    @State private var day: Date
    @State private var time: Date
    @State private var title: String
    @FocusState private var isTitleFocused: Bool

    init(item: ScheduleItem?, day: Date) {
        scheduleID = item?.id
        let initialDay = Calendar.current.startOfDay(
            for: item?.scheduledAt ?? day
        )
        _day = State(initialValue: initialDay)
        _time = State(
            initialValue: item?.scheduledAt
                ?? Self.defaultTime(for: initialDay)
        )
        _title = State(initialValue: item?.title ?? "")
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            Section("Date") {
                DatePicker(
                    "Date",
                    selection: $day,
                    displayedComponents: .date
                )
                .labelsHidden()
                .accessibilityLabel("Date")
            }

            Section {
                DatePicker(
                    "Starts",
                    selection: $time,
                    displayedComponents: .hourAndMinute
                )
            } header: {
                Text("Time")
            }

            Section {
                TextField(
                    "What's happening?",
                    text: $title,
                    axis: .vertical
                )
                .lineLimit(2...5)
                .textInputAutocapitalization(.sentences)
                .focused($isTitleFocused)
            } header: {
                Text("Title")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(.systemBackground))
        .tint(AppTheme.accent)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(scheduleID == nil ? "New Schedule" : "Edit Schedule")
                    .font(.callout)
                    .foregroundStyle(Color(.label))
            }
            .sharedBackgroundVisibility(.hidden)

            ToolbarItem(placement: .topBarLeading) {
                Button(action: dismiss.callAsFunction) {
                    Image("BackIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                .accessibilityLabel("Back")
            }
            .sharedBackgroundVisibility(.hidden)

            ToolbarItem(placement: .topBarTrailing) {
                Button(action: save) {
                    Image("CheckIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .opacity(canSave ? 1 : 0.35)
                }
                .disabled(!canSave)
                .accessibilityLabel("Save schedule")
            }
            .sharedBackgroundVisibility(.hidden)
        }
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            isTitleFocused = true
        }
    }

    private func save() {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents(
            [.hour, .minute],
            from: time
        )

        guard let scheduledAt = calendar.date(
            bySettingHour: timeComponents.hour ?? 0,
            minute: timeComponents.minute ?? 0,
            second: 0,
            of: day
        ),
        scheduleStore.saveItem(
            id: scheduleID,
            scheduledAt: scheduledAt,
            title: title
        ) else {
            return
        }

        dismiss()
    }

    private static func defaultTime(for day: Date) -> Date {
        let calendar = Calendar.current

        if calendar.isDateInToday(day) {
            return Date()
        }

        return calendar.date(
            bySettingHour: 9,
            minute: 0,
            second: 0,
            of: day
        ) ?? day
    }
}
