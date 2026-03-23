// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MCPClient",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "MCPClient", targets: ["MCPClient"]),
    ],
    dependencies: [
        .package(path: "../MCCore"),
    ],
    targets: [
        .target(
            name: "MCPClient",
            dependencies: ["MCCore"]
        ),
        .testTarget(
            name: "MCPClientTests",
            dependencies: ["MCPClient"]
        ),
    ]
)
