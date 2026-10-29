import Foundation
import Darwin

public final class NetworkMonitor: @unchecked Sendable {
    private var lastSampleTime = Date()
    private var lastInBytes: UInt64 = 0
    private var lastOutBytes: UInt64 = 0
    private var isFirstSample = true

    public init() {}

    public func sample() -> NetworkStats {
        var ifap: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifap) == 0, let first = ifap else {
            return NetworkStats()
        }
        defer { freeifaddrs(ifap) }

        var totalInBytes: UInt64 = 0
        var totalOutBytes: UInt64 = 0
        var activeIP = "127.0.0.1"
        var primaryInterface = "en0"

        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let current = cursor {
            let name = String(cString: current.pointee.ifa_name)
            let flags = Int32(current.pointee.ifa_flags)

            // Ignore loopback
            if (flags & IFF_LOOPBACK) == 0 && (flags & IFF_UP) != 0 {
                if let addr = current.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_LINK) {
                    if let data = current.pointee.ifa_data {
                        let ifData = data.assumingMemoryBound(to: if_data.self)
                        totalInBytes += UInt64(ifData.pointee.ifi_ibytes)
                        totalOutBytes += UInt64(ifData.pointee.ifi_obytes)
                    }
                } else if let addr = current.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_INET) {
                    var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    let saLen = socklen_t(addr.pointee.sa_len)
                    if getnameinfo(addr, saLen, &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0 {
                        let ipStr = String(cString: host)
                        if !ipStr.hasPrefix("127.") && activeIP == "127.0.0.1" {
                            activeIP = ipStr
                            primaryInterface = name
                        }
                    }
                }
            }
            cursor = current.pointee.ifa_next
        }

        let now = Date()
        let elapsed = max(0.2, now.timeIntervalSince(lastSampleTime))
        lastSampleTime = now

        if isFirstSample {
            isFirstSample = false
            lastInBytes = totalInBytes
            lastOutOutBytes(totalOutBytes)
            return NetworkStats(
                downloadBytesPerSec: 0.0,
                uploadBytesPerSec: 0.0,
                localIP: activeIP,
                interfaceName: primaryInterface
            )
        }

        let inDelta = totalInBytes >= lastInBytes ? totalInBytes - lastInBytes : 0
        let outDelta = totalOutBytes >= lastOutBytes ? totalOutBytes - lastOutBytes : 0
        lastInBytes = totalInBytes
        lastOutBytes = totalOutBytes

        let downRate = Double(inDelta) / elapsed
        let upRate = Double(outDelta) / elapsed

        return NetworkStats(
            downloadBytesPerSec: downRate,
            uploadBytesPerSec: upRate,
            localIP: activeIP,
            interfaceName: primaryInterface
        )
    }

    private func lastOutOutBytes(_ val: UInt64) {
        lastOutBytes = val
    }
}
