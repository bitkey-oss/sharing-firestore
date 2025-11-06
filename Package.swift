// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "sharing-firestore",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v7),
  ],
  products: [
    .library(
      name: "SharingFirestore",
      targets: ["SharingFirestore"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.10.0"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.6.4"),
    .package(url: "https://github.com/pointfreeco/swift-sharing", from: "2.3.0"),
    .package(url: "https://github.com/pointfreeco/swift-identified-collections", from: "1.1.1")
  ],
  targets: [
    .target(
      name: "SharingFirestore",
      dependencies: [
        .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
        .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
        .product(name: "Sharing", package: "swift-sharing"),
        .product(name: "IdentifiedCollections", package: "swift-identified-collections"),
      ]
    ),
    .testTarget(
      name: "SharingFirestoreTests",
      dependencies: [
        "SharingFirestore",
        .product(name: "DependenciesTestSupport", package: "swift-dependencies"),
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)
