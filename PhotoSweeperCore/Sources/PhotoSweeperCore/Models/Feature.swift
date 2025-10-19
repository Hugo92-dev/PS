import Foundation

/// Feature vector extracted from an asset
public struct Feature: Codable, Hashable {
    public let assetID: String
    public let pHash: UInt64 // Perceptual hash (64-bit)
    public let laplacianVariance: Double // Sharpness score
    public let entropy: Double // Color/luminance entropy (0-8 for 8 bins)
    public let visionFeaturePrint: Data? // VNFeaturePrintObservation descriptor (optional)
    public let colorAnalysis: ColorAnalysis?

    public init(
        assetID: String,
        pHash: UInt64,
        laplacianVariance: Double,
        entropy: Double,
        visionFeaturePrint: Data?,
        colorAnalysis: ColorAnalysis?
    ) {
        self.assetID = assetID
        self.pHash = pHash
        self.laplacianVariance = laplacianVariance
        self.entropy = entropy
        self.visionFeaturePrint = visionFeaturePrint
        self.colorAnalysis = colorAnalysis
    }
}

/// Color analysis for heuristic detection
public struct ColorAnalysis: Codable, Hashable {
    public let meanLuminance: Double // 0.0 - 1.0
    public let luminanceVariance: Double
    public let skinTonePercentage: Double // 0.0 - 1.0 (for finger detection)
    public let dominantColorCount: Int // Distinct colors above threshold

    public init(
        meanLuminance: Double,
        luminanceVariance: Double,
        skinTonePercentage: Double,
        dominantColorCount: Int
    ) {
        self.meanLuminance = meanLuminance
        self.luminanceVariance = luminanceVariance
        self.skinTonePercentage = skinTonePercentage
        self.dominantColorCount = dominantColorCount
    }

    /// Detects if image is mostly black
    public var isBlack: Bool {
        meanLuminance < 0.1 && luminanceVariance < 0.01
    }

    /// Detects if image is mostly white
    public var isWhite: Bool {
        meanLuminance > 0.9 && luminanceVariance < 0.01
    }
}
