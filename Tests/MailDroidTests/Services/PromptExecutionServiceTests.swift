import XCTest
@testable import MailDroidLib

final class PromptExecutionServiceTests: XCTestCase {

    // Use a dummy AppState for creating GmailService.
    // The actual GmailService is not called in these tests because
    // we test the helper methods directly.
    private var service: PromptExecutionService!

    @MainActor
    override func setUp() {
        super.setUp()
        let appState = AppState()
        let gmailService = GmailService(appState: appState)
        service = PromptExecutionService(gmailService: gmailService)
    }

    override func tearDown() {
        service = nil
        TestDefaults.cleanUp()
        super.tearDown()
    }

    // MARK: - parseActionability

    func testParseActionabilityYes() {
        let response = "You have urgent emails.\nACTIONABLE: YES"
        let (cleaned, actionable) = service.parseActionability(response)

        XCTAssertTrue(actionable)
        XCTAssertEqual(cleaned, "You have urgent emails.")
    }

    func testParseActionabilityNo() {
        let response = "Nothing urgent.\nACTIONABLE: NO"
        let (cleaned, actionable) = service.parseActionability(response)

        XCTAssertFalse(actionable)
        XCTAssertEqual(cleaned, "Nothing urgent.")
    }

    func testParseActionabilityNoSpace() {
        let response = "Result\nACTIONABLE:YES"
        let (_, actionable) = service.parseActionability(response)
        XCTAssertTrue(actionable)
    }

    func testParseActionabilityNoSpaceNO() {
        let response = "Result\nACTIONABLE:NO"
        let (_, actionable) = service.parseActionability(response)
        XCTAssertFalse(actionable)
    }

    func testParseActionabilityCaseInsensitive() {
        let response = "Result\nactionable: yes"
        let (_, actionable) = service.parseActionability(response)
        XCTAssertTrue(actionable)
    }

    func testParseActionabilityCaseInsensitiveNo() {
        let response = "Result\nActionable: No"
        let (_, actionable) = service.parseActionability(response)
        XCTAssertFalse(actionable)
    }

    func testParseActionabilityDefaultsToTrueWhenNoMarker() {
        let response = "Some LLM response without any marker."
        let (cleaned, actionable) = service.parseActionability(response)

        XCTAssertTrue(actionable, "Should default to true when no marker is found.")
        XCTAssertEqual(cleaned, "Some LLM response without any marker.")
    }

    func testParseActionabilityStripsMarkerLine() {
        let response = "Line 1\nLine 2\nACTIONABLE: YES"
        let (cleaned, _) = service.parseActionability(response)

        XCTAssertFalse(cleaned.contains("ACTIONABLE"))
        XCTAssertEqual(cleaned, "Line 1\nLine 2")
    }

    func testParseActionabilityStripsTrailingBlankLines() {
        let response = "Content\n\n\nACTIONABLE: NO\n\n"
        let (cleaned, _) = service.parseActionability(response)

        XCTAssertFalse(cleaned.hasSuffix("\n"))
        XCTAssertEqual(cleaned, "Content")
    }

    func testParseActionabilityWithLeadingWhitespace() {
        let response = "Result\n  ACTIONABLE: YES  "
        let (_, actionable) = service.parseActionability(response)
        XCTAssertTrue(actionable)
    }

    func testParseActionabilityLastMarkerWins() {
        // If the response has both markers, the last one should win.
        let response = "Part 1\nACTIONABLE: YES\nPart 2\nACTIONABLE: NO"
        let (_, actionable) = service.parseActionability(response)
        XCTAssertFalse(actionable, "The last marker should take precedence.")
    }

    // MARK: - truncateBody

    func testTruncateBodyShortString() {
        let result = service.truncateBody("Hello", maxLength: 500)
        XCTAssertEqual(result, "Hello")
    }

    func testTruncateBodyExactLength() {
        let body = String(repeating: "a", count: 500)
        let result = service.truncateBody(body, maxLength: 500)
        XCTAssertEqual(result.count, 500)
        XCTAssertFalse(result.hasSuffix("..."))
    }

    func testTruncateBodyLongString() {
        let body = String(repeating: "a", count: 600)
        let result = service.truncateBody(body, maxLength: 500)
        XCTAssertEqual(result.count, 503)  // 500 + "..."
        XCTAssertTrue(result.hasSuffix("..."))
    }

    func testTruncateBodyTrimsWhitespace() {
        let body = "  Hello World  \n\n"
        let result = service.truncateBody(body, maxLength: 500)
        XCTAssertEqual(result, "Hello World")
    }

    // MARK: - formatEmails

    func testFormatEmailsEmpty() {
        let result = service.formatEmails([])
        XCTAssertEqual(result, "[No emails found in the selected time range.]")
    }

    func testFormatEmailsSingleEmail() {
        let email = makeSampleEmail(
            subject: "Test Email",
            from: "sender@test.com",
            body: "Email body"
        )
        let result = service.formatEmails([email])

        XCTAssertTrue(result.contains("Email 1"))
        XCTAssertTrue(result.contains("Subject: Test Email"))
        XCTAssertTrue(result.contains("From: sender@test.com"))
        XCTAssertTrue(result.contains("Body: Email body"))
    }

    func testFormatEmailsMultipleEmails() {
        let emails = [
            makeSampleEmail(id: "1", subject: "First"),
            makeSampleEmail(id: "2", subject: "Second")
        ]
        let result = service.formatEmails(emails)

        XCTAssertTrue(result.contains("Email 1"))
        XCTAssertTrue(result.contains("Email 2"))
        XCTAssertTrue(result.contains("Subject: First"))
        XCTAssertTrue(result.contains("Subject: Second"))
    }

    // MARK: - buildUserContent

    func testBuildUserContent() {
        let result = service.buildUserContent(
            promptText: "Find urgent emails",
            formattedEmails: "[formatted emails here]",
            emailCount: 5
        )

        XCTAssertTrue(result.contains("5 email(s) to analyze"))
        XCTAssertTrue(result.contains("[formatted emails here]"))
        XCTAssertTrue(result.contains("User request: Find urgent emails"))
    }

    // MARK: - PromptExecutionError

    func testPromptExecutionErrorDescriptions() {
        XCTAssertNotNil(PromptExecutionError.noEnabledAccounts.errorDescription)
        XCTAssertNotNil(PromptExecutionError.noEmails.errorDescription)
        XCTAssertNotNil(PromptExecutionError.llmConfigMissing.errorDescription)
    }
}
