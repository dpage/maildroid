import Foundation
@testable import MailDroidLib

/// A custom UserDefaults suite used by tests to avoid polluting the
/// real app data. Each test class should call `cleanUp()` in its
/// tearDown method.
enum TestDefaults {
    /// The suite name for all test UserDefaults.
    static let suiteName = "page.conx.maildroid.tests"

    /// Returns a fresh UserDefaults suite for testing.
    static var suite: UserDefaults {
        return UserDefaults(suiteName: suiteName)!
    }

    /// Removes all keys from the test suite and also cleans keys
    /// written to UserDefaults.standard by the production code.
    static func cleanUp() {
        let standard = UserDefaults.standard
        let allKeys = standard.dictionaryRepresentation().keys
        for key in allKeys where key.hasPrefix("maildroid") {
            standard.removeObject(forKey: key)
        }
        standard.synchronize()

        UserDefaults().removePersistentDomain(forName: suiteName)
    }
}

/// Creates a sample Email for use in tests.
func makeSampleEmail(
    id: String = "msg1",
    threadId: String = "thread1",
    accountId: String = "account1",
    subject: String = "Test Subject",
    from: String = "sender@example.com",
    to: String = "recipient@example.com",
    date: Date = Date(),
    snippet: String = "A test snippet",
    body: String = "The full email body content.",
    labels: [String] = ["INBOX"],
    isUnread: Bool = true
) -> Email {
    return Email(
        id: id,
        threadId: threadId,
        accountId: accountId,
        subject: subject,
        from: from,
        to: to,
        date: date,
        snippet: snippet,
        body: body,
        labels: labels,
        isUnread: isUnread
    )
}

/// Creates a sample GmailAccount for use in tests.
func makeSampleAccount(
    id: String = "test-account-id",
    email: String = "test@example.com",
    displayName: String = "Test User",
    isEnabled: Bool = true
) -> GmailAccount {
    var account = GmailAccount(id: id, email: email, displayName: displayName)
    account.isEnabled = isEnabled
    return account
}

/// Creates a sample PromptConfig for use in tests.
func makeSamplePromptConfig(
    id: String = "test-prompt-id",
    name: String = "Test Prompt",
    prompt: String = "Summarize my emails",
    emailTimeRange: EmailTimeRange = .last24Hours,
    triggerType: TriggerType = .onDemand,
    schedule: Schedule? = nil,
    onlyShowIfActionable: Bool = false,
    isEnabled: Bool = true
) -> PromptConfig {
    return PromptConfig(
        id: id,
        name: name,
        prompt: prompt,
        emailTimeRange: emailTimeRange,
        triggerType: triggerType,
        schedule: schedule,
        onlyShowIfActionable: onlyShowIfActionable,
        isEnabled: isEnabled
    )
}
