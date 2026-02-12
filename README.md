# Maildroid

Maildroid is a native macOS menu bar application that connects
to Gmail accounts, fetches emails, and runs LLM prompts against
them for analysis. The app displays results in floating popup
windows; users can schedule prompts to run automatically.

## Features

Maildroid provides the following capabilities:

- The app connects to multiple Gmail accounts via Google OAuth.
- Users can configure prompts that analyse fetched emails.
- The app supports five LLM providers: Anthropic, OpenAI,
  Gemini, Ollama, and Docker Model Runner.
- Prompts can run on demand, on a schedule, or both.
- Floating popup windows display the LLM analysis results.
- The app stores OAuth tokens and API keys in the macOS
  Keychain.
- An execution history log tracks all past prompt runs.
- Users can filter email time ranges for each prompt.
- The app plays an optional sound when new results arrive.

## Requirements

Maildroid requires the following to build and run:

- macOS 13.0 (Ventura) or later.
- Swift 5.9 or later.
- Xcode 15.0 or later for building the project.
- A Google Cloud project with the Gmail API enabled.

## Setup

Follow these steps to set up the project for development.

1. Clone the repository.

   ```bash
   git clone https://github.com/dpage/maildroid.git
   cd maildroid
   ```

2. Copy the configuration template to create your config file.

   ```bash
   cp Maildroid/Sources/Config.template.swift \
      Maildroid/Sources/Config.swift
   ```

3. Edit `Config.swift` and add your Google OAuth credentials.

   ```swift
   static let googleClientID = "YOUR_ID.apps.googleusercontent.com"
   static let googleClientSecret = "YOUR_SECRET_OR_EMPTY"
   ```

4. Build the project to verify the setup.

   ```bash
   swift build
   ```

The `Config.swift` file is gitignored to prevent committing
credentials. Only `Config.template.swift` is tracked in version
control.

## Google Cloud Configuration

Maildroid requires Google OAuth credentials to access Gmail.
Complete the following steps in the Google Cloud Console to
create a project, enable the Gmail API, and generate the
OAuth credentials that Maildroid needs.

### Create a Google Cloud Project

A Google Cloud project acts as a container for your API
credentials and settings.

