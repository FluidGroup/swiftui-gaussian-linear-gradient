// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "swiftui-gaussian-linear-gradient",
  platforms: [
    .iOS(.v18),
    .macOS(.v15),
  ],
  products: [
    .library(
      name: "GaussianLinearGradient",
      targets: ["GaussianLinearGradient"]
    ),
  ],
  targets: [
    .target(
      name: "GaussianLinearGradient"
    ),
    .testTarget(
      name: "GaussianLinearGradientTests",
      dependencies: ["GaussianLinearGradient"]
    ),
  ],
  swiftLanguageModes: [.v6]
)
