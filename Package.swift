// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacStatusApp",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MacStatusApp", targets: ["MacStatusApp"])
    ],
    targets: [
        .executableTarget(
            name: "MacStatusApp",
            path: "Sources/MacStatusApp"
        ),
        .testTarget(
            name: "MacStatusAppTests",
            dependencies: ["MacStatusApp"],
            path: "Tests/MacStatusAppTests"
        )
    ]
)
