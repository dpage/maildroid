# Testing Strategy

This document describes the testing approach for the Maildroid
project.

## Test Framework

- The project uses Swift Testing and XCTest.
- Tests run via `swift test` or Xcode's test runner.

## Test Organisation

### Unit Tests

- Test individual models, services, and utilities.
- Mock external dependencies (network, Keychain).
- Focus on business logic and data transformations.

### Test Categories

- **Model tests**: Codable encoding/decoding, validation,
  computed properties.
- **Service tests**: API request construction, response parsing,
  error handling.
- **Utility tests**: Keychain operations, time formatting.

## Test Patterns

### Testing Codable Models

```swift
@Test func emailDecodesFromJSON() throws {
    let json = """
    {"id": "abc", "threadId": "def", ...}
    """
    let email = try JSONDecoder().decode(
        Email.self,
        from: json.data(using: .utf8)!
    )
    #expect(email.id == "abc")
}
```

### Testing Services with Mocks

- Use protocol-based dependency injection.
- Create mock implementations for testing.
- Verify request construction and response handling.

### Testing Error Paths

- Test that network errors are handled gracefully.
- Test that invalid responses produce meaningful errors.
- Test that token refresh is triggered on 401.

## Test Coverage Goals

- All model types: encoding, decoding, and validation.
- All service methods: success and error paths.
- All utility functions.
- OAuth flow: token exchange and refresh.

## Running Tests

Run all tests from the command line:

```bash
swift test
```

Run tests from Xcode:

- Use `Cmd+U` to run all tests.
- Use the test navigator to run individual tests.
