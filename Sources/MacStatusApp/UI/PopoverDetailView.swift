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
        ScrollView(showsIndicators: false) {
            VStack(spacing: 8) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Apple Silicon")
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundColor(.white)
                        Text("Hardware Telemetry")
                            .font(.system(size: 10))
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
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(5)
                }
                .padding(.horizontal, 2)
                .padding(.bottom, 2)

                // CPU Section
                MetricCard(
                    title: "⚡ CPU PROCESSOR",
                    badge: String(format: "%.1f%%", snapshot.cpu.totalUsage),
                    progress: snapshot.cpu.totalUsage / 100.0,
                    progressColor: Color(red: 10/255, green: 132/255, blue: 255/255)
                ) {
                    VStack(spacing: 3) {
                        HStack {
                            Text("E-Cores: \(String(format: "%.1f%%", snapshot.cpu.eCoreUsage))")
                                .font(.system(size: 9.5))
                                .foregroundColor(Color(white: 0.7))
                            Spacer()
                            Text("P-Cores: \(String(format: "%.1f%%", snapshot.cpu.pCoreUsage))")
                                .font(.system(size: 9.5))
                                .foregroundColor(Color(white: 0.7))
                        }

                        ProcessListView(
                            title: "Top CPU Consumers:",
                            processes: snapshot.topCPUProcesses,
                            isMemory: false
                        )
                    }
                    .padding(.top, 2)
                }

                // RAM Section
                MetricCard(
                    title: "🧠 UNIFIED MEMORY",
                    badge: "\(Formatters.formatBytes(snapshot.ram.usedBytes)) / \(Formatters.formatBytes(snapshot.ram.totalBytes))",
                    progress: snapshot.ram.usagePercentage / 100.0,
                    progressColor: Color(red: 48/255, green: 209/255, blue: 88/255)
                ) {
                    VStack(spacing: 3) {
                        HStack {
                            Text("App: \(Formatters.formatBytes(snapshot.ram.appBytes))")
                                .font(.system(size: 9.5))
                                .foregroundColor(Color(white: 0.7))
                            Spacer()
                            Text("Wired: \(Formatters.formatBytes(snapshot.ram.wiredBytes))")
                                .font(.system(size: 9.5))
                                .foregroundColor(Color(white: 0.7))
                        }

                        HStack {
                            Text("Compressed: \(Formatters.formatBytes(snapshot.ram.compressedBytes))")
                                .font(.system(size: 9.5))
                                .foregroundColor(Color(white: 0.7))
                            Spacer()
                            Text("Pressure: \(snapshot.ram.pressureState)")
                                .font(.system(size: 9.5, weight: .medium))
                                .foregroundColor(snapshot.ram.pressureState == "Normal" ? Color(red: 48/255, green: 209/255, blue: 88/255) : Color(red: 255/255, green: 159/255, blue: 10/255))
                        }

                        ProcessListView(
                            title: "Top Memory Consumers:",
                            processes: snapshot.topRAMProcesses,
                            isMemory: true
                        )
                    }
                    .padding(.top, 2)
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
                                .font(.system(size: 9.5))
                                .foregroundColor(Color(white: 0.6))
                            Spacer()
                            Text("Used: \(String(format: "%.1f%%", snapshot.disk.usedPercentage))")
                                .font(.system(size: 9.5, design: .monospaced))
                                .foregroundColor(.white)
                        }

                        HStack {
                            Text("Read: \(Formatters.formatSpeed(snapshot.disk.readBytesPerSec))")
                                .font(.system(size: 9.5, design: .monospaced))
                                .foregroundColor(Color(red: 100/255, green: 210/255, blue: 255/255))
                            Spacer()
                            Text("Write: \(Formatters.formatSpeed(snapshot.disk.writeBytesPerSec))")
                                .font(.system(size: 9.5, design: .monospaced))
                                .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                        }
                    }
                    .padding(.top, 1)
                }

                // 2-Column: Network & Thermal
                HStack(spacing: 6) {
                    // Network Card
                    VStack(alignment: .leading, spacing: 3) {
                        Text("🌐 NETWORK")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(Color(white: 0.65))

                        VStack(alignment: .leading, spacing: 1) {
                            Text("▼ \(Formatters.formatSpeed(snapshot.network.downloadBytesPerSec))")
                                .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                                .foregroundColor(Color(red: 100/255, green: 210/255, blue: 255/255))
                            Text("▲ \(Formatters.formatSpeed(snapshot.network.uploadBytesPerSec))")
                                .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                                .foregroundColor(Color(red: 48/255, green: 209/255, blue: 88/255))
                        }

                        Text("IF: \(snapshot.network.interfaceName) • IP: \(snapshot.network.localIP)")
                            .font(.system(size: 9))
                            .foregroundColor(Color(white: 0.55))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(white: 0.12).opacity(0.7))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    )

                    // Thermal Card
                    VStack(alignment: .leading, spacing: 3) {
                        Text("🌡 SOC THERMAL")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(Color(white: 0.65))

                        Text(String(format: "%.1f°C", snapshot.thermal.celsius))
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.temperatureColor(for: snapshot.thermal.celsius))

                        HStack {
                            Text("State: \(snapshot.thermal.thermalState.rawValue)")
                                .font(.system(size: 9))
                                .foregroundColor(Color(white: 0.55))
                            Spacer()
                            if let rpm = snapshot.thermal.fanRPM {
                                Text("\(rpm) RPM")
                                    .font(.system(size: 9))
                                    .foregroundColor(Color(white: 0.55))
                            } else {
                                Text("Fanless")
                                    .font(.system(size: 9))
                                    .foregroundColor(Color(white: 0.45))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(white: 0.12).opacity(0.7))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    )
                }

                // Bottom Actions
                HStack {
                    Button(action: openActivityMonitor) {
                        Text("Activity Monitor")
                            .font(.system(size: 10.5))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.white.opacity(0.15))

                    Button(action: openSystemSettings) {
                        Text("Configure...")
                            .font(.system(size: 10.5))
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.white.opacity(0.12))

                    Spacer()

                    Button(action: {
                        NSApplication.shared.terminate(nil)
                    }) {
                        Text("Quit")
                            .font(.system(size: 10.5))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 2)
            }
            .padding(10)
        }
        .frame(width: 300, height: 460)
        .background(
            VisualEffectView(material: .popover, blendingMode: .behindWindow)
        )
    }

    private func openActivityMonitor() {
        let path = "/System/Applications/Utilities/Activity Monitor.app"
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
    }

    private func openSystemSettings() {
        let path = "/System/Applications/System Settings.app"
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
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
