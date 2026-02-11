# OAuth Flow

This document describes the Google OAuth 2.0 implementation used
in Maildroid for Gmail access.

## Overview

Maildroid uses OAuth 2.0 with PKCE (Proof Key for Code Exchange)
to authenticate users with their Google accounts.

## Flow Steps

1. The user clicks "Add Account" in the settings.
2. The app generates a PKCE code verifier and code challenge.
3. The app opens an `ASWebAuthenticationSession` with the Google
   authorization URL.
4. The user signs in and grants Gmail permissions.
5. Google redirects back to the app's custom URL scheme with an
   authorization code.
6. The app exchanges the code for access and refresh tokens.
7. Tokens are stored in the macOS Keychain.

## Scopes

The app requests the following Google OAuth scopes:

- `https://www.googleapis.com/auth/gmail.readonly` - Read-only
  access to Gmail messages.
- `https://www.googleapis.com/auth/userinfo.email` - User's email
  address.
- `https://www.googleapis.com/auth/userinfo.profile` - User's
  basic profile information.

## Token Storage

- Access tokens and refresh tokens are stored in the macOS
  Keychain using `KeychainHelper`.
- Each account's tokens are stored with a key derived from the
  account ID.
- Tokens are never stored in UserDefaults or on disk.

## Token Refresh

- Access tokens expire after approximately one hour.
- Before making Gmail API calls, the service checks token expiry.
- If expired, the service uses the refresh token to obtain a new
  access token.
- The new access token replaces the old one in the Keychain.
- If the refresh token is revoked, the user must re-authenticate.

## PKCE Details

- Code verifier: 43-128 character random string (unreserved
  characters).
- Code challenge: Base64url-encoded SHA256 hash of the verifier.
- Code challenge method: `S256`.

## URL Scheme

- The app registers a custom URL scheme in Info.plist for OAuth
  callbacks.
- Format: `com.maildroid.oauth://callback`
- The scheme is used by `ASWebAuthenticationSession` to receive
  the authorization code.

## Configuration

- Google Client ID is stored in `Config.swift` (gitignored).
- `Config.template.swift` provides a template for developers.
- The Client ID must be registered in the Google Cloud Console
  with the correct redirect URI.
