// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PixooCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "PixooCore",
            targets: ["PixooCore"]),
    ],
    dependencies: [
        // No external dependencies - 100% on-device
    ],
    targets: [
        .target(
            name: "PixooCore",
            dependencies: [],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "PixooCoreTests",
            dependencies: ["PixooCore"]),
    ]
)
