import XCTest
@testable import MailDroidLib

final class PromptExecutionTests: XCTestCase {

    override func tearDown() {
        TestDefaults.cleanUp()
        super.tearDown()
    }

    // MARK: - Initialization

    func testInitWithDefaults() {
        let execution = PromptExecution(
            promptId: "p1",
            promptName: "Test",
            result: "Some result",
            wasActionable: true,
            emailCount: 5
        )

        XCTAssertFalse(execution.id.isEmpty)
        XCTAssertEqual(execution.promptId, "p1")
        XCTAssertEqual(execution.promptName, "Test")
        XCTAssertEqual(execution.result, "Some result")
        XCTAssertTrue(execution.wasActionable)
        XCTAssertEqual(execution.emailCount, 5)
        XCTAssertFalse(execution.wasShownToUser)
    }

    func testInitWithAllParameters() {
        let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
        let execution = PromptExecution(
            id: "exec-1",
            promptId: "p1",
            promptName: "Morning Check",
            timestamp: timestamp,
            result: "Nothing urgent.",
            wasActionable: false,
            emailCount: 10,
            wasShownToUser: true
        )

        XCTAssertEqual(execution.id, "exec-1")
        XCTAssertEqual(execution.timestamp, timestamp)
        XCTAssertFalse(execution.wasActionable)
        XCTAssertTrue(execution.wasShownToUser)
    }

    // MARK: - wasShownToUser Tracking

    func testDefaultWasShownToUserIsFalse() {
        let execution = PromptExecution(
            promptId: "p1",
            promptName: "Test",
            result: "Result",
            wasActionable: true,
            emailCount: 1
        )
        XCTAssertFalse(execution.wasShownToUser)
    }

    func testWasShownToUserCanBeSetToTrue() {
        let execution = PromptExecution(
            promptId: "p1",
            promptName: "Test",
            result: "Result",
            wasActionable: true,
            emailCount: 1,
            wasShownToUser: true
        )
        XCTAssertTrue(execution.wasShownToUser)
    }

    // MARK: - wasActionable

    func testWasActionableTrue() {
        let execution = PromptExecution(
            promptId: "p1",
            promptName: "Test",
            result: "Urgent items found.",
            wasActionable: true,
            emailCount: 3
        )
        XCTAssertTrue(execution.wasActionable)
    }

    func testWasActionableFalse() {
        let execution = PromptExecution(
            promptId: "p1",
            promptName: "Test",
            result: "Nothing to act on.",
            wasActionable: false,
            emailCount: 3
        )
        XCTAssertFalse(execution.wasActionable)
    }

    // MARK: - Persistence

    func testSaveAllAndLoadAll() {
        let executions = [
            PromptExecution(
                id: "e1",
                promptId: "p1",
                promptName: "First",
                result: "Result 1",
                wasActionable: true,
                emailCount: 5
            ),
            PromptExecution(
                id: "e2",
                promptId: "p2",
                promptName: "Second",
                result: "Result 2",
                wasActionable: false,
                emailCount: 3
            )
        ]

        PromptExecution.saveAll(executions)

        let loaded = PromptExecution.loadAll()
        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded[0].id, "e1")
        XCTAssertEqual(loaded[1].id, "e2")
    }

    func testLoadAllReturnsEmptyWhenNoData() {
        UserDefaults.standard.removeObject(forKey: "maildroid.promptExecutions")
        let loaded = PromptExecution.loadAll()
        XCTAssertTrue(loaded.isEmpty)
    }

    func testAppendInsertsAtFront() {
        let first = PromptExecution(
            id: "first",
            promptId: "p1",
            promptName: "First",
            result: "R1",
            wasActionable: true,
            emailCount: 1
        )
        PromptExecution.saveAll([first])

        let second = PromptExecution(
            id: "second",
            promptId: "p2",
            promptName: "Second",
            result: "R2",
            wasActionable: false,
            emailCount: 2
        )
        PromptExecution.append(second)

        let loaded = PromptExecution.loadAll()
        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded[0].id, "second", "Newest execution should be first.")
    }

    func testSaveAllTrimsToMaxStoredExecutions() {
        // Create 110 executions; only 100 should be stored.
        var executions: [PromptExecution] = []
        for i in 0..<110 {
            executions.append(
                PromptExecution(
                    id: "e\(i)",
                    promptId: "p1",
                    promptName: "Bulk",
                    result: "Result \(i)",
                    wasActionable: false,
                    emailCount: 0
                )
            )
        }

        PromptExecution.saveAll(executions)

        let loaded = PromptExecution.loadAll()
        XCTAssertEqual(loaded.count, 100)
        XCTAssertEqual(loaded[0].id, "e0", "The first 100 should be preserved.")
    }

    func testLoadExecutionsForPromptId() {
        let executions = [
            PromptExecution(
                id: "e1",
                promptId: "alpha",
                promptName: "Alpha",
                result: "R1",
                wasActionable: true,
                emailCount: 1
            ),
            PromptExecution(
                id: "e2",
                promptId: "beta",
                promptName: "Beta",
                result: "R2",
                wasActionable: false,
                emailCount: 2
            ),
            PromptExecution(
                id: "e3",
                promptId: "alpha",
                promptName: "Alpha",
                result: "R3",
                wasActionable: true,
                emailCount: 3
            )
        ]
        PromptExecution.saveAll(executions)

        let alphaExecutions = PromptExecution.loadExecutions(for: "alpha")
        XCTAssertEqual(alphaExecutions.count, 2)
        XCTAssertTrue(alphaExecutions.allSatisfy { $0.promptId == "alpha" })

        let betaExecutions = PromptExecution.loadExecutions(for: "beta")
        XCTAssertEqual(betaExecutions.count, 1)

        let gammaExecutions = PromptExecution.loadExecutions(for: "gamma")
        XCTAssertTrue(gammaExecutions.isEmpty)
    }

    // MARK: - Codable

    func testCodableRoundTrip() throws {
        let original = PromptExecution(
            id: "encode-test",
            promptId: "p1",
            promptName: "Encode",
            timestamp: Date(timeIntervalSince1970: 1_700_000_000),
            result: "Encoded result",
            wasActionable: true,
            emailCount: 7,
            wasShownToUser: true
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PromptExecution.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.promptId, original.promptId)
        XCTAssertEqual(decoded.promptName, original.promptName)
        XCTAssertEqual(decoded.result, original.result)
        XCTAssertEqual(decoded.wasActionable, original.wasActionable)
        XCTAssertEqual(decoded.emailCount, original.emailCount)
        XCTAssertEqual(decoded.wasShownToUser, original.wasShownToUser)
    }
}
