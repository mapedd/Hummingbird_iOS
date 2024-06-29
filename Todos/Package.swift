// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Todos",
  platforms: [.macOS(.v14)],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(
      name: "TodosCore",
      targets: ["TodosCore"]
    ),
    .executable(
      name: "TodosServer",
      targets: ["TodosServer"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
    .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0-alpha.1"),
    .package(url: "https://github.com/apple/swift-testing.git", branch: "main"),
    .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.21.0"),
    .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.9.0")
  ],
  targets: [
    .executableTarget(
      name: "TodosServer",
      dependencies: [
        "TodosCore"
      ]
    ),
    .executableTarget(
      name: "TodosTester",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "AsyncHTTPClient", package: "async-http-client"),
        "TodosCore"
      ]
    ),
    .target(
      name: "TodosCore",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "Hummingbird", package: "hummingbird"),
        .product(name: "PostgresNIO", package: "postgres-nio")
      ]
    ),
    .testTarget(
      name: "TodosTests",
      dependencies: [
        "TodosCore",
        .product(name: "Hummingbird", package: "hummingbird"),
        .product(name: "HummingbirdTesting", package: "hummingbird"),
        .product(name: "Testing", package: "swift-testing")
      ]
    )
  ]
)
