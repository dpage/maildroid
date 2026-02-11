import SwiftUI
import ServiceManagement

// MARK: - Settings Tab

enum SettingsTab: Int, CaseIterable {
    case general
    case accounts
    case llmProvider
    case prompts
    case about
}

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Binding var selectedTab: SettingsTab

    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView()
                .environmentObject(appState)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(SettingsTab.general)

            AccountsSettingsView()
                .environmentObject(appState)
                .tabItem {
                    Label("Accounts", systemImage: "person.2")
                }
                .tag(SettingsTab.accounts)

            ProviderSetupView()
                .environmentObject(appState)
                .tabItem {
                    Label("LLM Provider", systemImage: "brain")
                }
                .tag(SettingsTab.llmProvider)

            PromptsSettingsView()
                .environmentObject(appState)
                .tabItem {
                    Label("Prompts", systemImage: "text.bubble")
                }
                .tag(SettingsTab.prompts)

            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(SettingsTab.about)
        }
        .frame(width: 500, height: 450)
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var launchAtLogin: Bool
    @State private var playSound: Bool

    init() {
        let settings = AppSettings.load()
        _launchAtLogin = State(initialValue: settings.launchAtLogin)
        _playSound = State(initialValue: settings.playSound)
    }

    var body: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        setLaunchAtLogin(newValue)
                        appState.appSettings.launchAtLogin = newValue
                        appState.saveSettings()
                    }
            } header: {
                Text("System")
            }

            Section {
                Toggle("Play sound on new results", isOn: $playSound)
                    .onChange(of: playSound) { newValue in
                        appState.appSettings.playSound = newValue
                        appState.saveSettings()
                    }
            } header: {
                Text("Notifications")
            }
        }
        .formStyle(.grouped)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to set launch at login: \(error)")
        }
    }
}

// MARK: - Accounts Settings

struct AccountsSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var isAuthenticating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if appState.accounts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No accounts connected")
                        .font(.headline)

                    Text("Connect your Gmail accounts to analyze emails with prompts")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Add Gmail Account") {
                        addAccount()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isAuthenticating)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List {
                    ForEach(appState.accounts) { account in
                        AccountRowView(account: account) {
                            removeAccount(account)
                        } onToggle: { enabled in
                            toggleAccount(account, enabled: enabled)
                        }
                    }
                }

                Divider()

                HStack {
                    Button("Add Account") {
                        addAccount()
                    }
                    .disabled(isAuthenticating)

                    Spacer()

                    if isAuthenticating {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
                .padding()
            }
        }
    }

    private func addAccount() {
        isAuthenticating = true
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
                    isAuthenticating = false
                }
            } catch AuthError.userCancelled {
                await MainActor.run {
                    isAuthenticating = false
                }
            } catch {
                await MainActor.run {
                    isAuthenticating = false
                }
                print("Authentication failed: \(error.localizedDescription)")
            }
        }
    }

    private func removeAccount(_ account: GmailAccount) {
        GmailAccount.delete(account)
        appState.accounts.removeAll { $0.id == account.id }
    }

    private func toggleAccount(_ account: GmailAccount, enabled: Bool) {
        if let index = appState.accounts.firstIndex(
            where: { $0.id == account.id }
        ) {
            appState.accounts[index].isEnabled = enabled
            appState.saveAccounts()
        }
    }
}

// MARK: - Account Row View

struct AccountRowView: View {
    let account: GmailAccount
    let onRemove: () -> Void
    let onToggle: (Bool) -> Void

    @State private var isEnabled: Bool

    init(
        account: GmailAccount,
        onRemove: @escaping () -> Void,
        onToggle: @escaping (Bool) -> Void
    ) {
        self.account = account
        self.onRemove = onRemove
        self.onToggle = onToggle
        self._isEnabled = State(initialValue: account.isEnabled)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(account.displayName)
                    .font(.system(size: 13, weight: .medium))
                Text(account.email)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isEnabled)
                .toggleStyle(.switch)
                .labelsHidden()
                .onChange(of: isEnabled) { newValue in
                    onToggle(newValue)
                }

            Button(action: onRemove) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Prompts Settings

/// A wrapper that gives each editor presentation a unique identity.
/// Using `.sheet(item:)` with this type ensures SwiftUI creates a
/// fresh sheet whenever `editorItem` changes, which fixes the bug
/// where editing an existing prompt showed stale (empty) data.
struct PromptEditorItem: Identifiable {
    let id = UUID()
    let config: PromptConfig?
}

struct PromptsSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var editorItem: PromptEditorItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if appState.promptConfigs.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No prompts configured")
                        .font(.headline)

                    Text("Create prompts to analyze your emails with AI")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Create Prompt") {
                        editorItem = PromptEditorItem(config: nil)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List {
                    ForEach(appState.promptConfigs) { config in
                        PromptConfigRowView(
                            config: config,
                            onEdit: {
                                editorItem = PromptEditorItem(config: config)
                            },
                            onDelete: {
                                deletePrompt(config)
                            },
                            onToggle: { enabled in
                                togglePrompt(config, enabled: enabled)
                            }
                        )
                    }
                }

                Divider()

                HStack {
                    Button("Add Prompt") {
                        editorItem = PromptEditorItem(config: nil)
                    }

                    Spacer()
                }
                .padding()
            }
        }
        .sheet(item: $editorItem) { item in
            PromptEditorView(
                existingConfig: item.config,
                onSave: { config in
                    savePrompt(config)
                }
            )
            .environmentObject(appState)
        }
    }

    private func savePrompt(_ config: PromptConfig) {
        if let index = appState.promptConfigs.firstIndex(
            where: { $0.id == config.id }
        ) {
            appState.promptConfigs[index] = config
        } else {
            appState.promptConfigs.append(config)
        }
        appState.savePromptConfigs()
    }

    private func deletePrompt(_ config: PromptConfig) {
        appState.promptConfigs.removeAll { $0.id == config.id }
        appState.savePromptConfigs()
    }

    private func togglePrompt(_ config: PromptConfig, enabled: Bool) {
        if let index = appState.promptConfigs.firstIndex(
            where: { $0.id == config.id }
        ) {
            appState.promptConfigs[index].isEnabled = enabled
            appState.savePromptConfigs()
        }
    }
}

// MARK: - Prompt Config Row View

struct PromptConfigRowView: View {
    let config: PromptConfig
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggle: (Bool) -> Void

    @State private var isEnabled: Bool

    init(
        config: PromptConfig,
        onEdit: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onToggle: @escaping (Bool) -> Void
    ) {
        self.config = config
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onToggle = onToggle
        self._isEnabled = State(initialValue: config.isEnabled)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(config.name.isEmpty ? "Untitled Prompt" : config.name)
                    .font(.system(size: 13, weight: .medium))

                Text("\(config.triggerType.rawValue) - \(config.emailTimeRange.rawValue)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isEnabled)
                .toggleStyle(.switch)
                .labelsHidden()
                .onChange(of: isEnabled) { newValue in
                    onToggle(newValue)
                }

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
            .help("Edit prompt")

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
            .help("Delete prompt")
        }
        .padding(.vertical, 4)
    }
}

// MARK: - About View

struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope.badge.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text("MailDroid")
                .font(.title)
                .fontWeight(.bold)

            Text("Version 1.0.0")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("AI-powered email analysis from your menu bar")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    SettingsView(selectedTab: .constant(.general))
        .environmentObject(AppState())
}
