# 02 - Token Storage

## Where to Store

| Storage | Encrypted | Survives reinstall | Use for tokens? |
|---------|-----------|--------------------|-----------------|
| UserDefaults | No (plain plist) | No | ❌ Never |
| File in Documents | No (unless protected) | No | ❌ |
| **Keychain** | Yes (hardware-backed) | **Yes** | ✅ |
| Memory only | — | No | Access token cache |

## Strategy
- **Refresh token** → Keychain (long-lived, most sensitive)
- **Access token** → Keychain + in-memory copy for fast reads
- **User profile** → can be stored in normal storage (not secret)

## Accessibility Level

| Option | Meaning |
|--------|---------|
| `kSecAttrAccessibleWhenUnlocked` | Only while device is unlocked |
| `kSecAttrAccessibleAfterFirstUnlock` | After first unlock since boot → works for background refresh |
| `...ThisDeviceOnly` | Not in backups, not moved to a new device ✅ |

Use **`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`**: background tasks work, and tokens never leave the device.

## Code

```swift
import Security

final class KeychainStore {
    private let service = "com.shop.auth"

    func save(_ data: Data, for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(attributes as CFDictionary, nil)
    }

    func read(_ key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess {
            return result as? Data
        }
        return nil
    }

    func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
```

## Token Store on Top

```swift
final class TokenStore {
    private let keychain = KeychainStore()
    private var cached: AuthTokens?

    var tokens: AuthTokens? {
        if let cached = cached { return cached }
        guard let data = keychain.read("tokens"),
              let tokens = try? JSONDecoder().decode(AuthTokens.self, from: data) else { return nil }
        cached = tokens
        return tokens
    }

    func save(_ tokens: AuthTokens) {
        cached = tokens
        if let data = try? JSONEncoder().encode(tokens) {
            keychain.save(data, for: "tokens")
        }
    }

    func clear() {
        cached = nil
        keychain.delete("tokens")
    }
}
```

## Reinstall Gotcha
Keychain items **survive app deletion**. After a reinstall, old tokens would auto-login a user who expects a fresh start.

```swift
// On launch
if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
    tokenStore.clear()
    UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
}
```

UserDefaults is wiped on delete, so this flag detects a fresh install.

## Senior Point
Never log tokens, never put them in URLs (they end up in server logs), and never store them in UserDefaults. Save the tokens as **one item** so access and refresh can't get out of sync.

## One-Liner
Keychain with AfterFirstUnlockThisDeviceOnly, an in-memory cache for speed, and a first-launch check to clear tokens after reinstall.
