import Foundation

final class SharedDefaults {
    static let shared = SharedDefaults()

    private let defaults: UserDefaults

    private enum Keys {
        static let vpnState = "vpn_state"
        static let servers = "vpn_servers"
        static let activeServerID = "vpn_active_server_id"
        static let autoConnect = "vpn_auto_connect"
        static let killSwitch = "vpn_kill_switch"
        static let connectedSince = "vpn_connected_since"
    }

    init() {
        guard let defaults = UserDefaults(suiteName: AppConstants.VPN.appGroupID) else {
            fatalError("Failed to initialize UserDefaults with App Group: \(AppConstants.VPN.appGroupID)")
        }
        self.defaults = defaults
    }

    // MARK: - VPN State

    var vpnState: VPNConnectionState {
        get {
            guard let raw = defaults.string(forKey: Keys.vpnState),
                  let state = VPNConnectionState(rawValue: raw) else {
                return .disconnected
            }
            return state
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.vpnState)
        }
    }

    // MARK: - Servers

    var servers: [VLESSConfig] {
        get {
            guard let data = defaults.data(forKey: Keys.servers),
                  let configs = try? JSONDecoder().decode([VLESSConfig].self, from: data) else {
                return []
            }
            return configs
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.servers)
            }
        }
    }

    var activeServerID: UUID? {
        get {
            guard let str = defaults.string(forKey: Keys.activeServerID) else { return nil }
            return UUID(uuidString: str)
        }
        set {
            defaults.set(newValue?.uuidString, forKey: Keys.activeServerID)
        }
    }

    var activeServer: VLESSConfig? {
        guard let id = activeServerID else { return nil }
        return servers.first { $0.id == id }
    }

    // MARK: - Settings

    var autoConnect: Bool {
        get { defaults.bool(forKey: Keys.autoConnect) }
        set { defaults.set(newValue, forKey: Keys.autoConnect) }
    }

    var killSwitch: Bool {
        get { defaults.bool(forKey: Keys.killSwitch) }
        set { defaults.set(newValue, forKey: Keys.killSwitch) }
    }

    // MARK: - Connection Timer

    var connectedSince: Date? {
        get { defaults.object(forKey: Keys.connectedSince) as? Date }
        set { defaults.set(newValue, forKey: Keys.connectedSince) }
    }
}
