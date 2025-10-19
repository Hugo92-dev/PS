import XCTest
@testable import PhotoSweeperCore

final class LaplacianVarianceTests: XCTestCase {
    func testUniformImageLowVariance() throws {
        // Uniform gray image (no edges) should have low variance
        let pixels = [UInt8](repeating: 128, count: 100)
        let variance = LaplacianVariance.compute(imageData: pixels, width: 10, height: 10)

        XCTAssertLessThan(variance, 10.0, "Uniform image should have very low Laplacian variance")
        XCTAssertTrue(LaplacianVariance.isBlurry(variance), "Uniform image should be classified as blurry")
    }

    func testCheckerboardHighVariance() throws {
        // Checkerboard pattern (many edges) should have high variance
        var pixels = [UInt8]()
        for y in 0..<20 {
            for x in 0..<20 {
                pixels.append((x + y) % 2 == 0 ? 0 : 255)
            }
        }

        let variance = LaplacianVariance.compute(imageData: pixels, width: 20, height: 20)

        XCTAssertGreaterThan(variance, 100.0, "Checkerboard should have high Laplacian variance")
        XCTAssertFalse(LaplacianVariance.isBlurry(variance), "Sharp checkerboard should not be blurry")
    }

    func testGradientMediumVariance() throws {
        // Smooth gradient should have medium variance
        var pixels = [UInt8]()
        for y in 0..<16 {
            for x in 0..<16 {
                pixels.append(UInt8((x + y) * 8))
            }
        }

        let variance = LaplacianVariance.compute(imageData: pixels, width: 16, height: 16)

        XCTAssertGreaterThan(variance, 10.0, "Gradient should have some variance")
        XCTAssertLessThan(variance, 500.0, "Gradient should not have extreme variance")
    }

    func testBlurDetectionThreshold() throws {
        let sharpVariance = 150.0
        let blurryVariance = 30.0

        XCTAssertFalse(LaplacianVariance.isBlurry(sharpVariance, threshold: 60.0))
        XCTAssertTrue(LaplacianVariance.isBlurry(blurryVariance, threshold: 60.0))
    }
}
