import SwiftUI

enum Theme {
    // MARK: - Colors
    enum Colors {
        static let background = Color(hex: "0A0E14")
        static let surface = Color(hex: "141B26")
        static let surfaceLight = Color(hex: "1C2535")
        static let primary = Color(hex: "00D4AA")
        static let primaryDark = Color(hex: "00A886")
        static let secondary = Color(hex: "6C63FF")
        static let textPrimary = Color.white
        static let textSecondary = Color(hex: "8892A4")
        static let success = Color(hex: "00E676")
        static let warning = Color(hex: "FFB74D")
        static let error = Color(hex: "FF5252")

        static let gaugeGradient = LinearGradient(
            colors: [primary, Color(hex: "FFB74D"), error],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Fonts
    enum Fonts {
        static let headlineLarge = Font.system(size: 34, weight: .bold, design: .rounded)
        static let headlineMedium = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title = Font.system(size: 20, weight: .semibold)
        static let body = Font.system(size: 16, weight: .regular)
        static let caption = Font.system(size: 13, weight: .medium)
        static let speedValue = Font.system(size: 64, weight: .bold, design: .rounded)
        static let speedUnit = Font.system(size: 16, weight: .medium, design: .rounded)
        static let metric = Font.system(size: 24, weight: .semibold, design: .rounded)
    }

    // MARK: - Layout
    enum Layout {
        static let cornerRadius: CGFloat = 16
        static let cardPadding: CGFloat = 16
        static let screenPadding: CGFloat = 20
        static let spacing: CGFloat = 12
    }
}
