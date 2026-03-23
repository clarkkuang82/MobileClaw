// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MCNetworking",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "MCNetworking", targets: ["MCNetworking"]),
    ],
    dependencies: [
        .package(path: "../MCCore"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess", from: "4.2.2"),
    ],
    targets: [
        .target(
            name: "MCNetworking",
            dependencies: ["MCCore", "KeychainAccess"]
        ),
        .testTarget(
            name: "MCNetworkingTests",
            dependencies: ["MCNetworking"]
        ),
    ]
)
