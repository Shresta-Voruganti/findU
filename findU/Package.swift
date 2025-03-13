// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "findU",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "findU",
            targets: ["findU"]),
    ],
    dependencies: [
        // Firebase dependencies
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0"),
        
        // Image handling
        .package(url: "https://github.com/kean/Nuke.git", from: "12.0.0"),
        
        // Networking
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.0.0"),
        
        // SwiftUI helpers
        .package(url: "https://github.com/siteline/swiftui-introspect.git", from: "1.0.0"),
        
        // Keyboard handling
        .package(url: "https://github.com/michaelhenry/IQKeyboardManager.Swift.git", from: "6.5.0"),
    ],
    targets: [
        .target(
            name: "findU",
            dependencies: [
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
                .product(name: "FirebasePerformance", package: "firebase-ios-sdk"),
                .product(name: "Nuke", package: "Nuke"),
                .product(name: "NukeUI", package: "Nuke"),
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "SwiftUIIntrospect", package: "swiftui-introspect"),
                .product(name: "IQKeyboardManagerSwift", package: "IQKeyboardManager.Swift"),
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "findUTests",
            dependencies: ["findU"],
            path: "Tests"
        ),
    ]
) 