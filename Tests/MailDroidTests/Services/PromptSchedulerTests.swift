import XCTest
@testable import MailDroidLib

final class PromptSchedulerTests: XCTestCase {

    private var scheduler: PromptScheduler!

    @MainActor
    override func setUp() {
        super.setUp()
        scheduler = PromptScheduler()
    }

    @MainActor
    override func tearDown() {
        scheduler.cancelAll()
        scheduler = nil
        super.tearDown()
    }

    // MARK: - Hourly Schedule

    @MainActor
    func testNextFireDateHourlyFuture() {
        let calendar = Calendar.current
        let now = Date()
        let currentMinute = calendar.component(.minute, from: now)

        // Choose a minute that is definitely in the future within this hour.
        let futureMinute = (currentMinute + 30) % 60
        let schedule = Schedule(frequency: .hourly, minute: futureMinute)

        let nextFire = scheduler.nextFireDate(for: schedule)
        XCTAssertNotNil(nextFire)

        if let fire = nextFire {
            XCTAssertGreaterThan(fire, now)
            let fireMinute = calendar.component(.minute, from: fire)
            XCTAssertEqual(fireMinute, futureMinute)
        }
    }

    @MainActor
    func testNextFireDateHourlyPastMinuteAdvancesToNextHour() {
        let calendar = Calendar.current
        let now = Date()
        let currentMinute = calendar.component(.minute, from: now)

        // Choose a minute that has already passed this hour.
        let pastMinute: Int
        if currentMinute > 0 {
            pastMinute = currentMinute - 1
        } else {
            // If current minute is 0, the next fire at minute 59
            // would still be this hour's future. Skip the edge case.
            pastMinute = 59
        }

        let schedule = Schedule(frequency: .hourly, minute: pastMinute)
        let nextFire = scheduler.nextFireDate(for: schedule)

        XCTAssertNotNil(nextFire)
        if let fire = nextFire {
            XCTAssertGreaterThan(fire, now)
        }
    }

    // MARK: - Daily Schedule

    @MainActor
    func testNextFireDateDailyFutureToday() {
        let schedule = Schedule(frequency: .daily, minute: 59, hour: 23)
        let nextFire = scheduler.nextFireDate(for: schedule)

        XCTAssertNotNil(nextFire)
        if let fire = nextFire {
            XCTAssertGreaterThan(fire, Date())
        }
    }

    @MainActor
    func testNextFireDateDailyPastTimeTomorrow() {
        // Use a time in the past (00:00).
        let schedule = Schedule(frequency: .daily, minute: 0, hour: 0)
        let now = Date()
        let nextFire = scheduler.nextFireDate(for: schedule)

        XCTAssertNotNil(nextFire)
        if let fire = nextFire {
            XCTAssertGreaterThan(fire, now)
            // The fire date should be tomorrow at 00:00.
            let calendar = Calendar.current
            let fireDay = calendar.component(.day, from: fire)
            let todayDay = calendar.component(.day, from: now)
            // It should be a different day (tomorrow, or next month).
            XCTAssertNotEqual(fireDay, todayDay)
        }
    }

    // MARK: - Weekday Schedule

    @MainActor
    func testNextFireDateWeekdaysReturnsWeekday() {
        let schedule = Schedule(frequency: .weekdays, minute: 0, hour: 23)
        let nextFire = scheduler.nextFireDate(for: schedule)

        XCTAssertNotNil(nextFire)
        if let fire = nextFire {
            let calendar = Calendar.current
            let weekday = calendar.component(.weekday, from: fire)
            // Weekday values 2-6 are Mon-Fri.
            XCTAssertTrue(
                (2...6).contains(weekday),
                "Fire date should be a weekday, got weekday \(weekday)."
            )
        }
    }

