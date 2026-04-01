import SwiftUI

struct MetricTile: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    var color: Color = Theme.Colors.primary

    var body: some View {
        GlassCard {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)

                Text(value)
                    .font(Theme.Fonts.metric)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(unit)
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)

                Text(title)
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
