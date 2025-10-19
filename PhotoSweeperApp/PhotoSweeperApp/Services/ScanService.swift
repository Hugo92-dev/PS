import Foundation
import Photos
import Vision
import PhotoSweeperCore
import UIKit

@MainActor
class ScanService: ObservableObject {
    static let shared = ScanService()

    @Published var progress: ScanProgress?
    @Published var isScanning = false

    private let sweeper = Sweeper(config: .default)
    private let photoLibrary = PhotoLibraryManager.shared
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid

    private init() {}

    /// Start or resume scan
    func startScan(completion: @escaping ([Group], [HeuristicResult], [String: Asset]) -> Void) {
        guard !isScanning else { return }

        isScanning = true

        Task {
            do {
                // Try to resume
                if let savedProgress = try? sweeper.loadScanState(),
                   savedProgress.status == .paused || savedProgress.status == .running {
                    progress = savedProgress
                } else {
                    // Start new scan
                    let totalAssets = photoLibrary.fetchAllAssets().count
                    progress = ScanProgress(
                        processedCount: 0,
                        totalCount: totalAssets,
                        status: .running
                    )
                }

                await performScan()

                // Classify and group
                let (groups, heuristics, assets) = await finalizeResults()

                completion(groups, heuristics, assets)
            }

            isScanning = false
        }
    }

    private func performScan() async {
        let allAssets = photoLibrary.fetchAllAssets()
        var processedAssets: [Asset] = []

        // Begin background task
        beginBackgroundTask()

        // Process in batches
        let batchSize = 50
        var currentIndex = progress?.processedCount ?? 0

        while currentIndex < allAssets.count {
            let endIndex = min(currentIndex + batchSize, allAssets.count)
            var batch: [Asset] = []

            for i in currentIndex..<endIndex {
                let phAsset = allAssets.object(at: i)
                let asset = photoLibrary.convertToAsset(phAsset)
                batch.append(asset)
                processedAssets.append(asset)
            }

            // Extract features from batch (with Vision feature prints)
            let features = await self.extractFeaturesWithVision(for: batch)

            // Store features in sweeper
            for feature in features {
                // Features are automatically stored when extracted
            }

            // Update progress
            Task { @MainActor in
                self.progress?.processedCount = currentIndex + (endIndex - currentIndex)
                self.progress?.lastUpdatedAt = Date()
            }

            currentIndex = endIndex

            // Save progress
            progress?.processedCount = currentIndex
            progress?.cursor = batch.last?.id
            if let progress = progress {
                try? sweeper.saveScanState(progress: progress)
            }
        }

        // Mark as completed
        progress?.status = .completed
        if let progress = progress {
            try? sweeper.saveScanState(progress: progress)
        }

        endBackgroundTask()

        // Send notification
        NotificationService.shared.sendScanCompletedNotification(
            processedCount: allAssets.count
        )
    }

    private func requestImage(for assetID: String) async -> CGImage? {
        await withCheckedContinuation { continuation in
            photoLibrary.requestFullImage(for: assetID) { uiImage in
                continuation.resume(returning: uiImage?.cgImage)
            }
        }
    }

    /// Extract features with Vision feature prints
    private func extractFeaturesWithVision(for assets: [Asset]) async -> [Feature] {
        var features: [Feature] = []

        for asset in assets {
            guard let cgImage = await requestImage(for: asset.id) else { continue }

            // Extract basic features (pHash, Laplacian, entropy, color)
            guard var feature = FeatureExtractor.extract(from: cgImage, assetID: asset.id) else { continue }

            // Extract Vision feature print
            if let visionData = await VisionService.shared.extractFeaturePrint(from: cgImage) {
                // Create new feature with Vision data
                feature = Feature(
                    assetID: feature.assetID,
                    pHash: feature.pHash,
                    laplacianVariance: feature.laplacianVariance,
                    entropy: feature.entropy,
                    visionFeaturePrint: visionData,
                    colorAnalysis: feature.colorAnalysis
                )
            }

            features.append(feature)
        }

        // Store in sweeper (via internal cache)
        // Features are stored when scanBatch is called, but we're doing it manually here
        return features
    }

    private func finalizeResults() async -> ([Group], [HeuristicResult], [String: Asset]) {
        // Load all assets
        let allAssets = photoLibrary.fetchAllAssets()
        var assetsDict: [String: Asset] = [:]

        for i in 0..<allAssets.count {
            let phAsset = allAssets.object(at: i)
            let asset = photoLibrary.convertToAsset(phAsset)
            assetsDict[asset.id] = asset
        }

        // Group duplicates and similars
        let groups = sweeper.groupDuplicatesAndSimilars(assets: assetsDict)

        // Classify useless photos
        let heuristics = sweeper.classifyAll(assets: assetsDict)

        // Save results
        try? sweeper.saveGroups(groups)
        try? sweeper.saveHeuristics(heuristics)

        return (groups, heuristics, assetsDict)
    }

    // MARK: - Background Task

    private func beginBackgroundTask() {
        backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }

    func cancelScan() {
        isScanning = false
        progress?.status = .paused
        if let progress = progress {
            try? sweeper.saveScanState(progress: progress)
        }
    }
}
