//
//  YandexFileStorage.swift
//  Storage
//
//  Created by Татьяна Макеева on 05.04.2025.
//

import Foundation
import MKVNetwork
import YandexLoginSDK

final class YandexFileStorage: FileStorage {
    enum StorageError: LocalizedError {
        case invalidURL
        case fileNotFound(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL provided"
            case let .fileNotFound(file):
                return "File \(file) not found at specified location"
            }
        }
    }
    
    private let network: NetworkManaging
    private let rootPath: String
    private let logger: Logger?
    
    init(
        rootPath: String,
        network: NetworkManaging,
        logger: Logger? = nil
    ) {
        self.rootPath = rootPath
        self.network = network
        self.logger = logger
    }
    
    func resource(
        fileName: String,
        at resource: StorageResource?
    ) async throws -> StorageResource {
        var offsetToken: String? = nil

        repeat {
            let page = try await getResources(at: resource, limit: 100, offsetToken: offsetToken)

            if let found = page.resources.first(where: { $0.name == fileName }) {
                return found
            }

            offsetToken = page.nextOffsetToken
        } while offsetToken != nil

        throw StorageError.fileNotFound(fileName)
    }
    
    func resource(
        folderName: String,
        at resource: StorageResource?
    ) async throws -> StorageResource {
        var offsetToken: String? = nil

        repeat {
            let page = try await getResources(at: resource, limit: 100, offsetToken: offsetToken)

            if let found = page.resources.first(where: {
                $0.name == folderName && $0.type == .dir
            }) {
                return found
            }

            offsetToken = page.nextOffsetToken
        } while offsetToken != nil

        throw StorageError.fileNotFound(folderName)
    }
    
    func data(fileName: String) async throws -> Data {
        logger?.logYandex("Loading data for fileName: \(fileName)", level: .debug)
        do {
            let metadataURL = try await urlToLoadFile(path: fileName)
            let data: Data = try await network.dataRequest(url: metadataURL, method: .get)
            logger?.logYandex("Successfully loaded data for fileName: \(fileName)", level: .debug)
            return data
        } catch {
            logger?.logYandex("Failed to load data for fileName: \(fileName): \(error.localizedDescription)", level: .error)
            throw error
        }
    }
    
    func data(for resource: StorageResource) async throws -> Data {
        try await data(fileName: resource.path)
    }
    
    func urlToLoadFile(path: String) async throws -> URL {
        logger?.logYandex("Generating download URL for: \(path)", level: .debug)
        
        let fullPath = path.contains(rootPath) ? path : "\(rootPath)/\(path)"
        let parameters: Request.Query<String> = ["path": fullPath]
        
        do {
            let reponse: YandexDownloadResponse = try await network.dataRequest(
                url: URL(string: "https://cloud-api.yandex.net/v1/disk/resources/download")!,
                method: .get,
                parameters: .query(parameters)
            )
            
            guard let metadataURL = URL(string: reponse.href) else {
                logger?.logYandex("Invalid download URL received", level: .error)
                throw StorageError.invalidURL
            }
            
            logger?.logYandex("Generated download URL: \(metadataURL)", level: .debug)
            return metadataURL
        } catch {
            logger?.logYandex("Failed to generate download URL: \(error.localizedDescription)", level: .error)
            throw error
        }
    }
    
    func getFolder(at folderName: String) async throws -> StorageResource {
        try await resource(folderName: folderName, at: nil)
    }
    
    func getResources(
        at resource: StorageResource?,
        limit: Int,
        offsetToken: String?
    ) async throws -> (resources: [StorageResource], nextOffsetToken: String?) {
        logger?.logYandex("Fetching resources at: \(resource?.path ?? ""), limit: \(limit), offset: \(offsetToken ?? "empty")", level: .debug)
        let pathRequest = createPath(for: resource, fileOrFolderName: nil)
        
        let offset: Int = offsetToken.flatMap { Int($0) } ?? 0
        let parameters: Request.Query<String> = [
            "path": pathRequest,
            "limit": "\(limit)",
            "offset": "\(offset)",
        ]
        
        do {
            let reponse: YandexStorageResourcesResponse = try await network.dataRequest(
                url: URL(string: "https://cloud-api.yandex.net/v1/disk/resources")!,
                method: .get,
                parameters: .query(parameters))
            
            logger?.logYandex("Fetched \(reponse.embedded.items.count) resources", level: .info)
            let resources = reponse.embedded.items.map {
                StorageResource(
                    name: $0.name,
                    path: $0.path,
                    type: $0.toType,
                    modified: $0.modified
                )
            }
            let nextToken = resources.count < limit ? nil : "\(offset + limit)"
            return (resources, nextToken)
        } catch {
            logger?.logYandex("Failed to fetch resources: \(error.localizedDescription)", level: .error)
            throw error
        }
    }
    
    private func createPath(for resource: StorageResource?, fileOrFolderName: String?) -> String {
        var pathRequest: String
        if let path = resource?.path, path.contains(rootPath) {
            pathRequest = path
        } else if let path = resource?.path.replacingOccurrences(of: "disk:/", with: ""), !path.isEmpty {
            pathRequest = "\(rootPath)/\(path)"
        } else {
            pathRequest = rootPath
        }
        if let fileOrFolderName, !fileOrFolderName.isEmpty {
            pathRequest = pathRequest.appending("/").appending(fileOrFolderName)
        }
        return pathRequest
            .replacingOccurrences(of: "//", with: "/")
    }
    
    func createFolder(at resource: StorageResource?, folderName: String) async throws -> StorageResource {
        let path = [resource?.path, folderName].compactMap { $0 }.joined(separator: "/")
        logger?.logYandex("Creating folder at: \(path)", level: .info)
        
        let fullPath = createPath(for: resource, fileOrFolderName: folderName)
        let parameters: Request.Query<String> = ["path": fullPath]
        
        do {
            try await network.dataRequest(
                url: URL(string: "https://cloud-api.yandex.net/v1/disk/resources")!,
                method: .put,
                parameters: .query(parameters)
            )
            logger?.logYandex("Folder created successfully: \(fullPath)", level: .info)
            return StorageResource(name: folderName, path: path, type: .dir, modified: "")
        } catch {
            logger?.logYandex("Failed to create folder: \(error.localizedDescription)", level: .error)
            throw error
        }
    }
    
    @discardableResult
    func createFile(at resource: StorageResource?, fileName: String, with data: Data?) async throws -> StorageResource {
        let path = [resource?.path, fileName].compactMap { $0 }.joined(separator: "/")
        logger?.logYandex("Creating file at: \(path)", level: .info)
        
        let fullPath = createPath(for: resource, fileOrFolderName: fileName)
        let parameters: Request.Query<String> = ["path": fullPath]
        
        do {
            let reponse: YandexUploadResponse = try await network.dataRequest(
                url: URL(string: "https://cloud-api.yandex.net/v1/disk/resources/upload")!,
                method: .get,
                parameters: .query(parameters)
            )
            
            guard let uploadURL = URL(string: reponse.href) else {
                logger?.logYandex("Invalid upload URL received", level: .error)
                throw StorageError.invalidURL
            }
            
            try await network.uploadRequest(
                data: Data(),
                url: uploadURL,
                method: reponse.method
            )
            
            logger?.logYandex("File created successfully: \(fullPath)", level: .info)
            return StorageResource(name: fileName, path: path, type: .file(url: "", previewURL: ""), modified: "")
        } catch {
            logger?.logYandex("Failed to create file: \(error.localizedDescription)", level: .error)
            throw error
        }
    }
    
    func updateFile(at resource: StorageResource, with data: Data) async throws {
        let path = resource.path
        logger?.logYandex("Creating file at: \(path)", level: .info)
        
        let fullPath = createPath(for: resource, fileOrFolderName: nil)
        let parameters: Request.Query<String> = ["path": fullPath, "overwrite": "true"]
        
        do {
            let reponse: YandexUploadResponse = try await network.dataRequest(
                url: URL(string: "https://cloud-api.yandex.net/v1/disk/resources/upload")!,
                method: .get,
                parameters: .query(parameters)
            )
            
            guard let uploadURL = URL(string: reponse.href) else {
                logger?.logYandex("Invalid upload URL received", level: .error)
                throw StorageError.invalidURL
            }
            
            try await network.uploadRequest(
                data: data,
                url: uploadURL,
                method: reponse.method
            )
            
            logger?.logYandex("File created successfully: \(fullPath)", level: .info)
        } catch {
            logger?.logYandex("Failed to create file: \(error.localizedDescription)", level: .error)
            throw error
        }
    }
    
    func renameFile(at resource: StorageResource, with filename: String) async throws {
        let directoryPath = (resource.path as NSString).deletingLastPathComponent
        let newPath = (directoryPath as NSString).appendingPathComponent(filename)
        
        try await moveFile(from: resource.path, to: newPath)
        logger?.logYandex("Successfully renamed file from \(resource.name) to \(filename)", level: .debug)
    }
    
    func renameFolder(at resource: StorageResource, with filename: String) async throws {
        logger?.logYandex("Renaming folder from: \(resource.name) to: \(filename)", level: .info)
        
        let directoryPath = (resource.path as NSString).deletingLastPathComponent
        let newPath = (directoryPath as NSString).appendingPathComponent(filename)
        
        try await moveFile(from: resource.path, to: newPath)
        logger?.logYandex("Successfully renamed folder from \(resource.name) to \(filename)", level: .debug)
    }
    
    func moveFile(from pathFrom: String, to pathTo: String) async throws {
        logger?.logYandex("Moving file from: \(pathFrom) to: \(pathTo)", level: .info)
        
        let fromPath = pathFrom.contains(rootPath) ? pathFrom : "\(rootPath)/\(pathFrom)"
        let toPath = pathTo.contains(rootPath) ? pathTo : "\(rootPath)/\(pathTo)"
        
        let parameters: Request.Query<String> = [
            "from": fromPath,
            "path": toPath,
            "overwrite": "true",
            "force_async": "false",
        ]
        
        do {
            try await network.dataRequest(
                url: URL(string: "https://cloud-api.yandex.net/v1/disk/resources/move")!,
                method: .post,
                parameters: .query(parameters)
            )
            logger?.logYandex("File moved successfully", level: .info)
        } catch {
            logger?.logYandex("Failed to move file: \(error.localizedDescription)", level: .error)
            throw error
        }
    }
    
    func delete(at resource: StorageResource) async throws {
        logger?.logYandex("Deleting item at: \(resource)", level: .warning)
        let path = resource.path
        let fullPath = path.contains(rootPath) ? path : "\(rootPath)/\(path)"
        var parameters: Request.Query<String> = ["path": fullPath]
        if resource.type == .dir {
            parameters["recursive"] = "true"
        }
        try await network.dataRequest(
            url: URL(string: "https://cloud-api.yandex.net/v1/disk/resources")!,
            method: .delete,
            parameters: .query(parameters)
        )
    }
    
    func deleteAll() async throws {
        logger?.logYandex("Performing full log out", level: .warning)
        do {
            // TODO: remove token
            try YandexLoginSDK.shared.logout()
            logger?.logYandex("Logout successful", level: .info)
        } catch {
            logger?.logYandex("Logout failed: \(error.localizedDescription)", level: .error)
            throw error
        }
    }
}

extension Logger {
    fileprivate func logYandex(
        _ message: String,
        level: LogLevel,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(
            message,
            level: level,
            type: .yandex,
            file: file,
            function: function,
            line: line
        )
    }
}

fileprivate struct YandexDownloadResponse: Codable {
    let href: String
}

fileprivate struct YandexUploadResponse: Codable {
    enum CodingKeys: String, CodingKey {
        case operationid = "operation_id"
        case href, method, templated
    }
    
    let operationid: String
    let href: String
    let method: HTTPMethod
    let templated: Bool
}


extension YandexStorageResourcesResponse.Embedded.Item {
    fileprivate var toType: StorageResource.ItemType {
        switch self.type {
        case .dir: return .dir
        case .file: return .file(url: file!, previewURL: preview)
        }
    }
}
