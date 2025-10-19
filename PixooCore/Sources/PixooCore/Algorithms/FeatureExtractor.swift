import Foundation
import CoreGraphics

/// Orchestrates feature extraction from images
public struct FeatureExtractor {
    /// Extract all features from a CGImage
    /// - Parameters:
    ///   - cgImage: Source image
    ///   - assetID: Asset identifier
    ///   - includeVision: Whether to include Vision feature print (requires iOS runtime)
    /// - Returns: Feature vector
    public static func extract(
        from cgImage: CGImage,
        assetID: String,
        includeVision: Bool = false
    ) -> Feature? {
        // 1. Compute pHash
        guard let pHash = PHash.compute(from: cgImage) else { return nil }

        // 2. Compute Laplacian variance (sharpness)
        guard let laplacianVariance = LaplacianVariance.compute(from: cgImage) else { return nil }

        // 3. Compute entropy
        guard let entropy = Entropy.compute(from: cgImage, bins: 8) else { return nil }

        // 4. Analyze colors
        let colorAnalysis = ColorAnalyzer.analyze(from: cgImage)

        // 5. Vision feature print (optional, requires iOS runtime)
        // This will be computed by the app layer using VNImageRequestHandler
        let visionFeaturePrint: Data? = nil

        return Feature(
            assetID: assetID,
            pHash: pHash,
            laplacianVariance: laplacianVariance,
            entropy: entropy,
            visionFeaturePrint: visionFeaturePrint,
            colorAnalysis: colorAnalysis
        )
    }

    /// Extract features from raw pixel data (for testing)
    public static func extractFromPixels(
        grayscaleData: [UInt8],
        width: Int,
        height: Int,
        assetID: String
    ) -> Feature? {
        let pHash = PHash.compute(imageData: grayscaleData, width: width, height: height)
        let laplacianVariance = LaplacianVariance.compute(
            imageData: grayscaleData,
            width: width,
            height: height
        )
        let entropy = Entropy.compute(imageData: grayscaleData, bins: 8)

        return Feature(
            assetID: assetID,
            pHash: pHash,
            laplacianVariance: laplacianVariance,
            entropy: entropy,
            visionFeaturePrint: nil,
            colorAnalysis: nil
        )
    }
}
