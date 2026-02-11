import Foundation

enum LLMProviderType: String, Codable, CaseIterable {
    case anthropic = "Anthropic"
    case openai = "OpenAI"
    case gemini = "Gemini"
    case ollama = "Ollama"
    case dockerModelRunner = "Docker Model Runner"

    var defaultBaseURL: String {
        switch self {
        case .anthropic:
            return "https://api.anthropic.com/v1"
        case .openai:
            return "https://api.openai.com/v1"
        case .gemini:
            return "https://generativelanguage.googleapis.com/v1beta"
        case .ollama:
            return "http://localhost:11434/api"
        case .dockerModelRunner:
            return "http://localhost:12434/engines/llama.cpp/v1"
        }
    }

    var defaultModel: String {
        switch self {
        case .anthropic:
            return "claude-sonnet-4-20250514"
        case .openai:
            return "gpt-4o"
        case .gemini:
            return "gemini-2.0-flash"
        case .ollama:
            return "llama3.2"
        case .dockerModelRunner:
            return "ai/gemma3"
        }
    }

    var requiresAPIKey: Bool {
        switch self {
        case .anthropic, .openai, .gemini:
            return true
        case .ollama, .dockerModelRunner:
            return false
        }
    }
}

struct LLMConfig: Codable, Equatable {
    var provider: LLMProviderType
    var apiKey: String
    var baseURL: String
    var model: String

    init(
        provider: LLMProviderType = .anthropic,
        apiKey: String = "",
        baseURL: String? = nil,
        model: String? = nil
    ) {
        self.provider = provider
        self.apiKey = apiKey
        self.baseURL = baseURL ?? provider.defaultBaseURL
        self.model = model ?? provider.defaultModel
    }

    // MARK: - Persistence

    private static let configKey = "maildroid.llmConfig"

    static func load() -> LLMConfig? {
        guard let data = UserDefaults.standard.data(forKey: configKey),
              var config = try? JSONDecoder().decode(LLMConfig.self, from: data) else {
            return nil
        }

        // Load the API key from the Keychain.
        if let storedKey = KeychainHelper.loadLLMAPIKey(provider: config.provider.rawValue) {
            config.apiKey = storedKey
        }

        return config
    }

    func save() {
        // Save the API key to the Keychain separately.
        if !apiKey.isEmpty {
            KeychainHelper.saveLLMAPIKey(apiKey, provider: provider.rawValue)
        }

        // Save the config without the API key to UserDefaults.
        var configToSave = self
        configToSave.apiKey = ""

        if let data = try? JSONEncoder().encode(configToSave) {
            UserDefaults.standard.set(data, forKey: Self.configKey)
        }
    }
}
