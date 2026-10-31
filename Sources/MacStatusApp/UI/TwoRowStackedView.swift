import SwiftUI

public struct TwoRowStackedView: View {
    public let snapshot: SystemSnapshot

    public init(snapshot: SystemSnapshot) {
        self.snapshot = snapshot
    }

    public var body: some View {
        HStack(spacing: 8) {
            // Column 1: CPU & RAM
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 2.5) {
                    Text("CPU")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(Color(red: 10/255, green: 132/255, blue: 255/255))
                    Text(String(format: "%2.0f%%", snapshot.cpu.totalUsage))
                        .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 25, alignment: .leading)
                }

                HStack(spacing: 2.5) {
                    Text("RAM")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(Color(red: 48/255, green: 209/255, blue: 88/255))
                    Text(String(format: "%2.0f%%", snapshot.ram.usagePercentage))
                        .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 25, alignment: .leading)
                }
            }

            // Column 2: SSD & TMP
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 2.5) {
                    Text("SSD")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                    Text(String(format: "%2.0f%%", snapshot.disk.usedPercentage))
                        .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 25, alignment: .leading)
                }

                HStack(spacing: 2.5) {
                    Text("TMP")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(Self.tempColor(for: snapshot.thermal.celsius))
                    Text(String(format: "%.0f°", snapshot.thermal.celsius))
                        .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 20, alignment: .leading)
                }
            }

            // Column 3: Network Up (▲) & Down (▼)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 2) {
                    Text("▲")
                        .font(.system(size: 8.0, weight: .bold))
                        .foregroundColor(Color(red: 100/255, green: 210/255, blue: 255/255))
                    Text(Formatters.formatShortSpeed(snapshot.network.uploadBytesPerSec))
                        .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 32, alignment: .leading)
                }

                HStack(spacing: 2) {
                    Text("▼")
                        .font(.system(size: 8.0, weight: .bold))
                        .foregroundColor(Color(red: 48/255, green: 209/255, blue: 88/255))
                    Text(Formatters.formatShortSpeed(snapshot.network.downloadBytesPerSec))
                        .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 32, alignment: .leading)
                }
            }
        }
        .padding(.horizontal, 4)
        .frame(height: 22)
    }

    public static func tempColor(for celsius: Double) -> Color {
        Color.temperatureColor(for: celsius)
    }
}

