import Foundation

enum VLESSParserError: LocalizedError {
    case invalidScheme
    case missingUUID
    case invalidUUID
    case missingHost
    case missingPort
    case invalidPort

    var errorDescription: String? {
        switch self {
        case .invalidScheme: return "Invalid URI: must start with vless://"
        case .missingUUID: return "Missing UUID in URI"
        case .invalidUUID: return "Invalid UUID format"
        case .missingHost: return "Missing server address"
        case .missingPort: return "Missing server port"
        case .invalidPort: return "Invalid port number"
        }
    }
}

struct VLESSParser {

    static func parse(_ uri: String) throws -> VLESSConfig {
        let trimmed = uri.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.lowercased().hasPrefix("vless://") else {
            throw VLESSParserError.invalidScheme
        }

        // URLComponents doesn't handle vless:// well, so we manually parse
        // Format: vless://uuid@host:port?params#name
        let withoutScheme = String(trimmed.dropFirst("vless://".count))

        // Split fragment (#name)
        let fragmentParts = withoutScheme.split(separator: "#", maxSplits: 1)
        let mainPart = String(fragmentParts[0])
        let fragment = fragmentParts.count > 1
            ? String(fragmentParts[1]).removingPercentEncoding ?? String(fragmentParts[1])
            : nil

        // Split query (?params)
        let queryParts = mainPart.split(separator: "?", maxSplits: 1)
        let authorityPart = String(queryParts[0])
        let queryString = queryParts.count > 1 ? String(queryParts[1]) : nil

        // Parse uuid@host:port
        let atParts = authorityPart.split(separator: "@", maxSplits: 1)
        guard atParts.count == 2 else {
            throw VLESSParserError.missingUUID
        }

        let uuidString = String(atParts[0])
        guard UUID(uuidString: uuidString) != nil else {
            throw VLESSParserError.invalidUUID
        }

        let hostPort = String(atParts[1])

        // Handle IPv6 addresses [::1]:port
        let host: String
        let portString: String

        if hostPort.hasPrefix("[") {
            guard let closeBracket = hostPort.firstIndex(of: "]") else {
                throw VLESSParserError.missingHost
            }
            host = String(hostPort[hostPort.index(after: hostPort.startIndex)..<closeBracket])
            let afterBracket = hostPort[hostPort.index(after: closeBracket)...]
            guard afterBracket.hasPrefix(":") else {
                throw VLESSParserError.missingPort
            }
            portString = String(afterBracket.dropFirst())
        } else {
            let colonParts = hostPort.split(separator: ":", maxSplits: 1)
            guard colonParts.count == 2 else {
                throw VLESSParserError.missingPort
            }
            host = String(colonParts[0])
            portString = String(colonParts[1])
        }

        guard !host.isEmpty else {
            throw VLESSParserError.missingHost
        }

        guard let port = Int(portString), port > 0, port <= 65535 else {
            throw VLESSParserError.invalidPort
        }

        // Parse query parameters
        let params = parseQueryParams(queryString)

        let name = fragment ?? "\(host):\(port)"

        return VLESSConfig(
            name: name,
            address: host,
            port: port,
            uuid: uuidString,
            encryption: params["encryption"] ?? "none",
            flow: params["flow"],
            security: params["security"] ?? "tls",
            sni: params["sni"],
            fingerprint: params["fp"],
            alpn: params["alpn"]?.split(separator: ",").map(String.init),
            publicKey: params["pbk"],
            shortId: params["sid"],
            spiderX: params["spx"],
            network: params["type"] ?? "tcp",
            wsPath: params["path"],
            wsHost: params["host"],
            grpcServiceName: params["serviceName"]
        )
    }

    private static func parseQueryParams(_ query: String?) -> [String: String] {
        guard let query = query, !query.isEmpty else { return [:] }
        var params: [String: String] = [:]
        for pair in query.split(separator: "&") {
            let kv = pair.split(separator: "=", maxSplits: 1).map(String.init)
            if kv.count == 2 {
                params[kv[0]] = kv[1].removingPercentEncoding ?? kv[1]
            }
        }
        return params
    }
}
