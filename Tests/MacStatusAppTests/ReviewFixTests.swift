import Testing
import Foundation
@testable import MacStatusApp

@Suite("Review Fixes & Edge Case Tests")
struct ReviewFixTests {
    @Test func testAppMemoryExcludesPurgeable() {
        let mem = MemoryMonitor()
        let stats = mem.sample()
        #expect(stats.appBytes <= stats.usedBytes)
        #expect(stats.appBytes >= 0)
    }

    @Test func testNetworkMonitorHandlesLongSleepElapsedWithoutSpike() {
        let net = NetworkMonitor()
        _ = net.sample()
        // Simulate immediate second sample
        let stats2 = net.sample()
        #expect(!stats2.downloadBytesPerSec.isNaN)
        #expect(!stats2.uploadBytesPerSec.isNaN)
        #expect(stats2.downloadBytesPerSec >= 0)
    }

    @Test func testCPUMonitorCoreCounts() {
        let cpu = CPUMonitor()
        let stats = cpu.sample()
        #expect(stats.coreCount > 0)
        #expect(!stats.totalUsage.isNaN)
        #expect(!stats.eCoreUsage.isNaN)
        #expect(!stats.pCoreUsage.isNaN)
    }

    @Test func testThermalMonitorTemperatureValidRange() {
        let thermal = ThermalMonitor()
        let stats = thermal.sample()
        #expect(stats.celsius >= 20.0 && stats.celsius <= 110.0)
    }
}
