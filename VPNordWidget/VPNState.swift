import Foundation

enum VPNConnectionState: String, Codable {
    case disconnected
    case connecting
    case connected
    case disconnecting
    case error

    var label: String {
        switch self {
        case .disconnected: return String(localized: "Disconnected")
        case .connecting: return String(localized: "Connecting...")
        case .connected: return String(localized: "Connected")
        case .disconnecting: return String(localized: "Disconnecting...")
        case .error: return String(localized: "Error")
        }
    }

    var isActive: Bool {
        self == .connected
    }

    var isTransitioning: Bool {
        self == .connecting || self == .disconnecting
    }
}
