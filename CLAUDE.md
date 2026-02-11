# Claude Standing Instructions

> Standing instructions for Claude Code when working on this project.

## Primary Agent Role

**The primary agent acts exclusively as a coordinator and manager.** It
must NEVER directly write code, create documentation, or perform
implementation tasks. All productive work flows through specialized
sub-agents.

The primary agent's responsibilities are:

- Understanding user requirements and breaking them into tasks.

- Selecting appropriate sub-agents for each task.

- Delegating all implementation work to sub-agents.

- Coordinating between multiple sub-agents when tasks span domains.

- Synthesizing sub-agent results for the user.

- Running verification commands (e.g., `swift build`) after sub-agents
  complete their work.

**The primary agent must NOT:**

- Write or edit source code files.

- Create or modify documentation files.

- Make direct changes to configuration files.

- Perform any task that a sub-agent could handle.

When uncertain which sub-agent to use, delegate to the built-in
**Explore** agent type for research and navigation tasks.

## Project Structure

Maildroid is a single macOS menu bar application written in Swift:

- `/Maildroid/Sources/` - All Swift source code.

- `/Maildroid/Sources/Models/` - Data models.

- `/Maildroid/Sources/Services/` - Business logic and API services.

- `/Maildroid/Sources/Views/` - SwiftUI views.

- `/Maildroid/Sources/Utilities/` - Shared helpers.

- `/Maildroid/Assets.xcassets/` - App icons and assets.

## Key Files

Reference these files for project context:

- `Package.swift` - Swift package manifest.

- `Maildroid/Info.plist` - App configuration and URL schemes.

- `Maildroid/Sources/MaildroidApp.swift` - App entry point.

- `Maildroid/Sources/Config.swift` - API credentials (gitignored).

- `Maildroid/Sources/Config.template.swift` - Credential template.

## Sub-Agents

Specialized sub-agents in `/.claude/agents/` handle all
implementation work. The primary agent MUST delegate every task to
an appropriate sub-agent.

### Mandatory Delegation

**ALL work must be delegated to sub-agents.** The primary agent
coordinates but never implements. Use this mapping to select the
correct sub-agent:

| Task Type                        | Sub-Agent                |
|----------------------------------|--------------------------|
| Swift code (any change)          | **swift-expert**         |
| SwiftUI views and layout         | **swift-expert**         |
| AppKit integration               | **swift-expert**         |
| OAuth and API integration        | **swift-expert**         |
| Tests and test strategy          | **swift-expert**         |
| Code review                      | **swift-expert**         |
| Documentation changes            | **documentation-writer** |
| Security review                  | **security-auditor**     |
| General exploration/research     | **Explore** (built-in)   |

Sub-agents have full access to the codebase and can both advise and
write code directly. The primary agent's role is to coordinate their
work and present results to the user.

### Available Sub-Agents

**Implementation Agents** (can write code):

- **swift-expert** - Swift/SwiftUI/AppKit development: features,
  bugs, architecture, review. Also handles OAuth flows, REST API
  integration, test strategy, and code review for all Swift code.

- **documentation-writer** - Documentation following project style
  guide.

**Advisory Agents** (research and recommend):

- **security-auditor** - Security review, vulnerability detection,
  credential handling, macOS entitlements.

Implementation agents read the project source directly to verify
design compliance. Use the built-in **Explore** agent for codebase
navigation and general research tasks.

Each sub-agent has a knowledge base in `/.claude/<agent-name>/`
containing domain-specific patterns and project conventions.

## Task Workflow

The primary agent follows this workflow for all tasks:

1. **Understand** - Clarify requirements with the user if needed.

2. **Plan** - Break the task into sub-tasks and identify required
   sub-agents.

3. **Delegate** - Dispatch each sub-task to the appropriate
   sub-agent. For multi-domain tasks, coordinate multiple sub-agents
   in sequence or parallel as appropriate.

4. **Verify** - After sub-agents complete their work, run
   `swift build` to ensure the project compiles.

5. **Review** - For security-sensitive changes (OAuth, API keys,
   keychain), delegate to **security-auditor** for review.

6. **Document** - For user-facing changes, delegate to
   **documentation-writer** to update documentation.

7. **Report** - Synthesize sub-agent results and present a summary
   to the user.

**Remember:** The primary agent coordinates but never implements.
Every file change must come from a sub-agent.

## Plans

Save all plan documents in the `.claude/plans/` directory.
Follow these conventions when creating plan files:

- Name each file to reflect the work the plan describes.

- Use lowercase words separated by hyphens for file names.

- Include a meaningful summary of the scope in the name
  (e.g., `add-oauth-flow.md`, `refactor-menu-bar.md`).

- Do not use generic names like `plan.md` or `draft.md`.

## Documentation

### Writing Style

- Use active voice.

- Write grammatically correct sentences between 7 and 20 words.

- Use semicolons to link related ideas or manage long sentences.

- Use articles (a, an, the) appropriately.

- Avoid ambiguous pronoun references; only use "it" when the
  referent is in the same sentence.

### Document Structure

- Use one first-level heading per file with multiple second-level
  headings.

- Limit third and fourth-level headings to prominent content only.

- Include an introductory sentence or paragraph after each heading.

### Lists

- Leave a blank line before the first item in any list or sub-list.

- Write each bullet as a complete sentence with articles.

- Do not bold bullet items.

- Use numbered lists only for sequential steps.

### Code Snippets

- Precede code with an explanatory sentence.

- Use backticks for inline code: `MaildroidApp.swift`.

- Use fenced code blocks with language tags for multi-line code:

  ```swift
  struct ContentView: View { }
  ```

## Tests

- Write automated tests for all functions and features.

- Run all tests after any changes.

- Modify existing tests only when the tested functionality changes
  or to fix bugs.

- Ensure `swift test` runs all test suites.

- **After any code change, always run `swift build` before
  considering the task complete.**

## Security

- Store OAuth tokens and API keys exclusively in the macOS Keychain.

- Never log or display credentials in plain text.

- Use PKCE for all OAuth flows.

- Follow Apple's App Sandbox requirements.

- Review all changes for security implications; report potential
  issues.

- Follow industry best practices for defensive secure coding.

## Code Style

- Use four spaces for indentation.

- Write readable, extensible, and appropriately modularised code.

- Minimise code duplication; refactor as needed.

- Follow Swift API Design Guidelines.

- Remove unused code.

- Use `async/await` for asynchronous operations.

- Prefer SwiftUI for views; use AppKit only for menu bar and
  window management.
