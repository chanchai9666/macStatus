import Foundation
import Darwin

public final class ProcessMonitor: @unchecked Sendable {
    private struct PrevProcInfo {
        var time: UInt64
        var timestamp: Date
    }
    private var prevTimes: [Int32: PrevProcInfo] = [:]

    public init() {}

    public func sampleTopProcesses(limit: Int = 3) -> (topCPU: [TopProcessItem], topRAM: [TopProcessItem]) {
        var pids = [pid_t](repeating: 0, count: 1024)
        let numBytes = proc_listallpids(&pids, Int32(pids.count * MemoryLayout<pid_t>.size))
        guard numBytes > 0 else { return ([], []) }

        let count = Int(numBytes) / MemoryLayout<pid_t>.size
        let now = Date()

        var cpuList: [TopProcessItem] = []
        var ramList: [TopProcessItem] = []

        for i in 0..<count {
            let pid = pids[i]
            guard pid > 0 else { continue }

            var taskInfo = proc_taskinfo()
            let infoSize = Int32(MemoryLayout<proc_taskinfo>.size)
            let result = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &taskInfo, infoSize)
            guard result == infoSize else { continue }

            var nameBuffer = [CChar](repeating: 0, count: 256)
            proc_name(pid, &nameBuffer, UInt32(nameBuffer.count))
            var procName = String(cString: nameBuffer)
            if procName.isEmpty {
                procName = "PID \(pid)"
            }

            let memBytes = Int64(taskInfo.pti_resident_size)
            let totalCpuTime = taskInfo.pti_total_user + taskInfo.pti_total_system

            var cpuPercent = 0.0
            if let prev = prevTimes[pid] {
                let timeDelta = totalCpuTime >= prev.time ? totalCpuTime - prev.time : 0
                let wallDelta = max(0.1, now.timeIntervalSince(prev.timestamp))
                // nano to seconds = 1e9
                let seconds = Double(timeDelta) / 1_000_000_000.0
                cpuPercent = (seconds / wallDelta) * 100.0
            }
            prevTimes[pid] = PrevProcInfo(time: totalCpuTime, timestamp: now)

            let item = TopProcessItem(
                name: procName,
                pid: pid,
                cpuPercent: Formatters.clampPercentage(cpuPercent),
                memoryBytes: memBytes
            )
            cpuList.append(item)
            ramList.append(item)
        }

        let sortedCPU = cpuList
            .filter { $0.cpuPercent > 0.0 }
            .sorted { $0.cpuPercent > $1.cpuPercent }
            .prefix(limit)

        let sortedRAM = ramList
            .filter { $0.memoryBytes > 0 }
            .sorted { $0.memoryBytes > $1.memoryBytes }
            .prefix(limit)

        return (Array(sortedCPU), Array(sortedRAM))
    }
}
