//
//  DiskStorageActivatorMock.swift
//  Storage
//
//  Created by Татьяна Макеева on 24.04.2025.
//

import Foundation

public struct DiskStorageActivatorMock: DiskStorageActivator {
    public var type: DiskStorageActivatorType = .yandexDisk(clientID: "")
    
    public var startPath: String = ""
    
    public init() {}
    
    public func authorizeAndSaveToken() async throws {}
    
    public func handleURL(_ url: URL) -> Bool {
        true
    }
    
    public func activate() throws {
        
    }
}
