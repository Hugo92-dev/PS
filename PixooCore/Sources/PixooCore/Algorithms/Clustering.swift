import Foundation

#if canImport(Vision)
import Vision
#endif

/// Clustering algorithm for grouping duplicates and similar images
public struct Clustering {
    /// Group features into duplicate and similar clusters
    /// - Parameters:
    ///   - features: Array of extracted features
    ///   - assets: Dictionary of assets by ID
    ///   - config: Detection configuration
    /// - Returns: Array of groups
    public static func groupFeatures(
        _ features: [Feature],
        assets: [String: Asset],
        config: SweeperConfig
    ) -> [Group] {
        var groups = [Group]()
        var processed = Set<String>()

        for i in 0..<features.count {
            let feature1 = features[i]
            guard !processed.contains(feature1.assetID) else { continue }

            var duplicateMembers = [feature1.assetID]
            var similarMembers = [feature1.assetID]

            for j in (i + 1)..<features.count {
                let feature2 = features[j]
                guard !processed.contains(feature2.assetID) else { continue }

                // Compute pHash Hamming distance
                let hammingDist = PHash.hammingDistance(feature1.pHash, feature2.pHash)

                // Compute Vision distance (if available)
                var visionDistance: Double? = nil
                if let vp1 = feature1.visionFeaturePrint,
                   let vp2 = feature2.visionFeaturePrint {
                    visionDistance = computeVisionDistance(vp1, vp2)
                }

                // Classify as duplicate or similar
                let isDuplicate = hammingDist <= config.duplicateHammingThreshold ||
                                  (visionDistance ?? 1.0) <= config.duplicateVisionThreshold

                let isSimilar = !isDuplicate && (
                    (hammingDist >= config.similarHammingMin && hammingDist <= config.similarHammingMax) ||
                    ((visionDistance ?? 1.0) > config.duplicateVisionThreshold &&
                     (visionDistance ?? 1.0) <= config.similarVisionThreshold)
                )

                if isDuplicate {
                    duplicateMembers.append(feature2.assetID)
                } else if isSimilar {
                    similarMembers.append(feature2.assetID)
                }
            }

            // Create duplicate group if found
            if duplicateMembers.count > 1 {
                let members = createGroupMembers(
                    assetIDs: duplicateMembers,
                    features: features,
                    assets: assets
                )
                let group = Group(type: .duplicate, members: members)
                groups.append(group)
                processed.formUnion(duplicateMembers)
            }
            // Create similar group if found
            else if similarMembers.count > 1 {
                let members = createGroupMembers(
                    assetIDs: similarMembers,
                    features: features,
                    assets: assets
                )
                let group = Group(type: .similar, members: members)
                groups.append(group)
                processed.formUnion(similarMembers)
            }
        }

        return groups
    }

    /// Create group members with auto-selection
    /// Priority: resolution > sharpness > recency > file size
    private static func createGroupMembers(
        assetIDs: [String],
        features: [Feature],
        assets: [String: Asset]
    ) -> [GroupMember] {
        let featureMap = Dictionary(uniqueKeysWithValues: features.map { ($0.assetID, $0) })

        var members = assetIDs.compactMap { assetID -> GroupMember? in
            guard let asset = assets[assetID],
                  let feature = featureMap[assetID] else { return nil }

            return GroupMember(
                id: assetID,
                fileSize: asset.fileSize,
                resolution: asset.resolution,
                sharpness: feature.laplacianVariance,
                creationDate: asset.creationDate,
                shouldKeep: false,
                isSelected: false
            )
        }

        // Sort by priority: resolution > sharpness > recency > file size
        members.sort { m1, m2 in
            if m1.resolution != m2.resolution {
                return m1.resolution > m2.resolution
            }
            if abs(m1.sharpness - m2.sharpness) > 1.0 {
                return m1.sharpness > m2.sharpness
            }
            if let d1 = m1.creationDate, let d2 = m2.creationDate {
                return d1 > d2
            }
            return m1.fileSize > m2.fileSize
        }

        // Mark best as "keep", rest as "delete"
        if !members.isEmpty {
            members[0].shouldKeep = true
            members[0].isSelected = false
            for i in 1..<members.count {
                members[i].shouldKeep = false
                members[i].isSelected = true
            }
        }

        return members
    }

    /// Compute distance between Vision feature prints
    /// Note: Vision framework is only available at app layer (iOS runtime)
    /// This method attempts to use Vision if available, otherwise returns fallback
    private static func computeVisionDistance(_ fp1: Data, _ fp2: Data) -> Double {
        #if canImport(Vision)
        do {
            let observation1 = try VNFeaturePrintObservation(data: fp1)
            let observation2 = try VNFeaturePrintObservation(data: fp2)

            var distance: Float = 0
            try observation1.computeDistance(&distance, to: observation2)

            return Double(distance)
        } catch {
            // If Vision fails, return fallback
            return 0.5
        }
        #else
        // Vision not available (e.g., in tests), return neutral distance
        return 0.5
        #endif
    }

    /// Group burst photos by burstIdentifier or timestamp proximity
    public static func groupBursts(
        _ assets: [Asset],
        config: SweeperConfig
    ) -> [[Asset]] {
        var burstGroups: [String: [Asset]] = [:]
        var timestampGroups: [[Asset]] = []

        // 1. Group by burstIdentifier (iOS burst mode)
        for asset in assets {
            if let burstID = asset.burstIdentifier {
                burstGroups[burstID, default: []].append(asset)
            }
        }

        // 2. Group by timestamp proximity (±2s)
        let sortedByTime = assets
            .filter { $0.burstIdentifier == nil }
            .sorted { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }

        var currentGroup: [Asset] = []
        for asset in sortedByTime {
            guard let date = asset.creationDate else { continue }

            if let lastDate = currentGroup.last?.creationDate,
               abs(date.timeIntervalSince(lastDate)) <= config.burstTimeWindow {
                currentGroup.append(asset)
            } else {
                if currentGroup.count > 1 {
                    timestampGroups.append(currentGroup)
                }
                currentGroup = [asset]
            }
        }
        if currentGroup.count > 1 {
            timestampGroups.append(currentGroup)
        }

        return Array(burstGroups.values) + timestampGroups
    }
}
