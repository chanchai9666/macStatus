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
        let active = Int64(vmStats.active_count) * pageSize
        let wired = Int64(vmStats.wire_count) * pageSize
        let compressed = Int64(vmStats.compressor_page_count) * pageSize
        let speculative = Int64(vmStats.speculative_count) * pageSize
        let app = active + speculative
        let used = wired + app + compressed

        return RAMStats(
            totalBytes: totalRamBytes,
            usedBytes: min(totalRamBytes, used),
            appBytes: app,
            wiredBytes: wired,
            compressedBytes: compressed,
            pressureState: "Normal"
        )
    }
}
