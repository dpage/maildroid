// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MailDroid",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MailDroid", targets: ["MailDroid"])
    ],
    targets: [
        .target(
            name: "MailDroidLib",
            path: "Maildroid/Sources",
            exclude: ["Config.template.swift"],
            resources: [
                .process("../Info.plist")
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Security"),
                .linkedFramework("AuthenticationServices"),
                .linkedFramework("ServiceManagement")
            ]
        ),
        .executableTarget(
            name: "MailDroid",
            dependencies: ["MailDroidLib"],
            path: "Maildroid/AppEntry"
        ),
        .testTarget(
            name: "MailDroidTests",
            dependencies: ["MailDroidLib"],
            path: "Tests/MailDroidTests"
        )
    ]
)
