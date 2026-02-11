import Foundation

/// Errors that can occur during LLM API interactions.
enum LLMError: Error, LocalizedError {
    case apiError(statusCode: Int, message: String)
    case networkError(underlying: Error)
    case invalidResponse
    case modelNotFound(String)
    case rateLimited
    case missingAPIKey(provider: String)

    var errorDescription: String? {
        switch self {
        case .apiError(let statusCode, let message):
            return "API error (\(statusCode)): \(message)"
        case .networkError(let underlying):
            return "Network error: \(underlying.localizedDescription)"
        case .invalidResponse:
            return "The provider returned an invalid response."
        case .modelNotFound(let model):
            return "Model not found: \(model)"
        case .rateLimited:
            return "Rate limit exceeded. Please try again later."
        case .missingAPIKey(let provider):
            return "API key is required for \(provider). Configure it in Settings → LLM Provider."
        }
    }
}

/// A unified service that sends prompts to any supported LLM provider.
struct LLMService {

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Public API

    /// Sends a prompt to the configured LLM provider and returns the
    /// text response.
    func sendPrompt(
        config: LLMConfig,
        systemPrompt: String,
        userContent: String
    ) async throws -> String {
        if config.provider.requiresAPIKey && config.apiKey.isEmpty {
            throw LLMError.missingAPIKey(provider: config.provider.rawValue)
        }

        switch config.provider {
        case .anthropic:
            return try await sendAnthropic(
                config: config,
                systemPrompt: systemPrompt,
                userContent: userContent
            )
        case .openai:
            return try await sendOpenAI(
                config: config,
                systemPrompt: systemPrompt,
                userContent: userContent
            )
        case .gemini:
            return try await sendGemini(
                config: config,
                systemPrompt: systemPrompt,
                userContent: userContent
            )
        case .ollama:
            return try await sendOllama(
                config: config,
                systemPrompt: systemPrompt,
                userContent: userContent
            )
        case .dockerModelRunner:
            return try await sendDockerModelRunner(
                config: config,
                systemPrompt: systemPrompt,
                userContent: userContent
            )
        }
    }

    /// Fetches the list of available models for the given provider.
    func fetchAvailableModels(
        config: LLMConfig
    ) async throws -> [String] {
        switch config.provider {
        case .ollama:
            return try await fetchOllamaModels(config: config)
        case .dockerModelRunner:
            return try await fetchDockerModels(config: config)
        case .anthropic:
            return [
                "claude-sonnet-4-20250514",
                "claude-opus-4-20250514",
                "claude-haiku-4-20250514",
                "claude-3-5-sonnet-20241022",
                "claude-3-5-haiku-20241022"
            ]
        case .openai:
            return [
                "gpt-4o",
                "gpt-4o-mini",
                "gpt-4-turbo",
                "o1",
                "o1-mini",
                "o3-mini"
            ]
        case .gemini:
            return [
                "gemini-2.0-flash",
                "gemini-2.0-flash-lite",
                "gemini-1.5-pro",
                "gemini-1.5-flash"
            ]
        }
    }

    // MARK: - Anthropic

    private func sendAnthropic(
        config: LLMConfig,
        systemPrompt: String,
        userContent: String
    ) async throws -> String {
        let url = URL(string: "\(config.baseURL)/messages")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(
            "2023-06-01",
            forHTTPHeaderField: "anthropic-version"
        )

        let body: [String: Any] = [
            "model": config.model,
            "max_tokens": 4096,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userContent]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let json = try await performRequest(request)

        guard let content = json["content"] as? [[String: Any]],
              let first = content.first,
              let text = first["text"] as? String else {
            throw LLMError.invalidResponse
        }

        return text
    }

    // MARK: - OpenAI

    private func sendOpenAI(
        config: LLMConfig,
        systemPrompt: String,
        userContent: String
    ) async throws -> String {
        let url = URL(string: "\(config.baseURL)/chat/completions")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(
            "Bearer \(config.apiKey)",
            forHTTPHeaderField: "Authorization"
        )

        let body: [String: Any] = [
            "model": config.model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userContent]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let json = try await performRequest(request)
        return try extractOpenAIContent(from: json)
    }

