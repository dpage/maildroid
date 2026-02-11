import Foundation
import Combine

// MARK: - App State

class AppState: ObservableObject {
    @Published var accounts: [GmailAccount] = []
    @Published var promptConfigs: [PromptConfig] = []
    @Published var appSettings: AppSettings = AppSettings.load()
    @Published var executionHistory: [PromptExecution] = []
    @Published var isLoading: Bool = false
    @Published var selectedSettingsTab: SettingsTab = .general

    var cancellables = Set<AnyCancellable>()

    init() {
        loadState()
    }

    func loadState() {
        accounts = GmailAccount.loadAll()
        promptConfigs = PromptConfig.loadAll()
        appSettings = AppSettings.load()
        executionHistory = PromptExecution.loadAll()
    }

    func saveAccounts() {
        GmailAccount.saveAll(accounts)
    }

    func savePromptConfigs() {
        PromptConfig.saveAll(promptConfigs)
    }

    func saveSettings() {
        appSettings.save()
    }

    func saveExecutionHistory() {
        PromptExecution.saveAll(executionHistory)
    }
}
