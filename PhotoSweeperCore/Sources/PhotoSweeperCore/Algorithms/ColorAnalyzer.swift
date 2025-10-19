import Foundation
import CoreGraphics

/// Color analysis for heuristic detection (black, white, skin tone)
public struct ColorAnalyzer {
    /// Analyze color properties from CGImage
    public static func analyze(from cgImage: CGImage) -> ColorAnalysis? {
        guard let rgbaData = convertToRGBA(cgImage) else { return nil }

        let totalPixels = rgbaData.count / 4
        var luminanceSum = 0.0
        var skinTonePixels = 0
        var luminanceValues = [Double]()
        luminanceValues.reserveCapacity(totalPixels)

        for i in stride(from: 0, to: rgbaData.count, by: 4) {
            let r = Double(rgbaData[i]) / 255.0
            let g = Double(rgbaData[i + 1]) / 255.0
            let b = Double(rgbaData[i + 2]) / 255.0

            // Compute luminance (ITU-R BT.601)
            let luminance = 0.299 * r + 0.587 * g + 0.114 * b
            luminanceSum += luminance
            luminanceValues.append(luminance)

            // Check if pixel is skin tone (HSV-based detection)
            if isSkinTone(r: r, g: g, b: b) {
                skinTonePixels += 1
            }
        }

        let meanLuminance = luminanceSum / Double(totalPixels)
        let luminanceVariance = variance(luminanceValues, mean: meanLuminance)
        let skinTonePercentage = Double(skinTonePixels) / Double(totalPixels)

        // Count dominant colors (simplified: count bins with >1% coverage)
        let dominantColorCount = countDominantColors(rgbaData)

        return ColorAnalysis(
            meanLuminance: meanLuminance,
            luminanceVariance: luminanceVariance,
            skinTonePercentage: skinTonePercentage,
            dominantColorCount: dominantColorCount
        )
    }

    // MARK: - Private Helpers

    /// Detect skin tone using HSV color space
    /// H: 0-50° (red-yellow), S: 0.23-0.68, V: 0.35-1.0
    private static func isSkinTone(r: Double, g: Double, b: Double) -> Bool {
        let hsv = rgbToHSV(r: r, g: g, b: b)

        // Skin tone heuristic (empirical values)
        let hue = hsv.h
        let saturation = hsv.s
        let value = hsv.v

        return (hue >= 0 && hue <= 50) &&
               (saturation >= 0.23 && saturation <= 0.68) &&
               (value >= 0.35 && value <= 1.0)
    }

    private static func rgbToHSV(r: Double, g: Double, b: Double) -> (h: Double, s: Double, v: Double) {
        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        let delta = maxC - minC

        // Value
        let v = maxC

        // Saturation
        let s = maxC == 0 ? 0 : delta / maxC

        // Hue
        var h = 0.0
        if delta != 0 {
            if maxC == r {
                h = 60 * ((g - b) / delta).truncatingRemainder(dividingBy: 6)
            } else if maxC == g {
                h = 60 * ((b - r) / delta + 2)
            } else {
                h = 60 * ((r - g) / delta + 4)
            }
        }
        if h < 0 {
            h += 360
        }

        return (h, s, v)
    }

    private static func variance(_ values: [Double], mean: Double) -> Double {
        guard !values.isEmpty else { return 0.0 }
        let squaredDiffs = values.map { pow($0 - mean, 2) }
        return squaredDiffs.reduce(0.0, +) / Double(values.count)
    }

    private static func countDominantColors(_ rgbaData: [UInt8]) -> Int {
        // Simplified: quantize to 64 bins (4x4x4 RGB cube)
        var colorCounts = [Int: Int]()
        let binSize = 64 // 256 / 4

        for i in stride(from: 0, to: rgbaData.count, by: 4) {
            let r = Int(rgbaData[i]) / binSize
            let g = Int(rgbaData[i + 1]) / binSize
            let b = Int(rgbaData[i + 2]) / binSize
            let colorKey = r * 16 + g * 4 + b
            colorCounts[colorKey, default: 0] += 1
        }

        let totalPixels = rgbaData.count / 4
        let threshold = Int(Double(totalPixels) * 0.01) // 1% coverage

        return colorCounts.values.filter { $0 >= threshold }.count
    }

    private static func convertToRGBA(_ cgImage: CGImage) -> [UInt8]? {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        var pixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return pixels
    }
}
