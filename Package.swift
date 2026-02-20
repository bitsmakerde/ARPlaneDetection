// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ARPlaneDetection",
    platforms: [
        .iOS(.v18),
        .visionOS(.v2),
        .macOS(.v14)
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
