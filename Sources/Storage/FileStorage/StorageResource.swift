//
//  StorageFolder.swift
//  Storage
//
//  Created by Татьяна Макеева on 03.03.2025.
//

import Foundation

public struct StorageResource: Identifiable, Sendable, Hashable, Codable {
    public enum ItemType: Sendable, Hashable, Codable {
        case dir
        case file(url: String, previewURL: String?)
    }
    
    public let id: String
    public let name: String
    public let path: String
    public let type: ItemType
    public let modified: String
    
    public var isFile: Bool {
        switch type {
        case .dir:
            return false
        case .file:
            return true
        }
    }
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        path: String,
        type: ItemType,
        modified: String
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.type = type
        self.modified = modified
    }
}

extension StorageResource {
    public static func preview(
        id: String = UUID().uuidString,
        name: String = "Preview",
        path: String = "Preview",
        type: ItemType = .file(url: "", previewURL: ""),
        modified: String = ""
    ) -> StorageResource {
        .init(
            id: id,
            name: name,
            path: path,
            type: type,
            modified: modified
        )
    }
}
