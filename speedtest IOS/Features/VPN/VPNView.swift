import SwiftUI

struct VPNView: View {
    @StateObject private var viewModel = VPNViewModel()
    @State private var showSupportOptions = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 32) {
                        // Connection Button
                        connectionButton

                        // Status
                        statusSection

                        // Active Server
                        serverSection

                        // Error
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(Theme.Fonts.caption)
                                .foregroundStyle(Theme.Colors.error)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, Theme.Layout.screenPadding)
                    .padding(.bottom, 80)
                }

                // Support button
                supportButton
                    .padding(.trailing, Theme.Layout.screenPadding)
                    .padding(.bottom, 16)
            }
            .background(Theme.Colors.background)
            .navigationTitle("VPN")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showServerList = true
                    } label: {
                        Image(systemName: "server.rack")
                            .foregroundStyle(Theme.Colors.primary)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showAddServer) {
                AddServerView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showServerList) {
                ServerListView(serverStore: viewModel.serverStore, viewModel: viewModel)
            }
            .confirmationDialog("Support", isPresented: $showSupportOptions, titleVisibility: .visible) {
                Button("Telegram") {
                    if let url = URL(string: AppConstants.supportURL) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Website") {
                    if let url = URL(string: AppConstants.supportWebURL) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("How would you like to contact support?")
            }
            .task {
                await viewModel.setup()
            }
        }
    }

    // MARK: - Connection Button

    private var connectionButton: some View {
        Button {
            Task { await viewModel.toggleConnection() }
        } label: {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(ringColor.opacity(0.2), lineWidth: 4)
                    .frame(width: 200, height: 200)

                // Animated ring
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(ringAnimation, value: viewModel.state)

                // Inner circle
                Circle()
                    .fill(ringColor.opacity(0.1))
                    .frame(width: 180, height: 180)

                // Power icon
                VStack(spacing: 12) {
                    Image(systemName: powerIcon)
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(ringColor)

                    Text(viewModel.state.label)
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.top, 20)
    }

    // MARK: - Status Section

    private var statusSection: some View {
        VStack(spacing: 8) {
            if viewModel.state == .connected {
                Text(viewModel.formattedDuration)
                    .font(Theme.Fonts.headlineMedium)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .monospacedDigit()
            }
        }
    }

    // MARK: - Server Section

    private var serverSection: some View {
        Group {
            if let server = viewModel.serverStore.activeServer {
                GlassCard {
                    HStack {
                        if let flag = server.flagEmoji {
                            Text(flag)
                                .font(.system(size: 32))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(server.name)
                                .font(Theme.Fonts.title)
                                .foregroundStyle(Theme.Colors.textPrimary)

                            Text(server.displayAddress)
                                .font(Theme.Fonts.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            if let ping = viewModel.loadBalancer.formattedPing(for: server) {
                                Text(ping)
                                    .font(Theme.Fonts.caption)
                                    .foregroundStyle(Theme.Colors.primary)
                            }

                            Text(server.securityLabel)
                                .font(Theme.Fonts.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }
                }
                .onTapGesture {
                    viewModel.showServerList = true
                }
            } else {
                VombatButton(title: String(localized: "Add Server"), icon: "plus.circle") {
                    viewModel.showAddServer = true
                }
            }
        }
    }

    // MARK: - Support Button

    private var supportButton: some View {
        Button {
            showSupportOptions = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "headset.circle.fill")
                    .font(.system(size: 20))
                Text("Support")
                    .font(Theme.Fonts.caption)
            }
            .foregroundStyle(Theme.Colors.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Theme.Colors.primary.opacity(0.15))
            )
        }
    }

    // MARK: - Helpers

    private var ringColor: Color {
        switch viewModel.state {
        case .connected: return Theme.Colors.success
        case .connecting, .disconnecting: return Theme.Colors.primary
        case .disconnected: return Theme.Colors.textSecondary
        case .error: return Theme.Colors.error
        }
    }

    private var ringProgress: CGFloat {
        switch viewModel.state {
        case .connected: return 1.0
        case .connecting, .disconnecting: return 0.75
        case .disconnected: return 0.0
        case .error: return 0.0
        }
    }

    private var ringAnimation: Animation? {
        if viewModel.state.isTransitioning {
            return .linear(duration: 1).repeatForever(autoreverses: false)
        }
        return .easeInOut(duration: 0.5)
    }

    private var powerIcon: String {
        switch viewModel.state {
        case .connected: return "power"
        case .connecting, .disconnecting: return "arrow.triangle.2.circlepath"
        case .disconnected: return "power"
        case .error: return "exclamationmark.triangle"
        }
    }
}
