import SwiftUI

struct DNSLeakTestView: View {
    @StateObject private var viewModel = DNSLeakTestViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Shield indicator
                    shieldSection

                    // Status text
                    statusSection

                    // Test button
                    VombatButton(
                        title: String(localized: viewModel.isTesting ? "Testing..." : "Run DNS Leak Test"),
                        icon: viewModel.isTesting ? "arrow.triangle.2.circlepath" : "shield.checkered"
                    ) {
                        Task { await viewModel.runTest() }
                    }
                    .disabled(viewModel.isTesting)
                    .opacity(viewModel.isTesting ? 0.6 : 1)

                    // VPN status info
                    if !viewModel.vpnConnected {
                        vpnWarning
                    }

                    // Results
                    if !viewModel.results.isEmpty {
                        resultsSection
                    }

                    // Info card
                    infoCard
                }
                .padding(.horizontal, Theme.Layout.screenPadding)
                .padding(.top, 20)
            }
            .background(Theme.Colors.background)
            .navigationTitle(String(localized: "DNS Leak Test"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Shield

    private var shieldSection: some View {
        ZStack {
            Circle()
                .fill(shieldColor.opacity(0.1))
                .frame(width: 160, height: 160)

            Circle()
                .stroke(shieldColor.opacity(0.3), lineWidth: 3)
                .frame(width: 160, height: 160)

            Image(systemName: shieldIcon)
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(shieldColor)
                .symbolEffect(.pulse, isActive: viewModel.isTesting)
        }
        .padding(.top, 20)
    }

    private var shieldColor: Color {
        switch viewModel.status {
        case .safe: return Theme.Colors.success
        case .leak: return Theme.Colors.error
        case .noVPN: return Theme.Colors.warning
        case .testing: return Theme.Colors.primary
        case .error: return Theme.Colors.error
        case .idle: return Theme.Colors.textSecondary
        }
    }

    private var shieldIcon: String {
        switch viewModel.status {
        case .safe: return "checkmark.shield.fill"
        case .leak: return "exclamationmark.shield.fill"
        case .noVPN: return "shield.slash"
        case .testing: return "shield.checkered"
        case .error: return "xmark.shield"
        case .idle: return "shield"
        }
    }

    // MARK: - Status

    private var statusSection: some View {
        VStack(spacing: 8) {
            Text(viewModel.status.label)
                .font(Theme.Fonts.title)
                .foregroundStyle(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)

            if viewModel.queryTime > 0 {
                Text(String(format: String(localized: "Completed in %@s"), String(format: "%.1f", viewModel.queryTime)))
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
    }

    // MARK: - VPN Warning

    private var vpnWarning: some View {
        GlassCard {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Theme.Colors.warning)

                Text("Connect VPN first for accurate results")
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
    }

    // MARK: - Results

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DNS Servers Detected")
                .font(Theme.Fonts.title)
                .foregroundStyle(Theme.Colors.textPrimary)

            ForEach(viewModel.results) { result in
                GlassCard {
                    HStack {
                        Text(result.flagEmoji)
                            .font(.system(size: 28))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.ip)
                                .font(Theme.Fonts.body)
                                .foregroundStyle(Theme.Colors.textPrimary)
                                .monospacedDigit()

                            Text(result.isp)
                                .font(Theme.Fonts.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }

                        Spacer()

                        Text(result.country)
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Info Card

    private var infoCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Label("What is a DNS Leak?", systemImage: "info.circle")
                    .font(Theme.Fonts.body)
                    .foregroundStyle(Theme.Colors.primary)

                Text("A DNS leak occurs when your DNS queries bypass the VPN tunnel and go directly to your ISP's DNS servers, potentially exposing your browsing activity.")
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.bottom, 20)
    }
}
