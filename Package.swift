// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FinancialTracker",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "FinancialTracker",
            targets: ["FinancialTracker"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/airbnb/lottie-ios.git",
            from: "4.0.0"
        ),
        .package(
            url: "https://github.com/divkit/divkit-ios",
            from: "32.6.0"
        )
    ],
    targets: [
        .target(
            name: "FinancialTracker",
            dependencies: [
                .product(name: "Lottie", package: "lottie-ios"),
                .product(name: "DivKit", package: "divkit-ios")
            ],
            path: "FinancialTracker/FinancialTracker",
            resources: [
                .process("Resources"),
                .process("Assets.xcassets")
            ]
        ),
        .testTarget(
            name: "FinancialTrackerTests",
            dependencies: ["FinancialTracker"],
            path: "FinancialTrackerTests"
        ),
    ]
) 