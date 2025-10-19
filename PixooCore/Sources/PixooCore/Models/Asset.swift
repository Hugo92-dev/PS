import Foundation

/// Represents a photo/video asset from the library
public struct Asset: Identifiable, Codable, Hashable {
    public let id: String // PHAsset.localIdentifier
    public let creationDate: Date?
    public let modificationDate: Date?
    public let width: Int
    public let height: Int
    public let fileSize: Int64 // bytes
    public let mediaType: MediaType
    public let isFavorite: Bool
    public let burstIdentifier: String?

    public init(
        id: String,
        creationDate: Date?,
        modificationDate: Date?,
        width: Int,
        height: Int,
        fileSize: Int64,
        mediaType: MediaType,
        isFavorite: Bool,
        burstIdentifier: String?
    ) {
        self.id = id
        self.creationDate = creationDate
        self.modificationDate = modificationDate
        self.width = width
        self.height = height
        self.fileSize = fileSize
        self.mediaType = mediaType
        self.isFavorite = isFavorite
        self.burstIdentifier = burstIdentifier
    }

    public var resolution: Int {
        width * height
    }
}

public enum MediaType: String, Codable {
    case image
    case video
    case livePhoto
}
