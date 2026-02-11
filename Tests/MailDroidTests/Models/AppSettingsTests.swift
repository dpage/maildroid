import XCTest
@testable import MailDroidLib

final class AppSettingsTests: XCTestCase {

    override func tearDown() {
        TestDefaults.cleanUp()
        super.tearDown()
    }

    // MARK: - Default Values

    func testDefaultValues() {
        let settings = AppSettings()
        XCTAssertFalse(settings.launchAtLogin)
        XCTAssertTrue(settings.playSound)
        XCTAssertNil(settings.llmConfig)
    }

    // MARK: - Persistence

    func testSaveAndLoad() {
        var settings = AppSettings()
        settings.launchAtLogin = true
        settings.playSound = false
        settings.save()

        let loaded = AppSettings.load()
        XCTAssertTrue(loaded.launchAtLogin)
        XCTAssertFalse(loaded.playSound)
    }

    func testLoadReturnsDefaultsWhenNoDataStored() {
        // Ensure there is no stored data.
        UserDefaults.standard.removeObject(forKey: "maildroid.settings")

        let loaded = AppSettings.load()
        XCTAssertFalse(loaded.launchAtLogin)
        XCTAssertTrue(loaded.playSound)
        XCTAssertNil(loaded.llmConfig)
    }

    func testSaveWithLLMConfig() {
        var settings = AppSettings()
        settings.llmConfig = LLMConfig(
            provider: .openai,
            apiKey: "sk-test-key-12345",
            baseURL: "https://api.openai.com/v1",
            model: "gpt-4o"
        )
        settings.save()

        let loaded = AppSettings.load()
        XCTAssertNotNil(loaded.llmConfig)
        XCTAssertEqual(loaded.llmConfig?.provider, .openai)
        XCTAssertEqual(loaded.llmConfig?.model, "gpt-4o")
        // The API key should be restored from the Keychain (UserDefaults).
        XCTAssertEqual(loaded.llmConfig?.apiKey, "sk-test-key-12345")
    }

    func testSaveStripsAPIKeyFromUserDefaults() {
        var settings = AppSettings()
        settings.llmConfig = LLMConfig(
            provider: .anthropic,
            apiKey: "secret-key"
        )
        settings.save()

        // Read the raw data from UserDefaults to verify the API key
        // was not stored in plain text alongside the settings.
        guard let data = UserDefaults.standard.data(forKey: "maildroid.settings"),
              let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            XCTFail("Expected settings data in UserDefaults.")
            return
        }
        XCTAssertTrue(
            decoded.llmConfig?.apiKey.isEmpty ?? true,
            "The API key should be empty in the UserDefaults copy."
        )
    }

    // MARK: - Equatable

    func testEquatable() {
        let a = AppSettings()
        var b = AppSettings()
        XCTAssertEqual(a, b)

        b.playSound = false
        XCTAssertNotEqual(a, b)
    }
}
