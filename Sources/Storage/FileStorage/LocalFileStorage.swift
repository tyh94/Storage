//
//  LocalFileStorage.swift
//  Storage
//
//  Created by Татьяна Макеева on 05.04.2025.
//

import Foundation

final class LocalFileStorage: FileStorage  {
    enum Error: LocalizedError {
        case fileNotCreated
        case fileNotFound(String)
        case enumeratorFailed
        case folderNotFound(String)
        case folderAlreadyExists(String)
        case notAFolder(String)
        
        var errorDescription: String? {
            switch self {
            case .fileNotCreated:
                return "File could not be created"
            case let .fileNotFound(file):
                return "File \(file) not found"
            case .enumeratorFailed:
                return "Failed to enumerate directory contents"
            case let .folderAlreadyExists(folder):
                return "Folder already exists \(folder)"
            case let .folderNotFound(folder):
                return "Folder \(folder) not found"
            case let .notAFolder(folder):
                return "Not a folder \(folder)"
            }
        }
    }
    private var fileManager: FileManager { .default }
    private let rootURL: URL
    private let logger: Logger?
    
    init(
        rootURL: URL,
        logger: Logger? = nil
    ) {
        self.rootURL = rootURL
        self.logger = logger
        logger?.logLocal("📁 rootURL: \(rootURL)", level: .debug)
    }
    
    func resource(fileName: String) async throws -> StorageResource {
        let destinationURL = rootURL.appendingPathComponent(fileName)
        if fileManager.fileExists(atPath: destinationURL.path) {
            return StorageResource(name: fileName, path: fileName, type: .file(url: "", previewURL: ""), modified: "")
        } else {
            throw Error.fileNotFound(fileName)
        }
    }
    
    func resource(folderName: String) async throws -> StorageResource {
        let folderURL = rootURL.appendingPathComponent(folderName)
        
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: folderURL.path, isDirectory: &isDirectory) else {
            throw Error.folderNotFound(folderName)
        }
        
        guard isDirectory.boolValue else {
            throw Error.notAFolder(folderName)
        }
        
