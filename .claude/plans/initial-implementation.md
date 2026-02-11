# Maildroid - Implementation Plan

## Context

Build a macOS menu bar application called "Maildroid" that connects to Gmail accounts, fetches emails, and runs user-configured LLM prompts against them for analysis (e.g. summarising GitHub alerts). Results are displayed in floating popup windows. The app follows the same architectural patterns as the existing NeverMiss project (`/Users/dpage/git/never-miss`).

## Project Structure

```
/Users/dpage/git/maildroid/
├── CLAUDE.md                                # Primary agent instructions
├── .claude/
│   ├── settings.local.json                  # Permission whitelist
│   ├── agents/
│   │   ├── swift-expert.md                  # Swift implementation agent
│   │   ├── documentation-writer.md          # Documentation agent
│   │   └── security-auditor.md              # Security advisory agent
│   ├── swift-expert/                        # Swift expert knowledge base
│   │   ├── architecture-overview.md
│   │   ├── swiftui-patterns.md
│   │   ├── api-integration.md
│   │   ├── oauth-flow.md
│   │   ├── testing-strategy.md
│   │   ├── code-conventions.md
│   │   └── quality-checklist.md
│   ├── documentation-writer/                # Doc writer knowledge base
│   │   ├── style-guide.md
│   │   └── templates.md
│   └── security-auditor/                    # Security auditor knowledge base
│       ├── security-sensitive-areas.md
│       ├── credential-handling.md
│       └── security-checklist.md
├── Maildroid.xcodeproj/
├── Maildroid/
│   ├── Sources/
│   │   ├── MaildroidApp.swift              # App entry + AppDelegate + AppState
│   │   ├── Config.swift                     # (gitignored) Secrets
│   │   ├── Config.template.swift            # Template for Config.swift
│   │   ├── Models/
│   │   │   ├── GmailAccount.swift           # Gmail account model + persistence
│   │   │   ├── Email.swift                  # Email message model
│   │   │   ├── LLMProvider.swift            # LLM provider enum + config model
│   │   │   ├── PromptConfig.swift           # User prompt configuration model
│   │   │   ├── PromptExecution.swift         # Execution history/log model
│   │   │   └── AppSettings.swift            # App-wide settings
│   │   ├── Services/
│   │   │   ├── GoogleAuthService.swift      # OAuth (reuse from NeverMiss)
│   │   │   ├── GmailService.swift           # Gmail API - fetch emails
│   │   │   ├── LLMService.swift             # LLM API calls (all providers)
│   │   │   ├── PromptScheduler.swift        # Cron-like scheduling
│   │   │   └── PromptExecutionService.swift # Orchestrates: fetch emails -> LLM -> display
│   │   ├── Views/
│   │   │   ├── MenuDropdownView.swift       # Menu bar popover
│   │   │   ├── SettingsView.swift           # Settings window (tabbed)
│   │   │   ├── PromptEditorView.swift       # Create/edit prompt config
│   │   │   ├── ResultPopupView.swift        # Floating result window
│   │   │   ├── ExecutionHistoryView.swift   # Log of past executions
│   │   │   └── ProviderSetupView.swift      # LLM provider configuration
│   │   └── Utilities/
│   │       ├── KeychainHelper.swift         # Token storage (reuse from NeverMiss)
│   │       └── TimeFormatting.swift         # Time formatting (reuse from NeverMiss)
│   ├── Assets.xcassets/                     # App icon
│   ├── Info.plist
│   ├── Maildroid.entitlements
│   └── Maildroid.appstore.entitlements
├── .github/workflows/
│   ├── swift.yml                            # Build verification
│   └── direct-release.yml                   # Direct distribution (from NeverMiss)
├── Package.swift
├── .gitignore
└── README.md
```

## Implementation Steps

### Step 0: CLAUDE.md and Sub-Agent Configuration

Create the project's Claude Code configuration following the patterns
from `/Users/dpage/git/ai-dba-workbench/`.

**`/Users/dpage/git/maildroid/CLAUDE.md`** - Primary agent instructions:
- Primary agent acts as coordinator only; never writes code directly
- Project structure overview (single Swift macOS app)
- Sub-agent delegation table mapping task types to agents
- Task workflow (Understand, Plan, Delegate, Verify, Report)
- Documentation standards (adapted from ai-workbench style guide)
- Testing requirements (Swift-specific)
- Security guidelines (OAuth tokens, API keys, macOS sandboxing)
- Code style (4-space indentation, Swift conventions)

**Sub-agents** in `/.claude/agents/`:

