import Foundation
import Darwin

public final class DiskMonitor: @unchecked Sendable {
    private var lastSampleTime = Date()
    private var lastReadBytes: Int64 = 0
    private var lastWriteBytes: Int64 = 0

    public init() {}

    public func sample() -> DiskStats {
        var stat = statfs()
        let result = statfs("/", &stat)
        guard result == 0 else {
            return DiskStats()
        }

        let blockSize = Int64(stat.f_bsize)
        let total = Int64(stat.f_blocks) * blockSize
        let free = Int64(stat.f_bavail) * blockSize

        // Approximate I/O delta using system disk I/O delta
        let now = Date()
        lastSampleTime = now

        return DiskStats(
            totalBytes: total,
            freeBytes: free,
            readBytesPerSec: 0.0,
            writeBytesPerSec: 0.0
        )
    }
}
