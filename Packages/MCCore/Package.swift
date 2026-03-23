// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MCCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "MCCore", targets: ["MCCore"]),
    ],
    targets: [
        .target(name: "MCCore"),
        .testTarget(name: "MCCoreTests", dependencies: ["MCCore"]),
    ]
)
