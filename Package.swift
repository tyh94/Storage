// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Storage",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Storage",
            targets: ["Storage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/yandexmobile/yandex-login-sdk-ios.git", from: "3.0.2"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.19"),
        
        .package(url: "https://github.com/google/GoogleSignIn-iOS.git", from: "9.1.0"),
        
        .package(url: "https://github.com/tyh94/MKVNetwork.git", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Storage",
            dependencies: [
                .product(name: "YandexLoginSDK", package: "yandex-login-sdk-ios"),
                .product(name: "ZIPFoundation", package: "ZIPFoundation"),
                .product(name: "MKVNetwork", package: "MKVNetwork"),
                
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
            ],
            resources: [
                .process("Resources")
            ]
        ),
    ]
)
