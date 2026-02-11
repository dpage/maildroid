import SwiftUI

struct ProviderSetupView: View {
    @EnvironmentObject var appState: AppState

    @State private var providerType: LLMProviderType
    @State private var apiKey: String
    @State private var baseURL: String
    @State private var model: String
    @State private var availableModels: [String] = []
    @State private var isFetchingModels = false
    @State private var isTesting = false
    @State private var testResult: TestResult?
    @State private var fetchError: String?

    init() {
        let config = LLMConfig.load()
        _providerType = State(initialValue: config?.provider ?? .anthropic)
        _apiKey = State(initialValue: config?.apiKey ?? "")
        _baseURL = State(initialValue: config?.baseURL ?? LLMProviderType.anthropic.defaultBaseURL)
        _model = State(initialValue: config?.model ?? LLMProviderType.anthropic.defaultModel)
    }

    var body: some View {
        Form {
            Section {
                Picker("Provider", selection: $providerType) {
                    ForEach(LLMProviderType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .onChange(of: providerType) { newProvider in
                    baseURL = newProvider.defaultBaseURL
                    model = newProvider.defaultModel
                    availableModels = []
                    testResult = nil
                    fetchError = nil

                    // Clear API key when switching to a provider that
                    // does not require one.
                    if !newProvider.requiresAPIKey {
                        apiKey = ""
                    }
                }
            } header: {
                Text("Provider")
            }

            // API key section (only for cloud providers)
            if providerType.requiresAPIKey {
                Section {
                    SecureField("API Key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                } header: {
                    Text("Authentication")
                }
            }

            Section {
                TextField("Base URL", text: $baseURL)
                    .textFieldStyle(.roundedBorder)

                Button("Reset to Default") {
                    baseURL = providerType.defaultBaseURL
                }
                .font(.system(size: 12))
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            } header: {
                Text("Endpoint")
            }

            Section {
                HStack {
                    TextField("Model", text: $model)
                        .textFieldStyle(.roundedBorder)

                    Button(action: fetchModels) {
                        if isFetchingModels {
                            ProgressView()
                                .scaleEffect(0.6)
                                .frame(width: 16, height: 16)
                        } else {
                            Text("Fetch Models")
                        }
                    }
                    .disabled(isFetchingModels)
                }

                if !availableModels.isEmpty {
                    Picker("Available Models", selection: $model) {
                        ForEach(availableModels, id: \.self) { modelName in
                            Text(modelName).tag(modelName)
                        }
                    }
                }

                if let fetchError = fetchError {
                    Text(fetchError)
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                }
            } header: {
                Text("Model")
            }

            Section {
                HStack {
                    Button("Test Connection") {
                        testConnection()
                    }
                    .disabled(isTesting || !isConfigValid)

                    if isTesting {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 16, height: 16)
                    }

                    Spacer()

                    Button("Save") {
                        saveConfig()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isConfigValid)
                }

                if let testResult = testResult {
                    HStack(spacing: 6) {
                        Image(
                            systemName: testResult.success
                                ? "checkmark.circle.fill"
                                : "xmark.circle.fill"
                        )
                        .foregroundColor(testResult.success ? .green : .red)

                        Text(testResult.message)
                            .font(.system(size: 12))
                            .foregroundColor(
                                testResult.success ? .green : .red
                            )
                    }
                }
            } header: {
                Text("Actions")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Computed Properties

    private var isConfigValid: Bool {
        if providerType.requiresAPIKey && apiKey.isEmpty {
            return false
        }
        if baseURL.isEmpty || model.isEmpty {
            return false
        }
        return true
    }

    private var currentConfig: LLMConfig {
        LLMConfig(
            provider: providerType,
            apiKey: apiKey,
            baseURL: baseURL,
            model: model
        )
    }

    // MARK: - Actions

    private func fetchModels() {
        isFetchingModels = true
        fetchError = nil

        Task {
            do {
                let service = LLMService()
                let models = try await service.fetchAvailableModels(
                    config: currentConfig
                )

                await MainActor.run {
                    availableModels = models
                    isFetchingModels = false

                    // Auto-select the first model if the current one
                    // is not in the list.
                    if !models.contains(model), let first = models.first {
                        model = first
                    }
                }
            } catch {
                await MainActor.run {
                    fetchError = error.localizedDescription
                    isFetchingModels = false
                }
            }
        }
    }

    private func testConnection() {
        isTesting = true
        testResult = nil

        Task {
            do {
                let service = LLMService()
                let response = try await service.sendPrompt(
                    config: currentConfig,
                    systemPrompt: "You are a test assistant.",
                    userContent: "Reply with exactly: Connection successful"
                )

                await MainActor.run {
                    isTesting = false
                    testResult = TestResult(
                        success: true,
                        message: "Connected successfully. Response: \(String(response.prefix(80)))"
                    )
                }
            } catch {
                await MainActor.run {
                    isTesting = false
                    testResult = TestResult(
                        success: false,
                        message: error.localizedDescription
                    )
                }
            }
        }
    }

    private func saveConfig() {
        let config = currentConfig
        config.save()
        appState.appSettings.llmConfig = config
        appState.saveSettings()
    }
}

// MARK: - Test Result

private struct TestResult {
    let success: Bool
    let message: String
}

#Preview {
    ProviderSetupView()
        .environmentObject(AppState())
}
