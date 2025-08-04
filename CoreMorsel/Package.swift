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
  targets: [
    .target(
      name: "CoreMorsel"
    ),
    .testTarget(
      name: "CoreMorselTests",
      dependencies: ["CoreMorsel"]
    ),
  ]
)
