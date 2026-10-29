import SwiftUI

public struct CircularRingsView: View {
    public let snapshot: SystemSnapshot

    public init(snapshot: SystemSnapshot) {
        self.snapshot = snapshot
    }

    public var body: some View {
        HStack(spacing: 7) {
            // CPU Ring + %
            HStack(spacing: 3) {
                RingGauge(
                    percentage: snapshot.cpu.totalUsage,
                    tintColor: Color(red: 10/255, green: 132/255, blue: 255/255)
                )
                Text(String(format: "%2.0f%%", snapshot.cpu.totalUsage))
                    .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(width: 25, alignment: .leading)
            }

            // RAM Ring + %
            HStack(spacing: 3) {
                RingGauge(
                    percentage: snapshot.ram.usagePercentage,
                    tintColor: Color(red: 48/255, green: 209/255, blue: 88/255)
                )
                Text(String(format: "%2.0f%%", snapshot.ram.usagePercentage))
                    .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(width: 25, alignment: .leading)
            }

            // SSD Ring + %
            HStack(spacing: 3) {
                RingGauge(
                    percentage: snapshot.disk.usedPercentage,
                    tintColor: Color(red: 255/255, green: 159/255, blue: 10/255)
                )
                Text(String(format: "%2.0f%%", snapshot.disk.usedPercentage))
                    .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(width: 25, alignment: .leading)
            }

            // Network throughput badge (Fixed frame to prevent bouncing)
            HStack(spacing: 2) {
                Text("⇅")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(Color(red: 100/255, green: 210/255, blue: 255/255))
                Text(Formatters.formatShortSpeed(snapshot.network.totalThroughput))
                    .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(width: 34, alignment: .leading)
            }

            // SoC Temperature badge
            HStack(spacing: 2) {
                Text(String(format: "%.0f°", snapshot.thermal.celsius))
                    .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                    .foregroundColor(tempColor(snapshot.thermal.celsius))
                    .frame(width: 22, alignment: .leading)
            }
        }
        .padding(.horizontal, 4)
        .frame(height: 22)
    }

    private func tempColor(_ celsius: Double) -> Color {
        if celsius >= 85.0 {
            return Color(red: 255/255, green: 69/255, blue: 58/255)
        } else if celsius >= 65.0 {
            return Color(red: 255/255, green: 159/255, blue: 10/255)
        } else {
            return Color(red: 255/255, green: 214/255, blue: 10/255)
        }
    }
}
