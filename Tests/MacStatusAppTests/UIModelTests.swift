import Testing
@testable import MacStatusApp

@Suite("UI Gauge Geometry Tests")
struct UIModelTests {
    @Test func testRingAngleMath() {
        #expect(RingMath.trimFraction(percentage: 0.0) == 0.0)
        #expect(RingMath.trimFraction(percentage: 50.0) == 0.5)
        #expect(RingMath.trimFraction(percentage: 100.0) == 1.0)
        #expect(RingMath.trimFraction(percentage: -10.0) == 0.0)
        #expect(RingMath.trimFraction(percentage: 120.0) == 1.0)
    }
}
