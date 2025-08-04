// swift-tools-version: 5.10

import PackageDescription

let package = Package(
  name: "CoreMorsel",
  platforms: [
    .iOS("18"),
    .watchOS("11")
  ],
  products: [
    .library(
      name: "CoreMorsel",
      targets: ["CoreMorsel"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/TelemetryDeck/SwiftSDK", from: "2.9.4"),
    .package(url: "https://github.com/1998code/SwiftGlass", from: "1.8.0")
  ],
  targets: [
    .target(
      name: "CoreMorsel",
      dependencies: [
        .product(name: "TelemetryDeck", package: "SwiftSDK"),
        .product(name: "SwiftGlass", package: "SwiftGlass")
      ]
    ),
    .testTarget(
      name: "CoreMorselTests",
      dependencies: ["CoreMorsel"]
    ),
  ]
)
