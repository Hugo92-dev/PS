import XCTest
@testable import PixooCore

final class SweeperTests: XCTestCase {
    func testConfigurationDefaults() throws {
        let config = SweeperConfig.default

        XCTAssertEqual(config.duplicateHammingThreshold, 8)
        XCTAssertEqual(config.similarHammingMin, 9)
        XCTAssertEqual(config.similarHammingMax, 18)
        XCTAssertEqual(config.blurThreshold, 60.0)
        XCTAssertEqual(config.flatEntropyThreshold, 3.0)
    }

    func testConfigurationConservative() throws {
        let config = SweeperConfig.conservative

        XCTAssertLessThan(config.duplicateHammingThreshold, SweeperConfig.default.duplicateHammingThreshold)
        XCTAssertGreaterThan(config.blurThreshold, SweeperConfig.default.blurThreshold)
    }

    func testEstimatedSavings() throws {
        let sweeper = Sweeper(config: .default)

        let assets: [String: Asset] = [
            "1": Asset(id: "1", creationDate: Date(), modificationDate: nil, width: 1000, height: 1000, fileSize: 1_000_000, mediaType: .image, isFavorite: false, burstIdentifier: nil),
            "2": Asset(id: "2", creationDate: Date(), modificationDate: nil, width: 1000, height: 1000, fileSize: 500_000, mediaType: .image, isFavorite: false, burstIdentifier: nil),
            "3": Asset(id: "3", creationDate: Date(), modificationDate: nil, width: 1000, height: 1000, fileSize: 2_000_000, mediaType: .image, isFavorite: false, burstIdentifier: nil)
        ]

        let groups = [
            Group(type: .duplicate, members: [
                GroupMember(id: "1", fileSize: 1_000_000, resolution: 1_000_000, sharpness: 100, creationDate: Date(), shouldKeep: true, isSelected: false),
                GroupMember(id: "2", fileSize: 500_000, resolution: 1_000_000, sharpness: 90, creationDate: Date(), shouldKeep: false, isSelected: true)
            ])
        ]

        let heuristics = [
            HeuristicResult(assetID: "3", labels: [.blur], confidence: 0.8, reason: "Floue", isSelected: true)
        ]

        let savings = sweeper.estimatedSavings(groups: groups, heuristics: heuristics, assets: assets)

        // Should save: 500,000 (from group) + 2,000,000 (from heuristic) = 2,500,000
        XCTAssertEqual(savings, 2_500_000)
    }

    func testFormatBytes() throws {
        XCTAssertEqual(Sweeper.formatBytes(500), "500 Ko")
        XCTAssertEqual(Sweeper.formatBytes(1_048_576), "1.0 Mo")
        XCTAssertEqual(Sweeper.formatBytes(1_073_741_824), "1.00 Go")
        XCTAssertEqual(Sweeper.formatBytes(2_500_000_000), "2.33 Go")
    }

    func testHeuristicClassification() throws {
        let sweeper = Sweeper(config: .default)

        // Blurry image
        let blurryFeature = Feature(
            assetID: "blur",
            pHash: 0,
            laplacianVariance: 30.0, // Below threshold
            entropy: 5.0,
            visionFeaturePrint: nil,
            colorAnalysis: nil
        )

        let asset = Asset(
            id: "blur",
            creationDate: Date(),
            modificationDate: nil,
            width: 1000,
            height: 1000,
            fileSize: 500_000,
            mediaType: .image,
            isFavorite: false,
            burstIdentifier: nil
        )

        let result = sweeper.classify(feature: blurryFeature, asset: asset)

        XCTAssertNotNil(result)
        XCTAssertTrue(result?.labels.contains(.blur) ?? false)
        XCTAssertGreaterThan(result?.confidence ?? 0, 0.5)
    }

    func testStatistics() throws {
        let sweeper = Sweeper(config: .default)
        let stats = sweeper.getStatistics()

        XCTAssertEqual(stats.totalFeaturesExtracted, 0)
        XCTAssertEqual(stats.averageSharpness, 0.0)
        XCTAssertEqual(stats.averageEntropy, 0.0)
    }
}
