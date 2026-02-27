import AppKit

/// Generates a Markdown report from a PromptExecution and saves it via NSSavePanel.
enum ReportExporter {

    /// Builds a Markdown string from the given execution.
    static func markdownReport(for execution: PromptExecution) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let formattedTimestamp = formatter.string(from: execution.timestamp)

        return """
        # \(execution.promptName)

        - **Executed:** \(formattedTimestamp)
        - **Emails analysed:** \(execution.emailCount)

        ---

        \(execution.result)
        """
    }

    /// Presents an NSSavePanel and writes the Markdown report to the chosen location.
    @MainActor
    static func saveReport(for execution: PromptExecution) async {
        let panel = NSSavePanel()
        panel.title = "Save Execution Report"
        panel.allowedContentTypes = [.init(filenameExtension: "md")!]
        panel.nameFieldStringValue = defaultFilename(for: execution)
        panel.canCreateDirectories = true

        let response = await panel.beginSheetModal(
            for: NSApp.keyWindow ?? NSApp.mainWindow ?? NSWindow()
        )

        guard response == .OK, let url = panel.url else { return }

        let markdown = markdownReport(for: execution)
        do {
            try markdown.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Failed to save report"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.runModal()
        }
    }

    // MARK: - Private

    private static func defaultFilename(for execution: PromptExecution) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        let timestamp = formatter.string(from: execution.timestamp)
        let safeName = execution.promptName
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "/", with: "-")
        return "\(safeName)-\(timestamp).md"
    }
}
