import XCTest
@testable import PhotoSweeperCore

final class PHashTests: XCTestCase {
    func testPHashIdenticalImages() throws {
        // Create two identical 8x8 test images
        let pixels = [UInt8](repeating: 128, count: 64)

        let hash1 = PHash.compute(imageData: pixels, width: 8, height: 8)
        let hash2 = PHash.compute(imageData: pixels, width: 8, height: 8)

        XCTAssertEqual(hash1, hash2, "Identical images should have identical hashes")
    }

    func testPHashDifferentImages() throws {
        let pixels1 = [UInt8](repeating: 50, count: 64)
        let pixels2 = [UInt8](repeating: 200, count: 64)

        let hash1 = PHash.compute(imageData: pixels1, width: 8, height: 8)
        let hash2 = PHash.compute(imageData: pixels2, width: 8, height: 8)

        XCTAssertNotEqual(hash1, hash2, "Different images should have different hashes")
    }

    func testHammingDistance() throws {
        let hash1: UInt64 = 0b0000000000000000000000000000000000000000000000000000000000000000
        let hash2: UInt64 = 0b0000000000000000000000000000000000000000000000000000000000000001
        let hash3: UInt64 = 0b1111111111111111111111111111111111111111111111111111111111111111

        XCTAssertEqual(PHash.hammingDistance(hash1, hash1), 0)
        XCTAssertEqual(PHash.hammingDistance(hash1, hash2), 1)
        XCTAssertEqual(PHash.hammingDistance(hash1, hash3), 64)
    }

    func testPHashGradientPattern() throws {
        // Create a simple gradient (dark to light)
        var pixels = [UInt8]()
        for y in 0..<16 {
            for x in 0..<16 {
                pixels.append(UInt8((x + y) * 8))
            }
        }

        let hash = PHash.compute(imageData: pixels, width: 16, height: 16)
        XCTAssertNotEqual(hash, 0, "Hash should not be zero for gradient")
    }

    func testPHashDuplicateDetection() throws {
        // Two very similar images (1 pixel difference)
        var pixels1 = [UInt8](repeating: 128, count: 256)
        var pixels2 = pixels1
        pixels2[0] = 130

        let hash1 = PHash.compute(imageData: pixels1, width: 16, height: 16)
        let hash2 = PHash.compute(imageData: pixels2, width: 16, height: 16)

        let distance = PHash.hammingDistance(hash1, hash2)
        XCTAssertLessThanOrEqual(distance, 8, "Very similar images should have Hamming distance ≤ 8")
    }
}
