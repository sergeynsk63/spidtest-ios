import SwiftUI

struct SpeedTestHistoryView: View {
    @ObservedObject var store = TestHistoryStore.shared

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            if store.results.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 48))
                        .foregroundStyle(Theme.Colors.surfaceLight)
                    Text("No results yet")
                        .font(Theme.Fonts.body)
                        .foregroundStyle(Theme.Colors.textSecondary)
                    Text("Run a speed test to see history")
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            } else {
                List {
                    ForEach(store.results) { result in
                        historyRow(result)
                            .listRowBackground(Theme.Colors.surface)
                            .listRowSeparatorTint(Theme.Colors.surfaceLight)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle(String(localized: "History"))
        .toolbar {
            if !store.results.isEmpty {
                Button("Clear") {
                    store.clear()
                }
                .foregroundStyle(Theme.Colors.error)
            }
        }
    }

    private func historyRow(_ result: SpeedTestResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(result.date, format: .dateTime.day().month().year().hour().minute())
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                Spacer()
                Text(result.serverName)
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .foregroundStyle(Theme.Colors.primary)
                    Text("\(result.downloadSpeed.formattedSpeed)")
                        .foregroundStyle(Theme.Colors.textPrimary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .foregroundStyle(Theme.Colors.secondary)
                    Text("\(result.uploadSpeed.formattedSpeed)")
                        .foregroundStyle(Theme.Colors.textPrimary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(Theme.Colors.warning)
                    Text("\(result.ping.formattedPing) ms")
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
            }
            .font(Theme.Fonts.body)
        }
        .padding(.vertical, 4)
    }
}
