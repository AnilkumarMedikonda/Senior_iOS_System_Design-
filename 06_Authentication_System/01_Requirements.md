# 01 - Requirements

## Big Picture

```
LoginView → AuthService → POST /auth/login → { accessToken, refreshToken }
                │
                ├─► Keychain (tokens)
                └─► SessionManager (state: loggedIn)

Every API call → AuthInterceptor adds "Authorization: Bearer <access>"
   401 → TokenRefresher (one refresh for all) → retry once
   refresh fails → logout → LoginView
```

**Rule:** tokens live only in the Keychain, only one refresh runs at a time, and a failed refresh always ends in a clean logout.

## Functional
- Log in with username + password
- Stay logged in across app launches (auto-login)
- Attach the access token to every API request
- Refresh the access token silently when it expires
- Log out manually; force logout when the session is invalid
- Show the correct root screen: Login or Home

## Non-Functional
- Tokens stored securely (Keychain, never UserDefaults)
- Users never see an error just because the access token expired
- Many parallel 401s → **one** refresh call
- Logout clears every trace: tokens, caches, user data
- No token values in logs

## Out of Scope
- Sign up, forgot password
- Social login (Sign in with Apple / Google)
- Biometric unlock (can sit on top of the Keychain)

## Clarifying Questions to Ask
- Token lifetimes: access token? refresh token?
- Does the refresh token rotate (new one on every refresh)?
- Single device or multi-device sessions? Remote logout?
- Is biometric unlock required?

## Models

```swift
struct AuthTokens: Codable {
    let accessToken: String
    let refreshToken: String
}

struct User: Codable {
    let id: Int
    let username: String
    let firstName: String
}

enum SessionState: Equatable {
    case checking        // app launch, reading Keychain
    case loggedOut
    case loggedIn
}
```

## API Contract (DummyJSON)

| Endpoint | Body | Returns |
|----------|------|---------|
| `POST /auth/login` | username, password, expiresInMins | accessToken, refreshToken, user |
| `POST /auth/refresh` | refreshToken, expiresInMins | accessToken, refreshToken |
| `GET /auth/me` | Header: Bearer token | current user |

## One-Liner
Store tokens in the Keychain, attach them to every call, refresh once on 401, and log out cleanly when refresh fails.
