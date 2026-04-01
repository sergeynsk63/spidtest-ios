import Foundation

enum BalancingMode: String, Codable, CaseIterable {
    case manual = "manual"
    case bestPing = "best_ping"
    case roundRobin = "round_robin"
    case failover = "failover"

    var label: String {
        switch self {
        case .manual: return String(localized: "Manual")
        case .bestPing: return String(localized: "Best Ping")
        case .roundRobin: return String(localized: "Round Robin")
        case .failover: return String(localized: "Failover")
        }
    }

    var description: String {
        switch self {
        case .manual: return String(localized: "Connect to selected server")
        case .bestPing: return String(localized: "Auto-select fastest server")
        case .roundRobin: return String(localized: "Rotate servers each connection")
        case .failover: return String(localized: "Switch to next if server fails")
        }
    }

    var icon: String {
        switch self {
        case .manual: return "hand.tap"
        case .bestPing: return "bolt.fill"
        case .roundRobin: return "arrow.triangle.2.circlepath"
        case .failover: return "arrow.trianglehead.branch"
        }
    }
}

@MainActor
final class LoadBalancer: ObservableObject {
    static let shared = LoadBalancer()

    @Published var mode: BalancingMode {
        didSet { SharedDefaults.shared.balancingMode = mode }
    }

    @Published private(set) var serverPings: [UUID: Double] = [:]
    @Published private(set) var isMeasuring = false

    private var roundRobinIndex: Int = 0

    private init() {
        mode = SharedDefaults.shared.balancingMode
    }

    // MARK: - Select Server

    /// Returns the best server based on current balancing mode
    func selectServer(from servers: [VLESSConfig], current: VLESSConfig?) -> VLESSConfig? {
        guard !servers.isEmpty else { return nil }

        switch mode {
        case .manual:
            return current ?? servers.first

        case .bestPing:
            return bestPingServer(from: servers) ?? current ?? servers.first

        case .roundRobin:
            return roundRobinServer(from: servers)

        case .failover:
            return current ?? servers.first
        }
    }

    /// Returns the next failover server (skipping the failed one)
    func nextFailoverServer(from servers: [VLESSConfig], failed: VLESSConfig) -> VLESSConfig? {
        guard servers.count > 1 else { return nil }
        let remaining = servers.filter { $0.id != failed.id }

        // If we have ping data, pick the best from remaining
        if !serverPings.isEmpty {
            return remaining.min(by: { pingFor($0) < pingFor($1) })
        }

        // Otherwise just pick the next one
        return remaining.first
    }

    // MARK: - Ping Measurement

    func measureAllPings(servers: [VLESSConfig]) async {
        guard !servers.isEmpty, !isMeasuring else { return }
        isMeasuring = true
        serverPings = [:]

        await withTaskGroup(of: (UUID, Double).self) { group in
            for server in servers {
                group.addTask {
                    let ping = await self.measurePing(to: server.address, port: server.port)
                    return (server.id, ping)
                }
            }

            for await (id, ping) in group {
                serverPings[id] = ping
            }
        }

        isMeasuring = false
    }

    func pingFor(_ server: VLESSConfig) -> Double {
        serverPings[server.id] ?? .infinity
    }

    func formattedPing(for server: VLESSConfig) -> String? {
        guard let ping = serverPings[server.id], ping < .infinity else { return nil }
        return "\(Int(ping)) ms"
    }

    // MARK: - Private

    private func bestPingServer(from servers: [VLESSConfig]) -> VLESSConfig? {
        guard !serverPings.isEmpty else { return nil }
        return servers.min(by: { pingFor($0) < pingFor($1) })
    }

    private func roundRobinServer(from servers: [VLESSConfig]) -> VLESSConfig {
        let index = roundRobinIndex % servers.count
        roundRobinIndex += 1
        return servers[index]
    }

    private nonisolated func measurePing(to host: String, port: Int) async -> Double {
        let start = CFAbsoluteTimeGetCurrent()

        // TCP connect to measure latency
        let semaphore = DispatchSemaphore(value: 0)
        var elapsed: Double = .infinity

        let queue = DispatchQueue(label: "ping.\(host)")
        let connection = NWConnection(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(integerLiteral: UInt16(port)),
            using: .tcp
        )

        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
                connection.cancel()
                semaphore.signal()
            case .failed, .cancelled:
                semaphore.signal()
            default:
                break
            }
        }

        connection.start(queue: queue)
        _ = semaphore.wait(timeout: .now() + 5)
        connection.cancel()

        return elapsed
    }
}

import Network
