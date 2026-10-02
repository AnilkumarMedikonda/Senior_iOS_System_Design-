# 03 - Refresh Flow

## Two Tokens, Two Jobs

| Token | Lifetime | Sent with | Purpose |
|-------|----------|-----------|---------|
| Access token | Short (15–60 min) | Every API call | Prove who you are |
| Refresh token | Long (days–months) | Only `/auth/refresh` | Get a new access token |

A short access token limits damage if it leaks; the refresh token keeps the user logged in.

## Reactive Refresh — on 401

```
GET /orders  (Bearer old-access)
   ← 401 Unauthorized
POST /auth/refresh { refreshToken }
   ← 200 { accessToken, refreshToken }   → save to Keychain
GET /orders  (Bearer new-access)          → retry ONCE
   ← 200 ✅
```

## Code — AuthInterceptor in APIClient

```swift
func send<T: Decodable>(_ request: URLRequest, isRetry: Bool = false, completion: @escaping (Result<T, NetworkError>) -> Void) {
    var authorized = request
    if let token = tokenStore.tokens?.accessToken {
        authorized.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    perform(authorized) { (result: Result<T, NetworkError>) in
        // 401 → refresh once, then retry once
        if case .failure(.unauthorized) = result, !isRetry {
            self.refresher.refresh { refreshResult in
                switch refreshResult {
                case .success:
                    self.send(request, isRetry: true, completion: completion)
                case .failure:
                    self.session.forceLogout(reason: "Session expired")
                    completion(.failure(.unauthorized))
                }
            }
            return
        }
        completion(result)
    }
}
```

## Rules
- Retry the original request **only once** (`isRetry` flag) → no infinite loop
- Never attach the access token to `/auth/refresh` or `/auth/login`
- Refresh returns 401/403 → refresh token is dead → **logout**
- Refresh fails with no internet → keep tokens, show offline error (don't log out!)

## Proactive Refresh (optional)
Decode the JWT `exp` claim and refresh ~60s **before** expiry, so most requests never see a 401. Still keep the reactive path as the safety net.

## Refresh Token Rotation
Many servers return a **new refresh token** on every refresh and invalidate the old one. Always save **both** new tokens. Using an old refresh token again usually kills the whole session (theft detection).

## Senior Point
Distinguish *why* refresh failed: 401 from refresh = logout, network error = stay logged in and retry later. Logging users out on a flaky network is a common bug.

## One-Liner
On 401, refresh once, retry once, save both new tokens, and log out only when the refresh itself is rejected.
