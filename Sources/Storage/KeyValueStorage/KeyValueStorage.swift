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
