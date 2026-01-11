//
//  KeyValueStorage.swift
//  Storage
//
//  Created by Татьяна Макеева on 02.01.2026.
//

import Foundation

public protocol KeyValueStorage: Sendable {
    func set<T: Codable>(_ value: T, forKey key: String) throws
    func object<T: Codable>(forKey key: String) throws -> T?
    func removeObject(forKey key: String) throws
}

extension KeyValueStorage {
    public func set<T: Codable>(_ value: T, forKey key: some RawRepresentable<String>) throws {
        try set(value, forKey: key.rawValue)
    }
    
    public func object<T: Codable>(forKey key: some RawRepresentable<String>) throws -> T? {
        try object(forKey: key.rawValue)
    }
    
    public func removeObject(forKey key: some RawRepresentable<String>) throws {
        try removeObject(forKey: key.rawValue)
    }
}
