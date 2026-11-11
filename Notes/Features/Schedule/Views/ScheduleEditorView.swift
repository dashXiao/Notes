import SwiftUI

struct ScheduleEditorView: View {
    @EnvironmentObject private var scheduleStore: ScheduleStore
    @Environment(\.dismiss) private var dismiss

    @StateObject private var model: ScheduleEditorModel
    @FocusState private var isTitleFocused: Bool

    init(item: ScheduleItem?, day: Date) {
        _model = StateObject(wrappedValue: ScheduleEditorModel(item: item, day: day))
    }

    var body: some View {
        Form {
            Section("Date") {
                DatePicker(
                    "Date",
                    selection: $model.day,
                    displayedComponents: .date
                )
                .labelsHidden()
                .accessibilityLabel("Date")
            }
            .listRowBackground(AppTheme.surface)

            Section {
                Toggle("Time TBD", isOn: $model.isTimePending)

                if !model.isTimePending {
                    DatePicker(
                        "Starts",
                        selection: $model.time,
                        displayedComponents: .hourAndMinute
                    )
                }
            } header: {
                Text("Time")
            }
            .listRowBackground(AppTheme.surface)

            Section {
                TextField(
                    "What's happening?",
                    text: $model.title,
                    axis: .vertical
                )
                .lineLimit(2...5)
                .textInputAutocapitalization(.sentences)
                .focused($isTitleFocused)
            } header: {
                Text("Title")
            }
            .listRowBackground(AppTheme.surface)
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.canvas)
        .tint(AppTheme.accent)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            EditorToolbar(
                title: model.isEditing ? "Edit Schedule" : "New Schedule",
                saveLabel: "Save schedule",
                canSave: model.canSave,
                onBack: dismiss.callAsFunction,
                onSave: save
            )
        }
        .toolbarBackground(AppTheme.canvas, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            isTitleFocused = true
        }
    }

    private func save() {
        if model.save(in: scheduleStore) {
            dismiss()
        }
    }
}
