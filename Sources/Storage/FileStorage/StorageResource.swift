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
    public let modified: Date
    
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
        modified: Date
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.type = type
        self.modified = modified
    }
}

extension StorageResource {
    enum CodingKeys: String, CodingKey {
        case id, name, path, type, modified
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        path = try container.decode(String.self, forKey: .path)
        type = try container.decode(ItemType.self, forKey: .type)
        
        if let date = try? container.decode(Date.self, forKey: .modified) {
            modified = date
        } else {
            let dateString = try container.decode(String.self, forKey: .modified)
            
            if dateString.isEmpty {
                modified = Date.distantPast
            } else {
                let formatter = ISO8601DateFormatter()
                if let date = formatter.date(from: dateString) {
                    modified = date
                } else {
                    modified = Date.distantPast
                }
            }
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(path, forKey: .path)
        try container.encode(type, forKey: .type)
        try container.encode(modified, forKey: .modified)
    }
}

extension StorageResource.ItemType {
    enum CodingKeys: String, CodingKey {
        case kind
        case url
        case previewURL
        
        // старый формат
        case file
        case dir
    }

    enum Kind: String, Codable {
        case dir, file
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let kind = try? container.decode(Kind.self, forKey: .kind) {
            switch kind {
            case .dir:
                self = .dir
            case .file:
                let url = try container.decode(String.self, forKey: .url)
                let preview = try container.decodeIfPresent(String.self, forKey: .previewURL)
                self = .file(url: url, previewURL: preview)
            }
            return
        }

        if container.contains(.dir) {
            self = .dir
            return
        }

        if container.contains(.file) {
            let nested = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .file)
            let url = try nested.decode(String.self, forKey: .url)
            let preview = try nested.decodeIfPresent(String.self, forKey: .previewURL)
            self = .file(url: url, previewURL: preview)
            return
        }

        throw DecodingError.dataCorruptedError(
            forKey: .kind,
            in: container,
            debugDescription: "Unknown ItemType format"
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .dir:
            try container.encode(Kind.dir, forKey: .kind)
        case .file(let url, let preview):
            try container.encode(Kind.file, forKey: .kind)
            try container.encode(url, forKey: .url)
            try container.encodeIfPresent(preview, forKey: .previewURL)
        }
    }
}

extension StorageResource {
    public static func preview(
        id: String = UUID().uuidString,
        name: String = "Preview",
        path: String = "Preview",
        type: ItemType = .file(url: "", previewURL: ""),
        modified: Date = Date()
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
