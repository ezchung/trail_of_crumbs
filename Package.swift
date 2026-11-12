// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SourdoughApp",
    // Hummingbird requires macOS 14+ when building on a Mac. No effect on Linux.
    platforms: [.macOS(.v14)],
    dependencies: [
        // 2.27+ requires Swift 6.2. We're on 6.1.3 (see .swift-version), so cap below it.
        // After `swiftly install 6.2 && swiftly use 6.2`, change this to: from: "2.28.1"
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", "2.0.0"..<"2.27.0"),
    ],
    targets: [
        // Pure logic (recipes, math). No UI here, so it can be reused later by
        // a web server or an iOS app.
        .target(
            name: "SourdoughCore"),

        // The command-line app: `swift run SourdoughApp`
        .executableTarget(
            name: "SourdoughApp",
            dependencies: ["SourdoughCore"]),

        // The web app: `swift run SourdoughWeb`, then open http://localhost:8080
        .executableTarget(
            name: "SourdoughWeb",
            dependencies: [
                "SourdoughCore",
                .product(name: "Hummingbird", package: "hummingbird"),
            ]),

        // Tests for the logic, run with `swift test`.
        .testTarget(
            name: "SourdoughCoreTests",
            dependencies: ["SourdoughCore"]),
    ]
)
