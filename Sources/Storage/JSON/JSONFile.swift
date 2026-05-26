//
//  JSONFile.swift
//  Storage
//
//  Created by Татьяна Макеева on 04.01.2026.
//

import Foundation

public struct JSONFile<T: Decodable> {
    public let resource: StorageResource
    public let value: T
    
    public init(resource: StorageResource, value: T) {
        self.resource = resource
        self.value = value
    }
}

extension FileStorage {
    public func loadJSON<T: Decodable>(
        _ type: T.Type,
        from resource: StorageResource,
        logger: Logger? = nil
    ) async throws -> T {
        let data = try await data(for: resource)
        if let jsonString = String(data: data, encoding: .utf8) {
            logger?.info("Полученные данные JSON:", type: .common)
            logger?.info(jsonString, type: .common)
        }
        let decoder = JSONDecoder()
        // Настройте стратегию декодирования дат
        decoder.dateDecodingStrategy = .secondsSince1970
        
        return try decoder.decode(T.self, from: data)
    }
    
    public func saveJSON<T: Encodable>(
        _ value: T,
        to resource: StorageResource
    ) async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .secondsSince1970
        let data = try encoder.encode(value)
        try await updateFile(at: resource, with: data)
    }
}
