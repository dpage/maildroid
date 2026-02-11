import XCTest
@testable import MailDroidLib

final class TimeFormattingTests: XCTestCase {

    // MARK: - relativeTime

    func testRelativeTimeNow() {
        let now = Date()
        let past = now.addingTimeInterval(-5)
        let result = TimeFormatting.relativeTime(to: past, from: now)
        XCTAssertEqual(result, "now")
    }

    func testRelativeTimeLessThanOneMinute() {
        let now = Date()
        let future = now.addingTimeInterval(30)
        let result = TimeFormatting.relativeTime(to: future, from: now)
        XCTAssertEqual(result, "in < 1 min")
    }

    func testRelativeTimeExactlyOneMinute() {
        let now = Date()
        let future = now.addingTimeInterval(60)
        let result = TimeFormatting.relativeTime(to: future, from: now)
        XCTAssertEqual(result, "in 1 min")
    }

    func testRelativeTimeMinutes() {
        let now = Date()
        let future = now.addingTimeInterval(25 * 60)
        let result = TimeFormatting.relativeTime(to: future, from: now)
        XCTAssertEqual(result, "in 25 min")
    }

    func testRelativeTimeOneHour() {
        let now = Date()
        let future = now.addingTimeInterval(3600)
        let result = TimeFormatting.relativeTime(to: future, from: now)
        XCTAssertEqual(result, "in 1 hr")
    }

    func testRelativeTimeOneHourAndMinutes() {
        let now = Date()
        let future = now.addingTimeInterval(3600 + 15 * 60)
        let result = TimeFormatting.relativeTime(to: future, from: now)
        XCTAssertEqual(result, "in 1 hr 15 min")
    }

    func testRelativeTimeMultipleHours() {
        let now = Date()
        let future = now.addingTimeInterval(5 * 3600)
        let result = TimeFormatting.relativeTime(to: future, from: now)
        XCTAssertEqual(result, "in 5 hr")
    }

    func testRelativeTimeTomorrow() {
        let now = Date()
        let future = now.addingTimeInterval(25 * 3600)
        let result = TimeFormatting.relativeTime(to: future, from: now)
        XCTAssertEqual(result, "tomorrow")
    }

    func testRelativeTimeMultipleDays() {
        let now = Date()
        let future = now.addingTimeInterval(3 * 86400)
        let result = TimeFormatting.relativeTime(to: future, from: now)
        XCTAssertEqual(result, "in 3 days")
    }

    // MARK: - timeRange

    func testTimeRange() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        let start = formatter.date(from: "2025-01-15 14:00")!
        let end = formatter.date(from: "2025-01-15 15:30")!

        let result = TimeFormatting.timeRange(start: start, end: end)
        XCTAssertTrue(result.contains("-"), "Result should contain a separator dash.")
    }

    // MARK: - dateTime

    func testDateTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        let date = formatter.date(from: "2025-01-15 14:30")!
        let result = TimeFormatting.dateTime(date)

        XCTAssertTrue(result.contains("Jan"))
        XCTAssertTrue(result.contains("15"))
        XCTAssertTrue(result.contains("at"))
    }

    // MARK: - time

    func testTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        let date = formatter.date(from: "2025-01-15 14:30")!
        let result = TimeFormatting.time(date)

        // The result should contain a time component.
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("30"), "Should include the minute component.")
    }

    // MARK: - duration

    func testDurationMinutesOnly() {
        let start = Date()
        let end = start.addingTimeInterval(30 * 60)
        let result = TimeFormatting.duration(from: start, to: end)
        XCTAssertEqual(result, "30 minutes")
    }

    func testDurationOneMinute() {
        let start = Date()
        let end = start.addingTimeInterval(60)
        let result = TimeFormatting.duration(from: start, to: end)
        XCTAssertEqual(result, "1 minute")
    }

    func testDurationWholeHours() {
        let start = Date()
        let end = start.addingTimeInterval(2 * 3600)
        let result = TimeFormatting.duration(from: start, to: end)
        XCTAssertEqual(result, "2 hours")
    }

    func testDurationOneHour() {
        let start = Date()
        let end = start.addingTimeInterval(3600)
        let result = TimeFormatting.duration(from: start, to: end)
        XCTAssertEqual(result, "1 hour")
    }

    func testDurationHoursAndMinutes() {
        let start = Date()
        let end = start.addingTimeInterval(3600 + 45 * 60)
        let result = TimeFormatting.duration(from: start, to: end)
        XCTAssertEqual(result, "1 hr 45 min")
    }
}
