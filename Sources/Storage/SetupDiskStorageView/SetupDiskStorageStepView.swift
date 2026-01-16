//
//  SetupDiskStorageStepView.swift
//  FamilyFoodDiary
//
//  Created by Татьяна Макеева on 11.01.2026.
//

import SwiftUI
import Observation

struct SetupDiskStorageView: View {
    @State var viewModel: SetupDiskStorageViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var paths = [SetupDiskStorageViewModel.Step]()
    
    @ViewBuilder
    var content: some View {
        switch viewModel.status {
        case .loaded:
            NavigationStack(path: $viewModel.path) {
                VStack {
                    ProgressView()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationDestination(for: SetupDiskStorageViewModel.Step.self) { step in
                    FolderStepView(viewModel: viewModel, step: step)
                }
            }
        case .loading, .idle:
            VStack {
                ProgressView()
            }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .error(error):
            VStack {
                Text.localized(
                    "Error: %@",
                    error.localizedDescription
                )
                .foregroundColor(.red)
                Button {
                    Task { await viewModel.onAppear() }
                } label: {
                    Text.localized("Retry")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    var body: some View {
        content
            .task {
                await viewModel.onAppear()
            }
    }
}

import MKVNetwork

#Preview {
    SetupDiskStorageView(
        viewModel: SetupDiskStorageViewModel(
            diskActivator: DiskStorageActivatorMock(),
            tokenStorage: TokenStorageMock(),
            fileStorageBuilder: { _ in FileStorageMock() },
            folderChosen: { _ in
                
            }
        )
    )
}
