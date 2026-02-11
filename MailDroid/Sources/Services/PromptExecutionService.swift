import Foundation

/// Errors that can occur during prompt execution.
enum PromptExecutionError: Error, LocalizedError {
    case noEnabledAccounts
    case noEmails
    case llmConfigMissing

    var errorDescription: String? {
        switch self {
        case .noEnabledAccounts:
            return "No enabled Gmail accounts are available."
        case .noEmails:
            return "No emails were found in the selected time range."
        case .llmConfigMissing:
            return "LLM configuration is not set up."
        }
    }
}

/// Orchestrates prompt execution by fetching emails, building the
/// LLM prompt, and returning a structured execution record.
struct PromptExecutionService {

    private let gmailService: GmailService
    private let llmService: LLMService

    init(gmailService: GmailService, llmService: LLMService = LLMService()) {
        self.gmailService = gmailService
        self.llmService = llmService
    }

    // MARK: - Public API

    /// Executes the given prompt configuration against all enabled
    /// accounts and returns an execution record.
    ///
    /// The method fetches emails from every enabled account within
    /// the prompt's time range, formats them for the LLM, sends the
    /// combined prompt, and determines whether the result is
    /// actionable.
    func executePrompt(
        _ config: PromptConfig,
        accounts: [GmailAccount],
        llmConfig: LLMConfig
    ) async throws -> PromptExecution {
        let enabledAccounts = accounts.filter { $0.isEnabled }
        guard !enabledAccounts.isEmpty else {
            throw PromptExecutionError.noEnabledAccounts
        }

        // Fetch emails from all enabled accounts.
        let sinceDate = Date(
            timeIntervalSinceNow: -config.emailTimeRange.timeInterval
        )
        let emails = try await fetchEmailsFromAllAccounts(
            enabledAccounts,
            since: sinceDate
        )

        // Build the prompt payload.
        let formattedEmails = formatEmails(emails)
        let systemPrompt = """
            You are analyzing emails for the user. Review the provided \
            emails and respond to the user's request. Be concise and \
            actionable.

            IMPORTANT: You MUST end your response with exactly one of \
            these lines on its own line:
            ACTIONABLE: YES
            ACTIONABLE: NO

            Use "ACTIONABLE: YES" if there are items requiring the \
            user's attention or action. Use "ACTIONABLE: NO" if there \
            is nothing the user needs to act on.
            """
        let userContent = buildUserContent(
            promptText: config.prompt,
            formattedEmails: formattedEmails,
            emailCount: emails.count
        )

        // Send to the LLM.
        let response = try await llmService.sendPrompt(
            config: llmConfig,
            systemPrompt: systemPrompt,
            userContent: userContent
        )

        let (cleanedResponse, actionable) = parseActionability(response)

        return PromptExecution(
            promptId: config.id,
            promptName: config.name,
            result: cleanedResponse,
            wasActionable: actionable,
            emailCount: emails.count
        )
    }

    // MARK: - Email Fetching

    /// Fetches emails from every account and merges the results.
    ///
    /// Errors from individual accounts are collected but do not
    /// prevent other accounts from being queried. An error is thrown
    /// only if every account fails.
    private func fetchEmailsFromAllAccounts(
        _ accounts: [GmailAccount],
        since: Date
    ) async throws -> [Email] {
        var allEmails: [Email] = []
        var lastError: Error?

        for account in accounts {
            do {
                let emails = try await gmailService.fetchEmails(
                    account: account,
                    since: since
                )
                allEmails.append(contentsOf: emails)
            } catch {
                lastError = error
            }
        }

        // If every account failed, surface the last error.
        if allEmails.isEmpty, let error = lastError {
            throw error
        }

        // Sort by date descending so the most recent emails appear first.
        allEmails.sort { $0.date > $1.date }

        return allEmails
    }

    // MARK: - Email Formatting

    /// Formats a list of emails into structured text for the LLM.
    ///
    /// Each email includes its subject, sender, date, and body
    /// truncated to approximately 500 characters.
    func formatEmails(_ emails: [Email]) -> String {
        if emails.isEmpty {
            return "[No emails found in the selected time range.]"
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        var parts: [String] = []

        for (index, email) in emails.enumerated() {
            let truncatedBody = truncateBody(email.body, maxLength: 500)

            let entry = """
                --- Email \(index + 1) ---
                Subject: \(email.subject)
                From: \(email.from)
                Date: \(dateFormatter.string(from: email.date))
                Body: \(truncatedBody)
                """
            parts.append(entry)
        }

        return parts.joined(separator: "\n\n")
    }

    /// Truncates a body string to the given maximum length, appending
    /// an ellipsis when truncation occurs.
    func truncateBody(_ body: String, maxLength: Int) -> String {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.count <= maxLength {
            return trimmed
        }

        let endIndex = trimmed.index(
            trimmed.startIndex,
            offsetBy: maxLength
        )
        return String(trimmed[..<endIndex]) + "..."
    }

    // MARK: - Prompt Building

    /// Builds the user content string sent to the LLM.
    func buildUserContent(
        promptText: String,
        formattedEmails: String,
        emailCount: Int
    ) -> String {
        return """
            Here are \(emailCount) email(s) to analyze:

            \(formattedEmails)

            ---

            User request: \(promptText)
            """
    }

    // MARK: - Actionability Detection

    /// Parses the LLM response for a structured actionability marker
    /// and returns the cleaned response with the marker removed.
    ///
    /// The LLM is instructed to end its response with either
    /// `ACTIONABLE: YES` or `ACTIONABLE: NO`. This method strips that
    /// line and returns a boolean indicating actionability. If the
    /// marker is missing, the method defaults to `true` (actionable)
    /// as the safer assumption for notifications.
    func parseActionability(
        _ response: String
    ) -> (cleanedResponse: String, isActionable: Bool) {
        let lines = response.components(separatedBy: .newlines)
        var actionable = true
        var cleanedLines: [String] = []

        for line in lines {
            let trimmed = line
                .trimmingCharacters(in: .whitespaces)
                .uppercased()
            if trimmed == "ACTIONABLE: YES" || trimmed == "ACTIONABLE:YES" {
                actionable = true
            } else if trimmed == "ACTIONABLE: NO" || trimmed == "ACTIONABLE:NO" {
                actionable = false
            } else {
                cleanedLines.append(line)
            }
        }

        // Remove trailing blank lines left after stripping the marker.
        while cleanedLines.last?
            .trimmingCharacters(in: .whitespaces)
            .isEmpty == true {
            cleanedLines.removeLast()
        }

        return (cleanedLines.joined(separator: "\n"), actionable)
    }
}
