//
//  AvailableStorageSetup.swift
//  FamilyFoodDiary
//
//  Created by Татьяна Макеева on 12.01.2026.
//

import SwiftUI
import MKVNetwork

public protocol AvailableStorageSetup: Identifiable {
    var id: String { get }
    var name: LocalizedStringKey { get }
    
    var storageBuilder: (StorageResource) -> FileStorage { get }
    var activator: DiskStorageActivator { get }
    var tokenStorage: TokenStorage { get }
}

struct AvailableStorageSetupMock: AvailableStorageSetup {
    let id: String = UUID().uuidString
    let name: LocalizedStringKey = "Storage name"
    let storageBuilder: (StorageResource) -> FileStorage = { _ in FileStorageMock() }
    let activator: DiskStorageActivator = DiskStorageActivatorMock()
    let tokenStorage: TokenStorage = TokenStorageMock()
}
