// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "GoncharKit",
  platforms: [
    .visionOS(.v1)
  ],
  products: [
    .library(
      name: "GoncharKit",
      targets: ["GoncharKit"]),
  ],
  targets: [
    .target(
      name: "GoncharKit"),
    .testTarget(
      name: "GoncharKitTests",
      dependencies: ["GoncharKit"]),
  ]
)
