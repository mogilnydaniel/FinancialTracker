import Foundation

actor HybridBankAccountsService: BankAccountsServiceProtocol {
    private let persistence: BankAccountsPersistenceProtocol
    private let backup: any BackupProtocol
    private let networkClient: NetworkClient
    private let syncService: BackupSyncService?
    private let accountId: Int = 1
    
    init(
        persistence: BankAccountsPersistenceProtocol,
        backup: any BackupProtocol,
        networkClient: NetworkClient,
        syncService: BackupSyncService? = nil
    ) {
        self.persistence = persistence
        self.backup = backup
        self.networkClient = networkClient
        self.syncService = syncService
        
        Task { @MainActor in
            await setupNetworkMonitoring()
        }
    }
    
    private func setupNetworkMonitoring() async {
        Task { @MainActor in
            for await isConnected in NetworkConnectionDetector.shared.connectionStateChange.values {
                if isConnected {
                    Task {
                        await tryAutoSync()
                    }
                }
            }
        }
    }
    
    private func tryAutoSync() async {
        guard let syncService = syncService else { return }
        
        do {
            try await syncService.syncPendingBackups()
        } catch {
        }
    }
    
    func getBankAccount() async throws -> BankAccount {
        if let localAccount = try await persistence.getBankAccount() {
            Task {
                await syncFromNetwork()
            }
            return localAccount
        }
        
        return try await fetchAndSaveFromNetwork()
    }
    
    func updateBankAccount(_ updatedAccount: BankAccount) async throws -> BankAccount {
        let savedAccount = try await persistence.saveBankAccount(updatedAccount)
        
        await handleNetworkSync(savedAccount)
        
        return savedAccount
    }
    
    private func handleNetworkSync(_ account: BankAccount) async {
        do {
            _ = try await performNetworkUpdate(account)
            try await backup.removeBackup(
                entityType: "BankAccount",
                entityId: String(account.id)
            )
        } catch {
            try? await backup.createBackup(
                BackupItem<BankAccount>(
                    action: .update,
                    payload: account,
                    entityId: account.id
                )
            )
        }
    }
    
    private func performNetworkUpdate(_ account: BankAccount) async throws -> BankAccount {
        struct UpdateAccountBody: Encodable {
            let name: String
            let balance: Decimal
            let currency: String
        }
        
        let body = UpdateAccountBody(
            name: account.name,
            balance: account.balance,
            currency: account.currency.code
        )
        
        let endpoint = Endpoint(path: "/accounts/\(account.id)", method: .put)
        let dto: BankAccountDTO = try await networkClient.request(endpoint, body: body, encoder: JSONCoding.encoder)
        
        guard let updated = BankAccountDTOToDomainConverter.convert(dto) else {
            throw NSError(domain: "ConversionError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Ошибка обработки данных"])
        }
        
        return updated
    }
    
    private func fetchAndSaveFromNetwork() async throws -> BankAccount {
        let endpoint = Endpoint(path: "/accounts/\(accountId)", method: .get)
        let dto: BankAccountDTO = try await networkClient.request(endpoint, body: Optional<String>.none)
        
        guard let account = BankAccountDTOToDomainConverter.convert(dto) else {
            throw NSError(domain: "ConversionError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Ошибка обработки данных"])
        }
        
        return try await persistence.saveBankAccount(account)
    }
    
    private func syncFromNetwork() async {
        do {
            let networkAccount = try await fetchAndSaveFromNetwork()
            _ = networkAccount
        } catch {
        }
    }
} 
