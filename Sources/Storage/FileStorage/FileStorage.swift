//
//  FileStorage.swift
//  Storage
//
//  Created by Татьяна Макеева on 05.04.2025.
//

import Foundation

public protocol FileStorage: Sendable {
    func resource(
        fileName: String,
        at resource: StorageResource?
    ) async throws -> StorageResource
    func resource(
        folderName: String,
        at resource: StorageResource?
    ) async throws -> StorageResource
    func data(for resource: StorageResource) async throws -> Data
    func getFolder(at folderName: String) async throws -> StorageResource
    func getResources(
        at resource: StorageResource?,
        limit: Int,
        offsetToken: String?
    ) async throws -> (resources: [StorageResource], nextOffsetToken: String?)
    
    @discardableResult
    func createFolder(at resource: StorageResource?, folderName: String) async throws -> StorageResource
    @discardableResult
    func createFile(at resource: StorageResource?, fileName: String, with data: Data?) async throws -> StorageResource
    func updateFile(at resource: StorageResource, with data: Data) async throws
    func renameFile(at resource: StorageResource, with filename: String) async throws
    func renameFolder(at resource: StorageResource, with filename: String) async throws
    func moveFile(from pathFrom: String, to pathTo: String) async throws
    
    func delete(at resource: StorageResource) async throws
    func deleteAll() async throws
}

extension FileStorage {
    public func getResources(at resource: StorageResource?) async throws -> (resources: [StorageResource], nextOffsetToken: String?) {
        try await getResources(at: resource, limit: 20, offsetToken: nil)
    }
    
    @discardableResult
    public func createFolderIfNeeded(at folderName: String, at atResource: StorageResource?) async throws -> StorageResource {
        do {
            return try await resource(folderName: folderName, at: atResource)
        } catch {
            return try await createFolder(at: atResource, folderName: folderName)
        }
    }
}
