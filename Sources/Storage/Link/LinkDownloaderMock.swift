//
//  LinkDownloaderMock.swift
//  Storage
//
//  Created by Татьяна Макеева on 24.04.2025.
//

import Foundation

public struct LinkDownloaderMock: LinkDownloader {
    public init() {}
    
    public func download(for url: URL, progress: Progress) async throws -> URL {
       throw ""
    }
}
