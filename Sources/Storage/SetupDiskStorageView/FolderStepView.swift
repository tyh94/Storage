//
//  FolderStepView.swift
//  FamilyFoodDiary
//
//  Created by Татьяна Макеева on 12.01.2026.
//

import SwiftUI

struct FolderStepView: View {
    @Bindable var viewModel: SetupDiskStorageViewModel
    let step: SetupDiskStorageViewModel.Step
    @State private var showingAlertAddFolder = false
    @Environment(\.dismiss) private var dismiss
    @State private var folderName = ""
    
    var body: some View {
        List {
            ForEach(step.resources) { resource in
                ResourceRow(resource: resource, isSelectable: true) {
                    Task {
                        await viewModel.loadFolder(resource)
                    }
                }
                .onAppear {
                    if resource == step.resources.last,
                       step.nextOffsetToken != nil {
                        Task {
                            await viewModel.loadNextPage(for: step.current)
                        }
                    }
                }
            }
            
            if step.isLoadingNext {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
        .listStyle(.plain)
        .navigationBarBackButtonHidden()
        .navigationTitle(step.current.name.isEmpty ? Text("Root", bundle: .module) : Text(step.current.name))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if viewModel.path.count > 1 {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.goBack()
                    } label: {
                        HStack {
                            Image(systemName: "chevron.backward")
                            Text("Back", bundle: .module)
                        }
                    }
                }
            }
            
            if case .loaded = viewModel.status {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAlertAddFolder = true
                    } label: {
                        Label {
                            Text("Add folder", bundle: .module)
                        } icon: {
                            Image(systemName: "folder.badge.plus")
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await viewModel.saveCurrentFolder()
                        }
                    } label: {
                        Text("Select", bundle: .module)
                    }
                }
            }
        }
        .alert(Text("Enter folder name", bundle: .module), isPresented: $showingAlertAddFolder) {
            TextField(String(localized: "Enter folder name", bundle: .module), text: $folderName)
            Button(String(localized: "Cancel", bundle: .module), action: { showingAlertAddFolder = false })
            Button(String(localized: "Add", bundle: .module), action: createFolder).disabled(folderName.isEmpty)
        }
    }
    
    private func createFolder() {
        Task {
            await viewModel.createFolder(folderName)
            folderName = ""
            showingAlertAddFolder = false
        }
    }
}

import MKVNetwork

#Preview {
    NavigationStack {
        FolderStepView(
            viewModel: SetupDiskStorageViewModel(
                diskActivator: DiskStorageActivatorMock(),
                tokenStorage: TokenStorageMock(),
                fileStorageBuilder: { _ in FileStorageMock() },
                folderChosen: { _ in
                    
                }
            ),
            step: SetupDiskStorageViewModel.Step(
                resources: [.preview(), .preview()],
                current: StorageResource.preview()
            )
        )
    }
}
