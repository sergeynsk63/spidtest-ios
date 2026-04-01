import Foundation
import SwiftUI

// MARK: - GeoIP Lookup

private enum GeoIP {
    static func lookupCountryCode(for address: String) async -> String? {
        // ipwho.is — бесплатный HTTPS API без ключа
        let urlString = "https://ipwho.is/\(address)?fields=country_code"
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return json?["country_code"] as? String
        } catch {
            return nil
        }
    }
}

// MARK: - ServerStore

@MainActor
final class ServerStore: ObservableObject {
    static let shared = ServerStore()

    @Published private(set) var servers: [VLESSConfig] = []
    @Published var activeServerID: UUID?

    private let shared_defaults = SharedDefaults.shared

    private init() {
        servers = shared_defaults.servers
        activeServerID = shared_defaults.activeServerID
        resolveAllCountryCodes()
    }

    /// Resolve country codes for servers that don't have one
    private func resolveAllCountryCodes() {
        for server in servers where server.countryCode == nil {
            let serverID = server.id
            let address = server.address
            Task {
                if let code = await GeoIP.lookupCountryCode(for: address) {
                    if let index = self.servers.firstIndex(where: { $0.id == serverID }) {
                        self.servers[index].countryCode = code
                        // If server has a generic name (IP:port), generate a readable one
                        if self.servers[index].name.contains(":") || self.servers[index].name.contains("Marz") {
                            self.servers[index].name = self.generateName(countryCode: code)
                        }
                        self.save()
                    }
                }
            }
        }
    }

    // MARK: - CRUD

    func add(_ config: VLESSConfig) {
        servers.insert(config, at: 0)
        if servers.count == 1 {
            activeServerID = config.id
        }
        save()

        // Resolve country in background
        let serverID = config.id
        let address = config.address
        Task {
            if let code = await GeoIP.lookupCountryCode(for: address) {
                if let index = self.servers.firstIndex(where: { $0.id == serverID }) {
                    self.servers[index].countryCode = code
                    // If server has a generic name, generate a readable one
                    if self.servers[index].name.contains(":") || self.servers[index].name.contains("Marz") {
                        self.servers[index].name = self.generateName(countryCode: code)
                    }
                    self.save()
                }
            }
        }
    }

    /// Generate server name like "DE-1", "DE-2", "US-1"
    private func generateName(countryCode: String) -> String {
        let code = countryCode.uppercased()
        let existing = servers.filter { $0.countryCode?.uppercased() == code }
        let usedNumbers = existing.compactMap { server -> Int? in
            let parts = server.name.split(separator: "-")
            guard parts.count == 2,
                  parts[0] == Substring(code) else { return nil }
            return Int(parts[1])
        }
        let nextNumber = (usedNumbers.max() ?? 0) + 1
        return "\(code)-\(nextNumber)"
    }

    func remove(id: UUID) {
        servers.removeAll { $0.id == id }
        if activeServerID == id {
            activeServerID = servers.first?.id
        }
        save()
    }

    func setActive(id: UUID) {
        guard servers.contains(where: { $0.id == id }) else { return }
        activeServerID = id
        save()
    }

    var activeServer: VLESSConfig? {
        guard let id = activeServerID else { return servers.first }
        return servers.first { $0.id == id }
    }

    // MARK: - Import

    @discardableResult
    func importFromURI(_ uri: String) throws -> VLESSConfig {
        let config = try VLESSParser.parse(uri)

        // Check for duplicate (same address + port + uuid)
        if let existing = servers.first(where: {
            $0.address == config.address && $0.port == config.port && $0.uuid == config.uuid
        }) {
            throw ImportError.duplicate(existing.name)
        }

        add(config)
        return config
    }

    /// Import from subscription URL or direct URI.
    /// Returns the number of servers imported.
    func importFromInput(_ input: String) async throws -> Int {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Direct vless:// URI
        if trimmed.lowercased().hasPrefix("vless://") {
            try importFromURI(trimmed)
            return 1
        }

        // Subscription URL (https:// or http://)
        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
            return try await importFromSubscription(trimmed)
        }

        // Try base64-decoded content (some apps copy raw base64)
        if let decoded = decodeBase64(trimmed), decoded.contains("vless://") {
            return importMultipleURIs(decoded)
        }

        // Fallback: try as direct URI
        try importFromURI(trimmed)
        return 1
    }

    /// Fetch subscription URL, decode base64, import all vless:// URIs
    private func importFromSubscription(_ urlString: String) async throws -> Int {
        guard let url = URL(string: urlString) else {
            throw ImportError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ImportError.subscriptionFailed
        }

        guard let body = String(data: data, encoding: .utf8), !body.isEmpty else {
            throw ImportError.emptySubscription
        }

        // Subscription response is base64-encoded list of URIs
        let content: String
        if let decoded = decodeBase64(body.trimmingCharacters(in: .whitespacesAndNewlines)) {
            content = decoded
        } else {
            // Some providers return plain text URIs
            content = body
        }

        let count = importMultipleURIs(content)
        if count == 0 {
            throw ImportError.noServersFound
        }
        return count
    }

    /// Import multiple URIs from newline-separated string
    private func importMultipleURIs(_ content: String) -> Int {
        let lines = content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.lowercased().hasPrefix("vless://") }

        var imported = 0
        for line in lines {
            do {
                try importFromURI(line)
                imported += 1
            } catch ImportError.duplicate {
                continue // skip duplicates silently
            } catch {
                continue // skip unparseable URIs
            }
        }
        return imported
    }

    private func decodeBase64(_ string: String) -> String? {
        // Handle URL-safe base64 and padding
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        guard let data = Data(base64Encoded: base64) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Persistence

    private func save() {
        shared_defaults.servers = servers
        shared_defaults.activeServerID = activeServerID
    }

    // MARK: - Errors

    enum ImportError: LocalizedError {
        case duplicate(String)
        case invalidURL
        case subscriptionFailed
        case emptySubscription
        case noServersFound

        var errorDescription: String? {
            switch self {
            case .duplicate(let name):
                return "Server '\(name)' already exists"
            case .invalidURL:
                return "Invalid URL"
            case .subscriptionFailed:
                return "Failed to fetch subscription"
            case .emptySubscription:
                return "Subscription returned empty response"
            case .noServersFound:
                return "No VLESS servers found in subscription"
            }
        }
    }
}
