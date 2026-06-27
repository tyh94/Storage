//
//  KeyValueStorageMock.swift
//  Storage
//
//  Created by Татьяна Макеева on 11.01.2026.
//

import Foundation

public final class KeyValueStorageMock: KeyValueStorage, @unchecked Sendable {
    var objects: [String: Data]
    
    public init(objects: [String: Data] = [:]) {
        self.objects = objects
    }
    
    public func set<T>(_ value: T, forKey key: String) throws where T : Decodable, T : Encodable {
        let data = try JSONEncoder().encode(value)
        objects[key] = data
    }
    
    public func object<T>(forKey key: String) throws -> T? where T : Decodable, T : Encodable {
        guard let data = objects[key] else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    public func removeObject(forKey key: String) throws {
        objects.removeValue(forKey: key)
    }
}
