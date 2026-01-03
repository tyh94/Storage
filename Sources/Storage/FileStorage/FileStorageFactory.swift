//
//  FileStorageFactory.swift
//  Storage
//
//  Created by Татьяна Макеева on 14.07.2025.
//

import Foundation
import MKVNetwork

public enum FileStorageFactoryType {
    case local(rootURL: URL)
    case googleDrive(apiKey: String, parentID: String?)
    case yandex(rootPath: String?)
}

public enum FileStorageTokenFactoryType {
    case googleDrive
    case yandex
}

public typealias FileStorageFactory = Factory<FileStorageFactoryType, FileStorage>
public typealias FileStorageTokenFactory = Factory<FileStorageTokenFactoryType, TokenStorage>

public extension FileStorageTokenFactory {
    convenience init() {
        self.init { storage in
            switch storage {
            case .googleDrive:
                return FileStorageTokenService(
                    key: "GoogleDriveTokenKey",
                    storage: KeychainStorage()
                )
            case .yandex:
                return FileStorageTokenService(
                    key: "YandexDiskTokenKey",
                    storage: KeychainStorage()
                )
            }
        }
    }
}

public extension FileStorageFactory {
    convenience init(
        network: NetworkManaging,
        tokenFactory: FileStorageTokenFactory,
        logger: StorageLogger?
    ) {
        self.init() { storage in
            switch storage {
            case let .local(rootURL):
                return LocalFileStorage(
                    rootURL: rootURL,
                    logger: logger
                )
            case let .googleDrive(apiKey, parentID):
                let tokenStorage = tokenFactory.make(.googleDrive)
                let network = network.authorized(
                    authorizationHeaderProvider: { .authorization(bearerToken: $0) },
                    tokenStorage: tokenStorage,
                    tokenRefresher: GoogleSDKTokenRefresher(tokenStorage: tokenStorage),
                    logger: logger
                )
                    .parametrized(with: .query(["apiKey": apiKey]))
                return GoogleDriveFileStorage(
                    rootPath: parentID ?? "root",
                    network: network,
                    logger: logger
                )
            case let .yandex(rootPath):
                let network = network.authorized(
                    authorizationHeaderProvider: { .authorizationOAuth($0) },
                    tokenStorage: tokenFactory.make(.yandex),
                    tokenRefresher: nil,
                    logger: logger
                )
                return YandexFileStorage(
                    rootPath: rootPath ?? "/",
                    network: network,
                    logger: logger
                )
            }
        }
    }
}
