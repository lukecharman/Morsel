// swift-tools-version: 5.10

import PackageDescription

let package = Package(
  name: "CoreMorsel",
  platforms: [
    .iOS("26"),
    .watchOS("26")
  ],
  products: [
    .library(
      name: "CoreMorsel",
      targets: ["CoreMorsel"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/TelemetryDeck/SwiftSDK", from: "2.9.4")
  ],
  targets: [
    .target(
      name: "CoreMorsel",
      dependencies: [
        .product(name: "TelemetryDeck", package: "SwiftSDK")
      ]
    ),
    .testTarget(
      name: "CoreMorselTests",
      dependencies: ["CoreMorsel"]
    ),
  ]
)
