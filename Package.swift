// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BottomShelfer",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        // The library product consumers link against. `BottomShelfer` exposes
        // the presentation controller, detents, layout configuration, and the
        // bundled logo asset.
        .library(
            name: "BottomShelfer",
            targets: ["BottomShelfer"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "BottomShelfer",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "BottomShelferTests",
            dependencies: ["BottomShelfer"]
        ),
    ]
)
