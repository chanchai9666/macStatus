import Foundation
import Darwin

public final class NetworkMonitor: @unchecked Sendable {
    private var lastSampleUptime: TimeInterval = ProcessInfo.processInfo.systemUptime
    private var lastInBytes: UInt64 = 0
    private var lastOutBytes: UInt64 = 0
    private var isFirstSample = true
    private var cachedIP: String = "127.0.0.1"
    private var cachedInterface: String = "en0"
    private var lastIPLookupUptime: TimeInterval = 0

    public init() {}

    public func sample() -> NetworkStats {
        var ifap: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifap) == 0, let first = ifap else {
            return NetworkStats(localIP: cachedIP, interfaceName: cachedInterface)
        }
        defer { freeifaddrs(ifap) }

        var totalInBytes: UInt64 = 0
        var totalOutBytes: UInt64 = 0
        let nowUptime = ProcessInfo.processInfo.systemUptime
        let shouldLookupIP = (nowUptime - lastIPLookupUptime > 60.0) || isFirstSample

        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let current = cursor {
            let flags = Int32(current.pointee.ifa_flags)

            // Ignore loopback and down interfaces
            if (flags & IFF_LOOPBACK) == 0 && (flags & IFF_UP) != 0 {
                if let addr = current.pointee.ifa_addr {
                    let family = addr.pointee.sa_family
                    if family == UInt8(AF_LINK) {
                        if let data = current.pointee.ifa_data {
                            let ifData = data.assumingMemoryBound(to: if_data.self)
                            totalInBytes += UInt64(ifData.pointee.ifi_ibytes)
                            totalOutBytes += UInt64(ifData.pointee.ifi_obytes)
                        }
                    } else if shouldLookupIP && family == UInt8(AF_INET) {
                        var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        let saLen = socklen_t(addr.pointee.sa_len)
                        if getnameinfo(addr, saLen, &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0 {
                            let ipStr = host.withUnsafeBufferPointer { ptr in
                                String(cString: ptr.baseAddress!)
                            }
                            if !ipStr.hasPrefix("127.") {
                                cachedIP = ipStr
                                cachedInterface = String(cString: current.pointee.ifa_name)
                                lastIPLookupUptime = nowUptime
                            }
                        }
                    }
                }
            }
            cursor = current.pointee.ifa_next
        }

        let elapsed = nowUptime - lastSampleUptime
        lastSampleUptime = nowUptime

        if isFirstSample || elapsed > 4.0 || elapsed <= 0.05 {
            isFirstSample = false
            lastInBytes = totalInBytes
            lastOutBytes = totalOutBytes
            return NetworkStats(
                downloadBytesPerSec: 0.0,
                uploadBytesPerSec: 0.0,
                localIP: cachedIP,
                interfaceName: cachedInterface
            )
        }

        let inDelta = totalInBytes >= lastInBytes ? totalInBytes - lastInBytes : 0
        let outDelta = totalOutBytes >= lastOutBytes ? totalOutBytes - lastOutBytes : 0
        lastInBytes = totalInBytes
        lastOutBytes = totalOutBytes

        let downRate = Double(inDelta) / elapsed
        let upRate = Double(outDelta) / elapsed

        return NetworkStats(
            downloadBytesPerSec: max(0.0, downRate),
            uploadBytesPerSec: max(0.0, upRate),
            localIP: cachedIP,
            interfaceName: cachedInterface
        )
    }
}