1. **`swift-expert.md`** (Implementation agent, color: cyan)
   - Full-capability Swift/SwiftUI/AppKit development
   - Responsibilities: features, bugs, architecture, tests, code review
   - Covers: SwiftUI views, AppKit integration, async/await, Combine,
     OAuth flows, REST API integration, data persistence
   - Knowledge base at `/.claude/swift-expert/`:
     - `architecture-overview.md` - App architecture and patterns
     - `swiftui-patterns.md` - SwiftUI conventions used in project
     - `api-integration.md` - Gmail API and LLM API patterns
     - `oauth-flow.md` - Google OAuth implementation details
     - `testing-strategy.md` - Swift testing patterns
     - `code-conventions.md` - Project coding standards
     - `quality-checklist.md` - Review checklist

2. **`documentation-writer.md`** (Implementation agent, color: yellow)
   - Documentation creation and review
   - Adapted from ai-workbench pattern
   - Follows project documentation style guide
   - Knowledge base at `/.claude/documentation-writer/`:
     - `style-guide.md` - Documentation style requirements
     - `templates.md` - Standard document templates

3. **`security-auditor.md`** (Advisory agent, color: red)
   - Advisory only; does not write code
   - Focus areas: OAuth token handling, API key storage, LLM API
     security, macOS entitlements, network security
   - Knowledge base at `/.claude/security-auditor/`:
     - `security-sensitive-areas.md` - High-risk code locations
     - `credential-handling.md` - Token and API key management
     - `security-checklist.md` - Security review checklist

**Delegation table:**

| Task Type                        | Sub-Agent            |
|----------------------------------|----------------------|
| Swift code (any change)          | **swift-expert**     |
| SwiftUI views and layout         | **swift-expert**     |
| AppKit integration               | **swift-expert**     |
| OAuth and API integration        | **swift-expert**     |
| Tests and test strategy          | **swift-expert**     |
| Code review                      | **swift-expert**     |
| Documentation changes            | **documentation-writer** |
| Security review                  | **security-auditor** |
| General exploration/research     | **Explore** (built-in) |

**`/.claude/settings.local.json`** - Permission whitelist:
- `swift build`, `swift test`, `xcodebuild`, `swift package`
- `git` operations (log, status, diff, add, commit)
- `ls`, `mkdir`, `tree`

### Step 1: Project Scaffolding

Create the basic project structure:
- `Package.swift` - Swift 5.9, macOS 13.0 target, linked frameworks (AppKit, Security, AuthenticationServices, ServiceManagement)
- `Maildroid.xcodeproj` via `swift package generate-xcodeproj` or manual creation
- `Info.plist` with LSUIElement=true, URL scheme for OAuth callback, Gmail API usage description
- Entitlements files (direct + appstore)
- `.gitignore` (exclude Config.swift, build/, .DS_Store)
- `Config.template.swift` and `Config.swift` with Google OAuth credentials + Gmail API URLs
- `Assets.xcassets` with app icon placeholder

### Step 2: Core App Shell (Menu Bar App)

**File: `MaildroidApp.swift`** - Following NeverMiss pattern:
- `@main struct MaildroidApp: App` with empty hidden WindowGroup
- `AppDelegate` with NSStatusItem, NSPopover, settings window
- `AppState` (ObservableObject) holding accounts, prompts, settings, execution history
- Menu bar icon (SF Symbol: `envelope.badge.fill` or similar)
- Menu bar title: shows status like "Maildroid" or "2 prompts active"
- `setupMenuBar()`, `togglePopover()`, `openSettings()` following NeverMiss patterns exactly

### Step 3: Data Models

**`GmailAccount.swift`** - Adapted from NeverMiss `GoogleAccount.swift`:
- Same structure: id, email, displayName, isEnabled, tokens
- Same persistence pattern: metadata in UserDefaults, tokens in KeychainHelper
- Gmail-specific scopes instead of Calendar scopes

**`Email.swift`**:
```swift
struct Email: Identifiable, Codable {
    let id: String
    let threadId: String
    let accountId: String
    let subject: String
    let from: String
    let to: String
    let date: Date
    let snippet: String
    let body: String          // Plain text body
    let labels: [String]
    let isUnread: Bool
}
```

**`LLMProvider.swift`**:
```swift
enum LLMProviderType: String, Codable, CaseIterable {
    case anthropic = "Anthropic"
    case openai = "OpenAI"
    case gemini = "Gemini"
    case ollama = "Ollama"
    case dockerModelRunner = "Docker Model Runner"
}

struct LLMConfig: Codable, Equatable {
    var provider: LLMProviderType
    var apiKey: String          // For cloud providers
    var baseURL: String         // For Ollama/Docker Model Runner
    var model: String           // Selected model name
}
```

