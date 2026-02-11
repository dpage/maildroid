import XCTest
@testable import MailDroidLib

final class PromptConfigTests: XCTestCase {

    override func tearDown() {
        TestDefaults.cleanUp()
        super.tearDown()
    }

    // MARK: - Initialization

    func testDefaultInit() {
        let config = PromptConfig()
        XCTAssertFalse(config.id.isEmpty)
        XCTAssertEqual(config.name, "")
        XCTAssertEqual(config.prompt, "")
        XCTAssertEqual(config.emailTimeRange, .last24Hours)
        XCTAssertEqual(config.triggerType, .onDemand)
        XCTAssertNil(config.schedule)
        XCTAssertFalse(config.onlyShowIfActionable)
        XCTAssertTrue(config.isEnabled)
    }

    func testInitWithParameters() {
        let schedule = Schedule(frequency: .daily, minute: 30, hour: 9)
        let config = PromptConfig(
            id: "custom-id",
            name: "Morning Digest",
            prompt: "Summarize my emails",
            emailTimeRange: .last3Days,
            triggerType: .scheduled,
            schedule: schedule,
            onlyShowIfActionable: true,
            isEnabled: false
        )

        XCTAssertEqual(config.id, "custom-id")
        XCTAssertEqual(config.name, "Morning Digest")
        XCTAssertEqual(config.prompt, "Summarize my emails")
        XCTAssertEqual(config.emailTimeRange, .last3Days)
        XCTAssertEqual(config.triggerType, .scheduled)
        XCTAssertNotNil(config.schedule)
        XCTAssertTrue(config.onlyShowIfActionable)
        XCTAssertFalse(config.isEnabled)
    }

    // MARK: - Persistence

    func testSaveAllAndLoadAll() {
        let configs = [
            makeSamplePromptConfig(id: "p1", name: "Prompt 1"),
            makeSamplePromptConfig(id: "p2", name: "Prompt 2")
        ]

        PromptConfig.saveAll(configs)

        let loaded = PromptConfig.loadAll()
        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded[0].id, "p1")
        XCTAssertEqual(loaded[1].id, "p2")
    }

    func testLoadAllReturnsEmptyWhenNoData() {
        UserDefaults.standard.removeObject(forKey: "maildroid.promptConfigs")
        let loaded = PromptConfig.loadAll()
        XCTAssertTrue(loaded.isEmpty)
    }

    func testDelete() {
        let configs = [
            makeSamplePromptConfig(id: "keep", name: "Keep"),
            makeSamplePromptConfig(id: "remove", name: "Remove")
        ]
        PromptConfig.saveAll(configs)

        let toDelete = configs[1]
        PromptConfig.delete(toDelete)

        let remaining = PromptConfig.loadAll()
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining[0].id, "keep")
    }

    // MARK: - Codable Round Trip

    func testCodableRoundTrip() throws {
        let schedule = Schedule(
            frequency: .custom,
            minute: 15,
            hour: 10,
            daysOfWeek: [2, 4, 6]
        )
        let config = PromptConfig(
            id: "rt-test",
            name: "Round Trip",
            prompt: "Test prompt",
            emailTimeRange: .last7Days,
            triggerType: .both,
            schedule: schedule,
            onlyShowIfActionable: true,
            isEnabled: true
        )

        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(PromptConfig.self, from: data)

        XCTAssertEqual(decoded.id, config.id)
        XCTAssertEqual(decoded.name, config.name)
        XCTAssertEqual(decoded.prompt, config.prompt)
        XCTAssertEqual(decoded.emailTimeRange, config.emailTimeRange)
        XCTAssertEqual(decoded.triggerType, config.triggerType)
        XCTAssertEqual(decoded.schedule, config.schedule)
        XCTAssertEqual(decoded.onlyShowIfActionable, config.onlyShowIfActionable)
        XCTAssertEqual(decoded.isEnabled, config.isEnabled)
    }

    // MARK: - Legacy Decoding

    func testDecodesLegacyScheduleTimesFormat() throws {
        // Simulate the legacy JSON format that stored scheduleTimes.
        let legacyJSON = """
        {
            "id": "legacy-id",
            "name": "Legacy Prompt",
            "prompt": "Do something",
            "emailTimeRange": "Last 24 hours",
            "triggerType": "Scheduled",
            "scheduleTimes": [{"hour": 8, "minute": 45}],
            "onlyShowIfActionable": false,
            "isEnabled": true
        }
        """
        let data = legacyJSON.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(PromptConfig.self, from: data)

        XCTAssertEqual(decoded.id, "legacy-id")
        XCTAssertNotNil(decoded.schedule)
        XCTAssertEqual(decoded.schedule?.frequency, .daily)
        XCTAssertEqual(decoded.schedule?.hour, 8)
        XCTAssertEqual(decoded.schedule?.minute, 45)
    }

    func testDecodesWithoutScheduleOrLegacy() throws {
        let json = """
        {
            "id": "no-schedule",
            "name": "No Schedule",
            "prompt": "Test",
            "emailTimeRange": "Last 24 hours",
            "triggerType": "On Demand",
            "onlyShowIfActionable": false,
            "isEnabled": true
        }
        """
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(PromptConfig.self, from: data)

        XCTAssertEqual(decoded.id, "no-schedule")
        XCTAssertNil(decoded.schedule)
    }
}

