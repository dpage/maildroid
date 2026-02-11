# Credential Handling

This document describes how credentials and secrets are managed
in the Maildroid application.

## OAuth Token Storage

### Access Tokens

The app stores Google OAuth access tokens in the macOS Keychain.

The storage implementation resides in `KeychainHelper.swift` and
`GoogleAuthService.swift`.

The system uses the following approach:

- The app stores tokens in the macOS Keychain using the Security
  framework.
- Each token is keyed by the Gmail account ID.
- The key format is `maildroid.accessToken.{accountId}`.
- Tokens are never stored in UserDefaults or on disk.

### Refresh Tokens

The app stores Google OAuth refresh tokens alongside access
tokens.

The system uses the following approach:

- Refresh tokens use the key format
  `maildroid.refreshToken.{accountId}`.
- Refresh tokens are long-lived and survive app restarts.
- The app uses the refresh token to obtain new access tokens.
- Refresh tokens are removed when the account is deleted.

### Token Lifecycle

The token lifecycle follows these steps:

```
User authenticates via OAuth
        |
        v
Receive access + refresh tokens
        |
        v
Store both in Keychain
        |
        v
(On API call)
        |
        v
Read access token from Keychain
        |
        v
Include in Authorization header
        |
        v
(On 401 response)
        |
        v
Use refresh token to get new access token
        |
        v
Update access token in Keychain
```

## LLM API Key Storage

### Cloud Provider Keys

The app stores LLM API keys in the macOS Keychain.

The following security requirements apply:

- API keys for Anthropic, OpenAI, and Gemini are stored in the
  Keychain.
- The key format is `maildroid.llmApiKey.{provider}`.
- API keys are sent via HTTPS only.
- API keys are not logged or displayed in full.

### Local Provider Configuration

Ollama and Docker Model Runner do not require API keys.

The following considerations apply:

- Base URLs for local providers are stored in UserDefaults.
- HTTP is acceptable for localhost connections.
- Base URLs should be validated to ensure they point to
  localhost.

## Configuration Secrets

### Config.swift

The app's `Config.swift` file contains the Google OAuth Client
ID.

The following requirements apply:

- `Config.swift` is listed in `.gitignore`.
- `Config.template.swift` contains placeholder values.
- The Client ID is not a secret but should not be committed
  with real values.
- The template includes instructions for obtaining credentials.

## Logging Safety

### What Must Not Be Logged

The following items must never appear in log output:

```swift
// NEVER log these:
print("Access token: \(accessToken)")
print("Refresh token: \(refreshToken)")
print("API key: \(apiKey)")
```

### Safe Logging Patterns

The following patterns demonstrate safe logging practices:

```swift
// Log sanitised versions:
print("Auth attempt for account: \(accountEmail)")
print("API call to provider: \(provider.rawValue)")
print("Token refresh succeeded for: \(accountId)")
```

## Error Message Safety

### External Error Messages

The following examples show safe error messages:

```swift
// GOOD - Generic messages
throw AuthError.tokenRefreshFailed
throw LLMError.apiRequestFailed
throw GmailError.fetchFailed

// BAD - Leaks information
throw NSError(domain: "", code: 0,
    userInfo: [NSLocalizedDescriptionKey:
    "Token \(token) expired"])
```

## Cleanup Requirements

### Account Removal

When a user removes a Gmail account:

- Delete the access token from the Keychain.
- Delete the refresh token from the Keychain.
- Remove account metadata from UserDefaults.
- Remove related execution history entries.

### LLM Provider Change

When a user changes the LLM provider:

- Delete the old provider's API key from the Keychain.
- Store the new provider's API key in the Keychain.
