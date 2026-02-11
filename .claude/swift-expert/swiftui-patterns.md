# SwiftUI Patterns

This document describes the SwiftUI conventions used in the
Maildroid project.

## State Management

### AppState

The app uses a single `AppState` class as an `ObservableObject`:

- Injected via `@EnvironmentObject` into views.
- Holds all shared state: accounts, prompts, settings, history.
- Uses `@Published` properties for reactive updates.

### View-Local State

- Use `@State` for view-local state (toggles, text fields).
- Use `@Binding` to pass mutable state to child views.
- Use `@StateObject` for view-owned observable objects.

## View Composition

### Menu Bar Popover

- The popover content is a single SwiftUI view hosted in an
  `NSPopover`.
- The popover is sized at approximately 380x450 points.
- Sections are separated by `Divider()` elements.

### Settings Window

- Uses `TabView` with labelled tabs.
- Each tab is a separate SwiftUI view.
- Tabs: General, Accounts, LLM Provider, Prompts, About.

### Floating Popup

- The result popup uses a custom `NSWindow` subclass.
- The window is set to `.floating` level and joins all spaces.
- SwiftUI content is hosted via `NSHostingView`.

## Common Patterns

### List with Actions

```swift
List {
    ForEach(items) { item in
        ItemRow(item: item)
    }
    .onDelete { indexSet in
        deleteItems(at: indexSet)
    }
}
```

### Async Data Loading

```swift
.task {
    await loadData()
}
```

### Sheet Presentation

```swift
.sheet(isPresented: $showEditor) {
    PromptEditorView(prompt: selectedPrompt)
}
```

## Styling Conventions

- Use SF Symbols for icons throughout the app.
- Use system colours for consistency with macOS appearance.
- Prefer `.frame()` modifiers for explicit sizing.
- Use `.padding()` for consistent spacing.
