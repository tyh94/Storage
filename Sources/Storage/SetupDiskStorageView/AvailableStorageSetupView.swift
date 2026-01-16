//
//  AvailableStorageSetupView.swift
//  FamilyFoodDiary
//
//  Created by Татьяна Макеева on 12.01.2026.
//

import MKVNetwork
import SwiftUI

struct StorageSetupWrapper: Identifiable {
    let id: String
    let name: LocalizedStringKey
    let activator: DiskStorageActivator
    let storageBuilder: (StorageResource) -> FileStorage
    let tokenStorage: TokenStorage
    let base: any AvailableStorageSetup
    
    init(_ setup: any AvailableStorageSetup) {
        self.id = setup.id
        self.name = setup.name
        self.activator = setup.activator
        self.storageBuilder = setup.storageBuilder
        self.tokenStorage = setup.tokenStorage
        self.base = setup
    }
}

public struct AvailableStorageSetupView: View {
    @State var viewModel: AvailableStorageSetupViewModel
    
    @State private var selectedStorage: StorageSetupWrapper?
    @Environment(\.dismiss) private var dismiss
    
    public init(viewModel: AvailableStorageSetupViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            List(viewModel.storages, id: \.id) { storage in
                Text(storage.name)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedStorage = StorageSetupWrapper(storage)
                    }
            }
            .navigationTitle("Setup storage".localized)
        }
        .sheet(item: $selectedStorage) { setup in
            SetupDiskStorageView(
                viewModel: SetupDiskStorageViewModel(
                    diskActivator: setup.activator,
                    tokenStorage: setup.tokenStorage,
                    fileStorageBuilder: setup.storageBuilder,
                    folderChosen: {
                        selectedStorage = nil
                        dismiss()
                        viewModel.complete(
                            resource: $0,
                            storage: setup.activator.type
                        )
                    }
                )
            )
        }
    }
}

#Preview {
    AvailableStorageSetupView(
        viewModel: AvailableStorageSetupViewModel(
            storages: [
                AvailableStorageSetupMock(),
            ],
            completion: { _, _ in }
        )
    )
    .environment(\.locale, .init(identifier: "ru"))
}
