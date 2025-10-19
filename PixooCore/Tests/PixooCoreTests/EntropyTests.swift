import XCTest
@testable import PixooCore

final class EntropyTests: XCTestCase {
    func testUniformImageLowEntropy() throws {
        // Uniform image (all same color) should have entropy ≈ 0
        let pixels = [UInt8](repeating: 128, count: 256)
        let entropy = Entropy.compute(imageData: pixels, bins: 8)

        XCTAssertLessThan(entropy, 0.5, "Uniform image should have near-zero entropy")
        XCTAssertTrue(Entropy.isFlat(entropy, threshold: 3.0))
    }

    func testDiverseImageHighEntropy() throws {
        // Image with diverse values should have high entropy
        var pixels = [UInt8]()
        for i in 0..<256 {
            pixels.append(UInt8(i))
        }

        let entropy = Entropy.compute(imageData: pixels, bins: 8)

        XCTAssertGreaterThan(entropy, 2.5, "Diverse image should have high entropy")
        XCTAssertFalse(Entropy.isFlat(entropy, threshold: 3.0))
    }

    func testEntropyBinScaling() throws {
        let pixels = Array(0..<256).map { UInt8($0) }

        let entropy8 = Entropy.compute(imageData: pixels, bins: 8)
        let entropy16 = Entropy.compute(imageData: pixels, bins: 16)

        XCTAssertGreaterThan(entropy8, 0)
        XCTAssertGreaterThan(entropy16, 0)
        // More bins = potentially higher entropy
        XCTAssertGreaterThanOrEqual(entropy16, entropy8)
    }

    func testUniformityDetection() throws {
        // Mostly uniform with 10% noise
        var pixels = [UInt8](repeating: 100, count: 900)
        pixels += [UInt8](repeating: 200, count: 100)

        let uniformity = Entropy.computeUniformity(imageData: pixels, tolerance: 10)

        XCTAssertGreaterThan(uniformity, 0.85, "Should detect high uniformity (~90%)")
    }

    func testUniformityDiverseImage() throws {
        // Evenly distributed colors
        var pixels = [UInt8]()
        for i in 0..<256 {
            for _ in 0..<4 {
                pixels.append(UInt8(i))
            }
        }

        let uniformity = Entropy.computeUniformity(imageData: pixels, tolerance: 5)

        XCTAssertLessThan(uniformity, 0.1, "Diverse image should have low uniformity")
    }
}
