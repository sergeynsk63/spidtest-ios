import SwiftUI

struct VombatButton: View {
    let title: String
    let icon: String?
    var style: ButtonStyle = .primary
    let action: () -> Void

    enum ButtonStyle {
        case primary, secondary, destructive
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: Theme.Colors.primary
        case .secondary: Theme.Colors.surfaceLight
        case .destructive: Theme.Colors.error.opacity(0.2)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: Theme.Colors.background
        case .secondary: Theme.Colors.textPrimary
        case .destructive: Theme.Colors.error
        }
    }
}
