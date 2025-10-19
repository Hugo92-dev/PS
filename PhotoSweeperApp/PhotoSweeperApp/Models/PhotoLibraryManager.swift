import Photos
import UIKit
import PhotoSweeperCore

/// Wrapper around PhotoKit for photo library access
class PhotoLibraryManager {
    static let shared = PhotoLibraryManager()

    private init() {}

    /// Request photo library authorization
    func requestAuthorization() async -> PHAuthorizationStatus {
        return await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    /// Fetch all assets from library
    func fetchAllAssets() -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return PHAsset.fetchAssets(with: options)
    }

    /// Convert PHAsset to our Asset model
    func convertToAsset(_ phAsset: PHAsset) -> Asset {
        return Asset(
            id: phAsset.localIdentifier,
            creationDate: phAsset.creationDate,
            modificationDate: phAsset.modificationDate,
            width: phAsset.pixelWidth,
            height: phAsset.pixelHeight,
            fileSize: estimateFileSize(phAsset),
            mediaType: convertMediaType(phAsset.mediaType),
            isFavorite: phAsset.isFavorite,
            burstIdentifier: phAsset.burstIdentifier
        )
    }

    /// Request image for asset
    func requestImage(
        for assetID: String,
        targetSize: CGSize = CGSize(width: 512, height: 512),
        completion: @escaping (UIImage?) -> Void
    ) {
        guard let phAsset = fetchAsset(by: assetID) else {
            completion(nil)
            return
        }

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        PHImageManager.default().requestImage(
            for: phAsset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            completion(image)
        }
    }

    /// Request full-size image for feature extraction
    func requestFullImage(
        for assetID: String,
        completion: @escaping (UIImage?) -> Void
    ) {
        guard let phAsset = fetchAsset(by: assetID) else {
            completion(nil)
            return
        }

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        options.resizeMode = .exact

        PHImageManager.default().requestImage(
            for: phAsset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            completion(image)
        }
    }

    /// Delete assets (moves to Recently Deleted)
    func deleteAssets(_ assetIDs: [String], completion: @escaping (Bool, Error?) -> Void) {
        let phAssets = assetIDs.compactMap { fetchAsset(by: $0) }

        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(phAssets as NSArray)
        }, completionHandler: completion)
    }

    /// Open Recently Deleted album in Photos app
    func openRecentlyDeleted() {
        if let url = URL(string: "photos-redirect://") {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Private Helpers

    private func fetchAsset(by localIdentifier: String) -> PHAsset? {
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        return result.firstObject
    }

    private func estimateFileSize(_ phAsset: PHAsset) -> Int64 {
        // Estimate based on resolution and media type
        let pixels = phAsset.pixelWidth * phAsset.pixelHeight
        let bytesPerPixel: Int64 = phAsset.mediaType == .video ? 1 : 3

        // Rough estimate (JPEG compression ~10:1)
        return Int64(pixels) * bytesPerPixel / 10
    }

    private func convertMediaType(_ type: PHAssetMediaType) -> MediaType {
        switch type {
        case .image:
            return .image
        case .video:
            return .video
        default:
            return .image
        }
    }
}
