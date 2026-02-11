# Code Conventions

This document describes the coding standards for the Maildroid
project.

## Formatting

- Use four spaces for indentation (no tabs).
- Maximum line length: 100 characters preferred.
- Use trailing closures where idiomatic.
- Place opening braces on the same line.

## Naming

- Types and protocols: `UpperCamelCase` (e.g., `GmailAccount`).
- Functions, properties, and variables: `lowerCamelCase`
  (e.g., `fetchEmails`).
- Constants: `lowerCamelCase` (e.g., `maxRetryCount`).
- Enum cases: `lowerCamelCase` (e.g., `.anthropic`).
- Follow Swift API Design Guidelines for clarity at the call
  site.

## Type Design

- Prefer `struct` over `class` for data models.
- Use `enum` for fixed sets of values.
- Use `class` only when reference semantics are required
  (e.g., ObservableObject).
- Conform to `Codable` for persistence.
- Conform to `Identifiable` for SwiftUI lists.

## Error Handling

- Define custom error types for each service.
- Use `async throws` for operations that can fail.
- Handle errors at the call site; do not silently ignore.
- Log errors with context but without sensitive data.

## Async/Await

- Use `async/await` for all asynchronous operations.
- Use `Task { }` to bridge from synchronous contexts.
- Use `@MainActor` for UI-related code.
- Avoid Combine unless specifically needed.

## Access Control

- Use `private` for implementation details.
- Use `internal` (default) for module-internal APIs.
- Use `public` only for APIs exposed to other modules.
- Mark properties as `private(set)` when only the owning
  type should mutate them.

## SwiftUI Views

- Keep views small and focused.
- Extract reusable components into separate structs.
- Use `@EnvironmentObject` for shared state (AppState).
- Use `@State` for view-local state.
- Use `@Binding` for parent-owned state.

## Comments

- Write comments only where the logic is not self-evident.
- Use `///` for documentation comments on public APIs.
- Do not add comments to code you did not change.

## File Organisation

- One primary type per file.
- File name matches the primary type name.
- Group related extensions in the same file.
- Place files in the appropriate directory:
  - `Models/` for data types.
  - `Services/` for business logic.
  - `Views/` for SwiftUI views.
  - `Utilities/` for shared helpers.
