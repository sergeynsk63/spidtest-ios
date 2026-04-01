import WidgetKit
import SwiftUI

struct VPNStatusEntry: TimelineEntry {
    let date: Date
    let state: VPNConnectionState
    let serverName: String?
}

struct VPNStatusProvider: TimelineProvider {
    func placeholder(in context: Context) -> VPNStatusEntry {
        VPNStatusEntry(date: .now, state: .disconnected, serverName: "VPNeo")
    }

    func getSnapshot(in context: Context, completion: @escaping (VPNStatusEntry) -> Void) {
        let defaults = SharedDefaults.shared
        let entry = VPNStatusEntry(
            date: .now,
            state: defaults.vpnState,
            serverName: defaults.activeServer?.name
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VPNStatusEntry>) -> Void) {
        let defaults = SharedDefaults.shared
        let entry = VPNStatusEntry(
            date: .now,
            state: defaults.vpnState,
            serverName: defaults.activeServer?.name
        )
        let timeline = Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(60)))
        completion(timeline)
    }
}

struct VPNStatusWidget: Widget {
    let kind = "VPNStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VPNStatusProvider()) { entry in
            VPNStatusWidgetView(entry: entry)
                .containerBackground(Color(hex: "0A0E14"), for: .widget)
        }
        .configurationDisplayName("VPN Status")
        .description("See your VPN connection status at a glance.")
        .supportedFamilies([.systemSmall])
    }
}

struct VPNStatusWidgetView: View {
    let entry: VPNStatusEntry

    var body: some View {
        VStack(spacing: 12) {
            // Status icon
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: statusIcon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(statusColor)
            }

            // Status label
            Text(entry.state.label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)

            // Server name
            if let name = entry.serverName {
                Text(name)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "8892A4"))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "vpneo://toggle-vpn"))
    }

    private var statusColor: Color {
        switch entry.state {
        case .connected: return Color(hex: "00E676")
        case .connecting, .disconnecting: return Color(hex: "00D4AA")
        case .disconnected: return Color(hex: "8892A4")
        case .error: return Color(hex: "FF5252")
        }
    }

    private var statusIcon: String {
        switch entry.state {
        case .connected: return "shield.checkmark.fill"
        case .connecting, .disconnecting: return "shield.fill"
        case .disconnected: return "shield.slash"
        case .error: return "exclamationmark.shield"
        }
    }
}

// Widget needs its own Color+Hex since it's a separate target
private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