    // MARK: - Gemini

    private func sendGemini(
        config: LLMConfig,
        systemPrompt: String,
        userContent: String
    ) async throws -> String {
        var components = URLComponents(
            string: "\(config.baseURL)/models/\(config.model):generateContent"
        )!
        components.queryItems = [URLQueryItem(name: "key", value: config.apiKey)]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "system_instruction": [
                "parts": [["text": systemPrompt]]
            ],
            "contents": [
                [
                    "role": "user",
                    "parts": [["text": userContent]]
                ]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let json = try await performRequest(request)

        guard let candidates = json["candidates"] as? [[String: Any]],
              let first = candidates.first,
              let content = first["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw LLMError.invalidResponse
        }

        return text
    }

    // MARK: - Ollama

    private func sendOllama(
        config: LLMConfig,
        systemPrompt: String,
        userContent: String
    ) async throws -> String {
        let url = URL(string: "\(config.baseURL)/chat")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": config.model,
            "stream": false,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userContent]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let json = try await performRequest(request)

        guard let message = json["message"] as? [String: Any],
              let text = message["content"] as? String else {
            throw LLMError.invalidResponse
        }

        return text
    }

    // MARK: - Docker Model Runner

    private func sendDockerModelRunner(
        config: LLMConfig,
        systemPrompt: String,
        userContent: String
    ) async throws -> String {
        let url = URL(string: "\(config.baseURL)/chat/completions")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": config.model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userContent]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let json = try await performRequest(request)
        return try extractOpenAIContent(from: json)
    }

    // MARK: - Model Listing

    private func fetchOllamaModels(
        config: LLMConfig
    ) async throws -> [String] {
        let url = URL(string: "\(config.baseURL)/tags")!
        let request = URLRequest(url: url)

        let json = try await performRequest(request)

        guard let models = json["models"] as? [[String: Any]] else {
            throw LLMError.invalidResponse
        }

        return models.compactMap { $0["name"] as? String }
    }

    private func fetchDockerModels(
        config: LLMConfig
    ) async throws -> [String] {
        let url = URL(string: "\(config.baseURL)/models")!
        let request = URLRequest(url: url)

        let json = try await performRequest(request)

        guard let data = json["data"] as? [[String: Any]] else {
            throw LLMError.invalidResponse
        }

        return data.compactMap { $0["id"] as? String }
    }

    // MARK: - Shared Helpers

    /// Performs an HTTP request and returns the parsed JSON dictionary.
    private func performRequest(
        _ request: URLRequest
    ) async throws -> [String: Any] {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw LLMError.networkError(underlying: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }

        if httpResponse.statusCode == 429 {
            throw LLMError.rateLimited
        }

        guard let json = try? JSONSerialization.jsonObject(
            with: data
        ) as? [String: Any] else {
            throw LLMError.invalidResponse
        }

        if httpResponse.statusCode == 404 {
            let message = extractErrorMessage(from: json)
            throw LLMError.modelNotFound(message)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = extractErrorMessage(from: json)
            throw LLMError.apiError(
                statusCode: httpResponse.statusCode,
                message: message
            )
        }

        return json
    }

    /// Extracts the assistant message content from an OpenAI-compatible
    /// response format used by both OpenAI and Docker Model Runner.
    private func extractOpenAIContent(
        from json: [String: Any]
    ) throws -> String {
        guard let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw LLMError.invalidResponse
        }

        return content
    }

    /// Extracts a human-readable error message from an API error
    /// response body.
    private func extractErrorMessage(
        from json: [String: Any]
    ) -> String {
        // Anthropic and OpenAI use { "error": { "message": "..." } }.
        if let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            return message
        }

        // Some providers return a top-level "error" string.
        if let message = json["error"] as? String {
            return message
        }

        // Gemini uses { "error": { "status": "...", "message": "..." } }.
        if let error = json["error"] as? [String: Any],
           let status = error["status"] as? String {
            return status
        }

        return "Unknown error"
    }
}
