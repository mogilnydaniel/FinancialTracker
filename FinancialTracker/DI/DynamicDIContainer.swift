import Foundation
import SwiftUI
import Combine

@MainActor
final class DynamicDIContainer: ObservableObject {
    
    @Published private(set) var currentContainer: DIContainer
    
    private let settingsService: SettingsService
    private let migrationService: AutoMigrationService
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.settingsService = SettingsService()
        
        let token = "WNKoU01o5koxFvqP6882dwjR"
        let client = NetworkClient(token: token)
        self.currentContainer = DIContainer(
            categoriesService: NetworkCategoriesService(client: client),
            bankAccountsService: NetworkAccountsService(client: client),
            transactionsService: NetworkTransactionsService(client: client)
        )
        
        let dataMigrationService = DataMigrationService()
        self.migrationService = AutoMigrationService(
            settingsService: settingsService,
            migrationService: dataMigrationService
        )
        
        setupStorageTypeObservation()
    }
    
    private func setupStorageTypeObservation() {
        settingsService.storageTypePublisher
            .dropFirst()
            .sink { [weak self] newStorageType in
                self?.updateContainer(for: newStorageType)
            }
            .store(in: &cancellables)
    }
    
    private func updateContainer(for storageType: StorageType) {
    }
    
    private static func createContainer(for storageType: StorageType) -> DIContainer {
        let token = "WNKoU01o5koxFvqP6882dwjR"
        let client = NetworkClient(token: token)
        return DIContainer(
            categoriesService: NetworkCategoriesService(client: client),
            bankAccountsService: NetworkAccountsService(client: client),
            transactionsService: NetworkTransactionsService(client: client)
        )
    }

}

private struct DynamicDIContainerKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue: DynamicDIContainer = DynamicDIContainer()
}

extension EnvironmentValues {
    var dynamicDI: DynamicDIContainer {
        get { self[DynamicDIContainerKey.self] }
        set { self[DynamicDIContainerKey.self] = newValue }
    }
} 
