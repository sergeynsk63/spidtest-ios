import Foundation
import SwiftUI

@MainActor
final class SpeedTestViewModel: ObservableObject {
    @Published var phase: SpeedTestPhase = .idle
    @Published var currentSpeed: Double = 0
    @Published var downloadSpeed: Double = 0
    @Published var uploadSpeed: Double = 0
    @Published var ping: Double = 0
    @Published var jitter: Double = 0
    @Published var isTesting = false
    @Published var showResult = false

    private let service = SpeedTestService()
    private let historyStore = TestHistoryStore.shared
    private var testTask: Task<Void, Never>?

    var maxGaugeSpeed: Double {
        max(100, downloadSpeed, uploadSpeed, currentSpeed)
    }

    var latestResult: SpeedTestResult? {
        historyStore.results.first
    }

    func startTest() {
        guard !isTesting else { return }
        reset()
        isTesting = true

        testTask = Task {
            // Phase 1: Ping
            phase = .ping
            let pingResult = await service.measurePing()
            ping = pingResult.ping
            jitter = pingResult.jitter

            guard !Task.isCancelled else { return }

            // Phase 2: Download
            phase = .download
            downloadSpeed = await service.measureDownload { speed in
                Task { @MainActor in
                    self.currentSpeed = speed
                }
            }

            guard !Task.isCancelled else { return }

            // Phase 3: Upload
            phase = .upload
            currentSpeed = 0
            uploadSpeed = await service.measureUpload { speed in
                Task { @MainActor in
                    self.currentSpeed = speed
                }
            }

            // Done
            phase = .done
            currentSpeed = 0
            isTesting = false

            let result = SpeedTestResult(
                downloadSpeed: downloadSpeed,
                uploadSpeed: uploadSpeed,
                ping: ping,
                jitter: jitter,
                serverName: "Cloudflare",
                connectionType: service.connectionType()
            )
            historyStore.add(result)
            showResult = true
        }
    }

    func stopTest() {
        testTask?.cancel()
        testTask = nil
        isTesting = false
        phase = .idle
        currentSpeed = 0
    }

    private func reset() {
        phase = .idle
        currentSpeed = 0
        downloadSpeed = 0
        uploadSpeed = 0
        ping = 0
        jitter = 0
        showResult = false
    }
}
