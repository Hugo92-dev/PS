import Foundation

/// Configuration for detection thresholds
public struct SweeperConfig: Codable {
    // MARK: - Duplicate/Similar Detection

    /// Maximum Hamming distance for duplicates (pHash)
    public var duplicateHammingThreshold: Int = 8

    /// Hamming distance range for similars (9-18)
    public var similarHammingMin: Int = 9
    public var similarHammingMax: Int = 18

    /// Vision feature print distance for duplicates (0.0 - 1.0)
    public var duplicateVisionThreshold: Double = 0.05

    /// Vision feature print distance for similars (0.0 - 1.0)
    public var similarVisionThreshold: Double = 0.15

    // MARK: - Heuristic Detection (Useless Photos)

    /// Laplacian variance threshold for blur detection
    /// (tested at 512-1024 px resolution)
    public var blurThreshold: Double = 60.0

    /// Entropy threshold for flat/quasi-uniform backgrounds
    /// (8-bin histogram: ~3.0 = low diversity)
    public var flatEntropyThreshold: Double = 3.0

    /// Percentage threshold for quasi-uniform color detection
    public var flatUniformPercentage: Double = 0.95

    /// Luminance threshold for black detection (0.0 - 1.0)
    public var blackLuminanceMax: Double = 0.1
    public var blackVarianceMax: Double = 0.01

    /// Luminance threshold for white detection (0.0 - 1.0)
    public var whiteLuminanceMin: Double = 0.9
    public var whiteVarianceMax: Double = 0.01

    /// Skin tone percentage threshold for finger detection
    public var fingerSkinToneThreshold: Double = 0.4

    /// Texture variance threshold for finger detection
    public var fingerTextureVarianceMax: Double = 0.05

    /// Time window for burst detection (seconds)
    public var burstTimeWindow: TimeInterval = 2.0

    // MARK: - Performance

    /// Batch size for processing assets
    public var batchSize: Int = 50

    /// Maximum concurrent operations
    public var maxConcurrentOperations: Int = 4

    public init() {}

    public static let `default` = SweeperConfig()

    /// Conservative config (fewer false positives)
    public static let conservative = SweeperConfig(
        duplicateHammingThreshold: 5,
        duplicateVisionThreshold: 0.03,
        blurThreshold: 80.0,
        flatEntropyThreshold: 2.5
    )

    /// Aggressive config (more detections)
    public static let aggressive = SweeperConfig(
        duplicateHammingThreshold: 10,
        similarHammingMax: 20,
        duplicateVisionThreshold: 0.08,
        similarVisionThreshold: 0.2,
        blurThreshold: 50.0,
        flatEntropyThreshold: 3.5
    )

    private init(
        duplicateHammingThreshold: Int,
        duplicateVisionThreshold: Double,
        blurThreshold: Double,
        flatEntropyThreshold: Double
    ) {
        self.duplicateHammingThreshold = duplicateHammingThreshold
        self.duplicateVisionThreshold = duplicateVisionThreshold
        self.blurThreshold = blurThreshold
        self.flatEntropyThreshold = flatEntropyThreshold
    }
}
