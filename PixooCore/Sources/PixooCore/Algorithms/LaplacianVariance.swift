import Foundation
import CoreGraphics

/// Laplacian Variance computation for blur/sharpness detection
/// Higher variance = sharper image, Lower variance = blurrier image
public struct LaplacianVariance {
    /// Laplacian kernel (3x3 edge detection)
    private static let kernel: [[Double]] = [
        [ 0,  1,  0],
        [ 1, -4,  1],
        [ 0,  1,  0]
    ]

    /// Compute Laplacian variance from grayscale image data
    /// - Parameters:
    ///   - imageData: Raw grayscale pixel data (0-255)
    ///   - width: Image width
    ///   - height: Image height
    /// - Returns: Variance score (higher = sharper)
    public static func compute(imageData: [UInt8], width: Int, height: Int) -> Double {
        // Apply Laplacian kernel
        var laplacian = [Double]()
        laplacian.reserveCapacity((width - 2) * (height - 2))

        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                var sum = 0.0
                for ky in 0..<3 {
                    for kx in 0..<3 {
                        let pixelY = y + ky - 1
                        let pixelX = x + kx - 1
                        let pixelValue = Double(imageData[pixelY * width + pixelX])
                        sum += pixelValue * kernel[ky][kx]
                    }
                }
                laplacian.append(sum)
            }
        }

        // Compute variance
        return variance(laplacian)
    }

    /// Compute Laplacian variance from CGImage
    public static func compute(from cgImage: CGImage) -> Double? {
        guard let grayscale = convertToGrayscale(cgImage) else { return nil }
        return compute(
            imageData: grayscale.pixels,
            width: grayscale.width,
            height: grayscale.height
        )
    }

    /// Determine if image is blurry based on threshold
    /// - Parameters:
    ///   - variance: Laplacian variance score
    ///   - threshold: Threshold value (default: 60.0 for 512-1024px images)
    /// - Returns: True if blurry
    public static func isBlurry(_ variance: Double, threshold: Double = 60.0) -> Bool {
        return variance < threshold
    }

    // MARK: - Private Helpers

    private static func variance(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0.0 }

        let mean = values.reduce(0.0, +) / Double(values.count)
        let squaredDiffs = values.map { pow($0 - mean, 2) }
        return squaredDiffs.reduce(0.0, +) / Double(values.count)
    }

    private static func convertToGrayscale(_ cgImage: CGImage) -> (pixels: [UInt8], width: Int, height: Int)? {
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
        return (pixels, width, height)
    }
}
