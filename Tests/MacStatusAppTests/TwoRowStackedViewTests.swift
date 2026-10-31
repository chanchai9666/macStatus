import Testing
import SwiftUI
@testable import MacStatusApp

@Suite("TwoRowStackedView Tests")
@MainActor
struct TwoRowStackedViewTests {
    @Test func testTwoRowStackedViewInitializesWithSnapshot() {
        let snapshot = SystemSnapshot(
            cpu: CPUStats(totalUsage: 15.4),
            ram: RAMStats(totalBytes: 16_000_000_000, usedBytes: 8_000_000_000),
            disk: DiskStats(totalBytes: 500_000_000_000, freeBytes: 125_000_000_000),
            network: NetworkStats(downloadBytesPerSec: 8192, uploadBytesPerSec: 4096),
            thermal: ThermalStats(celsius: 52.0, thermalState: "Nominal")
        )
        
        let view = TwoRowStackedView(snapshot: snapshot)
        #expect(view.snapshot.cpu.totalUsage == 15.4)
        #expect(view.snapshot.thermal.celsius == 52.0)
    }

    @Test func testTwoRowStackedViewTempColorLogic() {
        #expect(TwoRowStackedView.tempColor(for: 50.0) == Color(red: 255/255, green: 214/255, blue: 10/255))
        #expect(TwoRowStackedView.tempColor(for: 70.0) == Color(red: 255/255, green: 159/255, blue: 10/255))
        #expect(TwoRowStackedView.tempColor(for: 90.0) == Color(red: 255/255, green: 69/255, blue: 58/255))
    }
}
