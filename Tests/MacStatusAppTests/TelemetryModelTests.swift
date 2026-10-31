import Testing
@testable import MacStatusApp

@Suite("Telemetry Models and Formatters Tests")
struct TelemetryModelTests {
    @Test func testByteFormatting() {
        #expect(Formatters.formatBytes(1024) == "1.0 KB")
        #expect(Formatters.formatBytes(1048576 * 1024 * 154) == "154.0 GB")
    }

    @Test func testSpeedFormatting() {
        #expect(Formatters.formatSpeed(1500) == "1.5 KB/s")
        #expect(Formatters.formatSpeed(1572864) == "1.5 MB/s")
    }

    @Test func testClampPercentages() {
        #expect(Formatters.clampPercentage(-5.0) == 0.0)
        #expect(Formatters.clampPercentage(105.0) == 100.0)
        #expect(Formatters.clampPercentage(42.5) == 42.5)
    }

    @Test func testThermalPressureStateEnum() {
        let stats = ThermalStats(celsius: 45.0, thermalState: .nominal)
        #expect(stats.thermalState == .nominal)
        #expect(stats.thermalState.rawValue == "Nominal")

        let stringStats = ThermalStats(celsius: 60.0, thermalState: "Fair")
        #expect(stringStats.thermalState == .fair)
    }

    @Test func testDiskIOStats() {
        let disk = DiskStats(totalBytes: 1_000_000, freeBytes: 500_000, readBytesPerSec: 1024, writeBytesPerSec: 2048)
        #expect(disk.readBytesPerSec == 1024)
        #expect(disk.writeBytesPerSec == 2048)
    }
}
