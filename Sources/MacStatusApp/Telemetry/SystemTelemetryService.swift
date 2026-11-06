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
    private var isUpdating = false

    public init() {
        self.currentSnapshot = sample(includeProcesses: false)
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
        guard !isUpdating else { return }
        isUpdating = true

        let cpuMon = self.cpuMonitor
        let ramMon = self.memoryMonitor
        let diskMon = self.diskMonitor
        let netMon = self.networkMonitor
        let thermMon = self.thermalMonitor
        let procMon = self.processMonitor

        Task.detached(priority: .utility) { [weak self] in
            let cpu = cpuMon.sample()
            let ram = ramMon.sample()
            let disk = diskMon.sample()
            let net = netMon.sample()
            let thermal = thermMon.sample()

            var topCPU: [TopProcessItem] = []
            var topRAM: [TopProcessItem] = []

            if includeProcesses {
                let procResult = procMon.sampleTopProcesses(limit: 3)
                topCPU = procResult.topCPU
                topRAM = procResult.topRAM
            }

            let newSnapshot = SystemSnapshot(
                cpu: cpu,
                ram: ram,
                disk: disk,
                network: net,
                thermal: thermal,
                topCPUProcesses: topCPU,
                topRAMProcesses: topRAM,
                timestamp: Date()
            )

            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.isUpdating = false
                let finalTopCPU = includeProcesses ? newSnapshot.topCPUProcesses : self.currentSnapshot.topCPUProcesses
                let finalTopRAM = includeProcesses ? newSnapshot.topRAMProcesses : self.currentSnapshot.topRAMProcesses

                self.currentSnapshot = SystemSnapshot(
                    cpu: newSnapshot.cpu,
                    ram: newSnapshot.ram,
                    disk: newSnapshot.disk,
                    network: newSnapshot.network,
                    thermal: newSnapshot.thermal,
                    topCPUProcesses: finalTopCPU,
                    topRAMProcesses: finalTopRAM,
                    timestamp: newSnapshot.timestamp
                )
            }
        }
    }
}
