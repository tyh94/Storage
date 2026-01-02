//
//  GoogleDriveStorage.swift
//  Storage
//
//  Created by Татьяна Макеева on 11.07.2025.
//

import GoogleSignIn
import UIKit

final class GoogleDriveStorage: DiskStorageActivator {
    enum StorageError: LocalizedError {
        case notAuthorized
        case invalidRootViewController
        case tokenRetrievalFailed
        
        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "Access not authorized"
            case .invalidRootViewController:
                return "Invalid root view controller"
            case .tokenRetrievalFailed:
                return "Failed to retrieve authentication token"
            }
        }
    }
    
    let type: DiskStorageActivatorType
    let startPath: String = "root"
    
    private let clientID: String
    private let scopes: [String]
    private let logger: Logger?
    
    @MainActor private var authorizationContinuation: CheckedContinuation<String, Error>?
    
    init(
        type: DiskStorageActivatorType,
        clientID: String,
        scopes: [String] = ["https://www.googleapis.com/auth/drive"],
        logger: Logger? = nil
    ) {
        self.type = type
        self.clientID = clientID
        self.scopes = scopes
        self.logger = logger
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
    }
    
    func activate() throws {
        // Конфигурация уже выполнена в init
    }
    
    @MainActor func authorize() async throws -> String {
        // Если уже авторизован - возвращаем токен
        if let currentUser = GIDSignIn.sharedInstance.currentUser {
            return currentUser.accessToken.tokenString
        }
        
        guard let rootVC = await getRootViewController() else {
            throw StorageError.invalidRootViewController
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            self.authorizationContinuation = continuation
            
            GIDSignIn.sharedInstance.signIn(
                withPresenting: rootVC,
                hint: nil,
                additionalScopes: scopes
            ) { [weak self] result, error in
                guard let self else { return }
                if let error = error {
                    authorizationContinuation?.resume(throwing: error)
                    authorizationContinuation = nil
                    return
                }
                
                guard let user = result?.user else {
                    authorizationContinuation?.resume(throwing: StorageError.notAuthorized)
                    authorizationContinuation = nil
                    return
                }
                
                let token = user.accessToken.tokenString
                authorizationContinuation?.resume(returning: token)
                authorizationContinuation = nil
            }
        }
    }
    
    func logout() {
        GIDSignIn.sharedInstance.signOut()
    }
    
    func handleURL(_ url: URL) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }
    
    @MainActor
    private func getRootViewController() async -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return nil
        }
        return rootViewController
    }
}
