# Security Checklist

This document provides security review checklists for common
development scenarios in the Maildroid project.

## OAuth Implementation Review

### PKCE Flow

- [ ] Code verifier generated with cryptographic randomness.
- [ ] Code verifier is 43-128 characters long.
- [ ] Code challenge uses SHA256 hash.
- [ ] Code challenge is Base64url-encoded.
- [ ] Code verifier is sent only in the token exchange request.

### Token Handling

- [ ] Access token stored in Keychain.
- [ ] Refresh token stored in Keychain.
- [ ] Tokens never stored in UserDefaults.
- [ ] Tokens never logged.
- [ ] Tokens cleared on account removal.
- [ ] Token refresh handles revocation gracefully.

### Authorization Request

- [ ] State parameter included for CSRF prevention.
- [ ] Redirect URI matches registered scheme.
- [ ] Scopes are minimal (gmail.readonly, userinfo).
- [ ] Consent screen shows correct app name.

## Gmail API Review

### Authentication

- [ ] Bearer token in Authorization header.
- [ ] Token refresh on 401 response.
- [ ] Failed refresh marks account for re-auth.
- [ ] No token in URL parameters.

### Data Handling

- [ ] Email content not persisted beyond immediate use.
- [ ] Email bodies cleared from memory after LLM call.
- [ ] Pagination handled to prevent excessive data loading.
- [ ] Error responses parsed without exposing raw data.

## LLM API Review

### API Key Security

- [ ] API keys stored in Keychain.
- [ ] Keys sent via appropriate header (not URL).
- [ ] HTTPS used for all cloud providers.
- [ ] HTTP acceptable only for localhost (Ollama, Docker).
- [ ] Keys not logged or displayed in full.

### Request/Response Security

- [ ] Email content sent to LLM is not logged.
- [ ] LLM responses may contain sensitive data; handle
      appropriately.
- [ ] Error responses do not expose API keys.
- [ ] Rate limit handling does not retry excessively.

## Keychain Operations Review

### Storage

- [ ] Correct item class (kSecClassGenericPassword).
- [ ] Key prefix is "maildroid" to avoid conflicts.
- [ ] Proper encoding of stored values.
- [ ] Access control attributes set appropriately.

### Retrieval

- [ ] Error handling for missing items.
- [ ] Proper decoding of retrieved values.
- [ ] No fallback to insecure storage on failure.

### Deletion

- [ ] All related items deleted on account removal.
- [ ] No orphaned Keychain entries after cleanup.

## macOS Security Review

### App Sandbox

- [ ] Entitlements are minimal and appropriate.
- [ ] Network access entitlement included (outgoing).
- [ ] No unnecessary file system access.
- [ ] Keychain access group configured correctly.

### Info.plist

- [ ] LSUIElement set to true (no Dock icon).
- [ ] URL scheme registered for OAuth callback.
- [ ] No unnecessary usage descriptions.

## Configuration Review

### Secrets Management

- [ ] Config.swift is in .gitignore.
- [ ] Config.template.swift has no real credentials.
- [ ] No secrets in source code.
- [ ] No secrets in UserDefaults.

### UserDefaults

- [ ] Only non-sensitive data in UserDefaults.
- [ ] Account metadata does not include tokens.
- [ ] Prompt configurations do not include API keys.
- [ ] Execution history does not include email bodies.

## Pre-Commit Checklist

Before committing security-related changes:

- [ ] No secrets in the diff.
- [ ] Error messages reviewed for information leakage.
- [ ] Logging reviewed for credential exposure.
- [ ] Keychain operations tested.
- [ ] Config.swift not in staged files.
