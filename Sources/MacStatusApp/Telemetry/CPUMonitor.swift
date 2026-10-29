import Foundation
import Darwin

public final class CPUMonitor: @unchecked Sendable {
    private struct CoreTicks {
        var user: UInt32 = 0
        var system: UInt32 = 0
        var idle: UInt32 = 0
        var nice: UInt32 = 0
    }

    private var previousCoreTicks: [CoreTicks] = []
    private var pCoreCount: Int = 0
    private var eCoreCount: Int = 0

    public init() {
        detectCoreTypes()
    }

    private func detectCoreTypes() {
        var pCores: Int32 = 0
        var size = MemoryLayout<Int32>.size
        if sysctlbyname("hw.perflevel0.logicalcpu", &pCores, &size, nil, 0) == 0 {
            self.pCoreCount = Int(pCores)
        }

        var eCores: Int32 = 0
        size = MemoryLayout<Int32>.size
        if sysctlbyname("hw.perflevel1.logicalcpu", &eCores, &size, nil, 0) == 0 {
            self.eCoreCount = Int(eCores)
        }

        if self.pCoreCount == 0 && self.eCoreCount == 0 {
            var ncpu: Int32 = 0
            size = MemoryLayout<Int32>.size
            sysctlbyname("hw.logicalcpu", &ncpu, &size, nil, 0)
            self.pCoreCount = max(1, Int(ncpu) / 2)
            self.eCoreCount = max(1, Int(ncpu) - self.pCoreCount)
        }
    }

    public func sample() -> CPUStats {
        var numCPUsU: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var numCpuInfo: mach_msg_type_number_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCPUsU,
            &cpuInfo,
            &numCpuInfo
        )

        guard result == KERN_SUCCESS, let cpuInfo = cpuInfo else {
            return CPUStats(totalUsage: 0.0, eCoreUsage: 0.0, pCoreUsage: 0.0, coreCount: max(1, pCoreCount + eCoreCount))
        }

        let numCPUs = Int(numCPUsU)
        var currentTicks: [CoreTicks] = []
        currentTicks.reserveCapacity(numCPUs)

        let stateMax = Int(CPU_STATE_MAX)
        for i in 0..<numCPUs {
            let offset = i * stateMax
            let u = UInt32(cpuInfo[offset + Int(CPU_STATE_USER)])
            let s = UInt32(cpuInfo[offset + Int(CPU_STATE_SYSTEM)])
            let idl = UInt32(cpuInfo[offset + Int(CPU_STATE_IDLE)])
            let n = UInt32(cpuInfo[offset + Int(CPU_STATE_NICE)])
            currentTicks.append(CoreTicks(user: u, system: s, idle: idl, nice: n))
        }

        // Deallocate mach memory
        let cpuInfoSize = vm_size_t(numCpuInfo) * vm_size_t(MemoryLayout<integer_t>.size)
        vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: cpuInfo)), cpuInfoSize)

        guard previousCoreTicks.count == numCPUs else {
            previousCoreTicks = currentTicks
            return CPUStats(totalUsage: 0.0, eCoreUsage: 0.0, pCoreUsage: 0.0, coreCount: numCPUs)
        }

        var totalInUse: Double = 0
        var totalAll: Double = 0
        var eInUse: Double = 0
        var eAll: Double = 0
        var pInUse: Double = 0
        var pAll: Double = 0

        for i in 0..<numCPUs {
            let prev = previousCoreTicks[i]
            let curr = currentTicks[i]

            let userDelta = Double(curr.user >= prev.user ? curr.user - prev.user : 0)
            let sysDelta = Double(curr.system >= prev.system ? curr.system - prev.system : 0)
            let niceDelta = Double(curr.nice >= prev.nice ? curr.nice - prev.nice : 0)
            let idleDelta = Double(curr.idle >= prev.idle ? curr.idle - prev.idle : 0)

            let inUse = userDelta + sysDelta + niceDelta
            let total = inUse + idleDelta

            totalInUse += inUse
            totalAll += total

            // In Apple Silicon: usually E-cores are the first eCoreCount cores, or perflevel1
            if i < eCoreCount {
                eInUse += inUse
                eAll += total
            } else {
                pInUse += inUse
                pAll += total
            }
        }

        previousCoreTicks = currentTicks

        let totalUsage = totalAll > 0 ? (totalInUse / totalAll) * 100.0 : 0.0
        let eUsage = eAll > 0 ? (eInUse / eAll) * 100.0 : totalUsage
        let pUsage = pAll > 0 ? (pInUse / pAll) * 100.0 : totalUsage

        return CPUStats(
            totalUsage: Formatters.clampPercentage(totalUsage),
            eCoreUsage: Formatters.clampPercentage(eUsage),
            pCoreUsage: Formatters.clampPercentage(pUsage),
            coreCount: numCPUs
        )
    }
}
