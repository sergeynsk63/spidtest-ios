import NetworkExtension
import SwiftyXrayKit
import os.log

class PacketTunnelProvider: NEPacketTunnelProvider {

    private let logger = Logger(subsystem: "com.vpneo.app.tunnel", category: "Tunnel")
    private var xrayClient: XRayTunnel?

    override func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        logger.info("Starting tunnel...")

        // 1. Read server config
        guard let proto = protocolConfiguration as? NETunnelProviderProtocol,
              let providerConfig = proto.providerConfiguration,
              let configData = providerConfig["config"] as? Data else {
            logger.error("No provider configuration found")
            completionHandler(NSError(domain: "VPNTunnel", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Invalid provider configuration"
            ]))
            return
        }

        let serverConfig: VLESSConfig
        do {
            serverConfig = try JSONDecoder().decode(VLESSConfig.self, from: configData)
        } catch {
            logger.error("Failed to decode config: \(error.localizedDescription)")
            completionHandler(NSError(domain: "VPNTunnel", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Config decode error: \(error.localizedDescription)"
            ]))
            return
        }

        logger.info("Server: \(serverConfig.address):\(serverConfig.port)")

        // 2. Build Xray JSON config
        let xrayConfig = XrayConfigBuilder.build(from: serverConfig)
        logger.info("Xray config built")

        // 3. Set tunnel network settings
        let tunnelSettings = createTunnelSettings()

        setTunnelNetworkSettings(tunnelSettings) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                self.logger.error("Tunnel settings error: \(error.localizedDescription)")
                completionHandler(error)
                return
            }

            self.logger.info("Tunnel settings applied, starting Xray...")

            // 4. Start Xray
            self.startXray(config: xrayConfig, completionHandler: completionHandler)
        }
    }

    private func startXray(config: String, completionHandler: @escaping (Error?) -> Void) {
        xrayClient = XRayTunnel(packetFlow: packetFlow)

        let dataDir = geoDataDirectory()
        let finalConfigPath = dataDir.appendingPathComponent("config.json")

        logger.info("Data dir: \(dataDir.path)")

        Task {
            do {
                try await xrayClient?.run(
                    dataDir: dataDir,
                    config: .json(config),
                    finalConfigPath: finalConfigPath
                )

                SharedDefaults.shared.vpnState = .connected
                SharedDefaults.shared.connectedSince = Date()

                self.logger.info("Xray started successfully")
                completionHandler(nil)
            } catch {
                self.logger.error("Xray start failed: \(error.localizedDescription)")
                completionHandler(error)
            }
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        logger.info("Stopping tunnel, reason: \(String(describing: reason))")

        Task {
            await xrayClient?.stop()
            xrayClient = nil

            SharedDefaults.shared.vpnState = .disconnected
            SharedDefaults.shared.connectedSince = nil

            logger.info("Tunnel stopped")
            completionHandler()
        }
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        completionHandler?(nil)
    }

    override func sleep(completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    override func wake() {}

    // MARK: - Network Settings

    private func createTunnelSettings() -> NEPacketTunnelNetworkSettings {
        // Используем подход из Example — находим свободный IP в 10.x.x.x
        let interfaces = enumerateInterfaces().map { $0.ip }.filter { $0.isIPv4() }
        var net = 5
        while interfaces.contains(where: { $0.hasPrefix("10.\(net)") }) {
            net += 1
        }
        let localIp = "10.\(net).5.2"

        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        settings.mtu = 1360

        // IPv4
        let ipv4 = NEIPv4Settings(addresses: [localIp], subnetMasks: ["255.255.255.255"])
        ipv4.includedRoutes = [NEIPv4Route.default()]
        ipv4.excludedRoutes = [
            NEIPv4Route(destinationAddress: "172.16.0.0", subnetMask: "255.240.0.0"),
            NEIPv4Route(destinationAddress: "192.168.0.0", subnetMask: "255.255.0.0"),
            NEIPv4Route(destinationAddress: "10.0.0.0", subnetMask: "255.0.0.0")
        ]
        settings.ipv4Settings = ipv4

        // DNS
        settings.dnsSettings = NEDNSSettings(servers: ["127.0.0.1", "1.1.1.1", "8.8.8.8"])

        return settings
    }

    // MARK: - Helpers

    private func geoDataDirectory() -> URL {
        let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppConstants.VPN.appGroupID
        )
        let geoDir = containerURL?.appendingPathComponent("geo") ?? URL(fileURLWithPath: NSTemporaryDirectory())

        try? FileManager.default.createDirectory(at: geoDir, withIntermediateDirectories: true)

        return geoDir
    }

    // MARK: - Network Interfaces

    struct NetworkInterfaceInfo {
        let name: String
        let ip: String
        let netmask: String
    }

    private func enumerateInterfaces() -> [NetworkInterfaceInfo] {
        var interfaces = [NetworkInterfaceInfo]()
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                let flags = Int32(ptr!.pointee.ifa_flags)
                var addr = ptr!.pointee.ifa_addr.pointee

                if (flags & (IFF_UP | IFF_RUNNING)) == (IFF_UP | IFF_RUNNING) {
                    if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {
                        var mask = ptr!.pointee.ifa_netmask.pointee
                        let zero = CChar(0)
                        var hostname = [CChar](repeating: zero, count: Int(NI_MAXHOST))
                        var netmask = [CChar](repeating: zero, count: Int(NI_MAXHOST))

                        if getnameinfo(&addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
                                       nil, socklen_t(0), NI_NUMERICHOST) == 0 {
                            let address = String(cString: hostname)
                            let ifname = String(cString: ptr!.pointee.ifa_name!)

                            if getnameinfo(&mask, socklen_t(mask.sa_len), &netmask, socklen_t(netmask.count),
                                           nil, socklen_t(0), NI_NUMERICHOST) == 0 {
                                let netmaskIP = String(cString: netmask)
                                interfaces.append(NetworkInterfaceInfo(name: ifname, ip: address, netmask: netmaskIP))
                            }
                        }
                    }
                }
                ptr = ptr!.pointee.ifa_next
            }
            freeifaddrs(ifaddr)
        }
        return interfaces
    }
}

// MARK: - String IP Helpers

private extension String {
    func isIPv4() -> Bool {
        var sin = sockaddr_in()
        return self.withCString { cstring in inet_pton(AF_INET, cstring, &sin.sin_addr) } == 1
    }
}
