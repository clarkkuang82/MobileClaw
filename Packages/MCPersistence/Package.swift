// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MCPersistence",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "MCPersistence", targets: ["MCPersistence"]),
    ],
    dependencies: [
        .package(path: "../MCCore"),
    ],
    targets: [
        .target(
            name: "MCPersistence",
            dependencies: ["MCCore"]
        ),
        .testTarget(
            name: "MCPersistenceTests",
            dependencies: ["MCPersistence"]
        ),
    ]
)
