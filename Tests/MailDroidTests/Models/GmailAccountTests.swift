import XCTest
@testable import MailDroidLib

final class GmailAccountTests: XCTestCase {

    override func tearDown() {
        TestDefaults.cleanUp()
        super.tearDown()
    }

    // MARK: - Initialization

    func testInitWithEmail() {
        let account = GmailAccount(email: "user@example.com")
        XCTAssertEqual(account.email, "user@example.com")
        XCTAssertEqual(account.displayName, "user@example.com")
        XCTAssertTrue(account.isEnabled)
        XCTAssertNil(account.accessToken)
        XCTAssertNil(account.refreshToken)
        XCTAssertNil(account.tokenExpiry)
    }

    func testInitWithDisplayName() {
        let account = GmailAccount(
            email: "user@example.com",
            displayName: "Test User"
        )
        XCTAssertEqual(account.displayName, "Test User")
    }

    func testInitWithEmptyDisplayNameFallsBackToEmail() {
        let account = GmailAccount(
            email: "user@example.com",
            displayName: ""
        )
        XCTAssertEqual(account.displayName, "user@example.com")
    }

    func testInitGeneratesUniqueId() {
        let a = GmailAccount(email: "a@example.com")
        let b = GmailAccount(email: "b@example.com")
        XCTAssertNotEqual(a.id, b.id)
    }

    // MARK: - Token Expiry

    func testIsTokenExpiredWhenNoExpiry() {
        let account = GmailAccount(email: "user@example.com")
        XCTAssertTrue(account.isTokenExpired)
    }

    func testIsTokenExpiredWhenExpiryInPast() {
        var account = GmailAccount(email: "user@example.com")
        account.tokenExpiry = Date(timeIntervalSinceNow: -120)
        XCTAssertTrue(account.isTokenExpired)
    }

    func testIsTokenNotExpiredWhenExpiryInFuture() {
        var account = GmailAccount(email: "user@example.com")
        account.tokenExpiry = Date(timeIntervalSinceNow: 3600)
        XCTAssertFalse(account.isTokenExpired)
    }

    func testIsTokenExpiredWithinOneMinuteBuffer() {
        var account = GmailAccount(email: "user@example.com")
        // Token expires in 30 seconds; the 60-second buffer should
        // cause isTokenExpired to return true.
        account.tokenExpiry = Date(timeIntervalSinceNow: 30)
        XCTAssertTrue(account.isTokenExpired)
    }

    // MARK: - Needs Reauthentication

    func testNeedsReauthenticationWhenNoRefreshToken() {
        let account = GmailAccount(email: "user@example.com")
        XCTAssertTrue(account.needsReauthentication)
    }

    func testNeedsReauthenticationWhenRefreshTokenEmpty() {
        var account = GmailAccount(email: "user@example.com")
        account.refreshToken = ""
        XCTAssertTrue(account.needsReauthentication)
    }

    func testDoesNotNeedReauthenticationWhenRefreshTokenPresent() {
        var account = GmailAccount(email: "user@example.com")
        account.refreshToken = "some-refresh-token"
        XCTAssertFalse(account.needsReauthentication)
    }

    // MARK: - Persistence

    func testSaveAllAndLoadAll() {
        var account = GmailAccount(
            id: "test-persist",
            email: "persist@example.com",
            displayName: "Persist User"
        )
        account.accessToken = "access-123"
        account.refreshToken = "refresh-456"
        account.tokenExpiry = Date(timeIntervalSince1970: 2_000_000_000)

        GmailAccount.saveAll([account])

        let loaded = GmailAccount.loadAll()
        XCTAssertEqual(loaded.count, 1)

        let loadedAccount = loaded[0]
        XCTAssertEqual(loadedAccount.id, "test-persist")
        XCTAssertEqual(loadedAccount.email, "persist@example.com")
        XCTAssertEqual(loadedAccount.displayName, "Persist User")
        XCTAssertEqual(loadedAccount.accessToken, "access-123")
        XCTAssertEqual(loadedAccount.refreshToken, "refresh-456")
        XCTAssertNotNil(loadedAccount.tokenExpiry)
    }

    func testLoadAllReturnsEmptyWhenNoData() {
        UserDefaults.standard.removeObject(forKey: "maildroid.accounts")
        let loaded = GmailAccount.loadAll()
        XCTAssertTrue(loaded.isEmpty)
    }

    func testSaveAllMultipleAccounts() {
        let accounts = [
            makeSampleAccount(id: "a1", email: "a1@example.com"),
            makeSampleAccount(id: "a2", email: "a2@example.com"),
            makeSampleAccount(id: "a3", email: "a3@example.com")
        ]

        GmailAccount.saveAll(accounts)

        let loaded = GmailAccount.loadAll()
        XCTAssertEqual(loaded.count, 3)
        XCTAssertEqual(loaded.map(\.id).sorted(), ["a1", "a2", "a3"])
    }

    // MARK: - Enabled/Disabled Toggle

    func testToggleEnabled() {
        var account = GmailAccount(email: "user@example.com")
        XCTAssertTrue(account.isEnabled)

        account.isEnabled = false
        XCTAssertFalse(account.isEnabled)

        account.isEnabled = true
        XCTAssertTrue(account.isEnabled)
    }

    func testEnabledStatePersists() {
        var account = makeSampleAccount(id: "toggle-test")
        account.isEnabled = false

        GmailAccount.saveAll([account])

        let loaded = GmailAccount.loadAll()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertFalse(loaded[0].isEnabled)
    }

    // MARK: - Deletion

    func testDelete() {
        let account1 = makeSampleAccount(id: "keep-me", email: "keep@example.com")
        let account2 = makeSampleAccount(id: "delete-me", email: "delete@example.com")

        GmailAccount.saveAll([account1, account2])
        XCTAssertEqual(GmailAccount.loadAll().count, 2)

        GmailAccount.delete(account2)

        let remaining = GmailAccount.loadAll()
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining[0].id, "keep-me")
    }

    func testDeleteCleansUpTokens() {
        var account = makeSampleAccount(id: "token-cleanup")
        account.accessToken = "secret-access"
        account.refreshToken = "secret-refresh"
        account.tokenExpiry = Date()

        GmailAccount.saveAll([account])
        GmailAccount.delete(account)

        // Verify tokens are removed from KeychainHelper (UserDefaults).
        let tokens = KeychainHelper.loadTokens(for: "token-cleanup")
        XCTAssertNil(tokens.accessToken)
        XCTAssertNil(tokens.refreshToken)
        XCTAssertNil(tokens.expiry)
    }

    // MARK: - Scopes

    func testScopesContainRequiredPermissions() {
        let scopes = GmailAccount.scopes
        XCTAssertTrue(scopes.contains("https://www.googleapis.com/auth/gmail.readonly"))
        XCTAssertTrue(scopes.contains("https://www.googleapis.com/auth/gmail.modify"))
        XCTAssertTrue(scopes.contains("https://www.googleapis.com/auth/userinfo.email"))
        XCTAssertTrue(scopes.contains("https://www.googleapis.com/auth/userinfo.profile"))
    }
}
