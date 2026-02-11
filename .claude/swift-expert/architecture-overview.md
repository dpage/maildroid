# Architecture Overview

Maildroid is a macOS menu bar application that connects to Gmail
accounts, fetches emails, and runs user-configured LLM prompts
against them for analysis.

## Application Architecture

The app follows a single-process, menu bar-only architecture:

- `MaildroidApp` is the `@main` entry point with an empty hidden
  `WindowGroup`.
- `AppDelegate` manages the `NSStatusItem`, `NSPopover`, and
  settings window.
- `AppState` (ObservableObject) holds all shared state: accounts,
  prompts, settings, and execution history.

## Component Layers

### Entry Point

- `MaildroidApp.swift` contains the app struct, AppDelegate, and
  AppState in a single file.
- The app sets `LSUIElement=true` in Info.plist to hide from the
  Dock.

### Models

- `GmailAccount` - Gmail account with OAuth tokens.
- `Email` - Parsed email message.
- `LLMProvider` - LLM provider type and configuration.
- `PromptConfig` - User-defined prompt with schedule.
- `PromptExecution` - Execution history record.
- `AppSettings` - App-wide preferences.

### Services

- `GoogleAuthService` - OAuth 2.0 with PKCE via
  ASWebAuthenticationSession.
- `GmailService` - Gmail API client for fetching emails.
- `LLMService` - Unified LLM API client supporting multiple
  providers.
- `PromptScheduler` - Timer-based scheduling for prompts.
- `PromptExecutionService` - Orchestrates email fetch, LLM call,
  and result display.

### Views

- `MenuDropdownView` - NSPopover content for the menu bar.
- `SettingsView` - Tabbed settings window.
- `PromptEditorView` - Create/edit prompt configuration.
- `ResultPopupView` - Floating result window.
- `ExecutionHistoryView` - Past execution log.
- `ProviderSetupView` - LLM provider configuration.

### Utilities

- `KeychainHelper` - macOS Keychain wrapper for token storage.
- `TimeFormatting` - Date and time display helpers.

## Persistence Strategy

- Gmail account metadata: UserDefaults (JSON encoded).
- OAuth tokens: macOS Keychain via KeychainHelper.
- LLM API keys: macOS Keychain via KeychainHelper.
- App settings: UserDefaults (JSON encoded).
- Prompt configurations: UserDefaults (JSON encoded).
- Execution history: UserDefaults (JSON encoded, capped at 100).

## Reference Project

Maildroid follows the same architectural patterns as the NeverMiss
project located at `/Users/dpage/git/never-miss/`. Key patterns
reused include:

- Menu bar app structure (NSStatusItem + NSPopover).
- Google OAuth flow (PKCE + ASWebAuthenticationSession).
- Keychain token storage.
- Floating popup window management.
- Settings window with TabView.
