import XCTest
@testable import MailDroidLib

final class GmailServiceTests: XCTestCase {

    // MARK: - GmailError Descriptions

    func testGmailErrorDescriptions() {
        let errors: [GmailError] = [
            .noAccessToken,
            .noRefreshToken,
            .noAppState,
            .invalidURL,
            .invalidResponse,
            .invalidListResponse,
            .invalidMessageResponse,
            .requestFailed(403),
            .unauthorized
        ]

        for error in errors {
            XCTAssertNotNil(
                error.errorDescription,
                "Error \(error) should have a description."
            )
        }
    }

    func testRequestFailedIncludesStatusCode() {
        let error = GmailError.requestFailed(502)
        XCTAssertTrue(error.errorDescription?.contains("502") ?? false)
    }

    // MARK: - Token Behavior

    func testAccountWithExpiredTokenCannotFetchWithoutRefreshToken() {
        // This test verifies the precondition logic in GmailAccount
        // that GmailService relies on.
        var account = makeSampleAccount()
        account.accessToken = nil
        account.refreshToken = nil
        account.tokenExpiry = Date(timeIntervalSinceNow: -3600)

        XCTAssertTrue(account.isTokenExpired)
        XCTAssertTrue(account.needsReauthentication)
    }

    func testAccountWithValidTokenDoesNotNeedRefresh() {
        var account = makeSampleAccount()
        account.accessToken = "valid-token"
        account.refreshToken = "refresh-token"
        account.tokenExpiry = Date(timeIntervalSinceNow: 3600)

        XCTAssertFalse(account.isTokenExpired)
        XCTAssertFalse(account.needsReauthentication)
    }
}
