import Foundation

public enum Formatters {
    public static func formatBytes(_ bytes: Int64) -> String {
        let b = Double(bytes)
        let kb = b / 1024.0
        let mb = kb / 1024.0
        let gb = mb / 1024.0
        let tb = gb / 1024.0

        if tb >= 1.0 {
            return String(format: "%.1f TB", tb)
        } else if gb >= 1.0 {
            return String(format: "%.1f GB", gb)
        } else if mb >= 1.0 {
            return String(format: "%.1f MB", mb)
        } else if kb >= 1.0 {
            return String(format: "%.1f KB", kb)
        } else {
            return "\(bytes) B"
        }
    }

    public static func formatSpeed(_ bytesPerSec: Double) -> String {
        let kb = bytesPerSec / 1024.0
        let mb = kb / 1024.0
        let gb = mb / 1024.0

        if gb >= 1.0 {
            return String(format: "%.1f GB/s", gb)
        } else if mb >= 1.0 {
            return String(format: "%.1f MB/s", mb)
        } else if kb >= 1.0 {
            return String(format: "%.1f KB/s", kb)
        } else {
            return String(format: "%.0f B/s", bytesPerSec)
        }
    }

    public static func formatShortSpeed(_ bytesPerSec: Double) -> String {
        let kb = bytesPerSec / 1024.0
        let mb = kb / 1024.0

        if mb >= 1.0 {
            return String(format: "%.1fM", mb)
        } else if kb >= 1.0 {
            return String(format: "%.0fK", kb)
        } else {
            return String(format: "%.0fB", bytesPerSec)
        }
    }

    public static func clampPercentage(_ value: Double) -> Double {
        min(100.0, max(0.0, value))
    }
}
