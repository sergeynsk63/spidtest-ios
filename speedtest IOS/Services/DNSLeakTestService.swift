import Foundation

final class DNSLeakTestService {

    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        session = URLSession(configuration: config)
    }

    // MARK: - Public

    func runTest() async throws -> [DNSLeakResult] {
        // Step 1: Get a test ID
        let testID = generateTestID()

        // Step 2: Make DNS requests to trigger resolution
        // These requests go to unique subdomains that the test server tracks
        await triggerDNSQueries(testID: testID)

        // Step 3: Fetch results — which DNS servers resolved our queries
        let results = try await fetchResults(testID: testID)
        return results
    }

    func checkForLeaks(results: [DNSLeakResult], vpnConnected: Bool) -> LeakStatus {
        guard vpnConnected else { return .noVPN }
        guard !results.isEmpty else { return .error("No results") }

        // If there's only 1 DNS server and it's a known public DNS, likely safe
        // If there are multiple ISP DNS servers, likely a leak
        // Simple heuristic: more than 2 unique ISPs suggests a leak
        let uniqueISPs = Set(results.map { $0.isp })

        // If any result looks like an ISP (not a known VPN/public DNS), it's a leak
        // This is a simplified check — in production, compare against VPN provider's DNS
        if results.count > 3 {
            return .leak
        }

        return .safe
    }

    // MARK: - Private

    private func generateTestID() -> String {
        let chars = "abcdefghijklmnopqrstuvwxyz0123456789"
        return String((0..<10).map { _ in chars.randomElement()! })
    }

    private func triggerDNSQueries(testID: String) async {
        // Make multiple DNS requests to unique subdomains
        // bash.ws tracks which DNS servers resolve these
        let baseURL = AppConstants.DNSLeakTest.apiBase

        for i in 1...10 {
            let urlString = "\(baseURL)/dnsleak/test/\(testID)?r=\(i)"
            guard let url = URL(string: urlString) else { continue }

            _ = try? await session.data(from: url)
            // Small delay between requests
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        }
    }

    private func fetchResults(testID: String) async throws -> [DNSLeakResult] {
        // Wait a moment for results to aggregate
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5s

        let urlString = "\(AppConstants.DNSLeakTest.apiBase)/dnsleak/test/\(testID)?json"
        guard let url = URL(string: urlString) else {
            throw DNSLeakError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw DNSLeakError.serverError
        }

        let apiResults = try JSONDecoder().decode([DNSLeakAPIResult].self, from: data)

        return apiResults
            .filter { $0.type == "dns" }
            .map { result in
                DNSLeakResult(
                    ip: result.ip,
                    country: result.country_name ?? "Unknown",
                    countryCode: result.country ?? "",
                    isp: result.asn ?? "Unknown ISP"
                )
            }
    }
}

// MARK: - API Models

private struct DNSLeakAPIResult: Codable {
    let ip: String
    let country: String?
    let country_name: String?
    let asn: String?
    let type: String?
}

enum DNSLeakError: LocalizedError {
    case invalidURL
    case serverError

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid test URL"
        case .serverError: return "Test server unavailable"
        }
    }
}
