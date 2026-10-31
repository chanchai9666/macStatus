import SwiftUI

public struct TwoRowStackedView: View {
    public let snapshot: SystemSnapshot

    public init(snapshot: SystemSnapshot) {
        self.snapshot = snapshot
    }

    public var body: some View {
        HStack(spacing: 6) {
            // Column 1: CPU & RAM
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 2) {
                    Text("CPU")
                        .font(.system(size: 8.0, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 10/255, green: 132/255, blue: 255/255))
                        .frame(width: 23, alignment: .leading)
                        .lineLimit(1)
                    Text(String(format: "%2.0f%%", snapshot.cpu.totalUsage))
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 30, alignment: .trailing)
                        .lineLimit(1)
                }

                HStack(spacing: 2) {
                    Text("RAM")
                        .font(.system(size: 8.0, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 48/255, green: 209/255, blue: 88/255))
                        .frame(width: 23, alignment: .leading)
                        .lineLimit(1)
                    Text(String(format: "%2.0f%%", snapshot.ram.usagePercentage))
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 30, alignment: .trailing)
                        .lineLimit(1)
                }
            }

            // Divider 1
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 1, height: 16)

            // Column 2: SSD & TMP
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 2) {
                    Text("SSD")
                        .font(.system(size: 8.0, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                        .frame(width: 23, alignment: .leading)
                        .lineLimit(1)
                    Text(String(format: "%2.0f%%", snapshot.disk.usedPercentage))
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 30, alignment: .trailing)
                        .lineLimit(1)
                }

                HStack(spacing: 2) {
                    Text("TMP")
                        .font(.system(size: 8.0, weight: .bold, design: .rounded))
                        .foregroundColor(Self.tempColor(for: snapshot.thermal.celsius))
                        .frame(width: 23, alignment: .leading)
                        .lineLimit(1)
                    Text(String(format: "%.0f°", snapshot.thermal.celsius))
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 26, alignment: .trailing)
                        .lineLimit(1)
                }
            }

            // Divider 2
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 1, height: 16)

            // Column 3: Network Up (▲) & Down (▼)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 2) {
                    Text("▲")
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundColor(Color(red: 100/255, green: 210/255, blue: 255/255))
                    Text(Formatters.formatShortSpeed(snapshot.network.uploadBytesPerSec))
                        .font(.system(size: 9.0, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 34, alignment: .trailing)
                        .lineLimit(1)
                }

                HStack(spacing: 2) {
                    Text("▼")
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundColor(Color(red: 48/255, green: 209/255, blue: 88/255))
                    Text(Formatters.formatShortSpeed(snapshot.network.downloadBytesPerSec))
                        .font(.system(size: 9.0, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 34, alignment: .trailing)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 5)
        .frame(height: 22)
    }

    public static func tempColor(for celsius: Double) -> Color {
        Color.temperatureColor(for: celsius)
    }
}

