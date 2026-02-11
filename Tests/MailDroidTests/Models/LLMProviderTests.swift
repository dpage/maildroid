import XCTest
@testable import MailDroidLib

final class LLMProviderTypeTests: XCTestCase {

    override func tearDown() {
        TestDefaults.cleanUp()
        super.tearDown()
    }

    // MARK: - All Provider Types

    func testAllCasesExist() {
        let allCases = LLMProviderType.allCases
        XCTAssertEqual(allCases.count, 5)
        XCTAssertTrue(allCases.contains(.anthropic))
        XCTAssertTrue(allCases.contains(.openai))
        XCTAssertTrue(allCases.contains(.gemini))
        XCTAssertTrue(allCases.contains(.ollama))
        XCTAssertTrue(allCases.contains(.dockerModelRunner))
    }

    // MARK: - Raw Values

    func testRawValues() {
        XCTAssertEqual(LLMProviderType.anthropic.rawValue, "Anthropic")
        XCTAssertEqual(LLMProviderType.openai.rawValue, "OpenAI")
        XCTAssertEqual(LLMProviderType.gemini.rawValue, "Gemini")
        XCTAssertEqual(LLMProviderType.ollama.rawValue, "Ollama")
        XCTAssertEqual(LLMProviderType.dockerModelRunner.rawValue, "Docker Model Runner")
    }

    // MARK: - Default Base URLs

    func testDefaultBaseURLs() {
        XCTAssertEqual(
            LLMProviderType.anthropic.defaultBaseURL,
            "https://api.anthropic.com/v1"
        )
        XCTAssertEqual(
            LLMProviderType.openai.defaultBaseURL,
            "https://api.openai.com/v1"
        )
        XCTAssertEqual(
            LLMProviderType.gemini.defaultBaseURL,
            "https://generativelanguage.googleapis.com/v1beta"
        )
        XCTAssertEqual(
            LLMProviderType.ollama.defaultBaseURL,
            "http://localhost:11434/api"
        )
        XCTAssertEqual(
            LLMProviderType.dockerModelRunner.defaultBaseURL,
            "http://localhost:12434/engines/llama.cpp/v1"
        )
    }

    // MARK: - Default Models

    func testDefaultModels() {
        XCTAssertEqual(
            LLMProviderType.anthropic.defaultModel,
            "claude-sonnet-4-20250514"
        )
        XCTAssertEqual(LLMProviderType.openai.defaultModel, "gpt-4o")
        XCTAssertEqual(
            LLMProviderType.gemini.defaultModel,
            "gemini-2.0-flash"
        )
        XCTAssertEqual(LLMProviderType.ollama.defaultModel, "llama3.2")
        XCTAssertEqual(
            LLMProviderType.dockerModelRunner.defaultModel,
            "ai/gemma3"
        )
    }

    // MARK: - API Key Requirements

    func testRequiresAPIKeyForCloudProviders() {
        XCTAssertTrue(LLMProviderType.anthropic.requiresAPIKey)
        XCTAssertTrue(LLMProviderType.openai.requiresAPIKey)
        XCTAssertTrue(LLMProviderType.gemini.requiresAPIKey)
    }

    func testDoesNotRequireAPIKeyForLocalProviders() {
        XCTAssertFalse(LLMProviderType.ollama.requiresAPIKey)
        XCTAssertFalse(LLMProviderType.dockerModelRunner.requiresAPIKey)
    }
}

// MARK: - LLMConfig Tests

final class LLMConfigTests: XCTestCase {

    override func tearDown() {
        TestDefaults.cleanUp()
        super.tearDown()
    }

    // MARK: - Initialization

    func testDefaultInit() {
        let config = LLMConfig()
        XCTAssertEqual(config.provider, .anthropic)
        XCTAssertEqual(config.apiKey, "")
        XCTAssertEqual(config.baseURL, LLMProviderType.anthropic.defaultBaseURL)
        XCTAssertEqual(config.model, LLMProviderType.anthropic.defaultModel)
    }

    func testInitWithProvider() {
        let config = LLMConfig(provider: .openai, apiKey: "sk-key")
        XCTAssertEqual(config.provider, .openai)
        XCTAssertEqual(config.apiKey, "sk-key")
        XCTAssertEqual(config.baseURL, LLMProviderType.openai.defaultBaseURL)
        XCTAssertEqual(config.model, LLMProviderType.openai.defaultModel)
    }

    func testInitWithCustomBaseURL() {
        let config = LLMConfig(
            provider: .openai,
            baseURL: "https://custom.api.com/v1"
        )
        XCTAssertEqual(config.baseURL, "https://custom.api.com/v1")
    }

    func testInitWithCustomModel() {
        let config = LLMConfig(provider: .anthropic, model: "custom-model")
        XCTAssertEqual(config.model, "custom-model")
    }

    // MARK: - Persistence

    func testSaveAndLoad() {
        let config = LLMConfig(
            provider: .gemini,
            apiKey: "gemini-key-123",
            model: "gemini-1.5-pro"
        )
        config.save()

        let loaded = LLMConfig.load()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.provider, .gemini)
        XCTAssertEqual(loaded?.model, "gemini-1.5-pro")
        XCTAssertEqual(loaded?.apiKey, "gemini-key-123")
    }

    func testLoadReturnsNilWhenNoData() {
        UserDefaults.standard.removeObject(forKey: "maildroid.llmConfig")
        let loaded = LLMConfig.load()
        XCTAssertNil(loaded)
    }

    func testSaveStoresAPIKeyInKeychainNotUserDefaults() {
        let config = LLMConfig(
            provider: .anthropic,
            apiKey: "secret-anthropic-key"
        )
        config.save()

        // Read raw data from UserDefaults.
        guard let data = UserDefaults.standard.data(forKey: "maildroid.llmConfig"),
              let decoded = try? JSONDecoder().decode(LLMConfig.self, from: data) else {
            XCTFail("Expected config data in UserDefaults.")
            return
        }
        XCTAssertTrue(
            decoded.apiKey.isEmpty,
            "The API key should not be stored in UserDefaults."
        )

        // Verify the key is in the Keychain (UserDefaults for this app).
        let storedKey = KeychainHelper.loadLLMAPIKey(provider: "Anthropic")
        XCTAssertEqual(storedKey, "secret-anthropic-key")
    }

    // MARK: - Equatable

    func testEquatable() {
        let a = LLMConfig(provider: .anthropic, apiKey: "key")
        let b = LLMConfig(provider: .anthropic, apiKey: "key")
        XCTAssertEqual(a, b)

        let c = LLMConfig(provider: .openai, apiKey: "key")
        XCTAssertNotEqual(a, c)
    }

    // MARK: - Codable

    func testCodableRoundTrip() throws {
        let original = LLMConfig(
            provider: .ollama,
            apiKey: "",
            baseURL: "http://localhost:11434/api",
            model: "llama3.2"
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(LLMConfig.self, from: data)
        XCTAssertEqual(decoded, original)
    }
}
