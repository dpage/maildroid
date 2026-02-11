# Documentation Style Guide

This is the authoritative style guide for all documentation in the
Maildroid project. These rules are derived from CLAUDE.md.

## Writing Style

### Voice and Tone

**Use active voice throughout.**

```markdown
<!-- BAD - Passive voice -->
The email is fetched by the service.

<!-- GOOD - Active voice -->
The service fetches the email.
```

### Sentence Structure

**Use full, grammatically correct sentences between 7 and 20
words.**

```markdown
<!-- BAD - Too short -->
Fetches emails.

<!-- BAD - Too long -->
The service fetches emails from all configured Gmail accounts
using the Gmail API and then sends the email content to the
configured LLM provider for analysis.

<!-- GOOD - Appropriate length -->
The service fetches emails from all configured Gmail accounts.
The LLM provider analyses the email content.
```

### Linking Ideas

**Use semicolons to link similar ideas or manage sentences that
are getting too long.**

```markdown
<!-- GOOD -->
The app connects to Gmail via OAuth; it stores tokens in the
macOS Keychain.
```

### Articles

**Use articles (a, an, the) when appropriate.**

```markdown
<!-- BAD - Missing articles -->
Service fetches emails.

<!-- GOOD - Proper articles -->
The service fetches the emails.
```

### Pronoun Clarity

**Do not refer to an object as "it" unless the object is in the
same sentence.**

```markdown
<!-- BAD - Ambiguous "it" -->
The service validates the token. It returns an error if invalid.

<!-- GOOD - Clear reference -->
The service validates the token. The service returns an error if
the token is invalid.

<!-- ALSO GOOD - Same sentence -->
The service validates the token and returns an error if it is
invalid.
```

### Emojis

**Do not use emojis unless explicitly requested.**

## Document Structure

### Headings

Each file should have:

- One first-level heading (`#`) as the document title.
- Multiple second-level headings (`##`) as main sections.
- Third and fourth level headings used sparingly.

### Introductions

**Each heading should have an introductory sentence or
paragraph.**

### Line Wrapping

**Wrap all markdown files at 79 characters or less.**

## Lists

### Blank Lines Before Lists

**Always leave a blank line before the first item in any list
or sub-list.**

```markdown
<!-- BAD - No blank line -->
The app supports:
- Gmail accounts
- Multiple LLM providers

<!-- GOOD - Blank line before list -->
The app supports:

- Gmail accounts.
- Multiple LLM providers.
```

### List Item Format

**Each entry in a bulleted list should be a complete sentence
with articles.**

### No Bold in Lists

**Do not use bold font for bullet items.**

### Numbered Lists

**Only use numbered lists when steps must be performed in
order.**

## Code Snippets

### Explanatory Text

**Include an explanatory sentence before code.**

Use this format: "In the following example, the `functionName`
function..."

### Inline Code

**Use backticks around single commands or code references.**

### Code Blocks

**Use fenced code blocks with language tags for multi-line
code.**

```swift
struct Email: Codable {
    let id: String
}
```
