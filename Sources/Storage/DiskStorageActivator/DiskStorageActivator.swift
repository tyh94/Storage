//
//  DiskStorageActivator.swift
//  Storage
//
//  Created by Татьяна Макеева on 03.03.2025.
//

import Foundation

public protocol DiskStorageActivator: Sendable {
    var startPath: String { get }
    var type: DiskStorageActivatorType { get }
    
    func activate() throws
    @MainActor func authorize() async throws -> String
    @discardableResult
    func handleURL(_ url: URL) -> Bool
}
