import SwiftUI

struct SettingsView: View {
    @State private var autoConnect = SharedDefaults.shared.autoConnect
    @State private var killSwitch = SharedDefaults.shared.killSwitch
    @ObservedObject private var loadBalancer = LoadBalancer.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // VPN Settings
                        GlassCard {
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "bolt.shield")
                                        .foregroundStyle(Theme.Colors.primary)
                                    Text("VPN Settings")
                                        .font(Theme.Fonts.title)
                                        .foregroundStyle(Theme.Colors.textPrimary)
                                    Spacer()
                                }

                                Toggle(isOn: $autoConnect) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                            .foregroundStyle(Theme.Colors.textSecondary)
                                            .frame(width: 24)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Auto-Connect")
                                                .font(Theme.Fonts.body)
                                                .foregroundStyle(Theme.Colors.textPrimary)
                                            Text("Connect on app launch")
                                                .font(Theme.Fonts.caption)
                                                .foregroundStyle(Theme.Colors.textSecondary)
                                        }
                                    }
                                }
                                .tint(Theme.Colors.primary)
                                .onChange(of: autoConnect) { _, newValue in
                                    SharedDefaults.shared.autoConnect = newValue
                                }

                                Divider()
                                    .background(Theme.Colors.surfaceLight)

                                Toggle(isOn: $killSwitch) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "hand.raised.fill")
                                            .foregroundStyle(Theme.Colors.textSecondary)
                                            .frame(width: 24)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Kill Switch")
                                                .font(Theme.Fonts.body)
                                                .foregroundStyle(Theme.Colors.textPrimary)
                                            Text("Block traffic if VPN drops")
                                                .font(Theme.Fonts.caption)
                                                .foregroundStyle(Theme.Colors.textSecondary)
                                        }
                                    }
                                }
                                .tint(Theme.Colors.primary)
                                .onChange(of: killSwitch) { _, newValue in
                                    SharedDefaults.shared.killSwitch = newValue
                                }
                            }
                        }
                        .padding(.horizontal, Theme.Layout.screenPadding)

                        // Load Balancing
                        GlassCard {
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "scale.3d")
                                        .foregroundStyle(Theme.Colors.primary)
                                    Text("Load Balancing")
                                        .font(Theme.Fonts.title)
                                        .foregroundStyle(Theme.Colors.textPrimary)
                                    Spacer()
                                }

                                ForEach(BalancingMode.allCases, id: \.self) { mode in
                                    Button {
                                        loadBalancer.mode = mode
                                    } label: {
                                        HStack(spacing: 10) {
                                            Image(systemName: mode.icon)
                                                .foregroundStyle(loadBalancer.mode == mode ? Theme.Colors.primary : Theme.Colors.textSecondary)
                                                .frame(width: 24)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(mode.label)
                                                    .font(Theme.Fonts.body)
                                                    .foregroundStyle(Theme.Colors.textPrimary)
                                                Text(mode.description)
                                                    .font(Theme.Fonts.caption)
                                                    .foregroundStyle(Theme.Colors.textSecondary)
                                            }

                                            Spacer()

                                            if loadBalancer.mode == mode {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(Theme.Colors.primary)
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }

                                    if mode != BalancingMode.allCases.last {
                                        Divider()
                                            .background(Theme.Colors.surfaceLight)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, Theme.Layout.screenPadding)

                        // History
                        NavigationLink {
                            SpeedTestHistoryView()
                        } label: {
                            GlassCard {
                                HStack {
                                    Image(systemName: "chart.bar.xaxis")
                                        .foregroundStyle(Theme.Colors.primary)
                                    Text("Speed Test History")
                                        .font(Theme.Fonts.body)
                                        .foregroundStyle(Theme.Colors.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(Theme.Colors.textSecondary)
                                }
                            }
                        }
                        .padding(.horizontal, Theme.Layout.screenPadding)

                        // Links section
                        VStack(spacing: 8) {
                            linkRow(icon: "bubble.left.fill", title: String(localized: "Support"), url: AppConstants.supportURL)
                            linkRow(icon: "doc.text.fill", title: String(localized: "Privacy Policy"), url: AppConstants.privacyPolicyURL)
                            linkRow(icon: "doc.text.fill", title: String(localized: "Terms of Service"), url: AppConstants.termsURL)
                        }
                        .padding(.horizontal, Theme.Layout.screenPadding)

                        // App info
                        VStack(spacing: 4) {
                            Text(AppConstants.appName)
                                .font(Theme.Fonts.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                            Text(String(format: String(localized: "Version %@"), Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"))
                                .font(Theme.Fonts.caption)
                                .foregroundStyle(Theme.Colors.textSecondary.opacity(0.6))
                        }
                        .padding(.top, 20)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle(String(localized: "Settings"))
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var ctaCard: some View {
        GlassCard {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 28))
                        .foregroundStyle(Theme.Colors.primary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Protect Your Connection")
                            .font(Theme.Fonts.title)
                            .foregroundStyle(Theme.Colors.textPrimary)

                        Text("Fast & secure VPN powered by VLESS+Reality")
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    Spacer()
                }

                Text("Get a free 3-day trial or subscribe for unlimited access. Works on all devices.")
                    .font(Theme.Fonts.body)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VombatButton(
                    title: String(localized: "Open in Telegram"),
                    icon: "paperplane.fill",
                    style: .primary
                ) {
                    openURL(AppConstants.telegramBotURL)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius)
                .stroke(Theme.Colors.primary.opacity(0.3), lineWidth: 1)
        )
    }

    private func linkRow(icon: String, title: String, url: String) -> some View {
        Button {
            openURL(url)
        } label: {
            GlassCard {
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(width: 24)
                    Text(title)
                        .font(Theme.Fonts.body)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        }
    }

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}
