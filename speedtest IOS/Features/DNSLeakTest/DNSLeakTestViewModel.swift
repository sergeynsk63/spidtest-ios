import Foundation

@MainActor
final class DNSLeakTestViewModel: ObservableObject {
    @Published var status: LeakStatus = .idle
    @Published var results: [DNSLeakResult] = []
    @Published var isTesting = false
    @Published var queryTime: TimeInterval = 0

    private let service = DNSLeakTestService()
    private let vpnManager = VPNManager.shared

    var vpnConnected: Bool {
        vpnManager.state == .connected
    }

    func runTest() async {
        isTesting = true
        status = .testing
        results = []
        queryTime = 0

        let startTime = CFAbsoluteTimeGetCurrent()

        do {
            let testResults = try await service.runTest()
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime

            results = testResults
            queryTime = elapsed
            status = service.checkForLeaks(results: testResults, vpnConnected: vpnConnected)
        } catch {
            status = .error(error.localizedDescription)
        }

        isTesting = false
    }
}
