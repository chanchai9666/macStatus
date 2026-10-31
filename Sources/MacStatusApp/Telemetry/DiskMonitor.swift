import Foundation
import Darwin
import IOKit

public final class DiskMonitor: @unchecked Sendable {
    private var lastSpaceSampleUptime: TimeInterval = 0
    private var cachedTotal: Int64 = 0
    private var cachedFree: Int64 = 0

    private var lastIOUptime: TimeInterval = 0
    private var lastReadBytes: Int64 = 0
    private var lastWriteBytes: Int64 = 0
    private var currentReadSpeed: Double = 0.0
    private var currentWriteSpeed: Double = 0.0

    public init() {
        refreshDiskSpace()
        _ = sampleDiskIO()
    }

    private func refreshDiskSpace() {
        var stat = statfs()
        if statfs("/", &stat) == 0 {
            let blockSize = Int64(stat.f_bsize)
            self.cachedTotal = Int64(stat.f_blocks) * blockSize
            self.cachedFree = Int64(stat.f_bavail) * blockSize
        }
        self.lastSpaceSampleUptime = ProcessInfo.processInfo.systemUptime
    }

    private func sampleDiskIO() -> (readSpeed: Double, writeSpeed: Double) {
        let nowUptime = ProcessInfo.processInfo.systemUptime

        var iterator: io_iterator_t = 0
        let matching = IOServiceMatching("IOBlockStorageDriver")
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return (currentReadSpeed, currentWriteSpeed)
        }

        var totalReadBytes: Int64 = 0
        var totalWriteBytes: Int64 = 0

        var service = IOIteratorNext(iterator)
        while service != 0 {
            if let unmanagedProps = IORegistryEntryCreateCFProperty(service, "Statistics" as CFString, kCFAllocatorDefault, 0) {
                if let statsDict = unmanagedProps.takeRetainedValue() as? [String: Any] {
                    if let r = statsDict["Bytes (Read)"] as? Int64 {
                        totalReadBytes += r
                    } else if let r = statsDict["Bytes (Read)"] as? NSNumber {
                        totalReadBytes += r.int64Value
                    }
                    if let w = statsDict["Bytes (Write)"] as? Int64 {
                        totalWriteBytes += w
                    } else if let w = statsDict["Bytes (Write)"] as? NSNumber {
                        totalWriteBytes += w.int64Value
                    }
                }
            }
            IOObjectRelease(service)
            service = IOIteratorNext(iterator)
        }
        IOObjectRelease(iterator)

        if lastIOUptime > 0 {
            let timeDelta = nowUptime - lastIOUptime
            if timeDelta > 0.1 {
                let readDelta = max(0, totalReadBytes - lastReadBytes)
                let writeDelta = max(0, totalWriteBytes - lastWriteBytes)
                currentReadSpeed = Double(readDelta) / timeDelta
                currentWriteSpeed = Double(writeDelta) / timeDelta
            }
        }

        lastReadBytes = totalReadBytes
        lastWriteBytes = totalWriteBytes
        lastIOUptime = nowUptime

        return (currentReadSpeed, currentWriteSpeed)
    }

    public func sample() -> DiskStats {
        let nowUptime = ProcessInfo.processInfo.systemUptime
        if nowUptime - lastSpaceSampleUptime > 15.0 || cachedTotal == 0 {
            refreshDiskSpace()
        }

        let io = sampleDiskIO()

        return DiskStats(
            totalBytes: cachedTotal,
            freeBytes: cachedFree,
            readBytesPerSec: io.readSpeed,
            writeBytesPerSec: io.writeSpeed
        )
    }
}
