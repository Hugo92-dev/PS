import Foundation
import CoreGraphics

/// Perceptual Hash (pHash) implementation for image similarity detection
/// Generates a 64-bit hash based on Discrete Cosine Transform (DCT)
public struct PHash {
    private static let hashSize = 8 // 8x8 = 64 bits
    private static let resizeSize = 32 // DCT input size

    /// Compute 64-bit perceptual hash from image data
    /// - Parameter imageData: Raw grayscale pixel data (0-255)
    /// - Parameter width: Image width
    /// - Parameter height: Image height
    /// - Returns: 64-bit hash
    public static func compute(imageData: [UInt8], width: Int, height: Int) -> UInt64 {
        // 1. Resize to 32x32 (reduce detail, keep structure)
        let resized = resize(imageData, fromWidth: width, fromHeight: height, toSize: resizeSize)

        // 2. Compute DCT (Discrete Cosine Transform)
        let dct = computeDCT(resized, size: resizeSize)

        // 3. Extract top-left 8x8 (low frequencies)
        let lowFreq = extractLowFrequencies(dct, size: hashSize)

        // 4. Compute median
        let median = computeMedian(lowFreq)

        // 5. Generate 64-bit hash (1 if > median, 0 otherwise)
        return generateHash(lowFreq, median: median)
    }

    /// Compute pHash from CGImage
    public static func compute(from cgImage: CGImage) -> UInt64? {
        guard let grayscale = convertToGrayscale(cgImage) else { return nil }
        return compute(
            imageData: grayscale.pixels,
            width: grayscale.width,
            height: grayscale.height
        )
    }

    /// Compute Hamming distance between two hashes (number of differing bits)
    public static func hammingDistance(_ hash1: UInt64, _ hash2: UInt64) -> Int {
        let xor = hash1 ^ hash2
        return xor.nonzeroBitCount
    }

    // MARK: - Private Helpers

    private static func resize(_ data: [UInt8], fromWidth: Int, fromHeight: Int, toSize: Int) -> [Double] {
        var result = [Double](repeating: 0.0, count: toSize * toSize)
        let scaleX = Double(fromWidth) / Double(toSize)
        let scaleY = Double(fromHeight) / Double(toSize)

        for y in 0..<toSize {
            for x in 0..<toSize {
                let srcX = Int(Double(x) * scaleX)
                let srcY = Int(Double(y) * scaleY)
                let index = srcY * fromWidth + srcX
                result[y * toSize + x] = Double(data[index])
            }
        }
        return result
    }

    private static func computeDCT(_ data: [Double], size: Int) -> [Double] {
        var result = [Double](repeating: 0.0, count: size * size)

        for v in 0..<size {
            for u in 0..<size {
                var sum = 0.0
                for y in 0..<size {
                    for x in 0..<size {
                        let pixel = data[y * size + x]
                        let cosU = cos((2.0 * Double(x) + 1.0) * Double(u) * .pi / (2.0 * Double(size)))
                        let cosV = cos((2.0 * Double(y) + 1.0) * Double(v) * .pi / (2.0 * Double(size)))
                        sum += pixel * cosU * cosV
                    }
                }

                let cu = u == 0 ? 1.0 / sqrt(2.0) : 1.0
                let cv = v == 0 ? 1.0 / sqrt(2.0) : 1.0
                result[v * size + u] = 0.25 * cu * cv * sum
            }
        }
        return result
    }

    private static func extractLowFrequencies(_ dct: [Double], size: Int) -> [Double] {
        var result = [Double]()
        result.reserveCapacity(hashSize * hashSize)
        for y in 0..<hashSize {
            for x in 0..<hashSize {
                result.append(dct[y * 32 + x])
            }
        }
        return result
    }

    private static func computeMedian(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        let mid = sorted.count / 2
        if sorted.count % 2 == 0 {
            return (sorted[mid - 1] + sorted[mid]) / 2.0
        } else {
            return sorted[mid]
        }
    }

    private static func generateHash(_ values: [Double], median: Double) -> UInt64 {
        var hash: UInt64 = 0
        for (index, value) in values.enumerated() {
            if value > median {
                hash |= (1 << index)
            }
        }
        return hash
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
