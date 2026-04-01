import SwiftUI

struct AddServerView: View {
    @ObservedObject var viewModel: VPNViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showScanner = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // URI Input
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("VLESS URI or Subscription URL", systemImage: "link")
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)

                        TextField("vless:// or https://...", text: $viewModel.importText, axis: .vertical)
                            .font(Theme.Fonts.body)
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .lineLimit(3...6)
                    }
                }

                // Import Button
                VombatButton(title: String(localized: "Import"), icon: "arrow.down.circle") {
                    Task {
                        await viewModel.importURI()
                    }
                }
                .opacity(viewModel.isImporting ? 0.5 : 1.0)
                .disabled(viewModel.isImporting)

                // Divider
                HStack {
                    Rectangle()
                        .fill(Theme.Colors.surfaceLight)
                        .frame(height: 1)
                    Text("or")
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                    Rectangle()
                        .fill(Theme.Colors.surfaceLight)
                        .frame(height: 1)
                }

                // QR Scan Button
                VombatButton(title: String(localized: "Scan QR Code"), icon: "qrcode.viewfinder", style: .secondary) {
                    showScanner = true
                }

                // Paste from clipboard
                VombatButton(title: String(localized: "Paste from Clipboard"), icon: "doc.on.clipboard", style: .secondary) {
                    if let clipboard = UIPasteboard.general.string {
                        viewModel.importText = clipboard
                    }
                }

                // Error
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.Colors.error)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
            .padding(Theme.Layout.screenPadding)
            .background(Theme.Colors.background)
            .navigationTitle(String(localized: "Add Server"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .sheet(isPresented: $showScanner) {
                QRCodeScannerView { code in
                    viewModel.importText = code
                    showScanner = false
                    Task {
                        try? await Task.sleep(for: .milliseconds(500))
                        await viewModel.importURI()
                    }
                }
            }
        }
    }
}
