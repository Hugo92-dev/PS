// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PhotoSweeperCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "PhotoSweeperCore",
            targets: ["PhotoSweeperCore"]),
    ],
    dependencies: [
        // No external dependencies - 100% on-device
    ],
    targets: [
        .target(
            name: "PhotoSweeperCore",
            dependencies: [],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "PhotoSweeperCoreTests",
            dependencies: ["PhotoSweeperCore"]),
    ]
)
