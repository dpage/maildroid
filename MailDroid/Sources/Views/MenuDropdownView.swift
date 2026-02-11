import SwiftUI

struct MenuDropdownView: View {
    @EnvironmentObject var appState: AppState
    @State private var runningPromptIds: Set<String> = []
    @State private var errorMessage: String?
    @State private var errorIsLLMConfig = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("MailDroid")
                    .font(.headline)
                Spacer()

                Button(action: {
                    NotificationCenter.default.post(
                        name: Notification.Name("openSettings"),
                        object: nil
                    )
                }) {
                    Image(systemName: "gear")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Open Settings")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            if appState.executionHistory.isEmpty && appState.promptConfigs.isEmpty {
                // Empty state: no prompts or execution history
                VStack(spacing: 12) {
                    Image(systemName: "envelope.badge.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)

                    if appState.accounts.isEmpty {
                        Text("Get started")
                            .font(.headline)
                        Text("Add a Gmail account and create a prompt to analyse your emails with AI.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        HStack(spacing: 12) {
                            Button("Add Account") {
                                addAccount()
                            }
                            .buttonStyle(.borderedProminent)
                            Button("Add Prompt") {
                                NotificationCenter.default.post(
                                    name: Notification.Name("openSettings"),
                                    object: nil,
                                    userInfo: ["tab": SettingsTab.prompts]
                                )
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    } else {
                        Text("Create a prompt")
                            .font(.headline)
                        Text("Create a prompt to start analysing your emails with AI.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Add Prompt") {
                            NotificationCenter.default.post(
                                name: Notification.Name("openSettings"),
                                object: nil,
                                userInfo: ["tab": SettingsTab.prompts]
                            )
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(24)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        // Active prompts section
                        if !appState.promptConfigs.isEmpty {
                            Text("Prompts")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.top, 10)
                                .padding(.bottom, 4)

                            ForEach(appState.promptConfigs) { config in
                                PromptRowView(
                                    config: config,
                                    isRunning: runningPromptIds.contains(config.id),
                                    unreadCount: unreadCount(for: config),
                                    onRunNow: {
                                        runPrompt(config)
                                    },
                                    onShowLatestUnread: {
                                        showLatestUnread(for: config)
                                    },
                                    onShowHistory: {
                                        NotificationCenter.default.post(
                                            name: Notification.Name("closePopover"),
                                            object: nil
                                        )
                                        NotificationCenter.default.post(
                                            name: Notification.Name("openExecutionHistory"),
                                            object: nil,
                                            userInfo: ["promptId": config.id]
                                        )
                                    }
                                )
                                Divider()
                                    .padding(.leading, 16)
                            }
                        }
                    }
                }
                .frame(maxHeight: 320)
            }

            // Error banner
            if let errorMessage = errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    Spacer()
                    if errorIsLLMConfig {
                        Button(action: { openLLMSettings() }) {
                            Text("Settings")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                        .help("Open LLM Provider settings")
                    }
                    Button(action: {
                        self.errorMessage = nil
                        self.errorIsLLMConfig = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
            }

            Divider()

            // Footer actions
            HStack {
                Spacer()

                Button("Quit") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(width: 380)
    }

    // MARK: - Computed Properties

    private func unreadCount(for config: PromptConfig) -> Int {
        appState.executionHistory.filter {
            $0.promptId == config.id && !$0.wasShownToUser
        }.count
    }

    // MARK: - Actions

    private func showLatestUnread(for config: PromptConfig) {
        guard let index = appState.executionHistory.firstIndex(
            where: { $0.promptId == config.id && !$0.wasShownToUser }
        ) else { return }

        let execution = appState.executionHistory[index]

        // Mark as shown.
        let updated = PromptExecution(
            id: execution.id,
            promptId: execution.promptId,
            promptName: execution.promptName,
            timestamp: execution.timestamp,
            result: execution.result,
            wasActionable: execution.wasActionable,
            emailCount: execution.emailCount,
            wasShownToUser: true
        )
        appState.executionHistory[index] = updated
        appState.saveExecutionHistory()

        // Show the result popup.
        let appDelegate = NSApp.delegate as? AppDelegate
        let controller = ResultPopupWindowController()
        appDelegate?.resultPopupController = controller
        controller.showResult(execution, appState: appState)
        NotificationCenter.default.post(
            name: Notification.Name("closePopover"),
            object: nil
        )
    }

    private func addAccount() {
        Task {
            do {
                let authService = GoogleAuthService(appState: appState)
                let account = try await authService.authenticate()

                await MainActor.run {
                    if let existingIndex = appState.accounts.firstIndex(
                        where: { $0.email == account.email }
                    ) {
                        appState.accounts[existingIndex] = account
                    } else {
                        appState.accounts.append(account)
                    }
                    appState.saveAccounts()
                }
            } catch AuthError.userCancelled {
                // User cancelled; no action needed.
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func openLLMSettings() {
        NotificationCenter.default.post(
            name: Notification.Name("openSettings"),
            object: nil,
            userInfo: ["tab": SettingsTab.llmProvider]
        )
    }

    private func runPrompt(_ config: PromptConfig) {
        guard let llmConfig = appState.appSettings.llmConfig else {
            errorMessage = "No LLM provider configured. Open Settings → LLM Provider to set one up."
            errorIsLLMConfig = true
            return
        }

        if llmConfig.provider.requiresAPIKey && llmConfig.apiKey.isEmpty {
            errorMessage = "API key required for \(llmConfig.provider.rawValue). Open Settings → LLM Provider to add your key."
            errorIsLLMConfig = true
            return
        }

        runningPromptIds.insert(config.id)

        Task {
            do {
                let gmailService = GmailService(appState: appState)
                let executionService = PromptExecutionService(
                    gmailService: gmailService
                )
                let execution = try await executionService.executePrompt(
                    config,
                    accounts: appState.accounts,
                    llmConfig: llmConfig
                )

                await MainActor.run {
                    appState.executionHistory.insert(execution, at: 0)
                    appState.saveExecutionHistory()
                    runningPromptIds.remove(config.id)
                    errorMessage = nil
                    errorIsLLMConfig = false
                }
            } catch {
                await MainActor.run {
                    runningPromptIds.remove(config.id)
                    errorMessage = error.localizedDescription
                    if let llmError = error as? LLMError,
                       case .missingAPIKey = llmError {
                        errorIsLLMConfig = true
                    } else {
                        errorIsLLMConfig = false
                    }
                }
            }
        }
    }
}

// MARK: - Prompt Row View

struct PromptRowView: View {
    let config: PromptConfig
    let isRunning: Bool
    let unreadCount: Int
    let onRunNow: () -> Void
    let onShowLatestUnread: () -> Void
    let onShowHistory: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 10) {
            // Unread indicator dot
            if unreadCount > 0 {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 8, height: 8)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(config.name.isEmpty ? "Untitled Prompt" : config.name)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)

                    if unreadCount > 0 {
                        Text("\(unreadCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                }

                Text(statusText)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if isRunning {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 20, height: 20)
            } else if config.triggerType != .scheduled || isHovering {
                Button(action: onShowHistory) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 11))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("View history for this prompt")

                Button(action: onRunNow) {
                    HStack(spacing: 3) {
                        Image(systemName: "play.fill")
                        Text("Run")
                    }
                    .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            if unreadCount > 0 {
                onShowLatestUnread()
            }
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }

    private var statusText: String {
        let triggerLabel: String
        switch config.triggerType {
        case .onDemand:
            triggerLabel = "On demand"
        case .scheduled:
            triggerLabel = scheduleDescription
        case .both:
            triggerLabel = "On demand + \(scheduleDescription)"
        }

        return "\(config.emailTimeRange.rawValue) - \(triggerLabel)"
    }

    private var scheduleDescription: String {
        config.schedule?.displayString ?? "No schedule"
    }
}

#Preview {
    MenuDropdownView()
        .environmentObject(AppState())
}
