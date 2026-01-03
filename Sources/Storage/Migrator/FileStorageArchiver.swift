//
//  FileStorageArchiver.swift
//  Storage
//
//  Created by Татьяна Макеева on 06.09.2025.
//

import Foundation

public protocol FileStorageArchiver {
    func createArchive(
        from source: FileStorage,
        archiveName: String
    ) async throws -> URL
}
