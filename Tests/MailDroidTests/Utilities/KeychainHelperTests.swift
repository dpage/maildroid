import XCTest
@testable import MailDroidLib

final class KeychainHelperTests: XCTestCase {

    override func tearDown() {
        TestDefaults.cleanUp()
        super.tearDown()
    }

    // MARK: - OAuth Token Operations

    func testSaveAndLoadTokens() {
        let accountId = "test-kc-account"
        let expiry = Date(timeIntervalSince1970: 2_000_000_000)

        KeychainHelper.saveTokens(
            accessToken: "access-token-123",
            refreshToken: "refresh-token-456",
            expiry: expiry,
            for: accountId
        )

        let loaded = KeychainHelper.loadTokens(for: accountId)
        XCTAssertEqual(loaded.accessToken, "access-token-123")
        XCTAssertEqual(loaded.refreshToken, "refresh-token-456")
        XCTAssertNotNil(loaded.expiry)

        // Compare with some tolerance for floating-point conversion.
        if let loadedExpiry = loaded.expiry {
            XCTAssertEqual(
                loadedExpiry.timeIntervalSince1970,
                expiry.timeIntervalSince1970,
                accuracy: 1.0
            )
        }
    }

    func testLoadTokensReturnsNilsWhenEmpty() {
        let loaded = KeychainHelper.loadTokens(for: "nonexistent-account")
        XCTAssertNil(loaded.accessToken)
        XCTAssertNil(loaded.refreshToken)
        XCTAssertNil(loaded.expiry)
    }

    func testDeleteTokens() {
        let accountId = "delete-test-account"

        KeychainHelper.saveTokens(
            accessToken: "to-delete",
            refreshToken: "to-delete",
            expiry: Date(),
            for: accountId
        )

        KeychainHelper.deleteTokens(for: accountId)

        let loaded = KeychainHelper.loadTokens(for: accountId)
        XCTAssertNil(loaded.accessToken)
        XCTAssertNil(loaded.refreshToken)
        XCTAssertNil(loaded.expiry)
    }

    func testSaveTokensWithNilValues() {
        let accountId = "partial-save-account"

        KeychainHelper.saveTokens(
            accessToken: nil,
            refreshToken: nil,
            expiry: nil,
            for: accountId
        )

        let loaded = KeychainHelper.loadTokens(for: accountId)
        XCTAssertNil(loaded.accessToken)
        XCTAssertNil(loaded.refreshToken)
        XCTAssertNil(loaded.expiry)
    }

    func testSaveTokensOverwritesPrevious() {
        let accountId = "overwrite-account"

        KeychainHelper.saveTokens(
            accessToken: "old-access",
            refreshToken: "old-refresh",
            expiry: Date(timeIntervalSince1970: 1_000_000),
            for: accountId
        )

        KeychainHelper.saveTokens(
            accessToken: "new-access",
            refreshToken: "new-refresh",
            expiry: Date(timeIntervalSince1970: 2_000_000),
            for: accountId
        )

        let loaded = KeychainHelper.loadTokens(for: accountId)
        XCTAssertEqual(loaded.accessToken, "new-access")
        XCTAssertEqual(loaded.refreshToken, "new-refresh")
    }

    // MARK: - LLM API Key Operations

    func testSaveAndLoadLLMAPIKey() {
        KeychainHelper.saveLLMAPIKey("sk-test-key", provider: "TestProvider")

        let loaded = KeychainHelper.loadLLMAPIKey(provider: "TestProvider")
        XCTAssertEqual(loaded, "sk-test-key")
    }

    func testLoadLLMAPIKeyReturnsNilWhenNotSet() {
        let loaded = KeychainHelper.loadLLMAPIKey(provider: "NonexistentProvider")
        XCTAssertNil(loaded)
    }

    func testDeleteLLMAPIKey() {
        KeychainHelper.saveLLMAPIKey("delete-me", provider: "DeleteProvider")
        KeychainHelper.deleteLLMAPIKey(provider: "DeleteProvider")

        let loaded = KeychainHelper.loadLLMAPIKey(provider: "DeleteProvider")
        XCTAssertNil(loaded)
    }

    func testSaveLLMAPIKeyOverwritesPrevious() {
        KeychainHelper.saveLLMAPIKey("old-key", provider: "Overwrite")
        KeychainHelper.saveLLMAPIKey("new-key", provider: "Overwrite")

        let loaded = KeychainHelper.loadLLMAPIKey(provider: "Overwrite")
        XCTAssertEqual(loaded, "new-key")
    }

    // MARK: - Bulk Operations

    func testDeleteAllTokens() {
        KeychainHelper.saveTokens(
            accessToken: "a",
            refreshToken: "b",
            expiry: Date(),
            for: "bulk-account"
        )
        KeychainHelper.saveLLMAPIKey("key", provider: "BulkProvider")

        KeychainHelper.deleteAllTokens()

        let tokens = KeychainHelper.loadTokens(for: "bulk-account")
        XCTAssertNil(tokens.accessToken)
        XCTAssertNil(tokens.refreshToken)

        let apiKey = KeychainHelper.loadLLMAPIKey(provider: "BulkProvider")
        XCTAssertNil(apiKey)
    }

    // MARK: - Multiple Accounts Isolation

    func testTokensIsolatedBetweenAccounts() {
        KeychainHelper.saveTokens(
            accessToken: "access-A",
            refreshToken: "refresh-A",
            expiry: nil,
            for: "account-A"
        )
        KeychainHelper.saveTokens(
            accessToken: "access-B",
            refreshToken: "refresh-B",
            expiry: nil,
            for: "account-B"
        )

        let tokensA = KeychainHelper.loadTokens(for: "account-A")
        let tokensB = KeychainHelper.loadTokens(for: "account-B")

        XCTAssertEqual(tokensA.accessToken, "access-A")
        XCTAssertEqual(tokensB.accessToken, "access-B")
        XCTAssertNotEqual(tokensA.accessToken, tokensB.accessToken)
    }
}
