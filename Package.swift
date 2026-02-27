// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "ACRouting",
    platforms: [
        .iOS(.v16),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "ACRouting",
            targets: ["ACRouting"]
        ),
    ],
    targets: [
        .target(
            name: "ACRouting"
        ),
        .testTarget(
            name: "ACRoutingTests",
            dependencies: ["ACRouting"]
        ),
    ]
)
