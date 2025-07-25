// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "Utilities",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "PieChart",
            type: .static,
            targets: ["PieChart"]),
    ],
    targets: [
        .target(
            name: "PieChart",
            dependencies: [],
            path: "Sources/PieChart"),
        .testTarget(
            name: "PieChartTests",
            dependencies: ["PieChart"],
            path: "Tests/PieChartTests"
        ),
    ]
)
