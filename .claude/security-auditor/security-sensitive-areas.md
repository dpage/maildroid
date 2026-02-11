# Security-Sensitive Areas

This document identifies code locations that require careful
security review.

## Critical Risk Areas

### OAuth Flow (`GoogleAuthService.swift`)

**Risk Level: CRITICAL**

| Concern | Check |
|---------|-------|
| PKCE implementation | Code verifier/challenge correct |
| Token storage | Keychain only, never UserDefaults |
| Token refresh | Refresh token not exposed |
| Redirect URI | Validated on callback |
| State parameter | CSRF prevention |

**Review checklist:**

- [ ] PKCE code verifier uses cryptographic randomness.
- [ ] Code challenge uses SHA256.
- [ ] Tokens stored exclusively in Keychain.
- [ ] Redirect URI matches registered scheme.
- [ ] Error messages do not leak token values.

### API Key Storage (`KeychainHelper.swift`)

**Risk Level: CRITICAL**

| Concern | Check |
|---------|-------|
| Keychain access | Proper item class and attributes |
| Key prefix | Uses "maildroid" prefix |
| Error handling | Failures handled gracefully |
| Cleanup | Keys removed on account deletion |

**Review checklist:**

- [ ] All secrets use Keychain, never UserDefaults.
- [ ] Keychain queries use appropriate access control.
- [ ] Delete operations clean up all related entries.
- [ ] Error handling does not expose secret values.

## High Risk Areas

### Gmail API Client (`GmailService.swift`)

**Risk Level: HIGH**

| Concern | Check |
|---------|-------|
| Token in requests | Bearer token in Authorization header |
| Token refresh | 401 triggers refresh, not re-auth |
| Data handling | Email content handled appropriately |
| Error messages | No token values in errors |

### LLM API Client (`LLMService.swift`)

**Risk Level: HIGH**

| Concern | Check |
|---------|-------|
| API key transmission | Via headers, not URL parameters |
| HTTPS enforcement | All cloud providers use HTTPS |
| Error messages | No API key values in errors |
| Local providers | HTTP acceptable for localhost only |

## Medium Risk Areas

### Configuration (`Config.swift`)

**Risk Level: MEDIUM**

| Concern | Check |
|---------|-------|
| Gitignore | Config.swift is gitignored |
| Template | Config.template.swift has no real secrets |
| Client ID | Not a secret but should not be logged |

### Execution History (`PromptExecution`)

**Risk Level: MEDIUM**

| Concern | Check |
|---------|-------|
| Email content | Not stored in execution history |
| LLM responses | May contain sensitive email data |
| Persistence | UserDefaults, not encrypted |

## Code Patterns to Flag

### Always Flag

```swift
// Storing secrets in UserDefaults - ALWAYS VULNERABLE
UserDefaults.standard.set(token, forKey: "oauthToken")

// Logging credentials - ALWAYS VULNERABLE
print("Token: \(accessToken)")
NSLog("API Key: \(apiKey)")

// Hardcoded credentials
let apiKey = "sk-..."
```

### Review Carefully

```swift
// HTTP for non-localhost - flag for review
let url = URL(string: "http://remote-server.com/api")

// Force unwrap on network response
let data = try! JSONDecoder().decode(Response.self, from: data)

// Email body in persistent storage
UserDefaults.standard.set(email.body, forKey: "lastEmail")
```

### Acceptable Patterns

```swift
// Keychain storage - SAFE
KeychainHelper.save(token, forKey: "maildroid.token.\(id)")

// HTTPS for cloud providers - SAFE
let url = URL(string: "https://api.anthropic.com/v1/messages")

// HTTP for localhost - ACCEPTABLE
let url = URL(string: "http://localhost:11434/api/chat")
```
