// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "picoledbare4swift",
  targets: [
    .executableTarget(
      name: "Application",
      path: "Sources/Application",
      swiftSettings: [
        .enableExperimentalFeature("Volatile")
      ]
    )
  ]
)
