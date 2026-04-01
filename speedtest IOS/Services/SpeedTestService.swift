import Foundation

enum SpeedTestPhase {
    case idle
    case ping
    case download
    case upload
    case done

    var label: String {
        switch self {
        case .idle: return String(localized: "Ready")
        case .ping: return String(localized: "Testing Ping...")
        case .download: return String(localized: "Download")
        case .upload: return String(localized: "Upload")
        case .done: return String(localized: "Done")
        }
    }
}

struct SpeedTestProgress {
    let phase: SpeedTestPhase
    let speed: Double
    let progress: Double
}

final class SpeedTestService: NSObject, Sendable {

    // MARK: - Ping

    func measurePing() async -> (ping: Double, jitter: Double) {
        var times: [Double] = []

        for _ in 0..<AppConstants.SpeedTest.pingCount {
            guard let url = URL(string: AppConstants.SpeedTest.pingURL) else { continue }
            let config = URLSessionConfiguration.ephemeral
            config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            let session = URLSession(configuration: config)

            let start = CFAbsoluteTimeGetCurrent()
            do {
                let (_, response) = try await session.data(from: url)
                if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
                    times.append(elapsed)
                }
            } catch {
                continue
            }
        }

        guard !times.isEmpty else { return (0, 0) }

        let avgPing = times.reduce(0, +) / Double(times.count)
        var jitter = 0.0
        if times.count > 1 {
            var diffs: [Double] = []
            for i in 1..<times.count {
                diffs.append(abs(times[i] - times[i - 1]))
            }
            jitter = diffs.reduce(0, +) / Double(diffs.count)
        }

        return (avgPing, jitter)
    }

    // MARK: - Download

    func measureDownload(onProgress: @escaping (Double) -> Void) async -> Double {
        guard let url = URL(string: AppConstants.SpeedTest.downloadURL) else { return 0 }

        let config = URLSessionConfiguration.ephemeral
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.timeoutIntervalForResource = AppConstants.SpeedTest.timeoutSeconds
        let session = URLSession(configuration: config)

        let start = CFAbsoluteTimeGetCurrent()
        var totalBytes: Int64 = 0

        do {
            let (bytes, response) = try await session.bytes(from: url)
            let expectedLength = (response as? HTTPURLResponse)
                .flatMap { Int64($0.value(forHTTPHeaderField: "Content-Length") ?? "") } ?? 25_000_000

            for try await byte in bytes {
                _ = byte
                totalBytes += 1

                if totalBytes % 50_000 == 0 {
                    let elapsed = CFAbsoluteTimeGetCurrent() - start
                    guard elapsed > 0 else { continue }
                    let speedMbps = Double(totalBytes * 8) / (elapsed * 1_000_000)
                    onProgress(speedMbps)
                }
            }
        } catch {
            // Test may be cancelled or timed out
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - start
        guard elapsed > 0 else { return 0 }
        return Double(totalBytes * 8) / (elapsed * 1_000_000)
    }

    // MARK: - Upload

    func measureUpload(onProgress: @escaping (Double) -> Void) async -> Double {
        guard let url = URL(string: AppConstants.SpeedTest.uploadURL) else { return 0 }

        let data = Data(repeating: 0xAB, count: AppConstants.SpeedTest.uploadSize)

        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForResource = AppConstants.SpeedTest.timeoutSeconds
        let session = URLSession(configuration: config)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")

        let start = CFAbsoluteTimeGetCurrent()

        do {
            let (_, response) = try await session.upload(for: request, from: data)
            let elapsed = CFAbsoluteTimeGetCurrent() - start
            guard elapsed > 0 else { return 0 }

            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                let speedMbps = Double(data.count * 8) / (elapsed * 1_000_000)
                onProgress(speedMbps)
                return speedMbps
            }
        } catch {
            // Upload failed
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - start
        guard elapsed > 0 else { return 0 }
        return Double(data.count * 8) / (elapsed * 1_000_000)
    }

    // MARK: - Connection type

    func connectionType() -> String {
        // Simplified — proper implementation would use NWPathMonitor
        "Wi-Fi"
    }
}
