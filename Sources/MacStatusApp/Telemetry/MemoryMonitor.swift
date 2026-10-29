import Foundation
import Darwin

public final class MemoryMonitor: @unchecked Sendable {
    public init() {}

    public func sample() -> RAMStats {
        var size = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        var vmStats = vm_statistics64_data_t()
        let hostPort = mach_host_self()

        let kerr = withUnsafeMutablePointer(to: &vmStats) { ptr -> kern_return_t in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(size)) { intPtr in
                host_statistics64(hostPort, HOST_VM_INFO64, intPtr, &size)
            }
        }

        guard kerr == KERN_SUCCESS else {
            return RAMStats()
        }

        var totalRamBytes: Int64 = 0
        var mib: [Int32] = [CTL_HW, HW_MEMSIZE]
        var length = MemoryLayout<Int64>.size
        sysctl(&mib, 2, &totalRamBytes, &length, nil, 0)

        let pageSize = Int64(sysconf(_SC_PAGESIZE))
        let appPages = max(0, Int64(vmStats.internal_page_count) - Int64(vmStats.purgeable_count))
        let appBytes = appPages * pageSize
        let wiredBytes = Int64(vmStats.wire_count) * pageSize
        let compressedBytes = Int64(vmStats.compressor_page_count) * pageSize
        let usedBytes = appBytes + wiredBytes + compressedBytes

        var pressureLevel: Int32 = 1
        var pressureSize = MemoryLayout<Int32>.size
        var pressureStr = "Normal"
        if sysctlbyname("kern.memorystatus_vm_pressure_level", &pressureLevel, &pressureSize, nil, 0) == 0 {
            switch pressureLevel {
            case 1: pressureStr = "Normal"
            case 2: pressureStr = "Warning"
            case 4: pressureStr = "Critical"
            default: pressureStr = "Normal"
            }
        }

        return RAMStats(
            totalBytes: totalRamBytes,
            usedBytes: min(totalRamBytes, usedBytes),
            appBytes: appBytes,
            wiredBytes: wiredBytes,
            compressedBytes: compressedBytes,
            pressureState: pressureStr
        )
    }
}
