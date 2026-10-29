import Foundation
import Combine

@MainActor
public final class SystemTelemetryService: ObservableObject {
    @Published public private(set) var currentSnapshot: SystemSnapshot = SystemSnapshot()

    private let cpuMonitor = CPUMonitor()
    private let memoryMonitor = MemoryMonitor()
    private let diskMonitor = DiskMonitor()
    private let networkMonitor = NetworkMonitor()
    private let thermalMonitor = ThermalMonitor()
    private let processMonitor = ProcessMonitor()

    public init() {
        updateSnapshot(includeProcesses: false)
    }

    public func sample(includeProcesses: Bool) -> SystemSnapshot {
        let cpu = cpuMonitor.sample()
        let ram = memoryMonitor.sample()
        let disk = diskMonitor.sample()
        let net = networkMonitor.sample()
        let thermal = thermalMonitor.sample()

        var topCPU: [TopProcessItem] = []
        var topRAM: [TopProcessItem] = []

        if includeProcesses {
            let procResult = processMonitor.sampleTopProcesses(limit: 3)
            topCPU = procResult.topCPU
            topRAM = procResult.topRAM
        } else {
            topCPU = currentSnapshot.topCPUProcesses
            topRAM = currentSnapshot.topRAMProcesses
        }

        return SystemSnapshot(
            cpu: cpu,
            ram: ram,
            disk: disk,
            network: net,
            thermal: thermal,
            topCPUProcesses: topCPU,
            topRAMProcesses: topRAM,
            timestamp: Date()
        )
    }

    public func updateSnapshot(includeProcesses: Bool) {
        self.currentSnapshot = sample(includeProcesses: includeProcesses)
    }
}
