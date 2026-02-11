import XCTest
@testable import MailDroidLib

final class LLMServiceTests: XCTestCase {

    // MARK: - Missing API Key Validation

    func testSendPromptThrowsMissingAPIKeyForAnthropic() async {
        let config = LLMConfig(provider: .anthropic, apiKey: "")
        let service = LLMService()

        do {
            _ = try await service.sendPrompt(
                config: config,
                systemPrompt: "System",
                userContent: "User"
            )
            XCTFail("Expected missingAPIKey error.")
        } catch let error as LLMError {
            if case .missingAPIKey(let provider) = error {
                XCTAssertEqual(provider, "Anthropic")
            } else {
                XCTFail("Expected missingAPIKey error, got \(error).")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testSendPromptThrowsMissingAPIKeyForOpenAI() async {
        let config = LLMConfig(provider: .openai, apiKey: "")
        let service = LLMService()

        do {
            _ = try await service.sendPrompt(
                config: config,
                systemPrompt: "System",
                userContent: "User"
            )
            XCTFail("Expected missingAPIKey error.")
        } catch let error as LLMError {
            if case .missingAPIKey(let provider) = error {
                XCTAssertEqual(provider, "OpenAI")
            } else {
                XCTFail("Expected missingAPIKey error, got \(error).")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testSendPromptThrowsMissingAPIKeyForGemini() async {
        let config = LLMConfig(provider: .gemini, apiKey: "")
        let service = LLMService()

        do {
            _ = try await service.sendPrompt(
                config: config,
                systemPrompt: "System",
                userContent: "User"
            )
            XCTFail("Expected missingAPIKey error.")
        } catch let error as LLMError {
            if case .missingAPIKey(let provider) = error {
                XCTAssertEqual(provider, "Gemini")
            } else {
                XCTFail("Expected missingAPIKey error, got \(error).")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testSendPromptDoesNotThrowMissingAPIKeyForOllama() async {
        // Ollama does not require an API key. We verify this without
        // making a real network call to avoid test flakiness.
        let config = LLMConfig(provider: .ollama, apiKey: "")
        XCTAssertFalse(
            config.provider.requiresAPIKey,
            "Ollama should not require an API key."
        )
    }

    func testSendPromptDoesNotThrowMissingAPIKeyForDocker() async {
        // Docker Model Runner does not require an API key, so the
        // provider's requiresAPIKey property should be false.
        // We verify this without making a real network call.
        let config = LLMConfig(provider: .dockerModelRunner, apiKey: "")
        XCTAssertFalse(
            config.provider.requiresAPIKey,
            "Docker Model Runner should not require an API key."
        )
    }

    // MARK: - Available Models (Static Lists)

    func testFetchAvailableModelsAnthropic() async throws {
        let config = LLMConfig(provider: .anthropic)
        let service = LLMService()
        let models = try await service.fetchAvailableModels(config: config)
        XCTAssertFalse(models.isEmpty)
        XCTAssertTrue(models.contains("claude-sonnet-4-20250514"))
    }

    func testFetchAvailableModelsOpenAI() async throws {
        let config = LLMConfig(provider: .openai)
        let service = LLMService()
        let models = try await service.fetchAvailableModels(config: config)
        XCTAssertFalse(models.isEmpty)
        XCTAssertTrue(models.contains("gpt-4o"))
    }

    func testFetchAvailableModelsGemini() async throws {
        let config = LLMConfig(provider: .gemini)
        let service = LLMService()
        let models = try await service.fetchAvailableModels(config: config)
        XCTAssertFalse(models.isEmpty)
        XCTAssertTrue(models.contains("gemini-2.0-flash"))
    }

    // MARK: - LLMError Descriptions

    func testLLMErrorDescriptions() {
        let errors: [LLMError] = [
            .apiError(statusCode: 500, message: "Server error"),
            .networkError(underlying: NSError(domain: "test", code: -1)),
            .invalidResponse,
            .modelNotFound("gpt-5"),
            .rateLimited,
            .missingAPIKey(provider: "TestProvider")
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Error \(error) should have a description.")
        }
    }

    func testAPIErrorDescription() {
        let error = LLMError.apiError(statusCode: 403, message: "Forbidden")
        XCTAssertTrue(error.errorDescription?.contains("403") ?? false)
        XCTAssertTrue(error.errorDescription?.contains("Forbidden") ?? false)
    }

    func testMissingAPIKeyDescription() {
        let error = LLMError.missingAPIKey(provider: "Anthropic")
        XCTAssertTrue(error.errorDescription?.contains("Anthropic") ?? false)
    }

    // MARK: - URLSession Injection

    func testCustomSessionIsUsed() {
        let config = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: config)
        let service = LLMService(session: session)
        // This just verifies the service can be constructed with a custom session.
        XCTAssertNotNil(service)
    }
}
