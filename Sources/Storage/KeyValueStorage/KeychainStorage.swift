//
//  KeychainStorage.swift
//  Storage
//
//  Created by Татьяна Макеева on 20.08.2025.
//

import Foundation

public final class KeychainStorage: KeyValueStorage {
    public enum KeychainError: LocalizedError {
        case tokenError
        case duplicateEntry
        case unknown(OSStatus)
        case encodingFailed
        
        public var errorDescription: String? {
            switch self {
            case .tokenError:
                return "Token error occurred"
            case .duplicateEntry:
                return "Duplicate entry found in keychain"
            case .unknown(let status):
                return "Unknown keychain error (OSStatus: \(status))"
            case .encodingFailed:
                return "Failed to encode data for keychain storage"
            }
        }
    }
    
    public init() {}

    public func set<T: Codable>(_ value: T, forKey key: String) throws {
        let data: Data
        
        // Special handling for String to avoid JSON encoding issues
        if let stringValue = value as? String {
            guard let stringData = stringValue.data(using: .utf8) else {
                throw KeychainError.encodingFailed
            }
            data = stringData
        } else {
            // Use PropertyListEncoder for other Codable types
            data = try PropertyListEncoder().encode(value)
        }
        try? removeObject(forKey: key)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status != errSecDuplicateItem else {
            throw KeychainError.duplicateEntry
        }
        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
    }

    public func object<T: Codable>(forKey key: String) throws -> T? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            if let stringData = String(data: data, encoding: .utf8),
               let result = stringData as? T {
                return result
            } else {
                return try PropertyListDecoder().decode(T.self, from: data)
            }
        }
        return nil
    }
    
    public func removeObject(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
    }
}
