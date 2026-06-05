// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "MacBookNotchTracker",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "MacBookNotchTrackerSupport",
            targets: ["MacBookNotchTrackerSupport"]
        )
    ],
    targets: [
        .target(
            name: "MacBookNotchTrackerSupport",
            path: "Sources/MacBookNotchTracker",
            exclude: [
                "App/MacBookNotchTrackerApp.swift"
            ]
        )
    ]
)
