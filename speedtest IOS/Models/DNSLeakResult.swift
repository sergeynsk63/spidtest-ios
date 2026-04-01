import Foundation

struct DNSLeakResult: Codable, Identifiable {
    let id: UUID
    let ip: String
    let country: String
    let countryCode: String
    let isp: String

    init(id: UUID = UUID(), ip: String, country: String, countryCode: String, isp: String) {
        self.id = id
        self.ip = ip
        self.country = country
        self.countryCode = countryCode
        self.isp = isp
    }

    var flagEmoji: String {
        let base: UInt32 = 127397
        return countryCode.uppercased().unicodeScalars.compactMap {
            UnicodeScalar(base + $0.value)
        }.map { String($0) }.joined()
    }
}

enum LeakStatus: Equatable {
    case safe
    case leak
    case noVPN
    case testing
    case error(String)
    case idle

    var label: String {
        switch self {
        case .safe: return String(localized: "No DNS Leak Detected")
        case .leak: return String(localized: "DNS Leak Detected!")
        case .noVPN: return String(localized: "VPN Not Connected")
        case .testing: return String(localized: "Testing...")
        case .error(let msg): return "\(String(localized: "Error")): \(msg)"
        case .idle: return String(localized: "Ready to Test")
        }
    }
}
