// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "MacBookNotchTracker",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "MacBookNotchTracker",
            targets: ["MacBookNotchTracker"]
        )
    ],
    targets: [
        .executableTarget(
            name: "MacBookNotchTracker",
            path: "Sources/MacBookNotchTracker"
        )
    ]
)
