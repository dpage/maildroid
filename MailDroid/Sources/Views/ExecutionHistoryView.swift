import SwiftUI

struct ExecutionHistoryView: View {
    @EnvironmentObject var appState: AppState

    /// An optional prompt ID used to pre-filter the history view.
    var initialPromptId: String?

    @State private var filterPromptName: String = ""
    @State private var expandedExecutionId: String?
    @State private var didApplyInitialFilter = false

    private var allPromptNames: [String] {
        var names = Set(appState.promptConfigs.map { $0.name })
        names.formUnion(appState.executionHistory.map { $0.promptName })
        return Array(names).sorted()
    }

    private var filteredExecutions: [PromptExecution] {
        if filterPromptName.isEmpty {
            return appState.executionHistory
        }
        return appState.executionHistory.filter { $0.promptName == filterPromptName }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Execution History")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                if !filteredExecutions.isEmpty {
                    Button(role: .destructive) {
                        if filterPromptName.isEmpty {
                            appState.executionHistory.removeAll()
                        } else {
                            appState.executionHistory.removeAll { $0.promptName == filterPromptName }
                        }
                        appState.saveExecutionHistory()
                    } label: {
                        Text("Clear All")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            // Filter picker
            if !allPromptNames.isEmpty {
                HStack {
                    Text("Filter:")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Picker("", selection: $filterPromptName) {
                        Text("All Prompts").tag("")
                        ForEach(allPromptNames, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .controlSize(.small)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }

            Divider()

            // Execution list
            if filteredExecutions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No history available")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(filteredExecutions) { execution in
                            ExecutionRow(
                                execution: execution,
                                isExpanded: expandedExecutionId == execution.id,
                                onToggle: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        if expandedExecutionId == execution.id {
                                            expandedExecutionId = nil
                                        } else {
                                            expandedExecutionId = execution.id
                                        }
                                    }
                                },
                                onDelete: {
                                    deleteExecution(execution)
                                }
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(minWidth: 480, minHeight: 400)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            guard !didApplyInitialFilter, let promptId = initialPromptId else { return }
            didApplyInitialFilter = true
            if let name = appState.executionHistory.first(
                where: { $0.promptId == promptId }
            )?.promptName {
                filterPromptName = name
            }
        }
    }

    private func deleteExecution(_ execution: PromptExecution) {
        appState.executionHistory.removeAll { $0.id == execution.id }
        appState.saveExecutionHistory()

        if expandedExecutionId == execution.id {
            expandedExecutionId = nil
        }
    }
}

// MARK: - Execution Row

struct ExecutionRow: View {
    let execution: PromptExecution
    let isExpanded: Bool
    let onToggle: () -> Void
    let onDelete: () -> Void

    private var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: execution.timestamp)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Summary row
            HStack(spacing: 12) {
                // Actionable status indicator
                Circle()
                    .fill(execution.wasActionable ? Color.orange : Color.green)
                    .frame(width: 10, height: 10)
                    .help(execution.wasActionable ? "Actionable" : "No action needed")

                VStack(alignment: .leading, spacing: 2) {
                    Text(execution.promptName)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        Text(formattedTimestamp)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text("\(execution.emailCount) email\(execution.emailCount == 1 ? "" : "s")")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Delete this execution")

                // Expand/collapse chevron
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .onTapGesture(perform: onToggle)

            // Expanded result content
            if isExpanded {
                Divider()
                    .padding(.leading, 42)

                MarkdownTextView(markdown: execution.result, baseFontSize: 13)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 42)
                    .padding(.vertical, 12)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
