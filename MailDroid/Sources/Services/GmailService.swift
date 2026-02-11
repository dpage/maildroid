import Foundation

/// Fetches emails from the Gmail API for a given account.
///
/// All requests include a Bearer token. On a 401 response the service
/// refreshes the access token via `GoogleAuthService` and retries once.
class GmailService {
    private weak var appState: AppState?

    init(appState: AppState) {
        self.appState = appState
    }

    // MARK: - Public API

    /// Fetches emails received after the given date for an account.
    ///
    /// The method pages through all results and fetches full message
    /// details for every message ID returned by the list endpoint.
    func fetchEmails(account: GmailAccount, since: Date) async throws -> [Email] {
        let messageIds = try await fetchAllMessageIds(account: account, since: since)

        var emails: [Email] = []
        for messageId in messageIds {
            let email = try await fetchMessageDetail(account: account, messageId: messageId)
            emails.append(email)
        }

        return emails
    }

    /// Fetches full details for a single message and parses it into an Email.
    func fetchMessageDetail(account: GmailAccount, messageId: String) async throws -> Email {
        let path = "/users/me/messages/\(messageId)?format=full"
        let data = try await authenticatedRequest(account: account, path: path)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw GmailError.invalidMessageResponse
        }

        return parseEmail(from: json, accountId: account.id)
    }

    // MARK: - Message List

    /// Fetches all message IDs matching the time filter, handling pagination.
    private func fetchAllMessageIds(account: GmailAccount, since: Date) async throws -> [String] {
        let timestamp = Int(since.timeIntervalSince1970)
        var allIds: [String] = []
        var pageToken: String?

        repeat {
            var path = "/users/me/messages?q=after:\(timestamp)"
            if let token = pageToken {
                path += "&pageToken=\(token)"
            }

            let data = try await authenticatedRequest(account: account, path: path)

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw GmailError.invalidListResponse
            }

            if let messages = json["messages"] as? [[String: Any]] {
                let ids = messages.compactMap { $0["id"] as? String }
                allIds.append(contentsOf: ids)
            }

            pageToken = json["nextPageToken"] as? String
        } while pageToken != nil

        return allIds
    }

    // MARK: - Authenticated Requests

    /// Performs a GET request against the Gmail API with automatic 401 retry.
    ///
    /// On a 401 response the method refreshes the account token through
    /// `GoogleAuthService` and retries the request exactly once.
    private func authenticatedRequest(
        account: GmailAccount,
        path: String
    ) async throws -> Data {
        var currentAccount = account

        print("[MailDroid] authenticatedRequest: account=\(account.email), hasAccessToken=\(account.accessToken != nil), hasRefreshToken=\(account.refreshToken != nil), isTokenExpired=\(account.isTokenExpired)")

        // Proactively refresh if the token is already expired.
        if currentAccount.isTokenExpired {
            guard currentAccount.refreshToken != nil,
                  currentAccount.refreshToken?.isEmpty == false else {
                print("[MailDroid] authenticatedRequest: token expired but no refresh token available for \(account.email)")
                throw GmailError.noRefreshToken
            }
            currentAccount = try await refreshToken(for: currentAccount)
        }

        guard let accessToken = currentAccount.accessToken else {
            throw GmailError.noAccessToken
        }

        let (data, statusCode) = try await performRequest(
            path: path,
            accessToken: accessToken
        )

        if statusCode == 401 {
            // Token was rejected; refresh and retry once.
            let refreshed = try await refreshToken(for: currentAccount)

            guard let newToken = refreshed.accessToken else {
                throw GmailError.noAccessToken
            }

            let (retryData, retryStatus) = try await performRequest(
                path: path,
                accessToken: newToken
            )

            guard retryStatus == 200 else {
                throw GmailError.requestFailed(retryStatus)
            }

            return retryData
        }

        guard statusCode == 200 else {
            throw GmailError.requestFailed(statusCode)
        }

        return data
    }

    /// Executes a single GET request and returns the body with the HTTP status code.
    private func performRequest(
        path: String,
        accessToken: String
    ) async throws -> (Data, Int) {
        guard let url = URL(string: Config.gmailBaseURL + path) else {
            throw GmailError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GmailError.invalidResponse
        }

        return (data, httpResponse.statusCode)
    }

    // MARK: - Token Refresh

    /// Refreshes the access token via GoogleAuthService and persists the update.
    private func refreshToken(for account: GmailAccount) async throws -> GmailAccount {
        guard let authService = await createAuthService() else {
            throw GmailError.noAppState
        }

        let updated = try await authService.refreshAccessToken(for: account)
        await persistUpdatedAccount(updated)
        return updated
    }

    @MainActor
    private func createAuthService() -> GoogleAuthService? {
        guard let appState = appState else { return nil }
        return GoogleAuthService(appState: appState)
    }

    @MainActor
    private func persistUpdatedAccount(_ account: GmailAccount) {
        guard let appState = appState else { return }
        if let index = appState.accounts.firstIndex(where: { $0.id == account.id }) {
            appState.accounts[index] = account
            appState.saveAccounts()
        }
    }

    // MARK: - Email Parsing

    /// Parses a Gmail API message JSON object into an Email model.
    private func parseEmail(from json: [String: Any], accountId: String) -> Email {
        let id = json["id"] as? String ?? ""
        let threadId = json["threadId"] as? String ?? ""
        let snippet = json["snippet"] as? String ?? ""
        let labelIds = json["labelIds"] as? [String] ?? []
        let isUnread = labelIds.contains("UNREAD")

        let payload = json["payload"] as? [String: Any] ?? [:]
        let headers = payload["headers"] as? [[String: Any]] ?? []

        let subject = headerValue(named: "Subject", in: headers)
        let from = headerValue(named: "From", in: headers)
        let to = headerValue(named: "To", in: headers)
        let dateString = headerValue(named: "Date", in: headers)
        let date = parseDate(dateString)

        let body = extractBody(from: payload, fallbackSnippet: snippet)

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
            labels: labelIds,
            isUnread: isUnread
        )
    }

    /// Returns the value of the first header matching the given name.
    private func headerValue(named name: String, in headers: [[String: Any]]) -> String {
        return headers.first { ($0["name"] as? String) == name }?["value"] as? String ?? ""
    }

    /// Parses an RFC 2822 date string into a Date.
    private func parseDate(_ string: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        // Gmail dates typically follow RFC 2822.
        let formats = [
            "EEE, dd MMM yyyy HH:mm:ss Z",
            "dd MMM yyyy HH:mm:ss Z",
            "EEE, dd MMM yyyy HH:mm:ss z"
        ]

        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: string) {
                return date
            }
        }

        return Date()
    }

    /// Extracts the plain text body from MIME parts.
    ///
    /// The method walks the part tree looking for text/plain first, then
    /// falls back to text/html with tags stripped, and finally to the
    /// message snippet.
    private func extractBody(from payload: [String: Any], fallbackSnippet: String) -> String {
        // Try to find body in parts (multipart messages).
        if let parts = payload["parts"] as? [[String: Any]] {
            if let plainText = findBodyPart(mimeType: "text/plain", in: parts) {
                return plainText
            }
            if let html = findBodyPart(mimeType: "text/html", in: parts) {
                return stripHTMLTags(from: html)
            }
        }

        // Single-part message: check the payload body directly.
        if let body = payload["body"] as? [String: Any],
           let data = body["data"] as? String,
           let decoded = decodeBase64URL(data) {
            let mimeType = payload["mimeType"] as? String ?? ""
            if mimeType == "text/html" {
                return stripHTMLTags(from: decoded)
            }
            return decoded
        }

        return fallbackSnippet
    }

    /// Recursively searches MIME parts for the first part matching the given type.
    private func findBodyPart(mimeType: String, in parts: [[String: Any]]) -> String? {
        for part in parts {
            let partMimeType = part["mimeType"] as? String ?? ""

            if partMimeType == mimeType,
               let body = part["body"] as? [String: Any],
               let data = body["data"] as? String,
               let decoded = decodeBase64URL(data) {
                return decoded
            }

            // Recurse into nested parts (e.g., multipart/alternative inside multipart/mixed).
            if let subParts = part["parts"] as? [[String: Any]],
               let result = findBodyPart(mimeType: mimeType, in: subParts) {
                return result
            }
        }

        return nil
    }

    /// Decodes a base64url-encoded string into a UTF-8 string.
    private func decodeBase64URL(_ encoded: String) -> String? {
        var base64 = encoded
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // Pad to a multiple of 4.
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }

        guard let data = Data(base64Encoded: base64) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Strips HTML tags from a string, returning plain text.
    private func stripHTMLTags(from html: String) -> String {
        var result = html

        // Replace <br> variants and block-level closing tags with newlines.
        let newlinePatterns = ["<br\\s*/?>", "</p>", "</div>", "</tr>", "</li>"]
        for pattern in newlinePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                result = regex.stringByReplacingMatches(
                    in: result,
                    range: NSRange(result.startIndex..., in: result),
                    withTemplate: "\n"
                )
            }
        }

        // Remove all remaining tags.
        if let regex = try? NSRegularExpression(pattern: "<[^>]+>", options: .caseInsensitive) {
            result = regex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: ""
            )
        }

        // Decode common HTML entities.
        result = result
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")

        // Collapse multiple blank lines.
        while result.contains("\n\n\n") {
            result = result.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Error Types

enum GmailError: LocalizedError {
    case noAccessToken
    case noRefreshToken
    case noAppState
    case invalidURL
    case invalidResponse
    case invalidListResponse
    case invalidMessageResponse
    case requestFailed(Int)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .noAccessToken:
            return "No access token available for this account."
        case .noRefreshToken:
            return "No refresh token available. Please re-authenticate the account."
        case .noAppState:
            return "Application state is unavailable."
        case .invalidURL:
            return "Failed to construct Gmail API URL."
        case .invalidResponse:
            return "Invalid response from Gmail API."
        case .invalidListResponse:
            return "Failed to parse message list response."
        case .invalidMessageResponse:
            return "Failed to parse message detail response."
        case .requestFailed(let code):
            return "Gmail API request failed with status \(code)."
        case .unauthorized:
            return "Authorization expired; please re-authenticate."
        }
    }
}
