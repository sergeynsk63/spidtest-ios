import Foundation

struct VLESSConfig: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var address: String
    var port: Int
    var uuid: String

    // Protocol
    var encryption: String
    var flow: String?

    // Security
    var security: String  // "tls" / "reality" / "none"
    var sni: String?
    var fingerprint: String?
    var alpn: [String]?

    // Reality
    var publicKey: String?
    var shortId: String?
    var spiderX: String?

    // Transport
    var network: String  // "tcp" / "ws" / "grpc" / "h2"
    var wsPath: String?
    var wsHost: String?
    var grpcServiceName: String?

    // Geo
    var countryCode: String?

    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        address: String,
        port: Int,
        uuid: String,
        encryption: String = "none",
        flow: String? = nil,
        security: String = "tls",
        sni: String? = nil,
        fingerprint: String? = nil,
        alpn: [String]? = nil,
        publicKey: String? = nil,
        shortId: String? = nil,
        spiderX: String? = nil,
        network: String = "tcp",
        wsPath: String? = nil,
        wsHost: String? = nil,
        grpcServiceName: String? = nil,
        countryCode: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.port = port
        self.uuid = uuid
        self.encryption = encryption
        self.flow = flow
        self.security = security
        self.sni = sni
        self.fingerprint = fingerprint
        self.alpn = alpn
        self.publicKey = publicKey
        self.shortId = shortId
        self.spiderX = spiderX
        self.network = network
        self.wsPath = wsPath
        self.wsHost = wsHost
        self.grpcServiceName = grpcServiceName
        self.countryCode = countryCode
        self.createdAt = createdAt
    }

    var displayAddress: String {
        address
    }

    var securityLabel: String {
        switch security {
        case "reality": return "Reality"
        case "tls": return "TLS"
        default: return "None"
        }
    }

    var flagEmoji: String? {
        guard let code = countryCode, code.count == 2 else { return nil }
        let base: UInt32 = 0x1F1E6
        let aValue = UInt32(UnicodeScalar("A").value)
        let chars = code.uppercased().unicodeScalars.compactMap { scalar -> Character? in
            guard let s = UnicodeScalar(base + scalar.value - aValue) else { return nil }
            return Character(s)
        }
        return chars.count == 2 ? String(chars) : nil
    }

    var networkLabel: String {
        switch network {
        case "ws": return "WebSocket"
        case "grpc": return "gRPC"
        case "h2": return "HTTP/2"
        default: return "TCP"
        }
    }
}
