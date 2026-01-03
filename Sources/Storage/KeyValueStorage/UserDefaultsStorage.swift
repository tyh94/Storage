//
//  UserDefaultsStorage.swift
//  Storage
//
//  Created by Татьяна Макеева on 20.08.2025.
//

import Foundation

public final class UserDefaultsStorage: KeyValueStorage, @unchecked Sendable {
    private let userDefaults = UserDefaults.standard
    
    public init() {}
    
    public func set<T>(_ value: T, forKey key: String) throws where T : Decodable, T : Encodable {
        let data = try JSONEncoder().encode(value)
        userDefaults.set(data, forKey: key)
    }
    
    public func object<T>(forKey key: String) throws -> T? where T : Decodable, T : Encodable {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    public func removeObject(forKey key: String) throws {
        userDefaults.removeObject(forKey: key)
    }
}

extension UserDefaults {
    @objc dynamic var userValue: Int {
        integer(forKey: "value")
    }
}

