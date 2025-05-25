// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JupSwift",
    platforms: [
        .iOS(.v13),
        .macOS(.v11),
        .watchOS(.v6),
        .tvOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "JupSwift",
            targets: ["JupSwift"]),
    ],
    dependencies: [
            .package(url: "https://github.com/attaswift/BigInt.git", from: "5.3.0"),
            .package(url: "https://github.com/jauyou/Clibsodium.git", from: "1.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "JupSwift",
            dependencies: ["BigInt", "Clibsodium"],
            resources: [
                .process("Resources/english.txt")
            ]
        ),
        .testTarget(
            name: "JupSwiftTests",
            dependencies: ["JupSwift"]
        ),
    ]
)
