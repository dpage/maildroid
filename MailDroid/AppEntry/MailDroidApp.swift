import SwiftUI
import MailDroidLib

// MARK: - App Entry Point

@main
struct MailDroidApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("MailDroid", systemImage: "envelope.badge.fill") {
            appDelegate.menuBarContentView()
        }
        .menuBarExtraStyle(.window)
    }
}
