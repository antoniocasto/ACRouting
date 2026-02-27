// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ACRouting",
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
