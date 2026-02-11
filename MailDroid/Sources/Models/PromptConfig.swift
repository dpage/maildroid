import Foundation

struct PromptConfig: Identifiable, Codable {
    let id: String
    var name: String
    var prompt: String
    var emailTimeRange: EmailTimeRange
    var triggerType: TriggerType
    var schedule: Schedule?
    var onlyShowIfActionable: Bool
    var isEnabled: Bool

    init(
        id: String = UUID().uuidString,
        name: String = "",
        prompt: String = "",
        emailTimeRange: EmailTimeRange = .last24Hours,
        triggerType: TriggerType = .onDemand,
        schedule: Schedule? = nil,
        onlyShowIfActionable: Bool = false,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.prompt = prompt
        self.emailTimeRange = emailTimeRange
        self.triggerType = triggerType
        self.schedule = schedule
        self.onlyShowIfActionable = onlyShowIfActionable
        self.isEnabled = isEnabled
    }

    // MARK: - Backward Compatibility

    /// Decodes from both the new format and the legacy format that
    /// stored scheduleTimes and scheduleInterval.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        prompt = try container.decode(String.self, forKey: .prompt)
        emailTimeRange = try container.decode(
            EmailTimeRange.self, forKey: .emailTimeRange
        )
        triggerType = try container.decode(
            TriggerType.self, forKey: .triggerType
        )
        onlyShowIfActionable = try container.decode(
            Bool.self, forKey: .onlyShowIfActionable
        )
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)

        // Try the new schedule field first; fall back to legacy
        // scheduleTimes for backward compatibility.
        if let newSchedule = try container.decodeIfPresent(
            Schedule.self, forKey: .schedule
        ) {
            schedule = newSchedule
        } else if let legacyTimes = try container.decodeIfPresent(
            [LegacyScheduleTime].self, forKey: .scheduleTimes
        ), let first = legacyTimes.first {
            schedule = Schedule(
                frequency: .daily,
                minute: first.minute,
                hour: first.hour,
                daysOfWeek: []
            )
        } else {
            schedule = nil
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, prompt, emailTimeRange, triggerType
        case schedule, scheduleTimes
        case onlyShowIfActionable, isEnabled
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(prompt, forKey: .prompt)
        try container.encode(emailTimeRange, forKey: .emailTimeRange)
        try container.encode(triggerType, forKey: .triggerType)
        try container.encodeIfPresent(schedule, forKey: .schedule)
        try container.encode(onlyShowIfActionable, forKey: .onlyShowIfActionable)
        try container.encode(isEnabled, forKey: .isEnabled)
    }

    /// Legacy model used only for decoding old data.
    private struct LegacyScheduleTime: Codable {
        var hour: Int
        var minute: Int
    }

    // MARK: - Persistence

    private static let promptsKey = "maildroid.promptConfigs"

    static func loadAll() -> [PromptConfig] {
        guard let data = UserDefaults.standard.data(forKey: promptsKey),
              let configs = try? JSONDecoder().decode([PromptConfig].self, from: data) else {
            return []
        }
        return configs
    }

    static func saveAll(_ configs: [PromptConfig]) {
        if let data = try? JSONEncoder().encode(configs) {
            UserDefaults.standard.set(data, forKey: promptsKey)
        }
    }

    static func delete(_ config: PromptConfig) {
        var configs = loadAll()
        configs.removeAll { $0.id == config.id }
        saveAll(configs)
    }
}

// MARK: - Supporting Types

enum EmailTimeRange: String, Codable, CaseIterable {
    case last24Hours = "Last 24 hours"
    case last3Days = "Last 3 days"
    case last7Days = "Last 7 days"

    var timeInterval: TimeInterval {
        switch self {
        case .last24Hours:
            return 86_400
        case .last3Days:
            return 259_200
        case .last7Days:
            return 604_800
        }
    }
}

enum TriggerType: String, Codable, CaseIterable {
    case onDemand = "On Demand"
    case scheduled = "Scheduled"
    case both = "Both"
}

// MARK: - Schedule

enum ScheduleFrequency: String, Codable, CaseIterable {
    case hourly = "Hourly"
    case daily = "Daily"
    case weekdays = "Weekdays"
    case custom = "Custom"
}

struct Schedule: Codable, Equatable {
    var frequency: ScheduleFrequency
    var minute: Int
    var hour: Int?
    var daysOfWeek: Set<Int>

    init(
        frequency: ScheduleFrequency = .daily,
        minute: Int = 0,
        hour: Int? = 9,
        daysOfWeek: Set<Int> = []
    ) {
        self.frequency = frequency
        self.minute = minute
        self.hour = hour
        self.daysOfWeek = daysOfWeek
    }

    /// A human-readable summary of the schedule.
    var displayString: String {
        switch frequency {
        case .hourly:
            return "Hourly at :\(String(format: "%02d", minute))"

        case .daily:
            return "Daily at \(formattedTime)"

        case .weekdays:
            return "Weekdays at \(formattedTime)"

        case .custom:
            let dayNames = sortedDayNames
            if dayNames.isEmpty {
                return "Daily at \(formattedTime)"
            }
            return "\(dayNames.joined(separator: ", ")) at \(formattedTime)"
        }
    }

    // MARK: - Private Helpers

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        var components = DateComponents()
        components.hour = hour ?? 0
        components.minute = minute

        let calendar = Calendar.current
        if let date = calendar.date(from: components) {
            return formatter.string(from: date)
        }
        return String(format: "%d:%02d", hour ?? 0, minute)
    }

    /// Short day names sorted in calendar order (Sun through Sat).
    private var sortedDayNames: [String] {
        let names = [
            1: "Sun", 2: "Mon", 3: "Tue", 4: "Wed",
            5: "Thu", 6: "Fri", 7: "Sat"
        ]
        return daysOfWeek.sorted().compactMap { names[$0] }
    }
}
