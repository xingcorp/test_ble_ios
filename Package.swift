// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BeaconAttendance",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)  // Add macOS support for command line build
    ],
    products: [
        .library(
            name: "BeaconAttendanceCore",
            targets: ["BeaconAttendanceCore"]
        ),
        .library(
            name: "BeaconAttendanceFeatures",
            targets: ["BeaconAttendanceFeatures"]
        )
    ],
    dependencies: [
        // Add external dependencies here if needed
    ],
    targets: [
        .target(
            name: "BeaconAttendanceCore",
            dependencies: [],
            path: "Sources/Core"
        ),
        .target(
            name: "BeaconAttendanceFeatures",
            dependencies: ["BeaconAttendanceCore"],
            path: "Sources/Features"
        ),
        .target(
            name: "BeaconAttendanceApp",
            dependencies: [
                "BeaconAttendanceCore",
                "BeaconAttendanceFeatures"
            ],
            path: "Sources/App"
        ),
        .testTarget(
            name: "BeaconAttendanceCoreTests",
            dependencies: ["BeaconAttendanceCore"],
            path: "Tests/Unit"
        )
    ]
)
