// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MCAgents",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "MCAgents", targets: ["MCAgents"]),
    ],
    dependencies: [
        .package(path: "../MCCore"),
        .package(path: "../MCNetworking"),
        .package(path: "../MCPClient"),
    ],
    targets: [
        .target(
            name: "MCAgents",
            dependencies: ["MCCore", "MCNetworking", "MCPClient"]
        ),
        .testTarget(
            name: "MCAgentsTests",
            dependencies: ["MCAgents"]
        ),
    ]
)
