import SwiftUI

struct SpeedGaugeView: View {
    let speed: Double
    let maxSpeed: Double
    let phase: String

    private var progress: Double {
        min(speed / maxSpeed, 1.0)
    }

    private let startAngle: Double = 135
    private let endAngle: Double = 405

    var body: some View {
        ZStack {
            // Background arc
            arcShape(progress: 1.0)
                .stroke(Theme.Colors.surfaceLight, style: StrokeStyle(lineWidth: 12, lineCap: .round))

            // Progress arc
            arcShape(progress: progress)
                .stroke(
                    AngularGradient(
                        colors: [Theme.Colors.primary, Theme.Colors.warning, Theme.Colors.error],
                        center: .center,
                        startAngle: .degrees(startAngle),
                        endAngle: .degrees(startAngle + (endAngle - startAngle) * progress)
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .animation(.easeInOut(duration: 0.3), value: progress)

            // Tick marks
            ForEach(0..<11, id: \.self) { i in
                let tickProgress = Double(i) / 10.0
                let angle = startAngle + (endAngle - startAngle) * tickProgress
                let isMain = i % 5 == 0

                Rectangle()
                    .fill(i == 0 || tickProgress <= progress ? Theme.Colors.textPrimary : Theme.Colors.surfaceLight)
                    .frame(width: isMain ? 2 : 1, height: isMain ? 10 : 6)
                    .offset(y: -100)
                    .rotationEffect(.degrees(angle))
            }

            // Center content
            VStack(spacing: 4) {
                Text(speed.formattedSpeed)
                    .font(Theme.Fonts.speedValue)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: speed)

                Text("Mbps")
                    .font(Theme.Fonts.speedUnit)
                    .foregroundStyle(Theme.Colors.textSecondary)

                Text(phase)
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.primary)
                    .padding(.top, 4)
            }
        }
        .frame(width: 260, height: 260)
    }

    private func arcShape(progress: Double) -> some Shape {
        Arc(
            startAngle: .degrees(startAngle),
            endAngle: .degrees(startAngle + (endAngle - startAngle) * progress),
            clockwise: false
        )
    }
}

private struct Arc: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let clockwise: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - 10
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}
