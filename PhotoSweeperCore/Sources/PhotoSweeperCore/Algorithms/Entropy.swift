import Foundation
import CoreGraphics

/// Entropy computation for detecting quasi-uniform backgrounds
/// Low entropy = low color/luminance diversity (flat background)
public struct Entropy {
    /// Compute entropy from grayscale image histogram
    /// - Parameters:
    ///   - imageData: Raw grayscale pixel data (0-255)
    ///   - bins: Number of histogram bins (default: 8)
    /// - Returns: Entropy value (0.0 to log2(bins))
    public static func compute(imageData: [UInt8], bins: Int = 8) -> Double {
        guard bins > 0 else { return 0.0 }

        // Build histogram
        var histogram = [Int](repeating: 0, count: bins)
        let binSize = 256 / bins

        for pixel in imageData {
            let binIndex = min(Int(pixel) / binSize, bins - 1)
            histogram[binIndex] += 1
        }

        // Compute entropy: H = -Σ(p * log2(p))
        let totalPixels = imageData.count
        var entropy = 0.0

        for count in histogram {
            guard count > 0 else { continue }
            let probability = Double(count) / Double(totalPixels)
            entropy -= probability * log2(probability)
        }

        return entropy
    }

    /// Compute entropy from CGImage
    public static func compute(from cgImage: CGImage, bins: Int = 8) -> Double? {
        guard let grayscale = convertToGrayscale(cgImage) else { return nil }
        return compute(imageData: grayscale, bins: bins)
    }

    /// Determine if image has flat/quasi-uniform background
    /// - Parameters:
    ///   - entropy: Entropy value
    ///   - threshold: Threshold (default: 3.0 for 8 bins)
    /// - Returns: True if flat
    public static func isFlat(_ entropy: Double, threshold: Double = 3.0) -> Bool {
        return entropy < threshold
    }

    /// Compute color uniformity percentage (dominant color coverage)
    /// - Parameters:
    ///   - imageData: Raw grayscale pixel data (0-255)
    ///   - tolerance: Color similarity tolerance (0-255)
    /// - Returns: Percentage of pixels matching dominant color (0.0 - 1.0)
    public static func computeUniformity(imageData: [UInt8], tolerance: Int = 10) -> Double {
        guard !imageData.isEmpty else { return 0.0 }

        // Find dominant color (mode)
        var histogram = [Int](repeating: 0, count: 256)
        for pixel in imageData {
            histogram[Int(pixel)] += 1
        }

        let dominantColor = histogram.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0

        // Count pixels within tolerance of dominant color
        let matchingPixels = imageData.filter { pixel in
            abs(Int(pixel) - dominantColor) <= tolerance
        }.count

        return Double(matchingPixels) / Double(imageData.count)
    }

    // MARK: - Private Helpers

    private static func convertToGrayscale(_ cgImage: CGImage) -> [UInt8]? {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerRow = width
        var pixels = [UInt8](repeating: 0, count: width * height)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return pixels
    }
}
