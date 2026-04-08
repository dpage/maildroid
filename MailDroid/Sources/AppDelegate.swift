import SwiftUI
import AppKit
import Combine

// MARK: - App Delegate

@MainActor
public class AppDelegate: NSObject, NSApplicationDelegate {
    var appState = AppState()
    var settingsWindow: NSWindow?
    var executionHistoryWindow: NSWindow?
    var resultPopupController: ResultPopupWindowController?
    var promptScheduler: PromptScheduler?
    private var promptConfigsCancellable: AnyCancellable?

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Prevent macOS from killing a menu bar app that has no open windows.
        ProcessInfo.processInfo.disableAutomaticTermination("Menu bar app")
        ProcessInfo.processInfo.disableSuddenTermination()

        setupNotificationObservers()
        setupPromptScheduler()

        // Hide dock icon - menu bar only app
        NSApp.setActivationPolicy(.accessory)
    }

    // MARK: - Prompt Scheduler

    private func setupPromptScheduler() {
        let scheduler = PromptScheduler()

        scheduler.onPromptDue = { [weak self] config in
            self?.executeScheduledPrompt(config)
        }

        scheduler.rescheduleAll(configs: appState.promptConfigs)

        // Observe changes to promptConfigs and reschedule when they change.
        promptConfigsCancellable = appState.$promptConfigs
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak scheduler] configs in
                MainActor.assumeIsolated {
                    scheduler?.rescheduleAll(configs: configs)
                }
            }

        promptScheduler = scheduler
    }

    /// Executes a scheduled prompt, stores the result, and shows the
    /// result popup.
    private func executeScheduledPrompt(_ config: PromptConfig) {
        guard let llmConfig = appState.appSettings.llmConfig else {
            return
        }

        if llmConfig.provider.requiresAPIKey && llmConfig.apiKey.isEmpty {
            return
        }

        Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                let gmailService = GmailService(appState: self.appState)
                let executionService = PromptExecutionService(
                    gmailService: gmailService
                )
                let execution = try await executionService.executePrompt(
                    config,
                    accounts: self.appState.accounts,
                    llmConfig: llmConfig
                )

                self.appState.executionHistory.insert(execution, at: 0)
                self.appState.saveExecutionHistory()

                // Respect the onlyShowIfActionable setting.
                if config.onlyShowIfActionable && !execution.wasActionable {
                    return
                }

                let controller = ResultPopupWindowController()
                self.resultPopupController = controller
                controller.showResult(execution, appState: self.appState)
            } catch {
                let failedExecution = PromptExecution(
                    promptId: config.id,
                    promptName: config.name,
                    result: error.localizedDescription,
                    wasActionable: true,
                    emailCount: 0,
                    wasShownToUser: false
                )
                self.appState.executionHistory.insert(failedExecution, at: 0)
                self.appState.saveExecutionHistory()
            }
        }
    }

    // MARK: - Notification Observers

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openSettings),
            name: Notification.Name("openSettings"),
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(closePopover),
            name: Notification.Name("closePopover"),
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openExecutionHistory),
            name: Notification.Name("openExecutionHistory"),
            object: nil
        )
    }

    // MARK: - Menu Bar Content

    /// Returns the content view for the menu bar extra scene.
    public func menuBarContentView() -> some View {
        MenuDropdownView()
            .environmentObject(appState)
    }

    // MARK: - Popover

    @objc func closePopover() {
        NSApp.keyWindow?.close()
    }

    // MARK: - Settings Window

    @objc func openSettings(_ notification: Notification) {
        // Update the selected tab if one was specified in userInfo
        if let tab = notification.userInfo?["tab"] as? SettingsTab {
            appState.selectedSettingsTab = tab
        }

        // Close the menu bar panel first
        NSApp.keyWindow?.close()

        // If the settings window already exists, bring it to front
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Create settings window
        let settingsView = SettingsView(
            selectedTab: Binding(
                get: { [weak appState] in appState?.selectedSettingsTab ?? .general },
                set: { [weak appState] in appState?.selectedSettingsTab = $0 }
            )
        )
        .environmentObject(appState)

        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "MailDroid Settings"
        window.styleMask = [.titled, .closable]
        window.setFrameAutosaveName("")
        window.setContentSize(NSSize(width: 500, height: 600))
        window.center()
        window.isReleasedWhenClosed = false

        settingsWindow = window

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Execution History Window

    @objc func openExecutionHistory(_ notification: Notification) {
        let promptId = notification.userInfo?["promptId"] as? String

        // If the history window already exists and no filter requested, bring it to front.
        if promptId == nil, let window = executionHistoryWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Close existing window when opening with a new filter.
        executionHistoryWindow?.close()
        executionHistoryWindow = nil

        let historyView = ExecutionHistoryView(initialPromptId: promptId)
            .environmentObject(appState)

        let hostingController = NSHostingController(rootView: historyView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Execution History"
        window.styleMask = [.titled, .closable, .resizable]
        window.setContentSize(NSSize(width: 560, height: 500))
        window.center()
        window.isReleasedWhenClosed = false

        executionHistoryWindow = window

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
