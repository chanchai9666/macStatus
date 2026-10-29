import Testing

@Suite("Package Initialization Tests")
struct PackageTests {
    @Test func testPackageTargetBuilds() {
        #expect(true)
    }
}
