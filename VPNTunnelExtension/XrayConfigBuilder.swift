import Foundation

struct XrayConfigBuilder {

    static func build(from config: VLESSConfig, socksPort: Int = 10808) -> String {
        let json = buildDictionary(from: config, socksPort: socksPort)
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return string
    }

    static func buildDictionary(from config: VLESSConfig, socksPort: Int = 10808) -> [String: Any] {
        var json: [String: Any] = [:]

        // Log
        json["log"] = [
            "loglevel": "warning"
        ]

        // Inbounds - SOCKS proxy
        json["inbounds"] = [
            [
                "tag": "socks-in",
                "port": socksPort,
                "listen": "127.0.0.1",
                "protocol": "socks",
                "settings": [
                    "udp": true
                ]
            ] as [String: Any]
        ]

        // Outbounds
        var outbound: [String: Any] = [
            "tag": "proxy",
            "protocol": "vless"
        ]

        // User settings
        var user: [String: Any] = [
            "id": config.uuid,
            "encryption": config.encryption
        ]
        if let flow = config.flow, !flow.isEmpty {
            user["flow"] = flow
        }

        outbound["settings"] = [
            "vnext": [
                [
                    "address": config.address,
                    "port": config.port,
                    "users": [user]
                ] as [String: Any]
            ]
        ]

        // Stream settings
        var streamSettings: [String: Any] = [
            "network": config.network
        ]

        // Security
        streamSettings["security"] = config.security

        switch config.security {
        case "tls":
            var tlsSettings: [String: Any] = [:]
            if let sni = config.sni, !sni.isEmpty {
                tlsSettings["serverName"] = sni
            }
            if let fp = config.fingerprint, !fp.isEmpty {
                tlsSettings["fingerprint"] = fp
            }
            if let alpn = config.alpn, !alpn.isEmpty {
                tlsSettings["alpn"] = alpn
            }
            if !tlsSettings.isEmpty {
                streamSettings["tlsSettings"] = tlsSettings
            }

        case "reality":
            var realitySettings: [String: Any] = [:]
            if let sni = config.sni, !sni.isEmpty {
                realitySettings["serverName"] = sni
            }
            if let fp = config.fingerprint, !fp.isEmpty {
                realitySettings["fingerprint"] = fp
            }
            if let pbk = config.publicKey, !pbk.isEmpty {
                realitySettings["publicKey"] = pbk
            }
            if let sid = config.shortId, !sid.isEmpty {
                realitySettings["shortId"] = sid
            }
            if let spx = config.spiderX, !spx.isEmpty {
                realitySettings["spiderX"] = spx
            }
            if !realitySettings.isEmpty {
                streamSettings["realitySettings"] = realitySettings
            }

        default:
            break
        }

        // Transport settings
        switch config.network {
        case "ws":
            var wsSettings: [String: Any] = [:]
            if let path = config.wsPath, !path.isEmpty {
                wsSettings["path"] = path
            }
            if let host = config.wsHost, !host.isEmpty {
                wsSettings["headers"] = ["Host": host]
            }
            if !wsSettings.isEmpty {
                streamSettings["wsSettings"] = wsSettings
            }

        case "grpc":
            if let serviceName = config.grpcServiceName, !serviceName.isEmpty {
                streamSettings["grpcSettings"] = [
                    "serviceName": serviceName
                ]
            }

        case "h2":
            var h2Settings: [String: Any] = [:]
            if let path = config.wsPath, !path.isEmpty {
                h2Settings["path"] = path
            }
            if let host = config.wsHost, !host.isEmpty {
                h2Settings["host"] = [host]
            }
            if !h2Settings.isEmpty {
                streamSettings["httpSettings"] = h2Settings
            }

        default:
            break // TCP — no extra settings
        }

        outbound["streamSettings"] = streamSettings

        // Direct and block outbounds
        let directOutbound: [String: Any] = [
            "tag": "direct",
            "protocol": "freedom"
        ]

        let blockOutbound: [String: Any] = [
            "tag": "block",
            "protocol": "blackhole"
        ]

        json["outbounds"] = [outbound, directOutbound, blockOutbound]

        // Routing — простые правила без GeoIP файлов
        json["routing"] = [
            "domainStrategy": "AsIs",
            "rules": [
                [
                    "type": "field",
                    "outboundTag": "direct",
                    "ip": [
                        "10.0.0.0/8",
                        "172.16.0.0/12",
                        "192.168.0.0/16",
                        "127.0.0.0/8"
                    ]
                ] as [String: Any]
            ]
        ]

        return json
    }
}
