import Foundation
import Network
import Combine

@MainActor
class NetworkConnectionDetector: ObservableObject {
    @Published var isConnected = false
    @Published var connectionType: NWInterface.InterfaceType?
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var previousConnectionState = false
    
    static let shared = NetworkConnectionDetector()
    
    private var connectionStateChangeSubject = PassthroughSubject<Bool, Never>()
    var connectionStateChange: AnyPublisher<Bool, Never> {
        connectionStateChangeSubject.eraseToAnyPublisher()
    }
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        monitor.cancel()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateConnectionStatus(path)
            }
        }
        monitor.start(queue: queue)
    }
    
    private func stopMonitoring() {
        monitor.cancel()
    }
    
    private func updateConnectionStatus(_ path: NWPath) {
        let newConnectionState = path.status == .satisfied
        
        if newConnectionState != previousConnectionState {
            connectionStateChangeSubject.send(newConnectionState)
            previousConnectionState = newConnectionState
        }
        
        isConnected = newConnectionState
        
        if newConnectionState {
            if path.usesInterfaceType(.wifi) {
                connectionType = .wifi
            } else if path.usesInterfaceType(.cellular) {
                connectionType = .cellular
            } else if path.usesInterfaceType(.wiredEthernet) {
                connectionType = .wiredEthernet
            } else {
                connectionType = nil
            }
        } else {
            connectionType = nil
        }
    }
    
    func checkConnection() -> Bool {
        return isConnected
    }
    
    func getConnectionType() -> NWInterface.InterfaceType? {
        return connectionType
    }
    
    func hasHighSpeedConnection() -> Bool {
        guard isConnected else { return false }
        return connectionType == .wifi || connectionType == .wiredEthernet
    }
} 