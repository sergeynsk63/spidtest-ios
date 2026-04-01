import Foundation

final class TestHistoryStore: ObservableObject {
    static let shared = TestHistoryStore()

    @Published private(set) var results: [SpeedTestResult] = []

    private init() {
        load()
    }

    func add(_ result: SpeedTestResult) {
        results.insert(result, at: 0)
        if results.count > AppConstants.History.maxResults {
            results = Array(results.prefix(AppConstants.History.maxResults))
        }
        save()
    }

    func clear() {
        results = []
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(results) else { return }
        UserDefaults.standard.set(data, forKey: AppConstants.History.storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: AppConstants.History.storageKey),
              let decoded = try? JSONDecoder().decode([SpeedTestResult].self, from: data) else { return }
        results = decoded
    }
}
