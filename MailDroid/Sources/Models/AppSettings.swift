import Foundation

struct AppSettings: Codable, Equatable {
    var launchAtLogin: Bool
    var playSound: Bool
    var llmConfig: LLMConfig?

    init() {
        self.launchAtLogin = false
        self.playSound = true
        self.llmConfig = nil
    }

    // MARK: - Persistence

    private static let settingsKey = "maildroid.settings"

    static func load() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: settingsKey),
              var settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings()
        }

        // Load the LLM config with its API key from the Keychain.
        settings.llmConfig = LLMConfig.load()

        return settings
    }

    func save() {
        // Save the LLM config separately so the API key goes to the Keychain.
        llmConfig?.save()

        // Save the settings without the LLM API key to UserDefaults.
        var settingsToSave = self
        settingsToSave.llmConfig?.apiKey = ""

        if let data = try? JSONEncoder().encode(settingsToSave) {
            UserDefaults.standard.set(data, forKey: Self.settingsKey)
        }
    }
}
