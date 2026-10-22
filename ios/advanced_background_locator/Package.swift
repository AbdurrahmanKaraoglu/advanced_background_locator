// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "advanced_background_locator",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "advanced-background-locator", targets: ["advanced_background_locator"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "advanced_background_locator",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ],
            cSettings: [
                // Lets the sources import the public headers with quotes, as with CocoaPods.
                .headerSearchPath("include/advanced_background_locator")
            ],
            linkerSettings: [
                .linkedFramework("CoreLocation")
            ]
        )
    ]
)
