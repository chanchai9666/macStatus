import Foundation

public struct CPUStats: Sendable {
    public let totalUsage: Double
    public let eCoreUsage: Double
    public let pCoreUsage: Double
    public let coreCount: Int

    public init(totalUsage: Double = 0.0, eCoreUsage: Double = 0.0, pCoreUsage: Double = 0.0, coreCount: Int = 8) {
        self.totalUsage = totalUsage
        self.eCoreUsage = eCoreUsage
        self.pCoreUsage = pCoreUsage
        self.coreCount = coreCount
    }
}

public struct RAMStats: Sendable {
    public let totalBytes: Int64
    public let usedBytes: Int64
    public let appBytes: Int64
    public let wiredBytes: Int64
    public let compressedBytes: Int64
    public let pressureState: String

    public var usagePercentage: Double {
        guard totalBytes > 0 else { return 0.0 }
        return (Double(usedBytes) / Double(totalBytes)) * 100.0
    }

    public init(
        totalBytes: Int64 = 0,
        usedBytes: Int64 = 0,
        appBytes: Int64 = 0,
        wiredBytes: Int64 = 0,
        compressedBytes: Int64 = 0,
        pressureState: String = "Normal"
    ) {
        self.totalBytes = totalBytes
        self.usedBytes = usedBytes
        self.appBytes = appBytes
        self.wiredBytes = wiredBytes
        self.compressedBytes = compressedBytes
        self.pressureState = pressureState
    }
}

public struct DiskStats: Sendable {
    public let totalBytes: Int64
    public let freeBytes: Int64
    public let readBytesPerSec: Double
    public let writeBytesPerSec: Double

    public var usedBytes: Int64 {
        max(0, totalBytes - freeBytes)
    }

    public var usedPercentage: Double {
        guard totalBytes > 0 else { return 0.0 }
        return (Double(usedBytes) / Double(totalBytes)) * 100.0
    }

    public init(
        totalBytes: Int64 = 0,
        freeBytes: Int64 = 0,
        readBytesPerSec: Double = 0.0,
        writeBytesPerSec: Double = 0.0
    ) {
        self.totalBytes = totalBytes
        self.freeBytes = freeBytes
        self.readBytesPerSec = readBytesPerSec
        self.writeBytesPerSec = writeBytesPerSec
    }
}

public struct NetworkStats: Sendable {
    public let downloadBytesPerSec: Double
    public let uploadBytesPerSec: Double
    public let localIP: String
    public let interfaceName: String

    public var totalThroughput: Double {
        downloadBytesPerSec + uploadBytesPerSec
    }

    public init(
        downloadBytesPerSec: Double = 0.0,
        uploadBytesPerSec: Double = 0.0,
        localIP: String = "127.0.0.1",
        interfaceName: String = "en0"
    ) {
        self.downloadBytesPerSec = downloadBytesPerSec
        self.uploadBytesPerSec = uploadBytesPerSec
        self.localIP = localIP
        self.interfaceName = interfaceName
    }
}

public enum ThermalPressureState: String, Sendable, CaseIterable {
    case nominal = "Nominal"
    case fair = "Fair"
    case serious = "Serious"
    case critical = "Critical"
    case unknown = "Unknown"
}

public struct ThermalStats: Sendable {
    public let celsius: Double
    public let thermalState: ThermalPressureState
    public let fanRPM: Int?

    public init(
        celsius: Double = 42.0,
        thermalState: ThermalPressureState = .nominal,
        fanRPM: Int? = nil
    ) {
        self.celsius = celsius
        self.thermalState = thermalState
        self.fanRPM = fanRPM
    }

    public init(
        celsius: Double,
        thermalState: String,
        fanRPM: Int? = nil
    ) {
        self.celsius = celsius
        self.thermalState = ThermalPressureState(rawValue: thermalState) ?? .unknown
        self.fanRPM = fanRPM
    }
}

public struct TopProcessItem: Identifiable, Sendable {
    public let id: Int32
    public let name: String
    public let pid: Int32
    public let cpuPercent: Double
    public let memoryBytes: Int64

    public var formattedMemory: String {
        Formatters.formatBytes(memoryBytes)
    }

    public var formattedCPU: String {
        String(format: "%.1f%%", cpuPercent)
    }

    public init(name: String, pid: Int32, cpuPercent: Double, memoryBytes: Int64) {
        self.id = pid
        self.name = name
        self.pid = pid
        self.cpuPercent = cpuPercent
        self.memoryBytes = memoryBytes
    }
}

public struct SystemSnapshot: Sendable {
    public let cpu: CPUStats
    public let ram: RAMStats
    public let disk: DiskStats
    public let network: NetworkStats
    public let thermal: ThermalStats
    public let topCPUProcesses: [TopProcessItem]
    public let topRAMProcesses: [TopProcessItem]
    public let timestamp: Date

    public init(
        cpu: CPUStats = CPUStats(),
        ram: RAMStats = RAMStats(),
        disk: DiskStats = DiskStats(),
        network: NetworkStats = NetworkStats(),
        thermal: ThermalStats = ThermalStats(),
        topCPUProcesses: [TopProcessItem] = [],
        topRAMProcesses: [TopProcessItem] = [],
        timestamp: Date = Date()
    ) {
        self.cpu = cpu
        self.ram = ram
        self.disk = disk
        self.network = network
        self.thermal = thermal
        self.topCPUProcesses = topCPUProcesses
        self.topRAMProcesses = topRAMProcesses
        self.timestamp = timestamp
    }
}
