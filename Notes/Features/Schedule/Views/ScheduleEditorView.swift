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
        }
        .scrollContentBackground(.hidden)
        .background(Color(.systemBackground))
        .tint(AppTheme.accent)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(model.isEditing ? "Edit Schedule" : "New Schedule")
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
                        .opacity(model.canSave ? 1 : 0.35)
                }
                .disabled(!model.canSave)
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
        if model.save(in: scheduleStore) {
            dismiss()
        }
    }
}
