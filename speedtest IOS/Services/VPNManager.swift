import Foundation
import NetworkExtension
import Combine

@MainActor
final class VPNManager: ObservableObject {
    static let shared = VPNManager()

    @Published private(set) var state: VPNConnectionState = .disconnected
    @Published private(set) var connectedSince: Date?

    private var manager: NETunnelProviderManager?
    private var statusObserver: NSObjectProtocol?

    private init() {}

    // MARK: - Setup

    func loadOrCreateManager() async throws {
        let managers = try await NETunnelProviderManager.loadAllFromPreferences()

        if let existing = managers.first {
            manager = existing
        } else {
            // Не создаём менеджер заранее — создадим при первом connect
            manager = nil
        }

        observeStatus()
        updateState()
    }

    // MARK: - Connect / Disconnect

    func connect(server: VLESSConfig) async throws {
        // Создаём или используем существующий менеджер
        let tunnelManager: NETunnelProviderManager
        if let existing = manager {
            tunnelManager = existing
        } else {
            tunnelManager = NETunnelProviderManager()
        }

        // Настраиваем протокол
        let proto = NETunnelProviderProtocol()
        proto.providerBundleIdentifier = AppConstants.VPN.tunnelBundleID
        proto.serverAddress = server.address

        // Передаём конфиг сервера
        if let configData = try? JSONEncoder().encode(server) {
            proto.providerConfiguration = [
                "config": configData
            ]
        }

        // Kill switch
        if SharedDefaults.shared.killSwitch {
            proto.includeAllNetworks = true
            proto.excludeLocalNetworks = true
        }

        tunnelManager.protocolConfiguration = proto
        tunnelManager.isEnabled = true
        tunnelManager.localizedDescription = AppConstants.appName

        // saveToPreferences вызовет системный диалог "Разрешить VPN?"
        try await tunnelManager.saveToPreferences()
        // После разрешения — перезагружаем
        try await tunnelManager.loadFromPreferences()

        manager = tunnelManager
        observeStatus()

        state = .connecting

        try tunnelManager.connection.startVPNTunnel()
    }

    func disconnect() {
        manager?.connection.stopVPNTunnel()
        state = .disconnecting
    }

    func toggleConnection(server: VLESSConfig?) async throws {
        if state == .connected || state == .connecting {
            disconnect()
        } else if let server = server {
            try await connect(server: server)
        }
    }

    // MARK: - Status Observation

    private func observeStatus() {
        statusObserver.map { NotificationCenter.default.removeObserver($0) }

        statusObserver = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: manager?.connection,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateState()
            }
        }
    }

    private func updateState() {
        guard let connection = manager?.connection else {
            state = .disconnected
            return
        }

        let newState = mapStatus(connection.status)
        state = newState

        if newState == .connected {
            if connectedSince == nil {
                connectedSince = connection.connectedDate ?? Date()
            }
            SharedDefaults.shared.vpnState = .connected
            SharedDefaults.shared.connectedSince = connectedSince
        } else {
            if newState == .disconnected || newState == .error {
                connectedSince = nil
                SharedDefaults.shared.connectedSince = nil
            }
            SharedDefaults.shared.vpnState = newState
        }
    }

    private func mapStatus(_ status: NEVPNStatus) -> VPNConnectionState {
        switch status {
        case .connected: return .connected
        case .connecting, .reasserting: return .connecting
        case .disconnecting: return .disconnecting
        case .disconnected: return .disconnected
        case .invalid: return .error
        @unknown default: return .disconnected
        }
    }
}
