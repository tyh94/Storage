// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Storage",
    platforms: [.iOS(.v16)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Storage",
            targets: ["Storage"]),
    ],
    dependencies: [
        .package(url: "git@github.com:yandexmobile/yandex-login-sdk-ios.git", from: "3.0.2"),
        .package(url: "git@github.com:weichsel/ZIPFoundation.git", from: "0.9.19"),
        
        .package(url: "git@github.com:google/GoogleSignIn-iOS.git", from: "9.0.0"),
        .package(url: "git@github.com:google/gtm-session-fetcher.git", from: "3.3.0"),
        .package(url: "git@github.com:google/GoogleUtilities.git", from: "8.1.0"),
        .package(url: "git@github.com:google/promises.git", from: "2.4.0"),
        .package(url: "git@github.com:openid/AppAuth-iOS.git", from: "2.0.0"),
        .package(url: "git@github.com:google/app-check.git", from: "11.2.0"),
        .package(url: "git@github.com:google/GTMAppAuth.git", from: "5.0.0"),
        
        .package(
            path: "../MKVNetwork"
        ),
        .package(
            path: "../Dependencies"
        ),
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
                .product(name: "Dependencies", package: "Dependencies"),
                
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
            ]
        ),
    ]
)
