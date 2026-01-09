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
    
    // MARK: - FileStorage методы
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

    private func resourceOnYandexDisk(fileName: String, at resource: StorageResource? = nil) async throws -> StorageResource {
        // Формируем путь для запроса
        let pathRequest: String
        if let resource = resource, !resource.path.isEmpty {
            // Убираем префикс "disk:/" если есть и корректируем путь
            let cleanPath = resource.path.replacingOccurrences(of: "disk:/", with: "")
            pathRequest = "\(rootPath)/\(cleanPath)"
        } else {
            pathRequest = rootPath
        }

        // Запросим максимум 1000 файлов, если надо можно разбить на страницы
        let parameters: Request.Query<String> = [
            "path": pathRequest,
            "limit": "1000"
        ]

        do {
            // Запрос списка файлов из Яндекс.Диска
            let response: YandexStorageResourcesResponse = try await network.dataRequest(
                url: URL(string: "https://cloud-api.yandex.net/v1/disk/resources")!,
                method: .get,
                parameters: .query(parameters)
            )

            // Поиск файла по имени
            if let item = response.embedded.items.first(where: { $0.name == fileName }) {
                // Вернём StorageResource, найденный на Яндекс.Диске
                return StorageResource(
                    name: item.name,
                    path: item.path,
                    type: item.toType,
                    modified: item.modified
                )
            } else {
                // Файл не найден - кидаем ошибку
                throw StorageError.fileNotFound(fileName)
            }
        } catch {
            // Логируем и кидаем дальше ошибку
            logger?.logYandex("Failed to check file presence: \(error)", level: .error)
            throw error
        }
    }
    
    func data(fileName: String) async throws -> Data {
        logger?.logYandex("Loading data for fileName: \(fileName)", level: .debug)
        do {
            let metadataURL = try await urlToLoadFile(path: fileName)
            let data: Data = try await network.dataRequest(url: metadataURL, method: .get)
            logger?.logYandex("Successfully loaded data for fileName: \(fileName)", level: .debug)
            return data
        } catch {
            logger?.logYandex("Failed to load data for fileName: \(fileName): \(error)", level: .error)
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
            logger?.logYandex("Failed to generate download URL: \(error)", level: .error)
            throw error
        }
    }
    
    func getFolder(at folderName: String) async throws -> StorageResource {
        StorageResource(
            name: folderName,
            path: folderName,
            type: .dir,
            modified: ""
        )
    }
    
    func getResources(
        at resource: StorageResource?,
        limit: Int,
        offsetToken: String?
    ) async throws -> (resources: [StorageResource], nextOffsetToken: String?) {
        logger?.logYandex("Fetching resources at: \(resource?.path ?? ""), limit: \(limit), offset: \(offsetToken ?? "empty")", level: .debug)
        var pathRequest: String
        if let path = resource?.path, path.contains(rootPath) {
            pathRequest = path
        } else if let path = resource?.path.replacingOccurrences(of: "disk:/", with: ""), !path.isEmpty {
            pathRequest = "\(rootPath)/\(path)"
        } else {
            pathRequest = rootPath
        }
        pathRequest = pathRequest.replacingOccurrences(of: "//", with: "/")
        
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
            logger?.logYandex("Failed to fetch resources: \(error)", level: .error)
            throw error
        }
    }
    
    func createFolder(at resource: StorageResource?, folderName: String) async throws -> StorageResource {
        let path = [resource?.path, folderName].compactMap { $0 }.joined(separator: "/")
        logger?.logYandex("Creating folder at: \(path)", level: .info)
        
        let fullPath = path.contains(rootPath) ? path : "\(rootPath)/\(path)"
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
            logger?.logYandex("Failed to create folder: \(error)", level: .error)
            throw error
        }
    }
    
    @discardableResult
    func createFile(at resource: StorageResource?, fileName: String, with data: Data?) async throws -> StorageResource {
        let path = [resource?.path, fileName].compactMap { $0 }.joined(separator: "/")
        return try await createFile(at: path, with: data)
    }
    
    @discardableResult
    private func createFile(at path: String, with data: Data?) async throws -> StorageResource {
        logger?.logYandex("Creating file at: \(path)", level: .info)
        
        let fullPath = path.contains(rootPath) ? path : "\(rootPath)/\(path)"
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
                data: data ?? Data(),
                url: uploadURL,
                method: reponse.method
            )
            
            logger?.logYandex("File created successfully: \(fullPath)", level: .info)
            return StorageResource(name: String(path.split(separator: "/").last ?? ""), path: path, type: .file(url: "", previewURL: ""), modified: "")
        } catch {
            logger?.logYandex("Failed to create file: \(error)", level: .error)
            throw error
        }
    }
    
    func updateFile(at resource: StorageResource, with data: Data) async throws {
        let path = resource.path
        try await updateFile(at: path, with: data)
    }
    
    private func updateFile(at path: String, with data: Data) async throws {
        logger?.logYandex("Updating file at: \(path)", level: .info)
        do {
            let tmpPath = "\(path)_tmp"
            try await createFile(at: tmpPath, with: data)
            try await moveFile(from: tmpPath, to: path)
            logger?.logYandex("File updated successfully: \(path)", level: .info)
        } catch {
            logger?.logYandex("Failed to update file: \(error)", level: .error)
            throw error
        }
    }
    
    func renameFile(at resource: StorageResource, with filename: String) async throws {
        // Получаем путь к директории файла
        let directoryPath = (resource.path as NSString).deletingLastPathComponent
        // Создаем новый путь с новым именем файла
        let newPath = (directoryPath as NSString).appendingPathComponent(filename)
        
        // Используем существующий метод moveFile
        try await moveFile(from: resource.path, to: newPath)
        logger?.logYandex("Successfully renamed file from \(resource.name) to \(filename)", level: .debug)
    }
    
    func renameFolder(at resource: StorageResource, with filename: String) async throws {
        logger?.logYandex("Renaming folder from: \(resource.name) to: \(filename)", level: .info)
        
        // Получаем путь к директории папки
        let directoryPath = (resource.path as NSString).deletingLastPathComponent
        // Создаем новый путь с новым именем папки
        let newPath = (directoryPath as NSString).appendingPathComponent(filename)
        
        // Используем метод moveFile (который работает и для папок в Яндекс.Диске)
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
            logger?.logYandex("Failed to move file: \(error)", level: .error)
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
        logger?.logYandex("Performing full logger?.logYandexout", level: .warning)
        do {
            // TODO: remove token
            try YandexLoginSDK.shared.logout()
            logger?.logYandex("Logout successful", level: .info)
        } catch {
            logger?.logYandex("Logout failed: \(error)", level: .error)
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
