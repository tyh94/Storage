//
//  FileStorageMock.swift
//  Storage
//
//  Created by Татьяна Макеева on 24.04.2025.
//

import Foundation

public struct FileStorageMock: FileStorage {
    public init() {}
    
    public func resource(
        fileName: String,
        at resource: StorageResource?
    ) async throws -> StorageResource {
        StorageResource(name: "", path: "", type: .dir, modified: "")
    }
    
    public func resource(
        folderName: String,
        at resource: StorageResource?
    ) async throws -> StorageResource {
        StorageResource(name: "", path: "", type: .dir, modified: "")
    }
    
    public func data(for resource: StorageResource) async throws -> Data {
        Data()
    }
    
    public func createFolder(at resource: StorageResource?, folderName: String) async throws -> StorageResource {
        StorageResource(name: "", path: "", type: .dir, modified: "")
    }
    
    public func createFile(at resource: StorageResource?, fileName: String, with data: Data?) async throws -> StorageResource {
        StorageResource(name: "", path: "", type: .dir, modified: "")
    }
    
    public func updateFile(at resource: StorageResource, with data: Data) async throws {
        
    }
    
    public func renameFile(at resource: StorageResource, with filename: String) async throws {
        
    }
    
    public func renameFolder(at resource: StorageResource, with filename: String) async throws {
        
    }
    
    public func moveFile(from pathFrom: String, to pathTo: String) async throws {
        
    }
    
    public func delete(at resource: StorageResource) async throws {
        
    }
    
    public func deleteAll() async throws {
    }
    
    public func getResources(
        at resource: StorageResource?,
        limit: Int,
        offsetToken: String?
    ) async throws -> (resources: [StorageResource], nextOffsetToken: String?) {
        if offsetToken == nil {
            return ([StorageResource(name: "Test", path: "Test", type: .dir, modified: "")], nil)
        }
        return ([], nil)
    }
    
    public func getFolder(at folderName: String) async throws -> StorageResource {
        StorageResource(name: folderName, path: folderName, type: .dir, modified: "")
    }
}
