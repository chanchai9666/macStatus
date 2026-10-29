import Testing
@testable import MacStatusApp

@Suite("Hardware Telemetry Providers Tests")
struct TelemetryProviderTests {
    @Test func testMemoryMonitorReturnsValidStats() {
        let mem = MemoryMonitor()
        let stats = mem.sample()
        #expect(stats.totalBytes > 0)
        #expect(stats.usedBytes > 0)
        #expect(stats.usagePercentage >= 0.0 && stats.usagePercentage <= 100.0)
    }

    @Test func testDiskMonitorReturnsRootVolume() {
        let disk = DiskMonitor()
        let stats = disk.sample()
        #expect(stats.totalBytes > 0)
        #expect(stats.freeBytes > 0)
        #expect(stats.usedPercentage >= 0.0 && stats.usedPercentage <= 100.0)
    }

    @Test func testThermalMonitorReturnsReasonableTemperature() {
        let thermal = ThermalMonitor()
        let stats = thermal.sample()
        #expect(stats.celsius >= 15.0 && stats.celsius <= 115.0)
    }
}