// MARK: - EmailTimeRange Tests

final class EmailTimeRangeTests: XCTestCase {

    func testAllCases() {
        let allCases = EmailTimeRange.allCases
        XCTAssertEqual(allCases.count, 3)
    }

    func testTimeIntervals() {
        XCTAssertEqual(EmailTimeRange.last24Hours.timeInterval, 86_400)
        XCTAssertEqual(EmailTimeRange.last3Days.timeInterval, 259_200)
        XCTAssertEqual(EmailTimeRange.last7Days.timeInterval, 604_800)
    }

    func testRawValues() {
        XCTAssertEqual(EmailTimeRange.last24Hours.rawValue, "Last 24 hours")
        XCTAssertEqual(EmailTimeRange.last3Days.rawValue, "Last 3 days")
        XCTAssertEqual(EmailTimeRange.last7Days.rawValue, "Last 7 days")
    }
}

// MARK: - TriggerType Tests

final class TriggerTypeTests: XCTestCase {

    func testAllCases() {
        let allCases = TriggerType.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.onDemand))
        XCTAssertTrue(allCases.contains(.scheduled))
        XCTAssertTrue(allCases.contains(.both))
    }

    func testRawValues() {
        XCTAssertEqual(TriggerType.onDemand.rawValue, "On Demand")
        XCTAssertEqual(TriggerType.scheduled.rawValue, "Scheduled")
        XCTAssertEqual(TriggerType.both.rawValue, "Both")
    }
}

// MARK: - Schedule Tests

final class ScheduleTests: XCTestCase {

    func testDefaultInit() {
        let schedule = Schedule()
        XCTAssertEqual(schedule.frequency, .daily)
        XCTAssertEqual(schedule.minute, 0)
        XCTAssertEqual(schedule.hour, 9)
        XCTAssertTrue(schedule.daysOfWeek.isEmpty)
    }

    func testDisplayStringHourly() {
        let schedule = Schedule(frequency: .hourly, minute: 15)
        XCTAssertEqual(schedule.displayString, "Hourly at :15")
    }

    func testDisplayStringHourlyZeroPadded() {
        let schedule = Schedule(frequency: .hourly, minute: 5)
        XCTAssertEqual(schedule.displayString, "Hourly at :05")
    }

    func testDisplayStringDaily() {
        let schedule = Schedule(frequency: .daily, minute: 0, hour: 9)
        XCTAssertTrue(schedule.displayString.hasPrefix("Daily at"))
    }

    func testDisplayStringWeekdays() {
        let schedule = Schedule(frequency: .weekdays, minute: 30, hour: 8)
        XCTAssertTrue(schedule.displayString.hasPrefix("Weekdays at"))
    }

    func testDisplayStringCustomWithDays() {
        let schedule = Schedule(
            frequency: .custom,
            minute: 0,
            hour: 10,
            daysOfWeek: [2, 4, 6]  // Mon, Wed, Fri
        )
        let display = schedule.displayString
        XCTAssertTrue(display.contains("Mon"))
        XCTAssertTrue(display.contains("Wed"))
        XCTAssertTrue(display.contains("Fri"))
    }

    func testDisplayStringCustomWithEmptyDaysFallsBackToDaily() {
        let schedule = Schedule(
            frequency: .custom,
            minute: 0,
            hour: 10,
            daysOfWeek: []
        )
        XCTAssertTrue(schedule.displayString.hasPrefix("Daily at"))
    }

    func testEquatable() {
        let a = Schedule(frequency: .daily, minute: 30, hour: 9)
        let b = Schedule(frequency: .daily, minute: 30, hour: 9)
        XCTAssertEqual(a, b)

        let c = Schedule(frequency: .hourly, minute: 30, hour: 9)
        XCTAssertNotEqual(a, c)
    }

    func testCodableRoundTrip() throws {
        let original = Schedule(
            frequency: .custom,
            minute: 45,
            hour: 14,
            daysOfWeek: [1, 3, 5, 7]
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Schedule.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func testScheduleFrequencyAllCases() {
        let all = ScheduleFrequency.allCases
        XCTAssertEqual(all.count, 4)
        XCTAssertTrue(all.contains(.hourly))
        XCTAssertTrue(all.contains(.daily))
        XCTAssertTrue(all.contains(.weekdays))
        XCTAssertTrue(all.contains(.custom))
    }
}
