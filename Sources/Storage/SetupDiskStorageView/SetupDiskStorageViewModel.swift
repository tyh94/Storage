//
//  SetupDiskStorageViewModel.swift
//  FamilyFoodDiary
//
//  Created by Татьяна Макеева on 12.01.2026.
//

import SwiftUI
import Observation
import MKVNetwork

@MainActor
@Observable
final class SetupDiskStorageViewModel {
    struct Step: Identifiable, Hashable {
        var id: String { current.path }
        var resources: [StorageResource]
        let current: StorageResource
        var isLoadingNext: Bool = false
        var nextOffsetToken: String?
    }
    
    enum Status: Equatable {
        case idle
        case loading
        case loaded
        case error(String)
    }
    
    private(set) var status: Status = .idle
    var path: [Step] = []
    private let pageSize: Int = 20
    private var fileStorage: FileStorage?
    
    private let diskActivator: DiskStorageActivator
    private let tokenStorage: TokenStorage // TODO: dublicate at storage
    private let fileStorageBuilder: (StorageResource) -> (FileStorage)
    private let folderChosen: (StorageResource) -> Void
    
    init(
        diskActivator: DiskStorageActivator,
        tokenStorage: TokenStorage,
        fileStorageBuilder: @escaping (StorageResource) -> (FileStorage),
        folderChosen: @escaping (StorageResource) -> Void
    ) {
        self.diskActivator = diskActivator
        self.tokenStorage = tokenStorage
        self.fileStorageBuilder = fileStorageBuilder
        self.folderChosen = folderChosen
    }
    
    func onAppear() async {
        status = .loading
        do {
            let token = try await diskActivator.authorize()
            try tokenStorage.saveToken(token)
            let rootResource = StorageResource(name: "", path: "", type: .dir, modified: "")
            let fileStorage = fileStorageBuilder(rootResource)
            self.fileStorage = fileStorage

            let (resources, nextToken) = try await fileStorage.getResources(
                at: nil,
                limit: pageSize,
                offsetToken: nil
            )

            path = [
                Step(
                    resources: resources,
                    current: rootResource,
                    nextOffsetToken: nextToken
                )
            ]

            status = .loaded
        } catch {
            status = .error(error.localizedDescription)
        }
    }
    
    func loadFolder(_ resource: StorageResource) async {
        status = .loading
        do {
            guard let fileStorage else { throw NSError(domain: "", code: 0, userInfo: nil) }
            let (resources, nextToken) = try await fileStorage.getResources(
                at: resource,
                limit: pageSize,
                offsetToken: nil
            )
            
            let step = Step(
                resources: resources,
                current: resource,
                nextOffsetToken: nextToken
            )
            
            path.append(step)
            status = .loaded
        } catch {
            status = .error(error.localizedDescription)
        }
    }
    
    func loadNextPage(for resource: StorageResource) async {
        guard let lastStep = path.last,
              lastStep.current == resource,
              let nextToken = lastStep.nextOffsetToken else {
            return
        }
        
        path[path.count - 1].isLoadingNext = true
        
        do {
            guard let fileStorage else { throw NSError(domain: "", code: 0, userInfo: nil) }
            let (resources, newNextToken) = try await fileStorage.getResources(
                at: resource,
                limit: pageSize,
                offsetToken: nextToken
            )
            
            path[path.count - 1].resources.append(contentsOf: resources)
            path[path.count - 1].nextOffsetToken = newNextToken
        } catch {
            status = .error(error.localizedDescription)
        }
        
        path[path.count - 1].isLoadingNext = false
    }
    
    func goBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
    
    func createFolder(_ name: String) async {
        guard !name.isEmpty,
              let lastStep = path.last else {
            return
        }
        
        status = .loading
        do {
            guard let fileStorage else { throw NSError(domain: "", code: 0, userInfo: nil) }
            let newFolder = try await fileStorage.createFolder(
                at: lastStep.current,
                folderName: name
            )
            
            if !path.isEmpty {
                path[path.count - 1].resources.append(newFolder)
            }
            
            await loadFolder(newFolder)
        } catch {
            status = .error(error.localizedDescription)
        }
    }
    
    func saveCurrentFolder() async {
        guard let lastStep = path.last else { return }
        
        folderChosen(lastStep.current)
    }
}
