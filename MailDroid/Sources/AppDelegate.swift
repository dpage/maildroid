import SwiftUI
import AppKit

// MARK: - App Delegate

public class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var appState = AppState()
    var settingsWindow: NSWindow?
    var executionHistoryWindow: NSWindow?
    var resultPopupController: ResultPopupWindowController?

    public func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupNotificationObservers()

        // Hide dock icon - menu bar only app
        NSApp.setActivationPolicy(.accessory)
    }

    // MARK: - Menu Bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "envelope.badge.fill", accessibilityDescription: "MailDroid")
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover = NSPopover()
        popover?.contentSize = NSSize(width: 380, height: 450)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(
            rootView: MenuDropdownView()
                .environmentObject(appState)
        )
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

    // MARK: - Popover

    @objc func togglePopover() {
        guard let button = statusItem?.button, let popover = popover else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    @objc func closePopover() {
        popover?.performClose(nil)
    }

    // MARK: - Settings Window

    @objc func openSettings(_ notification: Notification) {
        // Update the selected tab if one was specified in userInfo
        if let tab = notification.userInfo?["tab"] as? SettingsTab {
            appState.selectedSettingsTab = tab
        }

        // Close the popover first
        popover?.performClose(nil)

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
