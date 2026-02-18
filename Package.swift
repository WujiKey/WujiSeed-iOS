// swift-tools-version:6.0
// WujiLib + WujiSeedTests as a standalone Swift Package
// Enables: swift test (native macOS, no simulator required)

import PackageDescription

let package = Package(
    name: "WujiSeedLib",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/WujiKey/F9Grid.git", exact: Version(1, 2, 0)),
        .package(url: "https://github.com/jedisct1/swift-sodium", exact: Version(0, 9, 1)),
    ],
    targets: [
        .target(
            name: "WujiSeed",
            dependencies: [
                .product(name: "F9Grid", package: "F9Grid"),
                .product(name: "Sodium", package: "swift-sodium"),
            ],
            path: "WujiSeed/WujiLib"
        ),
        .testTarget(
            name: "WujiSeedTests",
            dependencies: ["WujiSeed"],
            path: "WujiSeedTests",
            resources: [
                .process("GoldenVectors")
            ]
        )
    ]
)
