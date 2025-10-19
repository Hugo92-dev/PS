import Foundation
import CoreGraphics

/// Main public API for PhotoSweeper Core
public class Sweeper {
    public let config: SweeperConfig
    public let storage: Storage

    private var cachedFeatures: [Feature] = []
    private var cachedAssets: [String: Asset] = [:]

    public init(config: SweeperConfig = .default, storage: Storage? = nil) {
        self.config = config
        self.storage = storage ?? Storage()
    }

    // MARK: - Scan (Streaming)

    /// Process a batch of assets and extract features
    /// - Parameters:
    ///   - assets: Batch of assets to process
    ///   - imageProvider: Closure to provide CGImage for each asset ID
    ///   - progressHandler: Called for each processed asset (current, total)
    /// - Returns: Extracted features for the batch
    public func scanBatch(
        _ assets: [Asset],
        imageProvider: (String) -> CGImage?,
        progressHandler: ((Int, Int) -> Void)? = nil
    ) -> [Feature] {
        var features = [Feature]()

        for (index, asset) in assets.enumerated() {
            guard let cgImage = imageProvider(asset.id) else { continue }

            if let feature = FeatureExtractor.extract(from: cgImage, assetID: asset.id) {
                features.append(feature)
                cachedFeatures.append(feature)
                cachedAssets[asset.id] = asset
            }

            progressHandler?(index + 1, assets.count)
        }

        return features
    }

    /// Save current scan state
    public func saveScanState(progress: ScanProgress) throws {
        try storage.saveScanProgress(progress)
        try storage.saveFeatures(cachedFeatures)
    }

    /// Load scan state (resume)
    public func loadScanState() throws -> ScanProgress? {
        let progress = try storage.loadScanProgress()
        cachedFeatures = try storage.loadFeatures()
        return progress
    }

    /// Clear scan state
    public func clearScanState() throws {
        try storage.clearAll()
        cachedFeatures.removeAll()
        cachedAssets.removeAll()
    }

    // MARK: - Classification

    /// Classify a single asset into heuristic labels
    /// - Parameters:
    ///   - feature: Extracted feature
    ///   - asset: Asset metadata
    /// - Returns: Heuristic result or nil if no labels apply
    public func classify(feature: Feature, asset: Asset) -> HeuristicResult? {
        return HeuristicClassifier.classify(feature: feature, asset: asset, config: config)
    }

    /// Classify all cached features
    public func classifyAll(assets: [String: Asset]) -> [HeuristicResult] {
        var results = HeuristicClassifier.classifyBatch(
            features: cachedFeatures,
            assets: assets,
            config: config
        )

        // Add burst labels
        let burstGroups = Clustering.groupBursts(Array(assets.values), config: config)
        HeuristicClassifier.markBursts(results: &results, burstGroups: burstGroups)

        return results
    }

    // MARK: - Grouping

    /// Group cached features into duplicate and similar clusters
    public func groupDuplicatesAndSimilars(assets: [String: Asset]) -> [Group] {
        return Clustering.groupFeatures(cachedFeatures, assets: assets, config: config)
    }

    /// Save groups to persistent storage
    public func saveGroups(_ groups: [Group]) throws {
        try storage.saveGroups(groups)
    }

    /// Load groups from persistent storage
    public func loadGroups() throws -> [Group] {
        return try storage.loadGroups()
    }

    /// Save heuristic results to persistent storage
    public func saveHeuristics(_ results: [HeuristicResult]) throws {
        try storage.saveHeuristics(results)
    }

    /// Load heuristic results from persistent storage
    public func loadHeuristics() throws -> [HeuristicResult] {
        return try storage.loadHeuristics()
    }

    // MARK: - Estimated Savings

    /// Compute estimated storage savings for selected items
    /// - Parameters:
    ///   - groups: Selected groups
    ///   - heuristics: Selected heuristic results
    ///   - assets: Asset dictionary
    /// - Returns: Total bytes that can be saved
    public func estimatedSavings(
        groups: [Group],
        heuristics: [HeuristicResult],
        assets: [String: Asset]
    ) -> Int64 {
        var totalBytes: Int64 = 0

        // Savings from groups
        for group in groups {
            totalBytes += group.potentialSavings
        }

        // Savings from heuristics
        for result in heuristics where result.isSelected {
            if let asset = assets[result.assetID] {
                totalBytes += asset.fileSize
            }
        }

        return totalBytes
    }

    /// Format byte count as human-readable string (Go, Mo, etc.)
    public static func formatBytes(_ bytes: Int64) -> String {
        let gb = Double(bytes) / 1_073_741_824 // 1024^3
        if gb >= 1.0 {
            return String(format: "%.2f Go", gb)
        }

        let mb = Double(bytes) / 1_048_576 // 1024^2
        if mb >= 1.0 {
            return String(format: "%.1f Mo", mb)
        }

        let kb = Double(bytes) / 1024
        return String(format: "%.0f Ko", kb)
    }

    // MARK: - Statistics

    /// Get scan statistics
    public func getStatistics() -> ScanStatistics {
        return ScanStatistics(
            totalFeaturesExtracted: cachedFeatures.count,
            averageSharpness: cachedFeatures.map { $0.laplacianVariance }.reduce(0, +) / Double(max(cachedFeatures.count, 1)),
            averageEntropy: cachedFeatures.map { $0.entropy }.reduce(0, +) / Double(max(cachedFeatures.count, 1))
        )
    }
}

public struct ScanStatistics {
    public let totalFeaturesExtracted: Int
    public let averageSharpness: Double
    public let averageEntropy: Double
}