**`PromptConfig.swift`**:
```swift
struct PromptConfig: Identifiable, Codable {
    let id: String
    var name: String                    // User-friendly name
    var prompt: String                  // The LLM prompt text
    var emailTimeRange: EmailTimeRange  // How far back to fetch emails
    var triggerType: TriggerType        // On-demand, scheduled, or both
    var scheduleTimes: [ScheduleTime]   // Times of day to run
    var scheduleInterval: TimeInterval? // Interval between runs (optional)
    var onlyShowIfActionable: Bool      // Suppress empty results
    var isEnabled: Bool
}

enum EmailTimeRange: String, Codable, CaseIterable {
    case last24Hours = "Last 24 hours"
    case last3Days = "Last 3 days"
    case last7Days = "Last 7 days"
}

enum TriggerType: String, Codable {
    case onDemand
    case scheduled
    case both
}

struct ScheduleTime: Codable, Equatable {
    var hour: Int       // 0-23
    var minute: Int     // 0-59
}
```

**`PromptExecution.swift`**:
```swift
struct PromptExecution: Identifiable, Codable {
    let id: String
    let promptId: String
    let promptName: String
    let timestamp: Date
    let result: String          // LLM response
    let wasActionable: Bool     // Did it have content worth showing
    let emailCount: Int         // Number of emails analysed
    let wasShownToUser: Bool    // Was the popup actually displayed
}
```

**`AppSettings.swift`** - Adapted from NeverMiss:
```swift
struct AppSettings: Codable, Equatable {
    var launchAtLogin: Bool
    var playSound: Bool          // Sound on new results
    var llmConfig: LLMConfig?    // Selected LLM provider/model
}
```

### Step 4: Gmail Integration

**`GoogleAuthService.swift`** - Directly reuse from NeverMiss, changing:
- Scopes to Gmail: `gmail.readonly`, `userinfo.email`, `userinfo.profile`
- All OAuth flow logic stays identical (PKCE, ASWebAuthenticationSession)

**`GmailService.swift`** - New service for Gmail API:
- `fetchEmails(account:, since:) -> [Email]` - Fetch emails within time range
- Uses Gmail API: `GET /gmail/v1/users/me/messages?q=after:{timestamp}`
- For each message ID: `GET /gmail/v1/users/me/messages/{id}?format=full`
- Parse MIME parts to extract plain text body
- Handle pagination (nextPageToken)
- 401 handling with token refresh (same pattern as NeverMiss CalendarService)

### Step 5: LLM Integration

**`LLMService.swift`** - Unified service supporting all providers:
- `sendPrompt(config: LLMConfig, systemPrompt: String, userContent: String) async throws -> String`
- Provider-specific API calls:
  - **Anthropic**: POST to `https://api.anthropic.com/v1/messages` with `x-api-key` header, model from config
  - **OpenAI**: POST to `https://api.openai.com/v1/chat/completions` with Bearer token
  - **Gemini**: POST to `https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent`
  - **Ollama**: POST to `http://localhost:11434/api/chat` (or configured baseURL)
  - **Docker Model Runner**: POST to `http://localhost:12434/engines/llama.cpp/v1/chat/completions` (or configured baseURL), OpenAI-compatible API
- Each provider: construct appropriate request body, parse response to extract text
- Error handling: API errors, rate limits, model not found
- Fetch available models for Ollama/Docker Model Runner via their list APIs

### Step 6: Prompt Scheduling & Execution

**`PromptScheduler.swift`**:
- Maintains timers for each scheduled prompt
- On app launch: calculate next fire time for each scheduled prompt
- `schedulePrompt(_ config: PromptConfig)` - Set up Timer for next scheduled time
- `cancelSchedule(for promptId: String)`
- Recalculate after each execution to find next time-of-day occurrence
- Support for daily schedule times (e.g. 9:00 AM, 5:00 PM)

**`PromptExecutionService.swift`** - Orchestrator:
1. Fetch emails from all enabled Gmail accounts within the prompt's time range
2. Format emails into a structured text block for LLM context
3. Build the full prompt: system instructions + email data + user prompt
4. Send to LLM via `LLMService`
5. Parse response: determine if "actionable" (non-empty, meaningful result)
6. Log execution to history (always)
7. If actionable OR `onlyShowIfActionable` is false: show floating popup
8. Email formatting: include subject, from, date, body (truncated) for each email

### Step 7: Views

**`MenuDropdownView.swift`** - Following NeverMiss pattern:
- Header: "Maildroid" + settings gear button
- Section: Active prompts list with status (last run time, next scheduled run)
- "Run Now" button per prompt for on-demand execution
- Section: Recent results (last 3-5) with truncated preview
- Footer: "Add Account" + "Quit" buttons
- Popover size: 380x450

**`SettingsView.swift`** - TabView with sections:
1. **General**: Launch at login, play sound on results
2. **Accounts**: Gmail account management (add/remove/toggle) - reuse NeverMiss AccountsSettingsView pattern
3. **LLM Provider**: Provider picker, API key input, base URL (for Ollama/Docker), model selection (dropdown that fetches available models for local providers)
4. **Prompts**: List of configured prompts, add/edit/delete, enable/disable toggle
5. **About**: App icon, name, version

