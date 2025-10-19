import XCTest
@testable import PixooCore

final class ClusteringTests: XCTestCase {
    func testGroupDuplicates() throws {
        // Create 3 features with similar pHashes (duplicates)
        let features = [
            Feature(assetID: "1", pHash: 0x0000000000000000, laplacianVariance: 100, entropy: 5.0, visionFeaturePrint: nil, colorAnalysis: nil),
            Feature(assetID: "2", pHash: 0x0000000000000001, laplacianVariance: 120, entropy: 5.1, visionFeaturePrint: nil, colorAnalysis: nil),
            Feature(assetID: "3", pHash: 0x0000000000000003, laplacianVariance: 110, entropy: 5.2, visionFeaturePrint: nil, colorAnalysis: nil)
        ]

        let assets: [String: Asset] = [
            "1": Asset(id: "1", creationDate: Date(), modificationDate: nil, width: 1000, height: 1000, fileSize: 500_000, mediaType: .image, isFavorite: false, burstIdentifier: nil),
            "2": Asset(id: "2", creationDate: Date(), modificationDate: nil, width: 1200, height: 1200, fileSize: 600_000, mediaType: .image, isFavorite: false, burstIdentifier: nil),
            "3": Asset(id: "3", creationDate: Date(), modificationDate: nil, width: 1100, height: 1100, fileSize: 550_000, mediaType: .image, isFavorite: false, burstIdentifier: nil)
        ]

        let groups = Clustering.groupFeatures(features, assets: assets, config: .default)

        XCTAssertEqual(groups.count, 1, "Should create 1 group for duplicates")
        XCTAssertEqual(groups.first?.type, .duplicate)
        XCTAssertEqual(groups.first?.members.count, 3)
    }

    func testAutoSelection() throws {
        // Higher resolution should be kept
        let features = [
            Feature(assetID: "low", pHash: 0x0000000000000000, laplacianVariance: 100, entropy: 5.0, visionFeaturePrint: nil, colorAnalysis: nil),
            Feature(assetID: "high", pHash: 0x0000000000000001, laplacianVariance: 100, entropy: 5.0, visionFeaturePrint: nil, colorAnalysis: nil)
        ]

        let assets: [String: Asset] = [
            "low": Asset(id: "low", creationDate: Date(), modificationDate: nil, width: 800, height: 600, fileSize: 100_000, mediaType: .image, isFavorite: false, burstIdentifier: nil),
            "high": Asset(id: "high", creationDate: Date(), modificationDate: nil, width: 1920, height: 1080, fileSize: 300_000, mediaType: .image, isFavorite: false, burstIdentifier: nil)
        ]

        let groups = Clustering.groupFeatures(features, assets: assets, config: .default)

        XCTAssertEqual(groups.count, 1)
        let bestMember = groups.first?.bestMember
        XCTAssertEqual(bestMember?.id, "high", "Higher resolution should be kept")
        XCTAssertTrue(bestMember?.shouldKeep ?? false)
    }

    func testBurstGrouping() throws {
        let now = Date()
        let assets = [
            Asset(id: "1", creationDate: now, modificationDate: nil, width: 1000, height: 1000, fileSize: 100_000, mediaType: .image, isFavorite: false, burstIdentifier: "burst1"),
            Asset(id: "2", creationDate: now.addingTimeInterval(0.5), modificationDate: nil, width: 1000, height: 1000, fileSize: 100_000, mediaType: .image, isFavorite: false, burstIdentifier: "burst1"),
            Asset(id: "3", creationDate: now.addingTimeInterval(1.0), modificationDate: nil, width: 1000, height: 1000, fileSize: 100_000, mediaType: .image, isFavorite: false, burstIdentifier: "burst1")
        ]

        let groups = Clustering.groupBursts(assets, config: .default)

        XCTAssertEqual(groups.count, 1, "Should group burst photos with same identifier")
        XCTAssertEqual(groups.first?.count, 3)
    }

    func testBurstTimestampGrouping() throws {
        let now = Date()
        let assets = [
            Asset(id: "1", creationDate: now, modificationDate: nil, width: 1000, height: 1000, fileSize: 100_000, mediaType: .image, isFavorite: false, burstIdentifier: nil),
            Asset(id: "2", creationDate: now.addingTimeInterval(1.0), modificationDate: nil, width: 1000, height: 1000, fileSize: 100_000, mediaType: .image, isFavorite: false, burstIdentifier: nil),
            Asset(id: "3", creationDate: now.addingTimeInterval(5.0), modificationDate: nil, width: 1000, height: 1000, fileSize: 100_000, mediaType: .image, isFavorite: false, burstIdentifier: nil)
        ]

        let groups = Clustering.groupBursts(assets, config: .default)

        XCTAssertEqual(groups.count, 1, "Should group photos within 2s window")
        XCTAssertEqual(groups.first?.count, 2, "Third photo is >2s away")
    }
}
