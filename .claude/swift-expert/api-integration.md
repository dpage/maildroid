# API Integration

This document describes the API integration patterns used in the
Maildroid project.

## Gmail API

### Authentication

- All Gmail API calls require a valid OAuth access token.
- The token is included as a Bearer token in the Authorization
  header.
- On 401 responses, the service attempts a token refresh before
  retrying.

### Endpoints

- List messages:
  `GET /gmail/v1/users/me/messages?q=after:{timestamp}`
- Get message:
  `GET /gmail/v1/users/me/messages/{id}?format=full`
- User profile:
  `GET /gmail/v1/users/me/profile`

### Response Parsing

- Messages use MIME multipart format.
- The service extracts the plain text body from MIME parts.
- Headers are parsed for subject, from, to, and date.
- Pagination uses `nextPageToken` for subsequent requests.

## LLM Provider APIs

### Anthropic

- Endpoint: `POST https://api.anthropic.com/v1/messages`
- Auth: `x-api-key` header.
- Request body includes `model`, `messages`, and `max_tokens`.
- Response contains `content[0].text`.

### OpenAI

- Endpoint: `POST https://api.openai.com/v1/chat/completions`
- Auth: Bearer token in Authorization header.
- Request body includes `model` and `messages` array.
- Response contains `choices[0].message.content`.

### Gemini

- Endpoint: `POST https://generativelanguage.googleapis.com/
  v1beta/models/{model}:generateContent`
- Auth: API key as query parameter.
- Request body includes `contents` array.
- Response contains `candidates[0].content.parts[0].text`.

### Ollama

- Endpoint: `POST http://localhost:11434/api/chat`
- Auth: None required (local service).
- Request body includes `model` and `messages`.
- Response contains `message.content`.
- List models: `GET http://localhost:11434/api/tags`

### Docker Model Runner

- Endpoint: `POST http://localhost:12434/engines/llama.cpp/
  v1/chat/completions`
- Auth: None required (local service).
- Uses OpenAI-compatible API format.
- List models via Docker Model Runner API.

## Common Patterns

### URLSession Usage

- All API calls use `URLSession.shared`.
- Requests use `async/await` with `URLSession.data(for:)`.
- JSON encoding/decoding uses `JSONEncoder`/`JSONDecoder`.
- Date decoding uses `.iso8601` strategy where applicable.

### Error Handling

- Network errors are caught and wrapped in service-specific
  error types.
- HTTP status codes are checked before parsing response bodies.
- 401 responses trigger token refresh for Gmail API calls.
- Rate limit responses (429) are reported to the user.

### Token Refresh

- When a Gmail API call returns 401, the service calls
  `GoogleAuthService.refreshToken()`.
- The refreshed token is stored in the Keychain.
- The original request is retried with the new token.
- If refresh fails, the account is marked as needing
  re-authentication.
