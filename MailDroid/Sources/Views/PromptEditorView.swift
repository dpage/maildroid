import SwiftUI

struct PromptEditorView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let existingConfig: PromptConfig?
    let onSave: (PromptConfig) -> Void

    @State private var name: String
    @State private var promptText: String
    @State private var emailTimeRange: EmailTimeRange
    @State private var triggerType: TriggerType
    @State private var scheduleFrequency: ScheduleFrequency
    @State private var scheduleMinute: Int
    @State private var scheduleHour: Int
    @State private var scheduleDays: Set<Int>
    @State private var onlyShowIfActionable: Bool

    init(
        existingConfig: PromptConfig? = nil,
        onSave: @escaping (PromptConfig) -> Void
    ) {
        self.existingConfig = existingConfig
        self.onSave = onSave

        let schedule = existingConfig?.schedule

        _name = State(initialValue: existingConfig?.name ?? "")
        _promptText = State(initialValue: existingConfig?.prompt ?? "")
        _emailTimeRange = State(
            initialValue: existingConfig?.emailTimeRange ?? .last24Hours
        )
        _triggerType = State(
            initialValue: existingConfig?.triggerType ?? .onDemand
        )
        _scheduleFrequency = State(
            initialValue: schedule?.frequency ?? .daily
        )
        _scheduleMinute = State(
            initialValue: schedule?.minute ?? 0
        )
        _scheduleHour = State(
            initialValue: schedule?.hour ?? 9
        )
        _scheduleDays = State(
            initialValue: schedule?.daysOfWeek ?? []
        )
        _onlyShowIfActionable = State(
            initialValue: existingConfig?.onlyShowIfActionable ?? false
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text(existingConfig == nil ? "New Prompt" : "Edit Prompt")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Name field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Name")
                            .font(.system(size: 12, weight: .medium))
                        TextField("Prompt name", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Prompt text
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Prompt")
                            .font(.system(size: 12, weight: .medium))
                        TextEditor(text: $promptText)
                            .font(.system(size: 13))
                            .frame(minHeight: 100, maxHeight: 160)
                            .border(Color.secondary.opacity(0.3))
                            .cornerRadius(4)
                    }

                    // Email time range picker
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Email Time Range")
                            .font(.system(size: 12, weight: .medium))
                        Picker("", selection: $emailTimeRange) {
                            ForEach(EmailTimeRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                    }

                    // Trigger type picker
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Trigger Type")
                            .font(.system(size: 12, weight: .medium))
                        Picker("", selection: $triggerType) {
                            ForEach(TriggerType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                    }

                    // Schedule configuration
                    if triggerType == .scheduled || triggerType == .both {
                        scheduleSection
                    }

                    // Only show if actionable toggle
                    Toggle(
                        "Only show if actionable",
                        isOn: $onlyShowIfActionable
                    )
                    .font(.system(size: 13))
                }
                .padding(20)
            }

            Divider()

            // Action buttons
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save") {
                    savePrompt()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(width: 440, height: 560)
    }

    // MARK: - Schedule Section

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Schedule")
                .font(.system(size: 12, weight: .medium))

            // Frequency picker
            Picker("Frequency", selection: $scheduleFrequency) {
                ForEach(ScheduleFrequency.allCases, id: \.self) { freq in
                    Text(freq.rawValue).tag(freq)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)

            // Time pickers
            HStack(spacing: 12) {
                if scheduleFrequency != .hourly {
                    // Hour picker
                    HStack(spacing: 4) {
                        Text("Hour")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Picker("Hour", selection: $scheduleHour) {
                            ForEach(0..<24, id: \.self) { h in
                                Text(hourLabel(h)).tag(h)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 90)
                    }
                }

                // Minute picker
                HStack(spacing: 4) {
                    Text(scheduleFrequency == .hourly
                         ? "Minutes past"
                         : "Minute")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Picker("Minute", selection: $scheduleMinute) {
                        ForEach(
                            stride(from: 0, to: 60, by: 5).map { $0 },
                            id: \.self
                        ) { m in
                            Text(String(format: ":%02d", m)).tag(m)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 70)
                }
            }

            // Day of week toggles for custom frequency
            if scheduleFrequency == .custom {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Days of week")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        ForEach(dayOptions, id: \.value) { day in
                            DayToggleButton(
                                label: day.label,
                                isSelected: scheduleDays.contains(day.value),
                                action: {
                                    if scheduleDays.contains(day.value) {
                                        scheduleDays.remove(day.value)
                                    } else {
                                        scheduleDays.insert(day.value)
                                    }
                                }
                            )
                        }
                    }
                }
            }

            // Schedule summary
            Text(currentSchedule.displayString)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .italic()
        }
    }

    // MARK: - Helpers

    private struct DayOption {
        let label: String
        let value: Int
    }

    private var dayOptions: [DayOption] {
        [
            DayOption(label: "Sun", value: 1),
            DayOption(label: "Mon", value: 2),
            DayOption(label: "Tue", value: 3),
            DayOption(label: "Wed", value: 4),
            DayOption(label: "Thu", value: 5),
            DayOption(label: "Fri", value: 6),
            DayOption(label: "Sat", value: 7)
        ]
    }

    private func hourLabel(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        var components = DateComponents()
        components.hour = hour
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour)"
    }

    private var currentSchedule: Schedule {
        Schedule(
            frequency: scheduleFrequency,
            minute: scheduleMinute,
            hour: scheduleFrequency == .hourly ? nil : scheduleHour,
            daysOfWeek: scheduleFrequency == .custom ? scheduleDays : []
        )
    }

    // MARK: - Actions

    private func savePrompt() {
        let schedule: Schedule? = (triggerType == .scheduled || triggerType == .both)
            ? currentSchedule
            : nil

        let config = PromptConfig(
            id: existingConfig?.id ?? UUID().uuidString,
            name: name.trimmingCharacters(in: .whitespaces),
            prompt: promptText,
            emailTimeRange: emailTimeRange,
            triggerType: triggerType,
            schedule: schedule,
            onlyShowIfActionable: onlyShowIfActionable,
            isEnabled: existingConfig?.isEnabled ?? true
        )

        onSave(config)
        dismiss()
    }
}

// MARK: - Day Toggle Button

struct DayToggleButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .frame(width: 36, height: 26)
                .background(
                    isSelected
                        ? Color.accentColor
                        : Color.secondary.opacity(0.15)
                )
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PromptEditorView(onSave: { _ in })
        .environmentObject(AppState())
}
