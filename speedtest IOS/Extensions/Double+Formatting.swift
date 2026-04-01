import Foundation

extension Double {
    var formattedSpeed: String {
        if self >= 100 {
            return String(format: "%.0f", self)
        } else if self >= 10 {
            return String(format: "%.1f", self)
        } else {
            return String(format: "%.2f", self)
        }
    }

    var formattedPing: String {
        if self >= 100 {
            return String(format: "%.0f", self)
        } else {
            return String(format: "%.1f", self)
        }
    }

    var formattedBytes: String {
        let kb = self / 1024
        let mb = kb / 1024
        let gb = mb / 1024
        if gb >= 1 {
            return String(format: "%.2f GB", gb)
        } else if mb >= 1 {
            return String(format: "%.1f MB", mb)
        } else {
            return String(format: "%.0f KB", kb)
        }
    }
}
