import Foundation

struct SpeedTestResult: Codable, Identifiable {
    let id: UUID
    let date: Date
    let downloadSpeed: Double
    let uploadSpeed: Double
    let ping: Double
    let jitter: Double
    let serverName: String
    let connectionType: String

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        downloadSpeed: Double,
        uploadSpeed: Double,
        ping: Double,
        jitter: Double,
        serverName: String = "Cloudflare",
        connectionType: String = "Wi-Fi"
    ) {
        self.id = id
        self.date = date
        self.downloadSpeed = downloadSpeed
        self.uploadSpeed = uploadSpeed
        self.ping = ping
        self.jitter = jitter
        self.serverName = serverName
        self.connectionType = connectionType
    }
}
