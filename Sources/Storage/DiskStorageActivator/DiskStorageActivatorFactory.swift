//
//  DiskStorageActivatorFactory.swift
//  Storage
//
//  Created by Татьяна Макеева on 14.05.2025.
//

import Foundation

public enum DiskStorageActivatorFactory {
    public static func build(_ type: DiskStorageActivatorType, logger: Logger? = nil) -> DiskStorageActivator {
        switch type {
        case let .yandexDisk(clientID):
            return YandexDiskStorage(type: type, clientID: clientID, logger: logger)
        case let .googleDrive(clientID):
            return GoogleDriveStorage(type: type, clientID: clientID, logger: logger)
        }
    }
}
