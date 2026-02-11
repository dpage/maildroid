import XCTest
@testable import MailDroidLib

final class EmailTests: XCTestCase {

    func testInitWithAllParameters() {
        let date = Date()
        let email = Email(
            id: "msg123",
            threadId: "thread456",
            accountId: "acct789",
            subject: "Meeting Tomorrow",
            from: "alice@example.com",
            to: "bob@example.com",
            date: date,
            snippet: "Let us discuss...",
            body: "Full body of the email.",
            labels: ["INBOX", "UNREAD"],
            isUnread: true
        )

        XCTAssertEqual(email.id, "msg123")
        XCTAssertEqual(email.threadId, "thread456")
        XCTAssertEqual(email.accountId, "acct789")
        XCTAssertEqual(email.subject, "Meeting Tomorrow")
        XCTAssertEqual(email.from, "alice@example.com")
        XCTAssertEqual(email.to, "bob@example.com")
        XCTAssertEqual(email.date, date)
        XCTAssertEqual(email.snippet, "Let us discuss...")
        XCTAssertEqual(email.body, "Full body of the email.")
        XCTAssertEqual(email.labels, ["INBOX", "UNREAD"])
        XCTAssertTrue(email.isUnread)
    }

    func testInitWithDefaults() {
        let email = Email(id: "1", threadId: "t1", accountId: "a1")

        XCTAssertEqual(email.id, "1")
        XCTAssertEqual(email.subject, "")
        XCTAssertEqual(email.from, "")
        XCTAssertEqual(email.to, "")
        XCTAssertEqual(email.snippet, "")
        XCTAssertEqual(email.body, "")
        XCTAssertEqual(email.labels, [])
        XCTAssertTrue(email.isUnread)
    }

    func testIdentifiable() {
        let email = Email(id: "unique-id", threadId: "t1", accountId: "a1")
        XCTAssertEqual(email.id, "unique-id")
    }

    func testCodable() throws {
        let original = makeSampleEmail()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Email.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.threadId, original.threadId)
        XCTAssertEqual(decoded.subject, original.subject)
        XCTAssertEqual(decoded.from, original.from)
        XCTAssertEqual(decoded.body, original.body)
        XCTAssertEqual(decoded.isUnread, original.isUnread)
    }
}
