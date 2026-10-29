import SwiftUI

public struct CircularRingsView: View {
    public let snapshot: SystemSnapshot

    public init(snapshot: SystemSnapshot) {
        self.snapshot = snapshot
    }

    public var body: some View {
        HStack(spacing: 8) {
            // CPU Ring
            RingGauge(
                label: "CPU",
                percentage: snapshot.cpu.totalUsage,
                tintColor: Color(red: 10/255, green: 132/255, blue: 255/255) // #0A84FF
            )

            // RAM Ring
            RingGauge(
                label: "RAM",
                percentage: snapshot.ram.usagePercentage,
                tintColor: Color(red: 48/255, green: 209/255, blue: 88/255) // #30D158
            )

            // SSD Ring
            RingGauge(
                label: "SSD",
                percentage: snapshot.disk.usedPercentage,
                tintColor: Color(red: 255/255, green: 159/255, blue: 10/255) // #FF9F0A
            )

            // Network throughput badge
            HStack(spacing: 2) {
                Text("⇅")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(red: 100/255, green: 210/255, blue: 255/255))
                Text(Formatters.formatShortSpeed(snapshot.network.totalThroughput))
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }

            // SoC Temperature badge
            HStack(spacing: 2) {
                Text(String(format: "%.0f°", snapshot.thermal.celsius))
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(tempColor(snapshot.thermal.celsius))
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }

    private func tempColor(_ celsius: Double) -> Color {
        if celsius >= 85.0 {
            return Color(red: 255/255, green: 69/255, blue: 58/255) // Red
        } else if celsius >= 65.0 {
            return Color(red: 255/255, green: 159/255, blue: 10/255) // Orange
        } else {
            return Color(red: 255/255, green: 214/255, blue: 10/255) // Gold
        }
    }
}
