import Foundation

enum AppConstants {
    static let appName = "VPNeo"
    static let telegramBotURL = "https://t.me/vpneo_appbot"
    static let supportURL = "https://t.me/vpneo_appbot"
    static let privacyPolicyURL = "https://vpneo.digital/privacy"
    static let termsURL = "https://vpneo.digital/terms"

    enum VPN {
        static let appGroupID = "group.com.vpneo.app"
        static let tunnelBundleID = "com.vpneo.app.tunnel"
        static let urlScheme = "vpneo"
        static let socksPort = 10808
    }

    enum SpeedTest {
        static let downloadURL = "https://speed.cloudflare.com/__down?bytes=25000000"
        static let uploadURL = "https://speed.cloudflare.com/__up"
        static let pingURL = "https://speed.cloudflare.com/__down?bytes=0"
        static let uploadSize = 5_000_000
        static let pingCount = 5
        static let timeoutSeconds: TimeInterval = 30
    }

    enum DNSLeakTest {
        static let apiBase = "https://bash.ws"
    }

    enum History {
        static let maxResults = 50
        static let storageKey = "speedtest_history"
    }

    static let promoURL = "https://vombat.app/protect"

    enum Notifications {
        static let scheduledKey = "notifications_scheduled"

        static let messages: [(id: String, title: String, body: String, delayHours: Int)] = [
            (
                id: "promo_day1",
                title: "Is your connection secure?",
                body: "Your network may be exposed. Learn how to protect it.",
                delayHours: 24
            ),
            (
                id: "promo_day3",
                title: "Slow internet? There might be a reason.",
                body: "Some providers throttle your speed. See how to fix it.",
                delayHours: 72
            ),
            (
                id: "promo_week1",
                title: "Your network health report",
                body: "Run a quick check and see tips to improve your speed and privacy.",
                delayHours: 168
            ),
        ]
    }
}
