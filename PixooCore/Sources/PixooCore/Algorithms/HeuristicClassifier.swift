import Foundation

/// Heuristic classifier for detecting useless photos
public struct HeuristicClassifier {
    /// Classify a feature vector into heuristic labels
    /// - Parameters:
    ///   - feature: Extracted feature
    ///   - asset: Asset metadata
    ///   - config: Detection configuration
    /// - Returns: Heuristic result with labels and reasons
    public static func classify(
        feature: Feature,
        asset: Asset,
        config: SweeperConfig
    ) -> HeuristicResult? {
        var labels = [HeuristicLabel]()
        var reasons = [String]()
        var confidenceSum = 0.0
        var confidenceCount = 0

        // 1. Blur detection
        if feature.laplacianVariance < config.blurThreshold {
            labels.append(.blur)
            reasons.append(String(format: "Netteté faible (%.1f < %.1f)", feature.laplacianVariance, config.blurThreshold))
            confidenceSum += 0.8
            confidenceCount += 1
        }

        // 2. Flat/quasi-uniform background
        if feature.entropy < config.flatEntropyThreshold {
            labels.append(.flat)
            reasons.append(String(format: "Fond quasi-uni (entropie %.2f < %.2f)", feature.entropy, config.flatEntropyThreshold))
            confidenceSum += 0.75
            confidenceCount += 1
        }

        // 3. Black detection
        if let colorAnalysis = feature.colorAnalysis {
            if colorAnalysis.isBlack {
                labels.append(.black)
                reasons.append(String(format: "Image très sombre (luminance %.1f%%)", colorAnalysis.meanLuminance * 100))
                confidenceSum += 0.9
                confidenceCount += 1
            }

            // 4. White detection
            if colorAnalysis.isWhite {
                labels.append(.white)
                reasons.append(String(format: "Image très claire (luminance %.1f%%)", colorAnalysis.meanLuminance * 100))
                confidenceSum += 0.9
                confidenceCount += 1
            }

            // 5. Finger detection
            if colorAnalysis.skinTonePercentage > config.fingerSkinToneThreshold &&
               colorAnalysis.luminanceVariance < config.fingerTextureVarianceMax {
                labels.append(.finger)
                reasons.append(String(format: "Doigt probable (%.0f%% zone peau, texture faible)", colorAnalysis.skinTonePercentage * 100))
                confidenceSum += 0.7
                confidenceCount += 1
            }
        }

        // 6. Burst detection (handled separately in groupBursts)
        // This label is added by Sweeper.classify when asset is part of a burst

        // No labels found
        guard !labels.isEmpty else { return nil }

        let averageConfidence = confidenceCount > 0 ? confidenceSum / Double(confidenceCount) : 0.5

        return HeuristicResult(
            assetID: feature.assetID,
            labels: labels,
            confidence: averageConfidence,
            reason: reasons.joined(separator: " • "),
            isSelected: true
        )
    }

    /// Classify multiple features in batch
    public static func classifyBatch(
        features: [Feature],
        assets: [String: Asset],
        config: SweeperConfig
    ) -> [HeuristicResult] {
        features.compactMap { feature in
            guard let asset = assets[feature.assetID] else { return nil }
            return classify(feature: feature, asset: asset, config: config)
        }
    }

    /// Add burst label to assets in burst groups
    public static func markBursts(
        results: inout [HeuristicResult],
        burstGroups: [[Asset]]
    ) {
        // Create set of all assets in bursts (except the first one to keep)
        var burstAssetIDs = Set<String>()
        for group in burstGroups {
            guard group.count > 1 else { continue }
            // Skip first (best quality)
            for asset in group.dropFirst() {
                burstAssetIDs.insert(asset.id)
            }
        }

        // Add burst label to existing results
        results = results.map { result in
            if burstAssetIDs.contains(result.assetID) && !result.labels.contains(.burst) {
                var newLabels = result.labels
                newLabels.append(.burst)
                let separator = result.reason.isEmpty ? "" : " • "
                let newReason = result.reason + separator + "Partie d'une rafale"

                return HeuristicResult(
                    id: result.id,
                    assetID: result.assetID,
                    labels: newLabels,
                    confidence: result.confidence,
                    reason: newReason,
                    isSelected: result.isSelected
                )
            }
            return result
        }

        // Create new results for burst assets not already classified
        let existingIDs = Set(results.map { $0.assetID })
        for assetID in burstAssetIDs where !existingIDs.contains(assetID) {
            results.append(HeuristicResult(
                assetID: assetID,
                labels: [.burst],
                confidence: 0.85,
                reason: "Partie d'une rafale",
                isSelected: true
            ))
        }
    }
}
