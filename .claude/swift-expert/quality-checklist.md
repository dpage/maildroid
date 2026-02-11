# Quality Checklist

This document provides review checklists for common change types
in the Maildroid project.

## General Review Checklist

- [ ] Code compiles without warnings.
- [ ] Four-space indentation used throughout.
- [ ] No unused imports or variables.
- [ ] No force unwraps unless justified.
- [ ] Error handling is complete (no ignored errors).
- [ ] Async/await used correctly.
- [ ] No retain cycles in closures (use `[weak self]`).

## Model Changes

- [ ] Conforms to `Codable` for persistence.
- [ ] Conforms to `Identifiable` for SwiftUI usage.
- [ ] Default values are sensible.
- [ ] Encoding/decoding tested with round-trip test.
- [ ] No secrets stored in model properties persisted
      to UserDefaults.

## Service Changes

- [ ] Uses `async/await` for asynchronous operations.
- [ ] Errors are handled and propagated appropriately.
- [ ] Network calls use HTTPS.
- [ ] API keys sent via appropriate headers.
- [ ] 401 responses trigger token refresh (Gmail).
- [ ] No credentials logged.
- [ ] Response parsing handles malformed data.

## View Changes

- [ ] Uses `@EnvironmentObject` for AppState access.
- [ ] State management is correct (@State vs @Binding).
- [ ] Accessibility labels present on interactive elements.
- [ ] Layout works at different window sizes.
- [ ] Loading and error states handled.
- [ ] No hardcoded strings (use appropriate constants).

## OAuth Changes

- [ ] PKCE code verifier and challenge generated correctly.
- [ ] Tokens stored in Keychain (not UserDefaults).
- [ ] Token refresh implemented.
- [ ] Scopes are minimal and appropriate.
- [ ] Redirect URI matches registered scheme.
- [ ] Error cases handled (user cancellation, network error).

## Keychain Changes

- [ ] Key prefix is "maildroid" to avoid conflicts.
- [ ] Data is properly encoded/decoded.
- [ ] Delete operations clean up all related entries.
- [ ] Error handling for Keychain access failures.

## Anti-Patterns to Avoid

- Force unwrapping (`!`) without prior nil check.
- Using `DispatchQueue` when `async/await` suffices.
- Storing secrets in UserDefaults.
- Ignoring errors with empty catch blocks.
- Blocking the main thread with synchronous network calls.
- Using global mutable state.
- Retaining `self` strongly in escaping closures.
