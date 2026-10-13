// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "IronFiveWorkoutFlow",
    platforms: [.macOS(.v14)],
    products: [.library(name: "WorkoutFlow", targets: ["WorkoutFlow"])],
    targets: [
        .target(name: "WorkoutFlow", path: "Sources/Support"),
        .testTarget(name: "WorkoutFlowTests", dependencies: ["WorkoutFlow"], path: "Tests/WorkoutFlowTests")
    ]
)