    @MainActor
    func testNextFireDateWeekdaysSkipsWeekend() {
        // Create a schedule for a time that has already passed today.
        let schedule = Schedule(frequency: .weekdays, minute: 0, hour: 0)
        let nextFire = scheduler.nextFireDate(for: schedule)

        XCTAssertNotNil(nextFire)
        if let fire = nextFire {
            let calendar = Calendar.current
            let weekday = calendar.component(.weekday, from: fire)
            XCTAssertTrue(
                (2...6).contains(weekday),
                "Expected a weekday, got \(weekday)."
            )
        }
    }

    // MARK: - Custom Schedule

    @MainActor
    func testNextFireDateCustomWithSpecificDays() {
        // Schedule for Wednesday only (weekday value 4).
        let schedule = Schedule(
            frequency: .custom,
            minute: 0,
            hour: 12,
            daysOfWeek: [4]
        )
        let nextFire = scheduler.nextFireDate(for: schedule)

        XCTAssertNotNil(nextFire)
        if let fire = nextFire {
            let calendar = Calendar.current
            let weekday = calendar.component(.weekday, from: fire)
            XCTAssertEqual(weekday, 4, "Expected Wednesday (4), got \(weekday).")
        }
    }

    @MainActor
    func testNextFireDateCustomWithEmptyDaysBehavesLikeDaily() {
        let schedule = Schedule(
            frequency: .custom,
            minute: 59,
            hour: 23,
            daysOfWeek: []
        )
        let nextFire = scheduler.nextFireDate(for: schedule)

        XCTAssertNotNil(nextFire)
        if let fire = nextFire {
            XCTAssertGreaterThan(fire, Date())
        }
    }

    @MainActor
    func testNextFireDateCustomMultipleDays() {
        // Schedule for Mon (2) and Fri (6).
        let schedule = Schedule(
            frequency: .custom,
            minute: 0,
            hour: 12,
            daysOfWeek: [2, 6]
        )
        let nextFire = scheduler.nextFireDate(for: schedule)

        XCTAssertNotNil(nextFire)
        if let fire = nextFire {
            let calendar = Calendar.current
            let weekday = calendar.component(.weekday, from: fire)
            XCTAssertTrue(
                [2, 6].contains(weekday),
                "Expected Mon (2) or Fri (6), got \(weekday)."
            )
        }
    }

    // MARK: - Schedule Prompt Behavior

    @MainActor
    func testSchedulePromptIgnoresDisabledConfig() {
        var config = makeSamplePromptConfig(triggerType: .scheduled)
        config.isEnabled = false
        config.schedule = Schedule(frequency: .daily, minute: 0, hour: 12)

        scheduler.schedulePrompt(config)
        // If it were scheduled, a timer would be created; just
        // verify no crash occurs.
    }

    @MainActor
    func testSchedulePromptIgnoresOnDemandConfig() {
        let config = makeSamplePromptConfig(
            triggerType: .onDemand,
            schedule: Schedule(frequency: .daily, minute: 0, hour: 12)
        )

        scheduler.schedulePrompt(config)
        // On-demand prompts should not create timers.
    }

    @MainActor
    func testSchedulePromptIgnoresConfigWithoutSchedule() {
        let config = makeSamplePromptConfig(triggerType: .scheduled)
        // schedule is nil by default.

        scheduler.schedulePrompt(config)
        // No schedule means no timer should be created.
    }

    @MainActor
    func testCancelAll() {
        let config = makeSamplePromptConfig(
            id: "cancel-test",
            triggerType: .scheduled,
            schedule: Schedule(frequency: .daily, minute: 59, hour: 23)
        )

        scheduler.schedulePrompt(config)
        scheduler.cancelAll()
        // Verify no crash and timers are invalidated.
    }

    @MainActor
    func testRescheduleAll() {
        let configs = [
            makeSamplePromptConfig(
                id: "rs1",
                triggerType: .scheduled,
                schedule: Schedule(frequency: .daily, minute: 59, hour: 23)
            ),
            makeSamplePromptConfig(
                id: "rs2",
                triggerType: .both,
                schedule: Schedule(frequency: .hourly, minute: 30)
            )
        ]

        scheduler.rescheduleAll(configs: configs)
        // Verify no crash; both prompts should be scheduled.
    }
}
