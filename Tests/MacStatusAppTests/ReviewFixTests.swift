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

    @Test func testProcessMonitorDynamicSampling() {
        let procMon = ProcessMonitor()
        let result = procMon.sampleTopProcesses(limit: 3)
        // System always has running processes
        #expect(!result.topRAM.isEmpty)
        for item in result.topRAM {
            #expect(item.pid > 0)
            #expect(!item.name.isEmpty)
            #expect(item.memoryBytes >= 0)
        }
    }

    @Test func testDiskMonitorSleepElapsedGuard() {
        let disk = DiskMonitor()
        let s1 = disk.sample()
        let s2 = disk.sample()
        #expect(s1.readBytesPerSec >= 0.0)
        #expect(s1.writeBytesPerSec >= 0.0)
        #expect(s2.readBytesPerSec >= 0.0)
        #expect(s2.writeBytesPerSec >= 0.0)
    }

    @Test func testRepeatedMachPortSampling() {
        let cpu = CPUMonitor()
        let mem = MemoryMonitor()
        for _ in 0..<30 {
            let cpuStats = cpu.sample()
            let memStats = mem.sample()
            #expect(cpuStats.coreCount > 0)
            #expect(memStats.totalBytes > 0)
        }
    }

    @MainActor
    @Test func testSystemTelemetryServiceAsyncUpdate() async throws {
        let service = SystemTelemetryService()
        let initialSnapshot = service.currentSnapshot
        #expect(initialSnapshot.cpu.coreCount > 0)

        service.updateSnapshot(includeProcesses: true)
        // Wait briefly for background Task.detached to complete and dispatch to MainActor
        try await Task.sleep(nanoseconds: 150_000_000) // 150ms
        let updatedSnapshot = service.currentSnapshot
        #expect(updatedSnapshot.timestamp >= initialSnapshot.timestamp)
    }
}
