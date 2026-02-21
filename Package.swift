// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "ARPlaneDetection",
    platforms: [
        .iOS(.v26),
        .visionOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "ARPlaneDetection",
            targets: ["ARPlaneDetection"]
        )
    ],
    targets: [
        .target(
            name: "ARPlaneDetection",
            dependencies: []
        ),
        .testTarget(
            name: "ARPlaneDetectionTests",
            dependencies: ["ARPlaneDetection"]
        )
    ]
)
