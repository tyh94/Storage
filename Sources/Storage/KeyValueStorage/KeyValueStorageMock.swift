//
//  KeyValueStorageMock.swift
//  Storage
//
//  Created by Татьяна Макеева on 11.01.2026.
//

import Foundation

public struct KeyValueStorageMock: KeyValueStorage {
    public init() {}
    public func set<T: Codable>(_ value: T, forKey key: String) throws {
        
    }
    
    public func object<T: Codable>(forKey key: String) throws -> T? {
        nil
    }
    
    public func removeObject(forKey key: String) throws {
        
    }
}
