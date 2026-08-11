// swift-tools-version: 6.2
import PackageDescription

// The shared creature layer: everything needed to draw a yolkling and reason
// about its identity, worn cosmetics and care model — and nothing else. Both the
// iOS app and the watch app depend on this product; iOS-only concerns
// (RevenueCat, Screen Time, HealthKit, Supabase) must stay OUT of this package
// so the watch build never sees them. See Packages/YolklingCore/README.md.
//
// The swiftSettings mirror the app targets' build settings in project.yml
// (SWIFT_DEFAULT_ACTOR_ISOLATION: MainActor, SWIFT_APPROACHABLE_CONCURRENCY: YES)
// so moving a file across this boundary never changes how it compiles.
let package = Package(
    name: "YolklingCore",
    platforms: [
        .iOS(.v18),
        .watchOS(.v11),
    ],
    products: [
        .library(name: "YolklingCore", targets: ["YolklingCore"]),
    ],
    targets: [
        .target(
            name: "YolklingCore",
            swiftSettings: [
                .defaultIsolation(MainActor.self),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
                .enableUpcomingFeature("InferIsolatedConformances"),
            ]
        ),
    ]
)
