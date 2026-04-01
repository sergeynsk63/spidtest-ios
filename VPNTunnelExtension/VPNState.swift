import Foundation

enum VPNConnectionState: String, Codable {
    case disconnected
    case connecting
    case connected
    case disconnecting
    case error

    var label: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .disconnecting: return "Disconnecting..."
        case .error: return "Error"
        }
    }

    var isActive: Bool {
        self == .connected
    }

    var isTransitioning: Bool {
        self == .connecting || self == .disconnecting
    }
}
