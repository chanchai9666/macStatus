import Testing
import SwiftUI
@testable import MacStatusApp

@Suite("Popover Component Tests")
@MainActor
struct PopoverViewTests {
    @Test func testProcessItemFormatting() {
        let item = TopProcessItem(name: "Google Chrome", pid: 1234, cpuPercent: 14.5, memoryBytes: 2147483648)
        #expect(item.formattedMemory == "2.0 GB")
        #expect(item.formattedCPU == "14.5%")
    }

    @Test func testMetricCardCreation() {
        let card = MetricCard(title: "CPU", badge: "24%", progress: 0.24, progressColor: .blue)
        #expect(card.title == "CPU")
        #expect(card.badge == "24%")
    }
}