**`PromptEditorView.swift`** - Sheet/window for creating/editing a prompt:
- Name field
- Prompt text (multi-line TextEditor)
- Email time range picker
- Trigger type picker (on-demand / scheduled / both)
- Schedule times editor (add/remove time-of-day entries)
- "Only show if actionable" toggle
- Save/Cancel buttons

**`ResultPopupView.swift`** - Following NeverMiss MeetingPopupView pattern:
- Floating window (NSWindow level: `.floating`, joins all spaces)
- Gradient header (blue->purple) with prompt name + timestamp chip
- Scrollable markdown-rendered result content (or plain text)
- Footer: "Dismiss" button + "View History" button
- Window size: 500x550
- Play sound on show (if enabled)
- `ResultPopupWindowController` managing lifecycle (same pattern as MeetingPopupWindowController)

**`ExecutionHistoryView.swift`** - Accessible from settings or menu:
- List of all past executions with timestamp, prompt name, actionable status
- Click to expand and see full result text
- "Clear All" button to delete history
- "Clear" button per individual entry
- Filtering by prompt name

### Step 8: GitHub Workflows

Copy from NeverMiss and adapt:
- `swift.yml` - Basic build check
- `direct-release.yml` - Direct distribution with DMG, adapt:
  - Change APP_NAME/BUNDLE_ID
  - Config.swift generation: include GOOGLE_CLIENT_ID for Gmail OAuth
  - Same signing/notarization flow

### Step 9: Persistence Strategy

- **Gmail accounts**: UserDefaults (metadata) + KeychainHelper (tokens) - same as NeverMiss
- **LLM config**: UserDefaults (JSON encoded AppSettings). API keys stored via KeychainHelper
- **Prompt configs**: UserDefaults (JSON encoded array)
- **Execution history**: UserDefaults (JSON encoded array, with a max cap of ~100 entries, FIFO)
- **App settings**: UserDefaults (JSON encoded)

## Files Reused from NeverMiss (with adaptation)

| NeverMiss File | Maildroid Equivalent | Changes |
|---|---|---|
| `NeverMissApp.swift` | `MaildroidApp.swift` | Menu bar title, services, state properties |
| `GoogleAuthService.swift` | `GoogleAuthService.swift` | Change scopes to Gmail |
| `GoogleAccount.swift` | `GmailAccount.swift` | Rename, same structure |
| `KeychainHelper.swift` | `KeychainHelper.swift` | Change key prefix to "maildroid" |
| `TimeFormatting.swift` | `TimeFormatting.swift` | Reuse as-is |
| `AppSettings.swift` | `AppSettings.swift` | Different settings fields |
| `MeetingPopupView.swift` | `ResultPopupView.swift` | Adapt content for LLM results |
| `MenuDropdownView.swift` | `MenuDropdownView.swift` | Prompt list instead of meetings |
| `SettingsView.swift` | `SettingsView.swift` | Different tabs (add LLM, Prompts) |
| `Config.template.swift` | `Config.template.swift` | Gmail URLs instead of Calendar |
| `direct-release.yml` | `direct-release.yml` | Change names/identifiers |

## Build Order

0. CLAUDE.md, sub-agent definitions, knowledge base stubs, settings.local.json
1. Project scaffolding (Package.swift, Info.plist, entitlements, .gitignore, Config)
2. Core app shell (MaildroidApp.swift with menu bar, AppState, empty popover)
3. Data models (all model files)
4. KeychainHelper + TimeFormatting utilities
5. GoogleAuthService + GmailAccount persistence
6. GmailService (email fetching)
7. LLMService (all providers)
8. PromptConfig persistence + PromptScheduler
9. PromptExecutionService (orchestration)
10. MenuDropdownView
11. SettingsView (General + Accounts tabs)
12. ProviderSetupView (LLM config tab)
13. PromptEditorView + Prompts settings tab
14. ResultPopupView + ResultPopupWindowController
15. ExecutionHistoryView
16. GitHub workflows
17. README.md

## Verification

1. `swift build` should compile without errors
2. Run from Xcode - app appears in menu bar only (no dock icon)
3. Click menu bar icon - popover appears with empty state
4. Open settings - all tabs render correctly
5. Add Gmail account - OAuth flow opens browser, tokens saved
6. Configure LLM provider with API key
7. Create a prompt, run on-demand - emails fetched, sent to LLM, result popup appears
8. Schedule a prompt - verify it fires at configured time
9. Check execution history - all runs logged
10. Clear history - entries removed
11. Quit and relaunch - all settings, accounts, prompts persist
