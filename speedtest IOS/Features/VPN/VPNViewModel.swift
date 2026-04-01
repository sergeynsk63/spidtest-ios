import Foundation
import SwiftUI
import Combine

@MainActor
final class VPNViewModel: ObservableObject {
    @Published var state: VPNConnectionState = .disconnected
    @Published var connectionDuration: TimeInterval = 0
    @Published var showAddServer = false
    @Published var showServerList = false
    @Published var importText = ""
    @Published var errorMessage: String?

    private let vpnManager = VPNManager.shared
    let serverStore = ServerStore.shared
    let loadBalancer = LoadBalancer.shared

    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var lastConnectedServer: VLESSConfig?
    private var failoverAttempts = 0
    private let maxFailoverAttempts = 3

    init() {
        vpnManager.$state
            .receive(on: DispatchQueue.main)
            .assign(to: &$state)

        $state
            .sink { [weak self] newState in
                guard let self = self else { return }
                if newState == .connected {
                    self.startTimer()
                    self.failoverAttempts = 0
                } else {
                    self.stopTimer()
                    if newState == .disconnected || newState == .error {
                        self.connectionDuration = 0
                    }
                    // Failover: if disconnected unexpectedly, try next server
                    if newState == .error,
                       self.loadBalancer.mode == .failover,
                       self.failoverAttempts < self.maxFailoverAttempts {
                        Task { await self.attemptFailover() }
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func setup() async {
        do {
            try await vpnManager.loadOrCreateManager()
        } catch {
            errorMessage = error.localizedDescription
        }

        // Measure pings if in bestPing mode
        if loadBalancer.mode == .bestPing {
            await loadBalancer.measureAllPings(servers: serverStore.servers)
        }
    }

    func toggleConnection() async {
        errorMessage = nil

        if state == .connected || state == .connecting {
            vpnManager.disconnect()
            return
        }

        // Select server based on balancing mode
        let server: VLESSConfig?
        if loadBalancer.mode == .bestPing && loadBalancer.serverPings.isEmpty {
            // Measure first, then select
            await loadBalancer.measureAllPings(servers: serverStore.servers)
            server = loadBalancer.selectServer(from: serverStore.servers, current: serverStore.activeServer)
        } else {
            server = loadBalancer.selectServer(from: serverStore.servers, current: serverStore.activeServer)
        }

        guard let server = server else {
            showAddServer = true
            return
        }

        // Update active server in store
        serverStore.setActive(id: server.id)
        lastConnectedServer = server

        do {
            try await vpnManager.connect(server: server)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @Published var isImporting = false

    func importURI() async {
        let text = importText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isImporting = true
        defer { isImporting = false }

        do {
            let count = try await serverStore.importFromInput(text)
            importText = ""
            showAddServer = false
            errorMessage = nil
            if count > 1 {
                errorMessage = nil // clear any previous error
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Failover

    private func attemptFailover() async {
        guard let failed = lastConnectedServer else { return }
        failoverAttempts += 1

        errorMessage = "Server failed. Switching... (\(failoverAttempts)/\(maxFailoverAttempts))"

        guard let next = loadBalancer.nextFailoverServer(from: serverStore.servers, failed: failed) else {
            errorMessage = "No other servers available"
            return
        }

        serverStore.setActive(id: next.id)
        lastConnectedServer = next

        do {
            try await vpnManager.connect(server: next)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Timer

    var formattedDuration: String {
        let hours = Int(connectionDuration) / 3600
        let minutes = (Int(connectionDuration) % 3600) / 60
        let seconds = Int(connectionDuration) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func startTimer() {
        stopTimer()
        let startDate = vpnManager.connectedSince ?? Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.connectionDuration = Date().timeIntervalSince(startDate)
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
