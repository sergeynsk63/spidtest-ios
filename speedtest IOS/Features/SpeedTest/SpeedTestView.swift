import SwiftUI

struct SpeedTestView: View {
    @StateObject private var viewModel = SpeedTestViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Gauge
                        SpeedGaugeView(
                            speed: viewModel.phase == .done ? 0 : viewModel.currentSpeed,
                            maxSpeed: viewModel.maxGaugeSpeed,
                            phase: viewModel.phase.label
                        )
                        .padding(.top, 20)

                        // Start / Stop button
                        VombatButton(
                            title: String(localized: viewModel.isTesting ? "Stop" : "Start Test"),
                            icon: viewModel.isTesting ? "stop.fill" : "play.fill",
                            style: viewModel.isTesting ? .destructive : .primary
                        ) {
                            if viewModel.isTesting {
                                viewModel.stopTest()
                            } else {
                                viewModel.startTest()
                            }
                        }
                        .padding(.horizontal, Theme.Layout.screenPadding)

                        // Results grid
                        if viewModel.phase != .idle {
                            resultsGrid
                                .padding(.horizontal, Theme.Layout.screenPadding)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }

                        // History
                        if let latest = viewModel.latestResult, !viewModel.isTesting && viewModel.phase == .idle {
                            lastResultCard(latest)
                                .padding(.horizontal, Theme.Layout.screenPadding)
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle(String(localized: "Speed Test"))
            .toolbarColorScheme(.dark, for: .navigationBar)
            .animation(.easeInOut(duration: 0.3), value: viewModel.phase)
        }
    }

    private var resultsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
        ], spacing: 12) {
            MetricTile(
                title: String(localized: "Ping"),
                value: viewModel.ping.formattedPing,
                unit: "ms",
                icon: "bolt.fill",
                color: pingColor
            )

            MetricTile(
                title: String(localized: "Jitter"),
                value: viewModel.jitter.formattedPing,
                unit: "ms",
                icon: "waveform.path",
                color: Theme.Colors.secondary
            )

            MetricTile(
                title: String(localized: "Download"),
                value: viewModel.downloadSpeed.formattedSpeed,
                unit: "Mbps",
                icon: "arrow.down.circle.fill",
                color: Theme.Colors.primary
            )

            MetricTile(
                title: String(localized: "Upload"),
                value: viewModel.uploadSpeed.formattedSpeed,
                unit: "Mbps",
                icon: "arrow.up.circle.fill",
                color: Theme.Colors.secondary
            )
        }
    }

    private func lastResultCard(_ result: SpeedTestResult) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Last Result")
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                    Spacer()
                    Text(result.date, style: .relative)
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                HStack(spacing: 20) {
                    Label("\(result.downloadSpeed.formattedSpeed) Mbps", systemImage: "arrow.down")
                        .foregroundStyle(Theme.Colors.primary)
                    Label("\(result.uploadSpeed.formattedSpeed) Mbps", systemImage: "arrow.up")
                        .foregroundStyle(Theme.Colors.secondary)
                    Label("\(result.ping.formattedPing) ms", systemImage: "bolt.fill")
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .font(Theme.Fonts.caption)
            }
        }
    }

    private var pingColor: Color {
        if viewModel.ping < 30 { return Theme.Colors.success }
        if viewModel.ping < 80 { return Theme.Colors.warning }
        return Theme.Colors.error
    }
}
