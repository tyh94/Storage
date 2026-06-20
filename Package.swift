// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Storage",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "Storage",
            targets: ["Storage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.19"),
    ],
    targets: [
        .target(
            name: "Storage",
            dependencies: [
                .product(name: "ZIPFoundation", package: "ZIPFoundation"),
            ],
            resources: [
                .process("Resources")
            ]
        ),
    ]
)
