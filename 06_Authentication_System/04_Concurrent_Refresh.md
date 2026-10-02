# 04 - Concurrent Refresh

## The Problem
The home screen fires 5 requests at once. The access token has expired:

```
GET /profile   → 401 → refresh #1
GET /orders    → 401 → refresh #2
GET /cart      → 401 → refresh #3
GET /wishlist  → 401 → refresh #4
GET /offers    → 401 → refresh #5
```

With **rotating refresh tokens**, refresh #1 succeeds and invalidates the old refresh token, so #2–#5 fail → the user is **logged out by mistake**.

## The Fix — Single Refresh, Many Waiters

```
GET /profile  → 401 → start refresh, waiters = [profile]
GET /orders   → 401 → refresh in progress, waiters = [profile, orders]
GET /cart     → 401 → waiters = [profile, orders, cart]
                         ...
refresh done  → save tokens → call every waiter → each retries once
```

## Code

```swift
final class TokenRefresher {
    private let api: AuthAPI
    private let tokenStore: TokenStore
    private let queue = DispatchQueue(label: "auth.refresh.queue")
    private var isRefreshing = false
    private var waiters: [(Result<Void, AuthError>) -> Void] = []

    init(api: AuthAPI, tokenStore: TokenStore) {
        self.api = api
        self.tokenStore = tokenStore
    }

    func refresh(completion: @escaping (Result<Void, AuthError>) -> Void) {
        queue.async {
            // 1. Join the waiting list
            self.waiters.append(completion)
            // 2. Already refreshing → just wait
            if self.isRefreshing { return }
            self.isRefreshing = true
            guard let refreshToken = self.tokenStore.tokens?.refreshToken else {
                self.finish(.failure(.noRefreshToken))
                return
            }
            // 3. One network call for everyone
            self.api.refresh(refreshToken) { result in
                self.queue.async {
                    switch result {
                    case .success(let tokens):
                        self.tokenStore.save(tokens)
                        self.finish(.success(()))
                    case .failure(let error):
                        self.finish(.failure(error))
                    }
                }
            }
        }
    }

    private func finish(_ result: Result<Void, AuthError>) {
        let list = waiters
        waiters = []
        isRefreshing = false
        for waiter in list {
            DispatchQueue.main.async { waiter(result) }
        }
    }
}
```

## Why It Works
- **Serial queue** → `isRefreshing` and `waiters` never race
- **First 401 starts the refresh**, every other 401 just appends a waiter
- **One result for all** → everyone retries with the same new token, or everyone fails together
- `finish` copies and clears the list **before** calling waiters → a waiter that triggers a new refresh starts cleanly

## Edge Case — Request Started With an Old Token
A request sent just before the refresh finishes can still return 401 *after* new tokens are saved. Fix: before refreshing, compare the token the request used with the current one; if they differ, **retry immediately** with the new token instead of refreshing again.

## Swift Concurrency Version (same idea)
An `actor` holding `var refreshTask: Task<AuthTokens, Error>?`: the first caller creates the task, others `await` the same task.

## Senior Point
This is the most-asked auth question. The answer is: one in-flight refresh, all 401s wait on it, serialized state, and a retry-once rule per request.

## One-Liner
The first 401 starts one refresh, every other 401 waits for it, and all retry with the same new token.
