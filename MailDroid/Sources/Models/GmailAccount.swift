import Foundation

struct GmailAccount: Identifiable, Codable {
    let id: String
    var email: String
    var displayName: String
    var isEnabled: Bool
    var accessToken: String?
    var refreshToken: String?
    var tokenExpiry: Date?

    var isTokenExpired: Bool {
        guard let expiry = tokenExpiry else { return true }
        return Date() >= expiry.addingTimeInterval(-60) // 1 minute buffer
    }

    var needsReauthentication: Bool {
        return refreshToken == nil || refreshToken?.isEmpty == true
    }

    init(id: String = UUID().uuidString, email: String, displayName: String = "") {
        self.id = id
        self.email = email
        self.displayName = displayName.isEmpty ? email : displayName
        self.isEnabled = true
    }

    // MARK: - Gmail Scopes

    static let scopes = [
        "https://www.googleapis.com/auth/gmail.readonly",
        "https://www.googleapis.com/auth/gmail.modify",
        "https://www.googleapis.com/auth/userinfo.email",
        "https://www.googleapis.com/auth/userinfo.profile"
    ]

    // MARK: - Persistence

    private static let accountsKey = "maildroid.accounts"

    static func loadAll() -> [GmailAccount] {
        guard let data = UserDefaults.standard.data(forKey: accountsKey),
              var accounts = try? JSONDecoder().decode([GmailAccount].self, from: data) else {
            print("[MailDroid] loadAll: no accounts found in UserDefaults")
            return []
        }

        print("[MailDroid] loadAll: loaded \(accounts.count) account(s) from UserDefaults")

        for i in accounts.indices {
            let tokens = KeychainHelper.loadTokens(for: accounts[i].id)
            accounts[i].accessToken = tokens.accessToken
            accounts[i].refreshToken = tokens.refreshToken
            accounts[i].tokenExpiry = tokens.expiry
            print("[MailDroid] loadAll: account \(accounts[i].email) - hasAccessToken=\(accounts[i].accessToken != nil), hasRefreshToken=\(accounts[i].refreshToken != nil), hasExpiry=\(accounts[i].tokenExpiry != nil)")
        }

        return accounts
    }

    static func saveAll(_ accounts: [GmailAccount]) {
        var accountsToSave = accounts
        for i in accountsToSave.indices {
            KeychainHelper.saveTokens(
                accessToken: accounts[i].accessToken,
                refreshToken: accounts[i].refreshToken,
                expiry: accounts[i].tokenExpiry,
                for: accounts[i].id
            )

            accountsToSave[i].accessToken = nil
            accountsToSave[i].refreshToken = nil
            accountsToSave[i].tokenExpiry = nil
        }

        if let data = try? JSONEncoder().encode(accountsToSave) {
            UserDefaults.standard.set(data, forKey: accountsKey)
            UserDefaults.standard.synchronize()
        }
    }

    static func delete(_ account: GmailAccount) {
        KeychainHelper.deleteTokens(for: account.id)
        var accounts = loadAll()
        accounts.removeAll { $0.id == account.id }
        saveAll(accounts)
    }
}
