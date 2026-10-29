import SwiftUI
import AppKit

public struct PopoverDetailView: View {
    @ObservedObject public var telemetryService: SystemTelemetryService
    public var onClose: (() -> Void)?

    public init(telemetryService: SystemTelemetryService, onClose: (() -> Void)? = nil) {
        self.telemetryService = telemetryService
        self.onClose = onClose
    }

    private var snapshot: SystemSnapshot {
        telemetryService.currentSnapshot
    }

    public var body: some View {
        VStack(spacing: 10) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Apple Silicon")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    Text("Hardware Telemetry")
                        .font(.system(size: 10.5))
                        .foregroundColor(Color(white: 0.6))
                }
                Spacer()
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(red: 48/255, green: 209/255, blue: 88/255))
                        .frame(width: 6, height: 6)
                    Text(String(format: "%.1f°C", snapshot.thermal.celsius))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.1))
                .cornerRadius(6)
            }
            .padding(.bottom, 2)

            // CPU Section
            MetricCard(
                title: "⚡ CPU PROCESSOR",
                badge: String(format: "%.1f%%", snapshot.cpu.totalUsage),
                progress: snapshot.cpu.totalUsage / 100.0,
                progressColor: Color(red: 10/255, green: 132/255, blue: 255/255)
            ) {
                VStack(spacing: 4) {
                    HStack {
                        Text("E-Cores:")
                            .font(.system(size: 10))
                            .foregroundColor(Color(white: 0.6))
                        Spacer()
                        Text(String(format: "%.1f%%", snapshot.cpu.eCoreUsage))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    HStack {
                        Text("P-Cores:")
                            .font(.system(size: 10))
                            .foregroundColor(Color(white: 0.6))
                        Spacer()
                        Text(String(format: "%.1f%%", snapshot.cpu.pCoreUsage))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white)
                    }

                    ProcessListView(
                        title: "Top CPU Consumers:",
                        processes: snapshot.topCPUProcesses,
                        isMemory: false
                    )
                }
                .padding(.top, 4)
            }

            // RAM Section
            MetricCard(
                title: "🧠 UNIFIED MEMORY",
                badge: "\(Formatters.formatBytes(snapshot.ram.usedBytes)) / \(Formatters.formatBytes(snapshot.ram.totalBytes))",
                progress: snapshot.ram.usagePercentage / 100.0,
                progressColor: Color(red: 48/255, green: 209/255, blue: 88/255)
            ) {
                VStack(spacing: 4) {
                    HStack {
                        Text("App Memory:")
                            .font(.system(size: 10))
                            .foregroundColor(Color(white: 0.6))
                        Spacer()
                        Text(Formatters.formatBytes(snapshot.ram.appBytes))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    HStack {
                        Text("Wired Memory:")
                            .font(.system(size: 10))
                            .foregroundColor(Color(white: 0.6))
                        Spacer()
                        Text(Formatters.formatBytes(snapshot.ram.wiredBytes))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white)
                    }

                    ProcessListView(
                        title: "Top Memory Consumers:",
                        processes: snapshot.topRAMProcesses,
                        isMemory: true
                    )
                }
                .padding(.top, 4)
            }

            // Storage Section
            MetricCard(
                title: "💾 MACINTOSH HD (SSD)",
                badge: "\(Formatters.formatBytes(snapshot.disk.freeBytes)) Free",
                progress: snapshot.disk.usedPercentage / 100.0,
                progressColor: Color(red: 255/255, green: 159/255, blue: 10/255)
            ) {
                VStack(spacing: 3) {
                    HStack {
                        Text("Total: \(Formatters.formatBytes(snapshot.disk.totalBytes))")
                            .font(.system(size: 10))
                            .foregroundColor(Color(white: 0.6))
                        Spacer()
                        Text("Used: \(String(format: "%.1f%%", snapshot.disk.usedPercentage))")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    if snapshot.disk.readBytesPerSec > 0 || snapshot.disk.writeBytesPerSec > 0 {
                        HStack {
                            Text("Disk I/O:")
                                .font(.system(size: 9.5))
                                .foregroundColor(Color(white: 0.5))
                            Spacer()
                            Text("R: \(Formatters.formatSpeed(snapshot.disk.readBytesPerSec)) | W: \(Formatters.formatSpeed(snapshot.disk.writeBytesPerSec))")
                                .font(.system(size: 9.5, design: .monospaced))
                                .foregroundColor(Color(white: 0.8))
                        }
                    }
                }
                .padding(.top, 2)
            }

            // 2-Column: Network & Thermal
            HStack(spacing: 8) {
                // Network Card
                VStack(alignment: .leading, spacing: 4) {
                    Text("🌐 NETWORK")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(white: 0.65))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("▼ \(Formatters.formatSpeed(snapshot.network.downloadBytesPerSec))")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(red: 100/255, green: 210/255, blue: 255/255))
                        Text("▲ \(Formatters.formatSpeed(snapshot.network.uploadBytesPerSec))")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(red: 48/255, green: 209/255, blue: 88/255))
                    }

                    Text("IP: \(snapshot.network.localIP)")
                        .font(.system(size: 9.5))
                        .foregroundColor(Color(white: 0.55))
                        .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(white: 0.12).opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )

                // Thermal Card
                VStack(alignment: .leading, spacing: 4) {
                    Text("🌡 SOC THERMAL")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(white: 0.65))

                    Text(String(format: "%.1f°C", snapshot.thermal.celsius))
                        .font(.system(size: 17, weight: .bold, design: .monospaced))
                        .foregroundColor(tempColor(snapshot.thermal.celsius))

                    Text("State: \(snapshot.thermal.thermalState)")
                        .font(.system(size: 9.5))
                        .foregroundColor(Color(white: 0.55))
                        .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(white: 0.12).opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
            }

            // Bottom Actions
            HStack {
                Button(action: openActivityMonitor) {
                    Text("Activity Monitor")
                        .font(.system(size: 11))
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.white.opacity(0.15))

                Spacer()

                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Text("Quit")
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
        .padding(14)
        .frame(width: 320)
        .background(
            VisualEffectView(material: .popover, blendingMode: .behindWindow)
        )
    }

    private func openActivityMonitor() {
        let path = "/System/Applications/Utilities/Activity Monitor.app"
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
    }

    private func tempColor(_ celsius: Double) -> Color {
        if celsius >= 85.0 {
            return Color(red: 255/255, green: 69/255, blue: 58/255)
        } else if celsius >= 65.0 {
            return Color(red: 255/255, green: 159/255, blue: 10/255)
        } else {
            return Color(red: 48/255, green: 209/255, blue: 88/255)
        }
    }
}

public struct VisualEffectView: NSViewRepresentable {
    public let material: NSVisualEffectView.Material
    public let blendingMode: NSVisualEffectView.BlendingMode

    public init(material: NSVisualEffectView.Material, blendingMode: NSVisualEffectView.BlendingMode) {
        self.material = material
        self.blendingMode = blendingMode
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
