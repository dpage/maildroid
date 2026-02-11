import Foundation

struct PromptExecution: Identifiable, Codable {
    let id: String
    let promptId: String
    let promptName: String
    let timestamp: Date
    let result: String
    let wasActionable: Bool
    let emailCount: Int
    let wasShownToUser: Bool

    init(
        id: String = UUID().uuidString,
        promptId: String,
        promptName: String,
        timestamp: Date = Date(),
        result: String,
        wasActionable: Bool,
        emailCount: Int,
        wasShownToUser: Bool = false
    ) {
        self.id = id
        self.promptId = promptId
        self.promptName = promptName
        self.timestamp = timestamp
        self.result = result
        self.wasActionable = wasActionable
        self.emailCount = emailCount
        self.wasShownToUser = wasShownToUser
    }

    // MARK: - Persistence

    private static let executionsKey = "maildroid.promptExecutions"
    private static let maxStoredExecutions = 100

    static func loadAll() -> [PromptExecution] {
        guard let data = UserDefaults.standard.data(forKey: executionsKey),
              let executions = try? JSONDecoder().decode([PromptExecution].self, from: data) else {
            return []
        }
        return executions
    }

    static func saveAll(_ executions: [PromptExecution]) {
        // Keep only the most recent executions to avoid unbounded storage growth.
        let trimmed = Array(executions.prefix(maxStoredExecutions))

        if let data = try? JSONEncoder().encode(trimmed) {
            UserDefaults.standard.set(data, forKey: executionsKey)
        }
    }

    static func append(_ execution: PromptExecution) {
        var executions = loadAll()
        executions.insert(execution, at: 0)
        saveAll(executions)
    }

    static func loadExecutions(for promptId: String) -> [PromptExecution] {
        return loadAll().filter { $0.promptId == promptId }
    }
}