1. Open the [Google Cloud Console](https://console.cloud.google.com/)
   and sign in with your Google account.
2. Click the project selector dropdown at the top of the page.
3. Click "New Project" in the upper-right corner of the dialog.
4. Enter "Maildroid" as the project name.
5. Leave the organisation and location fields at their defaults.
6. Click "Create" and wait for the project to be provisioned.
7. Click the project selector again and choose "Maildroid" to
   make the new project active.

### Enable the Gmail API

Maildroid uses the Gmail API to fetch email messages from
your accounts.

1. Open the navigation menu by clicking the hamburger icon in
   the top-left corner.
2. Navigate to "APIs & Services" and then select "Library."
3. Type "Gmail API" in the search bar and press Enter.
4. Click the "Gmail API" card in the search results.
5. Click the "Enable" button on the Gmail API detail page.
6. Wait for the API to activate; the console will redirect you
   to the API overview page.

### Configure the OAuth Consent Screen

The OAuth consent screen defines what users see when they
authorise Maildroid to access their Gmail data. You must
configure the consent screen before creating credentials.

1. Open the navigation menu and go to "APIs & Services" then
   "OAuth consent screen."
2. Select "External" as the user type and click "Create."
3. Enter "Maildroid" as the app name on the "App information"
   page.
4. Select your email address from the "User support email"
   dropdown.
5. Scroll down and enter your email address in the "Developer
   contact information" field.
6. Leave all other fields blank and click "Save and Continue."
7. On the "Data access" page, click the "Add or Remove Scopes"
   button.
8. In the scope filter, search for and select each of the
   following four scopes:

   - `https://www.googleapis.com/auth/gmail.readonly` grants
     read access to Gmail messages and metadata.
   - `https://www.googleapis.com/auth/gmail.modify` grants
     permission to modify Gmail messages and labels.
   - `https://www.googleapis.com/auth/userinfo.email` grants
     access to the account email address.
   - `https://www.googleapis.com/auth/userinfo.profile` grants
     access to basic profile information.

9. Click "Update" at the bottom of the scope selector panel.
10. Click "Save".
11. On the "Audience" page, click "Add Users."
12. Enter the Google email address you will use with Maildroid.
13. Click "Add" and then "Save and Continue."
14. Review the summary and click "Back to Dashboard."

The app will remain in "Testing" mode, which limits access
to the test users you added. This mode is sufficient for
personal use and does not require Google verification.

### Create OAuth Credentials

Maildroid uses "iOS" type OAuth credentials because the app
handles the OAuth callback through a custom URL scheme
rather than a web server redirect.

1. Open the navigation menu and go to "APIs & Services" then
   "Credentials."
2. Click the "Create Credentials" button at the top of the
   page.
3. Select "OAuth client ID" from the dropdown menu.
4. Choose "iOS" from the "Application type" dropdown.
5. Enter "Maildroid macOS" in the "Name" field.
6. Enter `page.conx.maildroid` in the "Bundle ID" field.
7. Leave the "App Store ID" and "Team ID" fields blank.
8. Click "Create" to generate the credentials.

### Copy Credentials to Config.swift

The console displays a dialog with your new credentials
after creation. Copy these values into your local
configuration file.

1. Copy the "Client ID" value from the dialog; the value
   ends with `.apps.googleusercontent.com`.
2. Open `Maildroid/Sources/Config.swift` in a text editor.
3. Replace `YOUR_CLIENT_ID.apps.googleusercontent.com` with
   the Client ID you copied.
4. Leave the `googleClientSecret` field set to an empty
   string; iOS-type credentials do not use a client secret.

The following example shows the completed configuration.

```swift
static let googleClientID =
    "123456789.apps.googleusercontent.com"
static let googleClientSecret = ""
```

The `Config.swift` file is gitignored to prevent accidental
credential exposure. Only `Config.template.swift` is tracked
in version control.

## LLM Provider Setup

Maildroid supports five LLM providers for email analysis.
Configure one provider in the app settings.

### Cloud Providers

Cloud providers require an API key from the provider.

- Anthropic uses the Claude family of models. Obtain an API
  key from the [Anthropic Console](https://console.anthropic.com/).
- OpenAI uses the GPT family of models. Obtain an API key
  from the [OpenAI Platform](https://platform.openai.com/).
- Gemini uses the Gemini family of models. Obtain an API key
  from [Google AI Studio](https://aistudio.google.com/).

### Local Providers

Local providers run models on your machine without API keys.

- Ollama serves models locally on port 11434. Install Ollama
  from [ollama.com](https://ollama.com/) and pull a model.
- Docker Model Runner serves models through Docker on port
  12434. Enable Model Runner in Docker Desktop settings.

## Usage

Maildroid runs as a menu bar application without a Dock icon.

### Adding Gmail Accounts

1. Click the Maildroid icon in the menu bar.
2. Click "Add Account" to start the OAuth flow.
3. Sign in with your Google account in the browser.
4. The app stores your tokens securely in the macOS Keychain.

### Configuring the LLM Provider

1. Open the settings window from the menu bar dropdown.
2. Select the "LLM Provider" tab.
3. Choose a provider and enter your API key or base URL.
4. Select a model from the dropdown list.

### Creating Prompts

1. Open the settings window and select the "Prompts" tab.
2. Click the add button to create a new prompt.
3. Enter a name and the prompt text for email analysis.
4. Select an email time range: last 24 hours, 3 days, or
   7 days.
5. Choose a trigger type: on demand, scheduled, or both.
6. Configure schedule times if using the scheduled trigger.
7. Toggle "Only show if actionable" to suppress empty results.

### Viewing Results

The app displays LLM results in floating popup windows. Each
popup shows the prompt name, a timestamp, and the analysis
content. Users can dismiss individual popups or view the full
execution history from the settings window.

## Development

This section covers building and understanding the project.

### Building

Build the project from the command line.

```bash
swift build
```

Run the test suite to verify changes.

```bash
swift test
```

### Project Structure

The project organises source code into four directories.

- `Maildroid/Sources/Models/` contains the data models for
  accounts, emails, prompts, and settings.
- `Maildroid/Sources/Services/` contains business logic for
  OAuth, Gmail, LLM integration, and scheduling.
- `Maildroid/Sources/Views/` contains SwiftUI views for the
  menu bar, settings, and result popups.
- `Maildroid/Sources/Utilities/` contains shared helpers for
  keychain access and time formatting.

### Key Files

These files serve as entry points for understanding the code.

- `Package.swift` defines the Swift package manifest.
- `Maildroid/Sources/MaildroidApp.swift` is the app entry
  point with the menu bar setup.
- `Maildroid/Sources/Config.template.swift` shows the
  required OAuth configuration structure.
- `Maildroid/Info.plist` contains the app configuration and
  URL schemes for OAuth callbacks.

## Distribution

Maildroid uses GitHub Actions for automated releases.

### GitHub Actions Workflows

The repository includes three workflow files.

- `.github/workflows/swift.yml` runs build verification on
  pull requests and pushes.
- `.github/workflows/direct-release.yml` creates signed
  release builds with DMG packaging for direct distribution.
- `.github/workflows/appstore-release.yml` builds and uploads
  the app to App Store Connect.

### Release Process

The direct release workflow triggers on version tags or manual
dispatch. The App Store workflow requires manual dispatch with
a version number. Both workflows generate `Config.swift` from
repository secrets and build the app for distribution.

## Release Configuration

Both release workflows require GitHub repository secrets.
Configure these secrets in the repository settings under
Settings > Secrets and variables > Actions.

### Common Secrets

Both workflows use the following secrets for OAuth
configuration.

- `GOOGLE_CLIENT_ID` stores the OAuth 2.0 client ID from
  the Google Cloud Console.
- `GOOGLE_CLIENT_SECRET` stores the OAuth 2.0 client secret
  from the Google Cloud Console.

Navigate to Google Cloud Console > APIs & Credentials >
OAuth 2.0 Client IDs to obtain these values.

### Direct Distribution Secrets

The direct distribution workflow uses these secrets for code
signing and notarisation.

- `APPLE_CERTIFICATE_BASE64` stores the base64-encoded
  Developer ID Application certificate as a `.p12` file.
- `APPLE_CERTIFICATE_PASSWORD` stores the password for
  the `.p12` certificate file.
- `APPLE_ID` stores the Apple ID email address used for
  notarisation.
- `APPLE_APP_SPECIFIC_PASSWORD` stores the app-specific
  password used for notarisation.
- `APPLE_TEAM_ID` stores the Apple Developer Team ID.

The following instructions explain how to obtain each value.

Export the Developer ID Application certificate from Keychain
Access as a `.p12` file. Run the following command to
base64-encode the certificate.

```bash
base64 -i certificate.p12 | pbcopy
```

Generate an app-specific password at appleid.apple.com under
Sign-In and Security > App-Specific Passwords. Find the Team
ID in the Apple Developer account under Membership.

### App Store Secrets

The App Store workflow requires the common secrets and the
following additional secrets.

- `APPSTORE_APP_CERTIFICATE_BASE64` stores the base64-encoded
  Apple Distribution certificate as a `.p12` file.
- `APPSTORE_APP_CERTIFICATE_PASSWORD` stores the password for
  the Apple Distribution certificate.
- `APPSTORE_INSTALLER_CERTIFICATE_BASE64` stores the
  base64-encoded 3rd Party Mac Developer Installer certificate
  as a `.p12` file.
- `APPSTORE_INSTALLER_CERTIFICATE_PASSWORD` stores the
  password for the installer certificate.
- `APPSTORE_PROVISIONING_PROFILE_BASE64` stores the
  base64-encoded Mac App Store provisioning profile.
- `APPSTORE_API_KEY_ID` stores the App Store Connect API
  key ID.
- `APPSTORE_API_ISSUER_ID` stores the App Store Connect API
  issuer ID.
- `APPSTORE_API_KEY_BASE64` stores the base64-encoded App
  Store Connect API private key as a `.p8` file.

The following instructions explain how to obtain each value.

Create the Apple Distribution and 3rd Party Mac Developer
Installer certificates in Apple Developer > Certificates.
Download each certificate; then export the certificate from
Keychain Access as a `.p12` file. Run the following command
to base64-encode each certificate.

```bash
base64 -i certificate.p12 | pbcopy
```

Create the provisioning profile in Apple Developer > Profiles
for Mac App Store distribution. Run the following command to
base64-encode the profile.

```bash
base64 -i profile.provisionprofile | pbcopy
```

Create the API key in App Store Connect > Users and Access >
Integrations > App Store Connect API. The key ID and issuer
ID appear on the same page after key creation.

## Privacy

Maildroid handles user data with the following principles:

- The app reads Gmail data in read-only mode for analysis.
- The app stores authentication tokens in the macOS Keychain.
- The app sends email content only to the configured LLM
  provider.
- The app runs entirely on your local machine.
- Cloud LLM providers process email content on their servers.
- Local providers keep all data on your machine.

## License

PostgreSQL License.
