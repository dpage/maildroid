import AppKit
import SwiftUI

class ResultPopupWindowController {
    private var window: NSWindow?

    func showResult(_ execution: PromptExecution, appState: AppState) {
        // Close any existing popup window before showing a new one.
        dismiss()

        let popupView = ResultPopupView(
            execution: execution,
            onViewHistory: {
                NSApp.keyWindow?.close()
                NotificationCenter.default.post(
                    name: Notification.Name("openExecutionHistory"),
                    object: nil,
                    userInfo: ["promptId": execution.promptId]
                )
            }
        )

        let hostingController = NSHostingController(rootView: popupView)

        let window = NSWindow(contentViewController: hostingController)
        window.styleMask = [.titled, .closable, .resizable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.level = .normal
        window.collectionBehavior = [.fullScreenAuxiliary]
        window.isReleasedWhenClosed = false

        window.setFrameAutosaveName("ResultPopupWindow")
        if !window.setFrameUsingName("ResultPopupWindow") {
            window.setContentSize(NSSize(width: 500, height: 550))
            window.center()
        }

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Play a notification sound when the popup appears.
        if appState.appSettings.playSound {
            NSSound(named: "Glass")?.play()
        }

        self.window = window
    }

    func dismiss() {
        window?.close()
        window = nil
    }
}
