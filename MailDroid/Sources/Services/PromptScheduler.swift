import Foundation

/// Manages timers for scheduled prompt configurations.
///
/// Each enabled prompt with a schedule gets a timer that fires at
/// the next occurrence. After firing, the timer reschedules for the
/// following occurrence.
@MainActor
final class PromptScheduler {

    /// Called when a scheduled prompt timer fires.
    var onPromptDue: ((PromptConfig) -> Void)?

    private var timers: [String: Timer] = [:]

    // MARK: - Public API

    /// Schedules a timer for the given prompt configuration.
    ///
    /// The method cancels any existing timer for the same prompt
    /// before creating a new one. Prompts without a schedule or
    /// with an on-demand-only trigger type are ignored.
    func schedulePrompt(_ config: PromptConfig) {
        cancelSchedule(for: config.id)

        guard config.isEnabled,
              config.triggerType == .scheduled || config.triggerType == .both,
              let schedule = config.schedule else {
            return
        }

        guard let nextFire = nextFireDate(for: schedule) else {
            return
        }

        let interval = nextFire.timeIntervalSinceNow
        guard interval > 0 else { return }

        let timer = Timer.scheduledTimer(
            withTimeInterval: interval,
            repeats: false
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleTimerFired(config: config)
            }
        }

        // Allow the timer to fire even when the run loop is tracking UI.
        RunLoop.main.add(timer, forMode: .common)
        timers[config.id] = timer
    }

    /// Cancels the scheduled timer for the given prompt identifier.
    func cancelSchedule(for promptId: String) {
        timers[promptId]?.invalidate()
        timers.removeValue(forKey: promptId)
    }

    /// Cancels all existing timers and reschedules from the provided
    /// configurations.
    func rescheduleAll(configs: [PromptConfig]) {
        cancelAll()

        for config in configs {
            schedulePrompt(config)
        }
    }

    /// Cancels every active timer.
    func cancelAll() {
        for timer in timers.values {
            timer.invalidate()
        }
        timers.removeAll()
    }

    // MARK: - Timer Handling

    /// Invokes the callback and reschedules the timer for the next
    /// occurrence.
    private func handleTimerFired(config: PromptConfig) {
        onPromptDue?(config)
        schedulePrompt(config)
    }

    // MARK: - Next Fire Date Calculation

    /// Computes the next fire date for the given schedule.
    ///
    /// The calculation depends on the schedule frequency:
    /// - Hourly: the next occurrence of :MM past the hour.
    /// - Daily: the next occurrence of HH:MM today or tomorrow.
    /// - Weekdays: the next occurrence of HH:MM on Monday-Friday.
    /// - Custom: the next occurrence of HH:MM on the specified days.
    func nextFireDate(for schedule: Schedule) -> Date? {
        let calendar = Calendar.current
        let now = Date()

        switch schedule.frequency {
        case .hourly:
            return nextHourlyFire(
                minute: schedule.minute,
                now: now,
                calendar: calendar
            )

        case .daily:
            return nextDailyFire(
                hour: schedule.hour ?? 0,
                minute: schedule.minute,
                now: now,
                calendar: calendar
            )

        case .weekdays:
            // Monday through Friday: weekday values 2-6 in Calendar.
            let weekdaySet: Set<Int> = [2, 3, 4, 5, 6]
            return nextWeeklyFire(
                hour: schedule.hour ?? 0,
                minute: schedule.minute,
                allowedWeekdays: weekdaySet,
                now: now,
                calendar: calendar
            )

        case .custom:
            if schedule.daysOfWeek.isEmpty {
                // No days selected behaves like daily.
                return nextDailyFire(
                    hour: schedule.hour ?? 0,
                    minute: schedule.minute,
                    now: now,
                    calendar: calendar
                )
            }
            return nextWeeklyFire(
                hour: schedule.hour ?? 0,
                minute: schedule.minute,
                allowedWeekdays: schedule.daysOfWeek,
                now: now,
                calendar: calendar
            )
        }
    }

    // MARK: - Fire Date Helpers

    /// Returns the next occurrence of the given minute past the hour.
    private func nextHourlyFire(
        minute: Int,
        now: Date,
        calendar: Calendar
    ) -> Date? {
        var components = calendar.dateComponents(
            [.year, .month, .day, .hour],
            from: now
        )
        components.minute = minute
        components.second = 0

        guard let candidate = calendar.date(from: components) else {
            return nil
        }

        if candidate > now {
            return candidate
        }

        return calendar.date(byAdding: .hour, value: 1, to: candidate)
    }

    /// Returns the next occurrence of HH:MM today or tomorrow.
    private func nextDailyFire(
        hour: Int,
        minute: Int,
        now: Date,
        calendar: Calendar
    ) -> Date? {
        var components = calendar.dateComponents(
            [.year, .month, .day],
            from: now
        )
        components.hour = hour
        components.minute = minute
        components.second = 0

        guard let candidate = calendar.date(from: components) else {
            return nil
        }

        if candidate > now {
            return candidate
        }

        return calendar.date(byAdding: .day, value: 1, to: candidate)
    }

    /// Returns the next occurrence of HH:MM on an allowed weekday.
    ///
    /// The allowedWeekdays set uses Calendar weekday values where
    /// 1 is Sunday and 7 is Saturday.
    private func nextWeeklyFire(
        hour: Int,
        minute: Int,
        allowedWeekdays: Set<Int>,
        now: Date,
        calendar: Calendar
    ) -> Date? {
        // Check today and the next six days to find the earliest match.
        for dayOffset in 0..<7 {
            guard let candidateDay = calendar.date(
                byAdding: .day, value: dayOffset, to: now
            ) else {
                continue
            }

            let weekday = calendar.component(.weekday, from: candidateDay)
            guard allowedWeekdays.contains(weekday) else {
                continue
            }

            var components = calendar.dateComponents(
                [.year, .month, .day],
                from: candidateDay
            )
            components.hour = hour
            components.minute = minute
            components.second = 0

            guard let candidate = calendar.date(from: components) else {
                continue
            }

            if candidate > now {
                return candidate
            }
        }

        // All allowed days this week have passed; wrap to next week.
        guard let nextWeekStart = calendar.date(
            byAdding: .day, value: 7, to: now
        ) else {
            return nil
        }

        for dayOffset in 0..<7 {
            guard let candidateDay = calendar.date(
                byAdding: .day, value: dayOffset, to: nextWeekStart
            ) else {
                continue
            }

            let weekday = calendar.component(.weekday, from: candidateDay)
            guard allowedWeekdays.contains(weekday) else {
                continue
            }

            var components = calendar.dateComponents(
                [.year, .month, .day],
                from: candidateDay
            )
            components.hour = hour
            components.minute = minute
            components.second = 0

            return calendar.date(from: components)
        }

        return nil
    }
}
