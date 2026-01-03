//
//  ZipFileStorageArchiver.swift
//  Storage
//
//  Created by Татьяна Макеева on 03.01.2026.
//

import Foundation
import ZIPFoundation

public enum ArchiverError: LocalizedError {
    case failedToCreateArchive
    case failedToOpenArchive
    case invalidArchiveStructure
    case extractionFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .failedToCreateArchive:
            return "Failed to create archive"
        case .failedToOpenArchive:
            return "Failed to open archive"
        case .invalidArchiveStructure:
            return "Invalid archive structure"
        case .extractionFailed(let error):
            return "Extraction failed: \(error.localizedDescription)"
        }
    }
}

public actor ZipFileStorageArchiver: FileStorageArchiver {
    private let fileManager: FileManager
    private let logger: Logger?
    
    public init(fileManager: FileManager = .default, logger: Logger? = nil) {
        self.fileManager = fileManager
        self.logger = logger
    }
    
    public func createArchive(from source: FileStorage, archiveName: String) async throws -> URL {
        logger?.info("Creating archive '\(archiveName)'", type: .archive)
        
        // Создаем временную директорию
        let tempDir = fileManager.temporaryDirectory
            .appendingPathComponent("FileStorageArchiver")
            .appendingPathComponent(UUID().uuidString)
        
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        let archiveURL = tempDir.appendingPathComponent(archiveName).appendingPathExtension("zip")
        
        // Создаем архив
        let archive = try Archive(url: archiveURL, accessMode: .create)
        
        // Получаем все файлы (без рекурсии по папкам)
        let allFiles = try await getAllFiles(from: source)
        
        // Добавляем файлы в архив
        for file in allFiles {
            let data = try await source.data(for: file)
            try archive.addEntry(with: file.name, type: .file, uncompressedSize: Int64(data.count)) { position, size in
                return data.subdata(in: Int(position)..<Int(position) + size)
            }
            
            logger?.debug("Added file to archive: \(file.name)", type: .archive)
        }
        
        logger?.info("Archive created successfully", type: .archive)
        return archiveURL
    }
    
    private func getAllFiles(from source: FileStorage) async throws -> [StorageResource] {
        var allFiles: [StorageResource] = []
        var foldersToProcess: [StorageResource] = []
        
        // Начинаем с корневой папки
        let root = try await source.getFolder(at: "")
        foldersToProcess.append(root)
        
        while let folder = foldersToProcess.popLast() {
            var offsetToken: String? = nil
            
            repeat {
                let (resources, nextOffsetToken) = try await source.getResources(
                    at: folder,
                    limit: 100,
                    offsetToken: offsetToken
                )
                
                for resource in resources {
                    switch resource.type {
                    case .dir:
                        foldersToProcess.append(resource)
                    case .file:
                        allFiles.append(resource)
                    }
                }
                
                offsetToken = nextOffsetToken
            } while offsetToken != nil
        }
        
        return allFiles
    }
    
    public func cleanupArchive(_ archiveURL: URL) async throws {
        let archiveDir = archiveURL.deletingLastPathComponent()
        try fileManager.removeItem(at: archiveDir)
        logger?.info("Cleaned up archive directory", type: .archive)
    }
}
