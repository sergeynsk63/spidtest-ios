import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            VPNView()
                .tabItem {
                    Image(systemName: "shield.fill")
                    Text("VPN")
                }
                .tag(0)

            SpeedTestView()
                .tabItem {
                    Image(systemName: "gauge.open.with.lines.needle.33percent.and.arrowtriangle")
                    Text("Speed")
                }
                .tag(1)

            DNSLeakTestView()
                .tabItem {
                    Image(systemName: "network.badge.shield.half.filled")
                    Text("DNS Test")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
                .tag(3)
        }
        .tint(Theme.Colors.primary)
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
