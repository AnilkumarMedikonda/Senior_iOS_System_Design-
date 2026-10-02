# 05 - Logout and Session Expiry

## Kinds of Logout

| Type | Trigger | Message |
|------|---------|---------|
| Manual | User taps Log Out | None |
| Forced | Refresh rejected (401/403) | "Session expired, please log in again" |
| Remote | Server revokes session (password change, other device) | "You were logged out" |
| Fresh install | Keychain has tokens, first launch | None (silent clear) |

## Logout Checklist — Clear Everything

```swift
func logout(reason: String?) {
    // 1. Tell the server (best effort, don't wait)
    authAPI.logout()
    // 2. Cancel in-flight requests
    URLSession.shared.getAllTasks { tasks in tasks.forEach { $0.cancel() } }
    // 3. Clear secrets
    tokenStore.clear()
    // 4. Clear user data
    imageCache.removeAll()
    URLCache.shared.removeAllCachedResponses()
    database.deleteUserData()
    // 5. Reset UI to Login
    state = .loggedOut
    expiryMessage = reason
}
```

Missing step 4 is a privacy bug: the next user on the same device sees the previous user's data.

## Session Expiry Flow

```
Any API call → 401
   → TokenRefresher.refresh()
        ├─ 200 → retry original → user never notices ✅
        ├─ 401/403 → forceLogout("Session expired") → Login screen
        └─ no internet → keep session, show offline error
```

## Auto-Login on Launch

```
App launch → state = .checking (splash)
   ├─ Keychain has tokens? no  → .loggedOut
   └─ yes → GET /auth/me
            ├─ 200 → .loggedIn
            ├─ 401 → refresh → retry /auth/me → .loggedIn or .loggedOut
            └─ offline → .loggedIn with cached user (offline-friendly)
```

## Root Switching

```swift
switch session.state {
case .checking:
    SplashView()
case .loggedOut:
    LoginView()
case .loggedIn:
    HomeView()
}
```

Replace the **root**, don't present Login on top: no Back button into the old session.

## Full Flow

```
Launch → Keychain → /auth/me → Home
API call → Bearer token → 401
   → single refresh (all 401s wait) → retry once
   → refresh rejected → clear tokens + caches + DB → Login ("Session expired")
Logout tap → same cleanup → Login
```

## Senior Point
Make logout one function that every path calls (manual, forced, remote), so cleanup can never be partially done. Never log out on network errors.

## One-Liner
One logout function clears tokens, caches and user data and swaps the root to Login; force it only when the server rejects the refresh.
