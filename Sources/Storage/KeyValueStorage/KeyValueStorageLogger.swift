//
//  KeyValueStorageLogger.swift
//  Storage
//
//  Created by Татьяна Макеева on 04.06.2026.
//

import Foundation

extension KeyValueStorage {
    public func logging(logger: Logger?) -> KeyValueStorage {
        guard let logger else {
            return self
        }
        return KeyValueStorageLogger(storage: self, logger: logger)
    }
}

struct KeyValueStorageLogger: KeyValueStorage {
    let storage: KeyValueStorage
    let logger: Logger
    
    public func set<T: Codable>(_ value: T, forKey key: String) throws {
        do {
            try storage.set(value, forKey: key)
        } catch {
            logger.error(error.localizedDescription, type: .common)
            throw error
        }
    }
    
    public func object<T: Codable>(forKey key: String) throws -> T? {
        do {
            return try storage.object(forKey: key)
        } catch {
            logger.error(error.localizedDescription, type: .common)
            throw error
        }
    }
    
    public func removeObject(forKey key: String) throws {
        do {
            try storage.removeObject(forKey: key)
        } catch {
            logger.error(error.localizedDescription, type: .common)
            throw error
        }
    }
}
