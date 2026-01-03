//
//  File.swift
//  Storage
//
//  Created by Татьяна Макеева on 14.03.2025.
//

import Foundation
import ZIPFoundation

public protocol LinkDownloader: Sendable {
    func download(for url: URL, progress: Progress) async throws -> URL
}

extension LinkDownloader {
    public func download(for url: String, progress: Progress) async throws -> URL {
        guard let url = URL(string: url) else {
            throw URLError(.badURL)
        }
        return try await download(for: url, progress: progress)
    }
}

public final class LinkDownloaderImpl: LinkDownloader {
    public init() {}
    
    public func download(for url: URL, progress: Progress) async throws -> URL {
        let delegate = DownloadDelegate(progress: progress)
        let (tempURL, _) = try await URLSession.shared.download(from: url, delegate: delegate)
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let uniqueFileName = UUID().uuidString
        let zipURL = documentsURL.appendingPathComponent(uniqueFileName + "_archive.zip")
        // Перемещаем скачанный файл
        try FileManager.default.moveItem(at: tempURL, to: zipURL)
        let destinationURL = documentsURL.appendingPathComponent(uniqueFileName)
        try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true)
        try FileManager.default.unzipItem(at: zipURL, to: destinationURL, pathEncoding: .utf8)
        try FileManager.default.removeItem(at: zipURL)
        return destinationURL
    }
}

private final class DownloadDelegate: NSObject, URLSessionTaskDelegate {
    private let progress: Progress
    
    init(progress: Progress) {
        self.progress = progress
    }
    
    func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
        progress.addChild(task.progress, withPendingUnitCount: 100)
    }
}
