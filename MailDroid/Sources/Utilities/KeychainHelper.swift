// NOTE: This implementation uses UserDefaults instead of the macOS Keychain
// to avoid repeated password prompts that occur with unsigned or development
// builds. For a production release with proper code signing and entitlements,
// the macOS Keychain (via the Security framework) would be the more secure
// storage mechanism for tokens and API keys.

import Foundation

/// Stores and retrieves secrets using UserDefaults.
///
/// All keys use the "maildroid" prefix. OAuth tokens are stored
/// per account; LLM API keys use a shared provider identifier.
struct KeychainHelper {
    private static let defaults = UserDefaults.standard
    private static let keyPrefix = "maildroid"

    // MARK: - Token Data

    struct TokenData {
        var accessToken: String?
        var refreshToken: String?
        var expiry: Date?
    }

    // MARK: - OAuth Token Operations

    /// Saves OAuth tokens for a specific account.
    static func saveTokens(
        accessToken: String?,
        refreshToken: String?,
        expiry: Date?,
        for accountId: String
    ) {
        print("[MailDroid] saveTokens for account \(accountId): accessToken=\(accessToken != nil), refreshToken=\(refreshToken != nil), expiry=\(expiry != nil)")
        if let accessToken = accessToken {
            save(
                value: accessToken,
                key: "\(keyPrefix).tokens.\(accountId).accessToken"
            )
        }
        if let refreshToken = refreshToken {
            save(
                value: refreshToken,
                key: "\(keyPrefix).tokens.\(accountId).refreshToken"
            )
        }
        if let expiry = expiry {
            let timestamp = String(expiry.timeIntervalSince1970)
            save(
                value: timestamp,
                key: "\(keyPrefix).tokens.\(accountId).tokenExpiry"
            )
        }
    }

    /// Loads OAuth tokens for a specific account.
    static func loadTokens(for accountId: String) -> TokenData {
        let accessToken = load(
            key: "\(keyPrefix).tokens.\(accountId).accessToken"
        )
        let refreshToken = load(
            key: "\(keyPrefix).tokens.\(accountId).refreshToken"
        )

        var expiry: Date?
        if let expiryString = load(
            key: "\(keyPrefix).tokens.\(accountId).tokenExpiry"
        ), let interval = Double(expiryString) {
            expiry = Date(timeIntervalSince1970: interval)
        }

        print("[MailDroid] loadTokens for account \(accountId): accessToken=\(accessToken != nil), refreshToken=\(refreshToken != nil), expiry=\(expiry != nil)")

        return TokenData(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiry: expiry
        )
    }

    /// Deletes all OAuth tokens for a specific account.
    static func deleteTokens(for accountId: String) {
        delete(key: "\(keyPrefix).tokens.\(accountId).accessToken")
        delete(key: "\(keyPrefix).tokens.\(accountId).refreshToken")
        delete(key: "\(keyPrefix).tokens.\(accountId).tokenExpiry")
    }

    // MARK: - LLM API Key Operations

    /// Saves an LLM API key identified by provider name.
    static func saveLLMAPIKey(_ key: String, provider: String) {
        save(
            value: key,
            key: "\(keyPrefix).llm.\(provider)"
        )
    }

    /// Loads an LLM API key for a given provider.
    static func loadLLMAPIKey(provider: String) -> String? {
        return load(key: "\(keyPrefix).llm.\(provider)")
    }

    /// Deletes an LLM API key for a given provider.
    static func deleteLLMAPIKey(provider: String) {
        delete(key: "\(keyPrefix).llm.\(provider)")
    }

    // MARK: - Low-Level UserDefaults Operations

    private static func save(value: String, key: String) {
        defaults.set(value, forKey: key)
        defaults.synchronize()
    }

    private static func load(key: String) -> String? {
        return defaults.string(forKey: key)
    }

    private static func delete(key: String) {
        defaults.removeObject(forKey: key)
        defaults.synchronize()
    }

    // MARK: - Bulk Operations

    /// Deletes all MailDroid items from UserDefaults matching the key prefix.
    static func deleteAllTokens() {
        let allKeys = defaults.dictionaryRepresentation().keys
        for key in allKeys where key.hasPrefix(keyPrefix) {
            defaults.removeObject(forKey: key)
        }
        defaults.synchronize()
    }
}