        return StorageResource(
            name: folderName,
            path: folderName,
            type: .dir,
            modified: ""
        )
    }
    
    func data(fileName: String) async throws -> Data {
        logger?.logLocal("Loading data for fileName: \(fileName)", level: .debug)
        do {
            let destinationURL = urlToLoadFile(path: fileName)
            let data = try Data(contentsOf: destinationURL)
            logger?.logLocal("Successfully loaded data for fileName: \(fileName)", level: .debug)
            return data
        } catch {
            logger?.logLocal("Failed to load data for fileName: \(fileName): \(error)", level: .error)
            throw error
        }
    }
    
    func data(for resource: StorageResource) async throws -> Data {
        try await data(fileName: resource.path)
    }
    
    func urlToLoadFile(path: String) -> URL {
        let url = rootURL.appendingPathComponent(path)
        logger?.logLocal("Generated load URL: \(url.path)", level: .debug)
        return url
    }
    
    func getResources(
        at resource: StorageResource?,
        limit: Int,
        offsetToken: String?
    ) async throws -> (resources: [StorageResource], nextOffsetToken: String?) {
        logger?.logLocal("Fetching resources at: \(resource?.path ?? "")", level: .debug)
        let destinationURL: URL
        if let path = resource?.path {
            destinationURL = rootURL.appendingPathComponent(path)
        } else {
            destinationURL = rootURL
        }
        
        do {
            let subpaths = try fileManager.contentsOfDirectory(
                at: destinationURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            )
            
            logger?.logLocal("Found \(subpaths.count) resources at: \(destinationURL)", level: .info)
            return (subpaths.map {
                let name = $0.lastPathComponent
                let path = $0.relativePath(from: rootURL) ?? name
                return StorageResource(
                    name: name,
                    path: path,
                    type: $0.isDirectory ? .dir : .file(url: $0.absoluteString, previewURL: $0.absoluteString),
                    modified: ""
                )
            }, nil)
        } catch {
            logger?.logLocal("Failed to get resources at \(destinationURL): \(error)", level: .error)
            throw error
        }
    }
    
    func getFolder(at folderName: String) async throws -> StorageResource {
        var isDirectory: ObjCBool = false
        if !fileManager.fileExists(
            atPath: rootURL.appendingPathComponent(folderName).path,
            isDirectory: &isDirectory
        ) {
            throw Error.fileNotFound(folderName)
        }
        
        return StorageResource(
            name: folderName,
            path: folderName,
            type: .dir,
            modified: ""
        )
    }
    
    func createFolder(at resource: StorageResource?, folderName: String) async throws -> StorageResource {
        let path = [resource?.path, folderName].compactMap { $0 }.joined(separator: "/")
        logger?.logLocal("Creating folder at: \(path)", level: .info)
        let destinationURL = rootURL.appendingPathComponent(path)
        do {
            try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true)
            logger?.logLocal("Folder created successfully: \(path)", level: .info)
            return StorageResource(name: folderName, path: path, type: .dir, modified: "")
        } catch {
            logger?.logLocal("Failed to create folder: \(path) - \(error)", level: .error)
            throw error
        }
    }
    
    @discardableResult
    func createFile(at resource: StorageResource?, fileName: String, with data: Data?) async throws -> StorageResource {
        let path = [resource?.path, fileName].compactMap { $0 }.joined(separator: "/")
        return try createFile(at: path, with: data)
    }
    
    @discardableResult
    private func createFile(at path: String, with data: Data?) throws -> StorageResource {
        logger?.logLocal("Creating file at: \(path)", level: .info)
        let destinationURL = rootURL.appendingPathComponent(path)
        let created = fileManager.createFile(atPath: destinationURL.path, contents: data)
        if created {
            logger?.logLocal("File created successfully: \(path)", level: .info)
            return StorageResource(name: destinationURL.lastPathComponent, path: path, type: .dir, modified: "")
        } else {
            logger?.logLocal("File creation returned false: \(path)", level: .warning)
            throw Error.fileNotCreated
        }
    }
    
    func updateFile(at resource: StorageResource, with data: Data) async throws {
        let path = resource.path
        logger?.logLocal("Updating file at: \(path)", level: .info)
        let destinationURL = rootURL.appendingPathComponent(path)
        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try data.write(to: destinationURL)
                logger?.logLocal("File updated successfully: \(path)", level: .info)
            } else {
                logger?.logLocal("File doesn't exist, creating new: \(path)", level: .debug)
                try createFile(at: path, with: data)
            }
        } catch {
            logger?.logLocal("File update failed: \(path) - \(error)", level: .error)
            throw error
        }
    }
    
    func renameFile(at resource: StorageResource, with filename: String) async throws {
        guard case let .file(url, _) = resource.type else {
            throw Error.fileNotFound(resource.name)
        }
        
        let sourceURL = URL(string: url) ?? rootURL.appendingPathComponent(resource.path)
        let destinationURL = sourceURL.deletingLastPathComponent().appendingPathComponent(filename)
        
        do {
            try fileManager.moveItem(at: sourceURL, to: destinationURL)
            logger?.logLocal("Successfully renamed file from \(resource.name) to \(filename)", level: .debug)
        } catch {
            logger?.logLocal("Failed to rename file from \(resource.name) to \(filename): \(error)", level: .error)
            throw error
        }
    }
    
    func renameFolder(at resource: StorageResource, with filename: String) async throws {
        guard case .dir = resource.type else {
            throw Error.folderNotFound(resource.name)
        }
        
        let sourceURL = rootURL.appendingPathComponent(resource.path)
        let destinationURL = sourceURL.deletingLastPathComponent().appendingPathComponent(filename)
        
        // Проверяем, что исходная папка существует
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            throw Error.folderNotFound(resource.name)
        }
        
        // Проверяем, что папка назначения не существует
        guard !fileManager.fileExists(atPath: destinationURL.path) else {
            throw Error.folderAlreadyExists(filename)
        }
        
        do {
            try fileManager.moveItem(at: sourceURL, to: destinationURL)
            logger?.logLocal("Successfully renamed folder from \(resource.name) to \(filename)", level: .debug)
        } catch {
            logger?.logLocal("Failed to rename folder from \(resource.name) to \(filename): \(error)", level: .error)
            throw error
        }
    }
    
    func moveFile(from pathFrom: String, to pathTo: String) async throws {
        logger?.logLocal("Moving file from: \(pathFrom) to: \(pathTo)", level: .info)
        do {
            try fileManager.moveItem(
                at: rootURL.appendingPathComponent(pathFrom),
                to: rootURL.appendingPathComponent(pathTo)
            )
            logger?.logLocal("File moved successfully", level: .info)
        } catch {
            logger?.logLocal("File move failed: \(error)", level: .error)
            throw error
        }
    }
    
    func delete(at resource: StorageResource) async throws {
        let path = resource.path
        logger?.logLocal("Deleting item at: \(path)", level: .info)
        do {
            try fileManager.removeItem(at: rootURL.appendingPathComponent(path))
            logger?.logLocal("Item deleted successfully: \(path)", level: .info)
        } catch {
            logger?.logLocal("Delete failed for \(path): \(error)", level: .error)
            throw error
        }
    }
    
    func deleteAll() async throws {
        logger?.logLocal("Deleting ALL items at root", level: .warning)
        do {
            try fileManager.removeItem(at: rootURL)
            logger?.logLocal("All items deleted successfully", level: .info)
        } catch {
            logger?.logLocal("Delete all failed: \(error)", level: .error)
            throw error
        }
    }
}

extension Logger {
     fileprivate func logLocal(
        _ message: String,
        level: LogLevel,
        type: LogMessageType = .localFilestorage,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(
            message,
            level: level,
            type: type,
            file: file,
            function: function,
            line: line
        )
    }
}

struct DirectoryIterator: Sequence {
    let enumerator: FileManager.DirectoryEnumerator
    
    func makeIterator() -> AnyIterator<Any> {
        AnyIterator {
            enumerator.nextObject()
        }
    }
}

extension URL {
    fileprivate var isDirectory: Bool {
       (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
    
    fileprivate func relativePath(from base: URL) -> String? {
        let baseComponents = base.standardizedFileURL.pathComponents
        let selfComponents = self.standardizedFileURL.pathComponents

        guard selfComponents.starts(with: baseComponents) else {
            return nil
        }

        let relativeComponents = selfComponents.dropFirst(baseComponents.count)
        return relativeComponents.joined(separator: "/")
    }
}
