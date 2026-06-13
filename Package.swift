// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DoctorAddressVerifier",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "DoctorAddressVerifier", targets: ["DoctorAddressVerifier"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "DoctorAddressVerifier",
            path: "Sources/DoctorAddressVerifier"
        )
    ]
)
