import Foundation
import Darwin

public final class DiskMonitor: @unchecked Sendable {
    private var lastSampleUptime: TimeInterval = 0
    private var cachedTotal: Int64 = 0
    private var cachedFree: Int64 = 0

    public init() {
        refreshDiskSpace()
    }

    private func refreshDiskSpace() {
        var stat = statfs()
        if statfs("/", &stat) == 0 {
            let blockSize = Int64(stat.f_bsize)
            self.cachedTotal = Int64(stat.f_blocks) * blockSize
            self.cachedFree = Int64(stat.f_bavail) * blockSize
        }
        self.lastSampleUptime = ProcessInfo.processInfo.systemUptime
    }

    public func sample() -> DiskStats {
        let nowUptime = ProcessInfo.processInfo.systemUptime
        if nowUptime - lastSampleUptime > 15.0 || cachedTotal == 0 {
            refreshDiskSpace()
        }

        return DiskStats(
            totalBytes: cachedTotal,
            freeBytes: cachedFree,
            readBytesPerSec: 0.0,
            writeBytesPerSec: 0.0
        )
    }
}
