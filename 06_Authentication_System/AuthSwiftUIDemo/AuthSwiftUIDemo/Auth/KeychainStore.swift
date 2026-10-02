//
//  KeychainStore.swift
//  AuthSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation
import Security

final class KeychainStore {
    private let service = "com.demo.auth"

    // MARK: - Save (delete old → add new)

    @discardableResult
    func save(_ data: Data, for key: String) -> Bool {
        let query = baseQuery(key)
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(attributes as CFDictionary, nil)
        print("KEYCHAIN: save \(key) → \(status == errSecSuccess ? "ok" : "failed \(status)")")
        return status == errSecSuccess
    }

    // MARK: - Read

    func read(_ key: String) -> Data? {
        var query = baseQuery(key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess {
            return result as? Data
        } else {
            return nil
        }
    }

    // MARK: - Delete

    func delete(_ key: String) {
        SecItemDelete(baseQuery(key) as CFDictionary)
        print("KEYCHAIN: delete \(key)")
    }

    private func baseQuery(_ key: String) -> [String: Any] {
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
    }
}
